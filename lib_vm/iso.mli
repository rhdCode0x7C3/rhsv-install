open Rh_path

type error =
  | File_not_found of Path.t
  | Checksum_mismatch of Sha256.t * Sha256.t
  | Regex
  | Fetch of Fetch.error

val pp_error : Format.formatter -> error -> unit
val get : unit -> (Path.t, error) result
