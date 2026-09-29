open Config

type _ t =
  | Get_disks : unit -> Disk.t list t
  | Select_disk : Disk.t list -> Disk.t t
  | Partition : Disk.t -> partition list t
  | Mkfs : partition list -> unit t
  | Mount : (partition * mount_opts) list -> unit t

let execute = function Select_disk l -> Disk.select l | _ -> .
