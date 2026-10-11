let void_url = "https://repo-default.voidlinux.org/live/current/"
let checksum_url = String.concat "" [ void_url; "sha256sum.txt" ]
let iso_re = Re.compile (Re.Pcre.re "void-live-x86_64-\\d{8}-base\.iso")

type error =
  | Parser
  | Checksum_mismatch of Sha256.t * Sha256.t
  | Download_failed of Curl.curlCode * string
  | Sys_error of string

let pp_error fmt = function
  | Parser -> Format.fprintf fmt "Parser error\n"
  | Checksum_mismatch (a, b) ->
      Format.fprintf fmt "\nChecksum mismatch:\n\n%s\n\n%s\n\n  "
        (Sha256.to_hex a) (Sha256.to_hex b)
  | Download_failed (code, s) ->
      Format.fprintf fmt "Download failed with code %d: %s\n"
        (Curl.int_of_curlCode code)
        s
  | Sys_error s -> Format.fprintf fmt "Sys_error: %s\n" s

let ( let* ) = Result.bind

let fetch_checksums () =
  Format.printf "Fetching checksums from %s\n" checksum_url;
  let res = Ezcurl.get ~url:checksum_url () in
  match res with
  | Ok s -> Ok s.body
  | Error (code, _) -> Error (Download_failed (code, checksum_url))

let get_line_number s grp =
  let start_pos = Re.Group.start grp 0 in
  let count_newlines s to_pos =
    let rec aux s i n =
      if i >= to_pos then n
      else
        match String.get s i with
        | '\n' -> aux s (i + 1) (n + 1)
        | _ -> aux s (i + 1) n
    in
    aux s 0 0
  in
  count_newlines s start_pos

let name_and_checksum checksums =
  Format.printf "Parsing filename and checksum\n";
  try
    let groups = Re.exec iso_re checksums in
    let name = Re.Group.get groups 0 in
    let line_n = get_line_number checksums groups in
    let lines = String.split_on_char '\n' checksums in
    match List.nth_opt lines line_n with
    | Some line -> (
        match String.split_last ~sep:" " line with
        | Some (_, s) -> Ok (name, s)
        | None -> Error Parser)
    | None -> Error Parser
  with Not_found -> Error Parser

let check_iso name checksum =
  Format.printf "Verifying SHA256 of ISO on disk\n";
  let open Rh_path in
  let iso_path = Path.append [ name ] Config.iso_dir in
  let url_cs = Sha256.of_hex checksum in
  match Sha256.file (Path.to_string iso_path) with
  | v ->
      if Sha256.equal v url_cs then Ok ()
      else Error (Checksum_mismatch (url_cs, v))
  | exception Sys_error s -> Error (Sys_error s)

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
    | Error (code, _) -> Error (Download_failed (code, url))
  in
  check_iso name checksum

let run () =
  let* txt = fetch_checksums () in
  let* name, checksum = name_and_checksum txt in
  match check_iso name checksum with
  | Ok () -> Ok ()
  | Error _ -> fetch_iso name checksum
