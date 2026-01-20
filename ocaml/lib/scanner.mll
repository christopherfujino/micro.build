{
  (* header *)
  open Parser
}

(* TODO: implement decimal *)
let num = ('0'|(['1'-'9']['0'-'9']*))

(* `rule`, `parse` are keywords *)
rule read = parse
  | num as lexeme { NUMBER (float_of_string lexeme) }
