type error =
  | Parser of string
  | Checksum_mismatch of Sha256.t * Sha256.t
  | Download_failed of int * string
  | Sys_error of string

val pp_error : Format.formatter -> error -> unit [@@ocaml.toplevel_printer]
val run : unit -> (unit, error) result
