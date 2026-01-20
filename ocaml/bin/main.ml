open Micro_build

let rec eval () =
  let s = read_line () in
  let lexbuf = Lexing.from_string s in
  let ast = Parser.expr Scanner.read lexbuf in
  ignore ast;
  eval ()

let () = eval ()
