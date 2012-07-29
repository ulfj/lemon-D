lemon-D
=======

Lemon parser with changes to support generating D language code

# Changes to Original Lemon

This project aims at providing better support for the lemon parser generator in the D programming language. 
The changes that was made to the lemon parser involves:

 - Specifying the target language on the command line.
 - Making the lemon parser generate D code when the D language is specified on the command line.
 - Adding a template file for the D programming language (lempar.d)
 
This version of the lemon parser should still run with C/C++. However, this have not yet been verified.

# Using with the D Programming Language


The grammar (calc-01.y) found in the examples folder may be compiled using the command line below:

	lemon L=D T=lempar.d <path>calc-01.y

This will give you a D source file named calc-01.d that should be compilable using the D compiler of your choice.
Notably is that calc-01 not is a valid D module name. The changes made to the lemon parser generator include allowing
a module name directive in the grammar file. The example below is the standard lemon example updated for D:

	%token_type {int}
	%name Calc
	%module_name "calc01"
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

The %module_name directive allow you to set a valid D module name in case the file name contains illegal characters.
The %name directive defines the name of the parser and in case of generating for D using the default lempar.d this 
will be the name of the parser class. To use the generated parser you will need to instantiate this class. The 
unittest code above show how this is done (auto p = new Calc();). 
Invoking the parser is done using the parse() member function. As can be seen in the example above - token identifiers
are generated as members of the parser class.

This example is too trivial to be useful but it gives a reasonable comparison to the original lemon example.

# Using in Conjunction with RE2C

In order to get a better test for the parser we need to build an example that is closer to a real-world scenario. 
My idea was that a JSON parser could be such an example. This example have been changed to the examples/json folder.
This example uses a RE2C scanner with the definitions in scanner.re and the lemon parser in parser.y. This example 
also defines a JSON value struct for storing the parsed result. I was first aiming to use the phobos std.Variant struct
but its implementation did not like being placed in a union, and thus starting out from zeroed memory. The JSON value 
struct in this example is ok with this.

To compile this example you will need to the RE2C found here: https://github.com/ulfj/re2c
This version of RE2C includes some minor updates to generate code that pleases the D compiler.

The scanner.re file is translated into scanner.d by RE2C. This file defines the JsonLexer struct. Together with the 
JSON parser (named JsonParser) they can be used to parse a JSON text string as:

	public Value parse(string jsonText) {
		JsonLexer lexer = JsonLexer(jsonText);
		JsonParser parser = new JsonParser;
		do {
			lexer.lex();
			parser.parse(lexer.yymajor, lexer.yyminor);
		}  while (lexer.yymajor > 0);
		return parser.result_;
	}

Examples of using this function:

Parsing a JSON object and writing the result:

	json.Value obj = json.parse(q"({
			"prop1": 123,
			"prop2": 3.14,
			"prop3": "txt",
			"prop4": [1,2,3,3.14,"txt"],
			"prop5": { "prop6": 1024 }
		   })");

	foreach (k, v; obj) {
		writeln("Member: ", k, " Value: ", v);
	}
	
Simple values:

	json.Value x = json.parse("3.14");
	writeln("Value: ", x);

Assigning from struct to JSON value:

	struct Point {
		real X;
		real Y;
	}

	Point pt = { X: 1, Y: 23 };
	json.Value val;
	val = pt;
	
Or, several levels:

	struct Point {
		real X;
		real Y;
	}

	struct Rect {
		Point topLeft;
		Point bottomRight;
	}

	struct PolyLine {
		int width = 5;
		Point[] coords;
	}

	PolyLine polyline = { width: 7, coords: [ {1,1}, {5,7}, {3,1} ] };

	json.Value val;
	val = polyline;

Writing the value back JSON text:

	json.Value val;
	val = ...;
	auto a = appender!string();
	val.toJSON(a);
	writeln("JSON: ", a.data);
	
