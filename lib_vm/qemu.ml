module List = ListLabels
module String = StringLabels

type opt = KV of string * string | V of string

let mk_option = function V s -> s | KV (k, v) -> Format.sprintf "%s=%s" k v
let mk_opts l = String.concat ~sep:"," (List.map ~f:mk_option l)
let mk_flag flag = Format.sprintf "-%s" flag
let mk_flag_opts (flag, opts) = [ mk_flag flag; mk_opts opts ]

(* QEMU command line options*)
let prog = Format.sprintf "qemu-system-%s" Config.arch
let machine_opts = ("machine", [ KV ("type", "q35"); KV ("accel", "tcg") ])
let cpu_opts = ("cpu", [ V "max" ])
let smp_opts = ("smp", [ V "2" ])
let m_opts = ("m", [ V "4G" ])
let scsi_opts = ("device", [ V "virtio-scsi-pci" ])

let hd_opts =
  ( "device",
    [ V "scsi-hd"; KV ("drive", "hd"); KV ("serial", "IM A FAKE HARD DRIVE") ]
  )

let rng_opts = ("device", [ V "virtio-rng-pci" ])
let rtc_opts = ("rtc", [ KV ("base", "utc"); KV ("clock", "host") ])
let nic_opts = ("nic", [ V "user"; KV ("hostfwd", "tcp::2222-:22") ])

(* let proto_disk_opts ~img = *)
(*   let open Rh_path in *)
(*   ( "blockdev", *)
(*     [ *)
(*       KV ("driver", "file"); *)
(*       KV ("node-name", "proto_disk"); *)
(*       KV ("filename", Path.to_string img); *)
(*       KV ("cache.direct", "on"); *)
(*     ] ) *)

let vm_opts () =
  Ok
    (List.flatten
       (List.map ~f:mk_flag_opts
          [
            machine_opts;
            cpu_opts;
            smp_opts;
            m_opts;
            scsi_opts;
            hd_opts;
            rng_opts;
            rtc_opts;
            nic_opts;
            (* proto_disk_opts ~img; *)
          ]))
