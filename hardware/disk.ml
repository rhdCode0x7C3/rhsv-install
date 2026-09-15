module Unix = UnixLabels

let myfunc = print_endline "Hello from hardware disk!"

let lsblk () =
  let input = Unix.open_process_in "lsblk -o NAME,SIZE,MODEL --json" in
  let return = In_channel.input_all input in
  In_channel.close input;
  return
