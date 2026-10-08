module Unix = UnixLabels
open Rh_path

let arch = "x86_64"
let vm_name = "rhsv-vm"
let home_dir = Unix.getenv "HOME" |> Path.of_string
let share_dir = Path.append [ ".local"; "share" ] home_dir
let data_dir = Path.append [ vm_name ] share_dir
let iso_dir = Path.append [ "iso" ] data_dir
let base_dir = Path.append [ "base" ] data_dir
let overlays_dir = Path.append [ "overlays" ] data_dir
