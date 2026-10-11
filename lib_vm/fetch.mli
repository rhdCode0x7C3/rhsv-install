type error =
  | Parser
  | Checksum_mismatch of Sha256.t * Sha256.t
  | Download_failed of Curl.curlCode * string
  | Sys_error of string

val pp_error : Format.formatter -> error -> unit
val run : unit -> (unit, error) result
