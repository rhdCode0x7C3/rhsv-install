type p_type = EFI | Linux_fs
type partition = { n : int; size : int; (* size in GiB *) p_type : p_type }
type mount_opts = string list
