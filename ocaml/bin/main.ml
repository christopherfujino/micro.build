open Micro_build

let eval_line line =
  let lexbuf = Lexing.from_string line in
  let ast = Parser.expr Scanner.read lexbuf in
  ignore ast

(*
let rec eval () =
  let s = read_line () in
  eval_line s;
  eval ()
*)

let () =
  let test_specs = ["42"; "21"] in
  List.iter eval_line test_specs
