module List = ListLabels
open Rh_path
open Result.Syntax

type error =
  | Download_failed of int * string
  | System of string
  | Cache of Path.t * string
  | Not_found of Path.t
  | Unavailable of Path.t
  | Permissions of Path.t
  | Is_dir of Path.t
  | No_parent
  | Verification of Path.t
  | Always_download
  | Other of Path.t

let pp_error fmt = function
  | Download_failed (code, s) ->
      Format.fprintf fmt "Download failed with code %d: %s\n" code s
  | System s -> Format.fprintf fmt "Sys_error: %s\n" s
  | Cache (p, s) ->
      Format.fprintf fmt "Failed to write to %s\n Error: %s\n"
        (Path.to_string p) s
  | Not_found p -> Format.fprintf fmt "File not found: %s\n" (Path.to_string p)
  | Unavailable p ->
      Format.fprintf fmt "Permission denied: %s\n" (Path.to_string p)
  | Permissions p ->
      Format.fprintf fmt "Permission denied: %s\n" (Path.to_string p)
  | Is_dir p -> Format.fprintf fmt "Is directory: %s\n" (Path.to_string p)
  | No_parent -> print_endline "Path has no parent"
  | Verification p ->
      Format.fprintf fmt "Failed verification: %s\n" (Path.to_string p)
  | Always_download -> print_endline "Always download"
  | Other p -> Format.fprintf fmt "File error - other: %s\n" (Path.to_string p)

type t = Local of Path.t | Both of Path.t * string

let local_file ?verify path =
  let rec aux n path =
    match Unix.stat (Path.to_string path) with
    | stats when stats.st_kind = S_REG && stats.st_perm >= 0o600 -> (
        match verify with
        | Some f -> ( match f path with Ok () -> Ok path | Error e -> Error e)
        | None -> Ok path)
    | stats when stats.st_kind = S_DIR -> Error (Is_dir path)
    | exception Unix.Unix_error (EACCES, _, _) -> Error (Permissions path)
    | exception Unix.Unix_error (ENOENT, _, _) -> Error (Not_found path)
    | exception Unix.Unix_error (EAGAIN, _, _) ->
        if n > 5 then Error (Unavailable path) else aux (n + 1) path
    | _ -> Error (Other path)
  in
  aux 0 path

let cache ~path bytes =
  match
    Out_channel.with_open_bin (Path.to_string path) (fun oc ->
        Out_channel.output_bytes oc bytes)
  with
  | () -> Ok ()
  | exception Sys_error s -> Error (Cache (path, s))

let part_of ~path =
  match Path.parent path with
  | Some parent ->
      let basename = Path.filename path ^ ".part" in
      Ok (Path.append [ basename ] parent)
  | None -> Error No_parent

let remote_file ~path url =
  Format.printf "Fetching remote file from %s\n%!" url;
  let res = Ezcurl.get ~url () in
  match res with
  | Ok s when s.code = 200 -> (
      let* part = part_of ~path in
      match cache ~path:part (Bytes.of_string s.body) with
      | _ -> (
          match local_file part with
          | Ok _ ->
              Sys.rename (Path.to_string part) (Path.to_string path);
              Ok path
          | Error e -> Error e))
  | Ok s -> Error (Download_failed (s.code, url))
  | Error (code, _) -> Error (Download_failed (Curl.int_of_curlCode code, url))

let file ?verify resource =
  match resource with
  | Local path -> local_file ?verify path
  | Both (path, url) -> (
      match local_file path with
      | Ok p -> Ok p
      | Error _ -> (
          match remote_file ~path url with
          | Ok p -> Ok p
          | Error _ -> failwith "Fatal error: unable to fetch file"))
