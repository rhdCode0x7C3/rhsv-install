module List = ListLabels
module String = StringLabels
module Unix = UnixLabels
open Rhsv_vm

let () =
  let qemu_opts =
    match Qemu.vm_opts () with
    | Ok opts -> opts
    | Error e ->
        Fetch.pp_error Format.std_formatter e;
        failwith "Fatal error"
  in
  let args = Array.of_list (Qemu.prog :: qemu_opts) in
  let env = [||] in
  let stdout, stdin, stderr = Unix.open_process_args_full Qemu.prog args env in
  print_endline (In_channel.input_all stderr);
  List.iter ~f:In_channel.close [ stdout; stderr ];
  Out_channel.close stdin
