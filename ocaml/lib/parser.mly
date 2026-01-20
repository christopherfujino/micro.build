%{
  (* Header *)
%}

%token <float> NUMBER

%start <unit> expr

%%

expr: f = NUMBER {
  Printf.printf "%f\n" f
}
