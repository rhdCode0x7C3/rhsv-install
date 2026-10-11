module List = ListLabels

let void_url = "https://repo-default.voidlinux.org/live/current/"
let checksum_url = void_url ^ "sha256sum.txt"

let iso_re =
  Re.compile (Re.Pcre.re "(void-live-x86_64-\\d{8}-base\\.iso).{4}(.*)")

type error =
  | Parser of string
  | Checksum_mismatch of Sha256.t * Sha256.t
  | Download_failed of int * string
  | System of string

let pp_error fmt = function
  | Parser s -> Format.fprintf fmt "Parser error:\n%s\n" s
  | Checksum_mismatch (a, b) ->
      Format.fprintf fmt "Checksum mismatch:\n Expected: %s\n Got:      %s\n"
        (Sha256.to_hex a) (Sha256.to_hex b)
  | Download_failed (code, s) ->
      Format.fprintf fmt "Download failed with code %d: %s\n" code s
  | System s -> Format.fprintf fmt "Sys_error: %s\n" s

let ( let* ) = Result.bind

let fetch_checksums () =
  Format.printf "Fetching checksums from %s\n" checksum_url;
  let res = Ezcurl.get ~url:checksum_url () in
  match res with
  | Ok s ->
      if s.code = 200 then Ok s.body
      else Error (Download_failed (s.code, checksum_url))
  | Error (code, _) ->
      Error (Download_failed (Curl.int_of_curlCode code, checksum_url))

let name_and_checksum checksums =
  Format.printf "Parsing filename and checksum\n";
  let* groups =
    try Ok (Re.exec iso_re checksums)
    with Not_found -> Error (Parser "Groups not found")
  in
  match (Re.Group.get groups 1, Re.Group.get groups 2) with
  | name, checksum ->
      Format.printf "Name: %s\nChecksum: %s\n" name checksum;
      Ok (name, checksum)
  | exception Not_found ->
      Error (Parser "Failed to parse file name and checksum")

let check_iso name checksum =
  Format.printf "Verifying SHA256 of ISO on disk\n";
  let open Rh_path in
  let iso_path = Path.append [ name ] Config.iso_dir in
  let url_cs = Sha256.of_hex checksum in
  match Sha256.file (Path.to_string iso_path) with
  | v ->
      if Sha256.equal v url_cs then Ok ()
      else Error (Checksum_mismatch (url_cs, v))
  | exception Sys_error s -> Error (System s)

let fetch_iso name checksum =
  Format.printf "Fetching ISO\n";
  let open Rh_path in
  let dest = Path.append [ name ] Config.iso_dir in
  let url = String.concat "" [ void_url; name ] in
  let res = Ezcurl.get ~url () in
  let* () =
    match res with
    | Ok c ->
        Ok
          (Out_channel.with_open_bin (Path.to_string dest) (fun oc ->
               Out_channel.output_bytes oc (Bytes.of_string c.Ezcurl_core.body)))
    | Error (code, _) ->
        Error (Download_failed (Curl.int_of_curlCode code, url))
  in
  check_iso name checksum

let run () =
  let* txt = fetch_checksums () in
  let* name, checksum = name_and_checksum txt in
  match check_iso name checksum with
  | Ok () -> Ok ()
  | Error (Checksum_mismatch _) -> fetch_iso name checksum
  | Error (System s) -> failwith (Format.asprintf "Fatal error: %s" s)
  | _ -> failwith (Format.asprintf "Fatal error")
