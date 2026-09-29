module List = ListLabels

let print_kv k v v_printer =
  Format.printf "%s)\n" k;
  v_printer Format.std_formatter v;
  print_newline

let alist l =
  let indices =
    List.init ~len:(List.length l) ~f:(fun i -> string_of_int (i + 1))
  in
  List.combine indices l

let print alist v_printer =
  List.iter
    ~f:(fun el ->
      let k, v = el in
      print_kv k v v_printer ())
    alist

let rec select l v_printer =
  let alist = alist l in
  Format.printf "Select one of the following options:\n\n";
  print alist v_printer;
  let selected =
    match
      List.assoc_opt
        (print_string "# ";
         read_line ())
        alist
    with
    | Some v -> v
    | None ->
        print_endline "Invalid selection";
        select l v_printer
  in
  selected
