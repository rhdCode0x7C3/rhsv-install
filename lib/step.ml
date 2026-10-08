open Config

type error

type _ t =
  | Get_disks : Disk.t list t
  | Select_disk : Disk.t list -> Disk.t t
  | Partition : Disk.t -> partition list t
  | Mkfs : partition list -> unit t
  | Mount : (partition * mount_opts) list -> unit t

let execute : type a. a t -> (a, error) result = function
  | Get_disks -> Ok (Disk.get ())
  | Select_disk l -> Ok (Disk.select l)
  | _ -> failwith "unimplemented"
