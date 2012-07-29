module scanner;
import std.variant;
import std.typetuple;
import std.typecons;
import std.conv;
import std.array;
import json;
import parser;
	
struct JsonLexer {

	alias int       yymajor_type;
	alias json.Value token_type;

	private yymajor_type     yymajor_;
	private token_type       yyminor_;
	private immutable(char)* tokenStart_;
	private immutable(char)* YYMARKER;
	private immutable(char)* YYCURSOR;

	this(string json) {
		YYCURSOR    = json.ptr;
		tokenStart_ = json.ptr;
		YYMARKER    = json.ptr;
	}
	@property yymajor_type yymajor() {
		return yymajor_;
	}
	@property token_type yyminor() {
		return yyminor_;
	}

	string yytext() {
		return tokenStart_[0..YYCURSOR - tokenStart_];
	}

	yymajor_type lex() {
		yyminor_ = yyminor_.init;

	lbl_std:
		tokenStart_ = YYCURSOR;

	/*!re2c
		re2c:define:YYCTYPE	= char;
		re2c:yyfill:enable  = 0;

		digit			=	[0-9];
		hexdigit		=	[0-9a-fA-F];
		hexdigit4		=	hexdigit{4};
		ws				=	[ \t\r];
		integer			=	([-])?digit+;
		float           =	([-])? digit+ "." digit* ([eE] ([+-])? digit+)?;
		schar			=	"\\\"" | [^\"];
		string			=	["](schar)*["];
		any				=	[\001-\377];

		[\n]+				{ goto lbl_std; }
		ws+					{ goto lbl_std; }

		"\""				{ goto lbl_escaped_string_start; }

		"["					{ return yymajor_ = JsonParser.TK_L_SQBRACKET; }
		"]"					{ return yymajor_ = JsonParser.TK_R_SQBRACKET; }
		"{"					{ return yymajor_ = JsonParser.TK_L_CURLYBRACKET; }
		"}"					{ return yymajor_ = JsonParser.TK_R_CURLYBRACKET; }
		","					{ return yymajor_ = JsonParser.TK_COMMA; }
		":"					{ return yymajor_ = JsonParser.TK_COLON; }
		"true"				{ yyminor_ = true;  return yymajor_ = JsonParser.TK_LIT_TRUE; }
		"false"				{ yyminor_ = false; return yymajor_ = JsonParser.TK_LIT_FALSE; }
		"null"				{ yyminor_ = null; return yymajor_ = JsonParser.TK_LIT_NULL; }

		integer				{ yyminor_ = to!int(yytext()); return yymajor_ = JsonParser.TK_INTEGER; }
		float				{ yyminor_ = to!real(yytext()); return yymajor_ = JsonParser.TK_FLOAT;   }
		[\000]				{ return yymajor_ = 0; }
		[\001-\377]			{ return yymajor_ = -1; }
	*/

lbl_escaped_string_start:
		
		auto a = appender!string();

lbl_escaped_string:

		tokenStart_ = YYCURSOR;

	/*!re2c
	
		"\\\""					{ a.put('\"'); goto lbl_escaped_string; }
		"\\\\"					{ a.put('\\'); goto lbl_escaped_string; }
		"\\/"					{ a.put('/'); goto lbl_escaped_string; }
		"\\b"					{ a.put('\b'); goto lbl_escaped_string; }
		"\\f"					{ a.put('\f'); goto lbl_escaped_string; }
		"\\n"					{ a.put('\n'); goto lbl_escaped_string; }
		"\\r"					{ a.put('\r'); goto lbl_escaped_string; }
		"\\t"					{ a.put('\t'); goto lbl_escaped_string; }
		"\\u" hexdigit4			{	
									static assert('a' > 'A', "Logic error - assumption that 'a' > 'A' failed");
									dchar c = 0;
									foreach (ch; tokenStart_[2 .. 6]) { 
										c = c << 4;
										if (ch > 'a')
											c |= ch - 'a' + 10;
										else if (ch > 'A')
											c |= ch - 'A' + 10;
										else
											c |= ch - '0';
									}
									a.put(c);
									goto lbl_escaped_string; 
								}
		"\\" any				{ 
									// Accepts an unknown escape char as the char itself (is this correct?)
									a.put(*YYCURSOR); 
									goto lbl_escaped_string; 
								}
		"\""					{ yyminor_ = a.data; return yymajor_ = JsonParser.TK_STRING;  }
		[^"\\]+					{ a.put(yytext()); goto lbl_escaped_string; }
	*/
	}

};


