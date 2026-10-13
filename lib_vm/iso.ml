open Rh_path
open Result.Syntax

type error =
  | File_not_found of Path.t
  | Checksum_mismatch of Sha256.t * Sha256.t
  | Regex
  | Fetch of Fetch.error

let pp_error fmt = function
  | File_not_found p ->
      Format.fprintf fmt "File not found: %s" (Path.to_string p)
  | Checksum_mismatch (expected, got) ->
      Format.fprintf fmt "Checksum mismatch\nExpected: %s\nGot:    %s\n"
        (Sha256.to_hex expected) (Sha256.to_hex got)
  | Regex -> Format.fprintf fmt "Regex error"
  | Fetch e -> Fetch.pp_error fmt e

let fetch ?verify resource =
  match Fetch.file ?verify resource with
  | Ok ic -> Ok ic
  | Error e -> Error (Fetch e)

let manifest_resource =
  Fetch.Both (Config.iso_manifest_path, Config.iso_manifest_url)

let manifest () =
  let* path =
    fetch ~verify:(fun _ -> Error Always_download) manifest_resource
  in
  Ok
    (In_channel.with_open_text (Path.to_string path) (fun ic ->
         In_channel.input_all ic))

let name_and_checksum manifest =
  let iso_re =
    Re.compile
      (Re.Pcre.re "(void-live-x86_64-\\d{8}-base\\.iso)\\) = ([0-9a-f]{64})")
  in
  match Re.exec iso_re manifest with
  | exception Not_found -> Error Regex
  | groups -> Ok (Re.Group.get groups 1, Re.Group.get groups 2)

let get () =
  let* manifest = manifest () in
  let* name, checksum = name_and_checksum manifest in
  let path = Path.append [ name ] Config.iso_dir in
  let url = Config.void_url ^ name in
  let verify path =
    let open Sha256 in
    let expected = of_hex checksum in
    let actual = file (Path.to_string path) in
    if equal expected actual then Ok ()
    else Error (Checksum_mismatch (expected, actual))
  in
  match fetch (Both (path, url)) with
  | Ok path -> ( match verify path with Ok () -> Ok path | Error e -> Error e)
  | Error e -> Error e
