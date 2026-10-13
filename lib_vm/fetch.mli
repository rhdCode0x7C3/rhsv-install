open Rh_path

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

val pp_error : Format.formatter -> error -> unit [@@ocaml.toplevel_printer]

type t = Local of Path.t | Both of Path.t * string

val file: ?verify:(Path.t -> (unit, error) result) -> t -> (Path.t, error) result
