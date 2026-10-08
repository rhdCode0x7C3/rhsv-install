module List = ListLabels
module String = StringLabels
module Unix = UnixLabels
open Rhsv_vm

let () =
  let args = Array.of_list (Qemu.prog :: Qemu.vm_opts "hi") in
  let env = [||] in
  let stdout, stdin, stderr = Unix.open_process_args_full Qemu.prog args env in
  print_endline (In_channel.input_all stderr);
  List.iter ~f:In_channel.close [ stdout; stderr ];
  Out_channel.close stdin
