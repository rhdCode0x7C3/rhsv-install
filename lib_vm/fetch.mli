open Rh_path

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

val pp_error : Format.formatter -> error -> unit [@@ocaml.toplevel_printer]

type _ t =
  | Local : Path.t -> [> `local ] t
  | Remote : string -> [> `remote ] t
  | Both : Path.t * string -> [> `both | `remote ] t

  (*
val file: ?verify:(Path.t -> (unit, error) result) -> t -> (Path.t, error) result
   *)
