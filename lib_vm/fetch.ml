let void_url = "https://repo-default.voidlinux.org/live/current/"
let checksum_url = String.concat "" [ void_url; "sha256sum.txt" ]
let iso_re = Re.compile (Re.Pcre.re "void-live-x86_64-\\d{8}-base.iso")

type error =
  | Parser
  | File_not_found of Rh_path.Path.t
  | Checksum_mismatch of Sha256.t * Sha256.t
  | Download_failed of Curl.curlCode * string

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

let iso_exists name =
  let open Rh_path in
  try
    match
      (Unix.stat (Path.to_string (Path.append [ name ] Config.iso_dir))).st_kind
    with
    | S_REG -> true
    | _ ->
        Format.printf "ISO exists on disk\n";
        false
  with _ ->
    Format.printf "ISO does not exist on disk\n";
    false

let check_iso name checksum =
  Format.printf "Verifying SHA256 of ISO on disk\n";
  let open Rh_path in
  let iso_path = Path.append [ name ] Config.iso_dir in
  let url_cs = Sha256.of_hex checksum in
  let file_cs = Sha256.file (Path.to_string iso_path) in
  try
    if Sha256.equal url_cs file_cs then Ok ()
    else Error (Checksum_mismatch (url_cs, file_cs))
  with _ -> Error (File_not_found iso_path)

let fetch_iso name =
  Format.printf "Fetching ISO";
  let open Rh_path in
  let dest = Path.append [ name ] Config.iso_dir in
  let url = String.concat "" [ void_url; name ] in
  let res = Ezcurl.get ~url () in
  match res with
  | Ok c ->
      Ok
        (Out_channel.with_open_bin (Path.to_string dest) (fun oc ->
             Out_channel.output_bytes oc (Bytes.of_string c.Ezcurl_core.body)))
  | Error (code, _) -> Error (Download_failed (code, url))

let run () =
  let ( let* ) = Result.bind in
  let* txt = fetch_checksums () in
  let* name, checksum = name_and_checksum txt in
  if iso_exists name then
    match check_iso name checksum with
    | Ok () -> Ok ()
    | Error _ -> fetch_iso name
  else fetch_iso name
