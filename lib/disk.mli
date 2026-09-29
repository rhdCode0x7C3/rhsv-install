type t = { name : string; size : int; id : string }

val pp : Format.formatter -> t -> unit [@@ocaml.toplevel_printer]
val get : unit -> t list
val select : t list -> t
