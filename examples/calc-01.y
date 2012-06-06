%token_type {int}
%name Calc
%left PLUS MINUS.
%left DIVIDE TIMES.

%include {

	unittest {
		auto p = new Calc();
    
		/* First input: 15 / 5 */
		p.parse(Calc.INTEGER, 15);
		p.parse(Calc.DIVIDE, 0);
		p.parse(Calc.INTEGER, 5);
		p.parse(0, 0);

		/* Second input: 50 + 125 */
		p.parse(Calc.INTEGER, 50);
		p.parse(Calc.PLUS, 0);
		p.parse(Calc.INTEGER, 125);
		p.parse(0, 0);

		/* Third input: 50 * 125 + 125 */
		p.parse(Calc.INTEGER, 50);
		p.parse(Calc.TIMES, 0);
		p.parse(Calc.INTEGER, 125);
		p.parse(Calc.PLUS, 0);
		p.parse(Calc.INTEGER, 125);
		p.parse(0, 0);
	}
}

%syntax_error {
	writeln("Syntax error!");
}

program ::= expr(A).   { writeln("Result=", A); }

expr(A) ::= expr(B) MINUS  expr(C).   { A = B - C; }
expr(A) ::= expr(B) PLUS  expr(C).   { A = B + C; }
expr(A) ::= expr(B) TIMES  expr(C).   { A = B * C; }
expr(A) ::= expr(B) DIVIDE expr(C).  {
	if (C != 0) {
		A = B / C;
	} else {
		writeln("divide by zero");
	}
}  /* end of DIVIDE */
expr(A) ::= INTEGER(B). { A = B; }
