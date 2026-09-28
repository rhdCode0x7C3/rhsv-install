open Config

type t =
  | Inspect_hardware of unit
  | Partition of disk
  | Mkfs of partition list
  | Mount of (partition * mount_opts) list
