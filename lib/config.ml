open Rh_path

type disk = Path.t
type partition = Path.t
type mount_opts = partition * string list
type t = { disk : disk; partitions : partition list; mount_opts : mount_opts }
