module List = ListLabels
module Unix = UnixLabels
open Rh_path

type error = Path of Path.t | URL of string

let required_dirs = [ Config.iso_dir; Config.base_dir; Config.overlays_dir ]
let mkdir_p dir = Unix.execv ~prog:"mkdir" ~args:[| "mkdir"; "-p"; dir |]

let dirs () =
  List.iter
    ~f:(fun dir -> mkdir_p dir)
    (List.map ~f:Path.to_string required_dirs)

(* let download_iso ~url () = failwith "Unimplemented" *)
(**)
(* let iso ?p ~url = *)
(*   match p with *)
(*   | Some path -> ( try Ok (Unix.stat path) with _ -> Error (Path path)) *)
(*   | None -> ( try Ok (download_iso ~url ()) with _ -> Error (URL url)) *)
