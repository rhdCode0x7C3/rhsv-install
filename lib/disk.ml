module Unix = UnixLabels
module String = StringLabels

type t = { name : string; size : int; id : string }

let pp ppf t =
  Format.fprintf ppf "Name: %s\nSize: %d\nID: %s\n" t.name t.size t.id

let disk_of_json json =
  let open Yojson.Safe.Util in
  {
    name = json |> member "name" |> to_string;
    size = json |> member "size" |> to_int;
    id = json |> member "id" |> to_string;
  }

let get () =
  let ic =
    Unix.open_process_args_in "/usr/bin/lsblk"
      [| "lsblk"; "--bytes"; "--output"; "NAME,SIZE,ID"; "--nodeps"; "--json" |]
  in
  let payload = Yojson.Safe.from_channel ic in
  In_channel.close ic;
  let open Yojson.Safe.Util in
  let devices = payload |> member "blockdevices" |> to_list in
  List.map disk_of_json devices

let select l = User_input.select l pp
