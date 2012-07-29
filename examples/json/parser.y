%include {   

import std.array;
import std.typecons;
import json;

}

%token_type			{ json.Value }
%default_type		{ json.Value }
%extra_argument		{ json.Value result_ }
%module_name		"parser"
%token_prefix		TK_
%token_destructor	{ }
%name				JsonParser

%start_symbol	json_value

//
// JSON parser
//

json_value(A) ::= value(B). { 
	A = B; 
	result_ = A; 
}

// object
object(A) ::= L_CURLYBRACKET R_CURLYBRACKET. { 
	json.Value[string] o;
	A = o;
}

object(A) ::= L_CURLYBRACKET members(B) R_CURLYBRACKET.	{ 
	A = B; 
}

// members
members(A) ::= pair(B).	{ 
	if (A.type != Type.Object) {
		json.Value[string] o = [ B[0]: json.Value(B[1]) ];
		A = o;
	}
	else {
		A[B[0]] = B[1];
	}
}

members(A) ::= members(B) COMMA pair(C). { 
	A = B; 
	A[C[0]] = C[1]; 
}

// pair
%type pair { Tuple!(string, json.Value) }
pair(A)	::= STRING(B) COLON value(C). { 
	A = tuple(B.get!string, C); 
}

// array
array(A) ::= L_SQBRACKET R_SQBRACKET. { 
	json.Value[] a;
	A = a; 
}

array(A) ::= L_SQBRACKET elements(B) R_SQBRACKET. { 
	A = B.data; 
}

// elements 
%type elements { Appender!(json.Value[]) }
elements(A) ::= value(B). { 
	A.put(B); 
}

elements(A) ::= elements(B) COMMA value(C).	{ 
	A = B; 
	A.put(C); 
}

// values
value(A) ::= STRING|INTEGER|FLOAT|LIT_TRUE|LIT_FALSE|LIT_NULL(B).	{ A = B; }
value(A) ::= object(B).												{ A = B; }
value(A) ::= array(B).												{ A = B; }

