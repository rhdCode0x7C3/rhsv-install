module List = ListLabels
open Rh_path
open Result.Syntax

type error =
  | Bad_response of int * string
  | Download_failed of string * string
  | System of string
  | Cache of Path.t * string
  | Not_found of Path.t
  | Unavailable of Path.t
  | Permissions of Path.t
  | Is_dir of Path.t
  | No_parent
  | Verification of Path.t
  | Malformed_url of string
  | Other of Path.t

let pp_error fmt = function
  | Bad_response (code, s) ->
      Format.fprintf fmt "Download failed with code %d: %s\n" code s
  | Download_failed (s, url) ->
      Format.fprintf fmt "Download failed:\nURL: %s\nMessage: %s" url s
  | System s -> Format.fprintf fmt "Sys_error: %s\n" s
  | Cache (p, s) ->
      Format.fprintf fmt "Failed to write to %a\n Error: %s\n" Path.pp p s
  | Not_found p -> Format.fprintf fmt "File not found: %a\n" Path.pp p
  | Unavailable p -> Format.fprintf fmt "Unavailable: %a\n" Path.pp p
  | Permissions p -> Format.fprintf fmt "Permission denied: %a\n" Path.pp p
  | Is_dir p -> Format.fprintf fmt "Is directory: %a\n" Path.pp p
  | No_parent -> print_endline "Path has no parent"
  | Verification p -> Format.fprintf fmt "Failed verification: %a\n" Path.pp p
  | Malformed_url url -> Format.fprintf fmt "Malformed URL: %s\n" url
  | Other p -> Format.fprintf fmt "File error - other: %a\n" Path.pp p

type _ t =
  | Local : Path.t -> [> `local ] t
  | Remote : string -> [> `remote ] t
  | Both : Path.t * string -> [> `both | `remote ] t

let filename url =
  match String.split_last ~sep:"/" url with
  | Some (_, fn) -> Ok fn
  | None -> Error (Malformed_url url)

let path_of = function
  | Local path | Both (path, _) -> Ok path
  | Remote url ->
      let* fn = filename url in
      Ok (Path.append [ fn ] Config.data_dir)

let part_of =
  let random_string length =
    let buf = Buffer.create length in
    for _ = 1 to length do
      Buffer.add_char buf (Char.chr (97 + Random.int 26))
    done;
    Buffer.contents buf
  in
  function
  | Local path | Both (path, _) -> Ok path
  | Remote url ->
      let* fn = filename url in
      let part_nm = fn ^ random_string 16 in
      Ok (Path.append [ part_nm ] Config.data_dir)

let download ?path url =
  let final_path =
    match path with
    | Some path -> Ok path
    | None ->
        let* fn = filename url in
        Ok (Path.append [ fn ] Config.data_dir)
  in
  let oc p = open_out_bin (Path.to_string p) in
  let cleanup oc path () =
    close_out_noerr oc;
    try Sys.remove (Path.to_string path) with _ -> ()
  in
  let write_into oc : Ezcurl.input_stream =
    object
      method on_input = output oc

      method on_close =
        fun () ->
          flush oc;
          close_out oc
    end
  in
  let* part = part_of (Remote url) in
  let oc = oc part in
  let write_into = write_into oc in
  let res = Ezcurl.http_stream ~url ~meth:Ezcurl.GET ~write_into () in
  match res with
  | exception _ ->
      cleanup oc part ();
      Error (Download_failed (url, "Ezcurl raised an exception"))
  | Ok r when r.code = 200 -> (
      let* path = final_path in
      try
        Sys.rename (Path.to_string part) (Path.to_string path);
        Ok path
      with _ -> Error (System "Sys.rename raised an exception"))
  | Ok r -> Error (Bad_response (r.code, url))
  | Error (_, s) -> Error (Download_failed (url, s))

let cache : [< `remote | `both ] t -> (Path.t, error) result = function
  | Remote url -> download url
  | Both (path, url) -> download url ~path
