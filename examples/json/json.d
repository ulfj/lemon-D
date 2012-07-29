module json;
import std.traits;
import std.array;
import std.conv;
import std.algorithm;
import core.stdc.string;
import std.stdio;
import scanner;
import parser;

/**
 * Find the most suitable type supported by the json value struct or void if 
 * no suitable type can be found.
 * Returns: The JSON type associated with the type T or void if no type can
 *          be determined.
 */
template toJsonType(T)
{
	static if (is(T == bool)) { 
		alias bool toJsonType; 
	}
	else static if (is(T : long)) {
		alias long toJsonType; 
	}
	else static if (is(T : real)) { 
		alias real toJsonType; 
	}
	else static if (is(T == typeof(null))) {
		alias typeof(null) toJsonType;
	}
	else static if (is(T : const(char[])) || is(T : const(wchar[])) || is(T : const(dchar[]))) {
		alias string toJsonType; 
	}
	else static if (is(T x: U[], U)) {
		static if (!is(toJsonType!U == void)) {
			alias Value[] toJsonType;
		}
		else {
			alias void toJsonType;
		}
	}
	else static if (is(T x: U[string], U)) {
		static if (!is(toJsonType!U == void)) {
			alias Value[string] toJsonType;
		}
		else {
			alias void toJsonType;
		}
	}
	else {
		// Make it void if no suitable type can be found
		alias void toJsonType;
	}
}
unittest {
	// Compile-time validation for toJsonType!T
	static assert(is(toJsonType!short == long));
	static assert(is(toJsonType!int == long));
	static assert(is(toJsonType!long == long));

	static assert(is(toJsonType!string == string));
	static assert(is(toJsonType!wstring == string));
	static assert(is(toJsonType!dstring == string));

	static assert(is(toJsonType!bool == bool));

	static assert(is(toJsonType!float == real));
	static assert(is(toJsonType!double == real));
	static assert(is(toJsonType!real == real));

	static assert(is(toJsonType!(short[]) == Value[]));
	static assert(is(toJsonType!(float[]) == Value[]));
	static assert(is(toJsonType!(string[]) == Value[]));
	static assert(is(toJsonType!(Value[]) == Value[]));

	static assert(is(toJsonType!(int[string]) == Value[string]));
	static assert(is(toJsonType!(string[string]) == Value[string]));
	static assert(is(toJsonType!(Value[string]) == Value[string]));

	static assert(is(toJsonType!(typeof(null)) == typeof(null)));
}

/**
 * The enumeration type that describes the value contained in the json.value struct.
 */
public enum Type : byte {
	Undefined = 0,		/// The json.value struct contains no value (uninitialized/zeroed memory)
	Null,				/// The json null value
	Boolean,			/// Boolean true or false value
	String,				/// The $(XREF json.Value) struct contains a string
	Integer,			/// The $(XREF json.Value) struct contains an integer value
	Number,				/// The $(XREF json.Value) struct contains a floating point value
	Object,				/// The $(XREF json.Value) struct contains a JSON object (D associative array json.Value[string])
	Array				/// The $(XREF json.Value) struct contains a JSON array (json.Value[])
}

/**
 * Finds the JSON type enumeration value associated with the type T.
 * Returns: The JSON type as described by the $(XREF json.Type) enumeration.
 */
template toJsonTypeId(T)
{
	     static if (is(toJsonType!T == real))   		enum toJsonTypeId = Type.Number;
	else static if (is(toJsonType!T == bool))   		enum toJsonTypeId = Type.Boolean;
	else static if (is(toJsonType!T == long))   		enum toJsonTypeId = Type.Integer;
	else static if (is(toJsonType!T == string))   		enum toJsonTypeId = Type.String;
	else static if (is(toJsonType!T == Value[])) 	   	enum toJsonTypeId = Type.Array;
	else static if (is(toJsonType!T == Value[string])) 	enum toJsonTypeId = Type.Object;
	else static if (is(toJsonType!T == typeof(null)))   enum toJsonTypeId = Type.Null;
	else                                                enum toJsonTypeId = Type.Undefined;
}
unittest {
	static assert(toJsonTypeId!real 		   == Type.Number);
	static assert(toJsonTypeId!bool 		   == Type.Boolean);
	static assert(toJsonTypeId!long 		   == Type.Integer);
	static assert(toJsonTypeId!string 		   == Type.String);
	static assert(toJsonTypeId!(Value[]) 	   == Type.Array);
	static assert(toJsonTypeId!(Value[string]) == Type.Object);
	static assert(toJsonTypeId!(typeof(null))  == Type.Null);
	static assert(toJsonTypeId!void 		   == Type.Undefined);
}

/**
 * The json.Value struct type
 */
struct Value {
	
	private Type type_;		/// The json.Type enumeration value describing the content of the json.Value union.

	/// Union of all possible JSON values
	private union {
		void*         	u_;	/// undefined - (variable to associate the undefined type with)
		typeof(null)  	n_;	/// null - (variable to associate the null type with)
		bool 			b_;	/// boolean value storage
		string 			s_;	/// string value storage
		long          	i_;	/// integer value storage
		real 			r_;	/// floating point value storage
		Value[string] 	o_;	/// JSON object value storage
		Value[] 	  	a_;	/// JSON array value storage
	}

	/// Return a reference to the storage variable associated with storing values of type T.
	/// The return value is typed using the JSON type of T.
	@property private ref toJsonType!T vref(T)() {
		     static if (is(toJsonType!T == real))   		   return r_;
		else static if (is(toJsonType!T == bool))   		   return b_;
		else static if (is(toJsonType!T == long))   		   return i_;
		else static if (is(toJsonType!T == typeof(null)))      return n_;
		else static if (is(toJsonType!T == string))   		   return s_;
		else static if (is(toJsonType!T == Value[])) 	   	   return a_;
		else static if (is(toJsonType!T == Value[string])) 	   return o_;
		else                                                   return u_;
	}
	
	/// Construct a json.Value from a value of type T.
	this(T)(T v) {
		opAssign(v);
	}

	/**
	 * Implememts the assignment operator for the json.Value struct.
	 * Params:
	 *      v = The value to assign from.
	 * Returns: A reference to this
	 */
	ref Value opAssign(T)(T v) {
		static if ((is(T x : U[], U) || is(T x : U[N], size_t N)) && !isSomeString!T) {
			// An array of type U
			auto a = appender!(Value[])();
			a.reserve(v.length);
			foreach (ref item; v) {
				a.put(Value(item));
			}
			type_ = Type.Array;
			a_ = a.data;
			return this;
		}
		else static if (is(T == Value)) {
			// The copy is "shallow" and this will refer to the same array/object.
			memcpy(&this, &v, v.sizeof);
			return this;
		}
		else static if (is(T == struct) || is(T == class)) {
			// Assigning to a json value from a struct. An oppurtunity for some D compile-time magic.
			// Lets try to assign each value member of the D struct to a member of the json object.
			string assignFrom(T)() {
				string a;
				foreach (i, m; __traits(allMembers, T)) {
					if (!__traits(isFinalFunction, T, m) && !__traits(isStaticFunction, T, m)) {
						a ~= `this["` ~ m ~ `"] = v.` ~ m ~ ";\n";
					}
				}
				return a;
			}
			mixin(assignFrom!T());
			return this;
		}
		else static if (!is(toJsonType!T == void)) {
			type_ = toJsonTypeId!T;
			vref!T = v;
			return this;
		}
		else {
			static assert(false, "Unsupported type being asigned");
		}
	}

	/// Return the json.Type enumeration value of the json.Value struct.
	@property public Type type() {
		return type_;
	}

	/// Clears the content of the json.Value struct. This leaves the json.Value struct
	/// with the type Type.Undefined.
	public void clear() {
		memset(&this, 0, this.sizeof);
	}

	/// Returns the value at position index of a JSON array.
	public Value opIndex(int index) {
		if (type_ == Type.Array) {
			return a_[index];
		}
		//if (type_ == Type.String) {
		//    return Value(s_[index]);
		//}
		throw new Exception("Index operator not supported on scalar json types or objects");
	}

	/// Returns a member of a JSON object.
	public Value opIndex(string member) {
		if (type_ == Type.Object) {
			return o_[member];
		}
		throw new Exception("Member (string index) operator not supported on scalar types, arrays or strings");
	}

	public ref Value opIndexAssign(T)(T value, size_t index) {
		
	}

	/// Assigning a new member to a JSON object or updating an existing member
	public ref Value opIndexAssign(T)(T value, string index) 
	in {
		assert(type_ != Type.Undefined || vref!(Value[string]) == null);
	}
	body {
		if (type_ == Type.Undefined) {
			// The JSON value have not yet been assigned anything (or its been cleared) so
			// it should be ok to morph this object into a JSON object type and assign the value.
			type_ = Type.Object;
		}
		else if (type_ == Type.Object) {
			// Fine - already an object
		}
		else {
			// The JSON value contains a type other than object or undefined
			debug writeln("Assigning to JSON value member although the JSON value not is an object: ", type_);
			throw new Exception("Assigning to JSON value member although the JSON value not is an object");
		}
		// The Value struct in the associative array is not being initialized correctly by the compiler.
		// The commented line below may be more efficient when this problem have been fixed.
		//vref!(Value[string])[index] = value;
		vref!(Value[string])[index] = Value(value);
		return this;
	}

	/// Iterate values contained in this JSON array. This function does 
	/// nothing if this json.Value does not contain an array. 
    int opApply(scope int delegate(ref Value value) dg)
    {
		int result = 0;
		if (type_ == Type.Array) {
			auto a = vref!(Value[]);
			if (a !is null) {
				foreach (v; a) {
					result = dg(v);
					if (result)
						break;
				}
			}
		}
		return result;
    }

	/// Iterate keys and values of a JSON object. This function does nothing unless 
	/// this object contains a JSON object.
    int opApply(scope int delegate(string key, ref Value value) dg)
    {
		int result = 0;
		if (type_ == Type.Object) {
			auto o = vref!(Value[string]);
			if (o !is null) {
				foreach (k, v; o) {
					result = dg(k, v);
					if (result)
						break;
				}
			}
		}
		return result;
    }

	/// Returns a string representation of the value contained in the json.Value struct.
	/// Note that the returned string does not conform to the JSON format. Use the function
	/// toJSON to retrieve a string that conforms to JSON formatting.
    string toString() const {
		final switch (type_) {
			case Type.Undefined:	return "(undefined)";
			case Type.Null:			return "(null)";
			case Type.Boolean:		return to!string(b_);
			case Type.Integer:		return to!string(i_);
			case Type.Number:		return to!string(r_);
			case Type.Array:		return to!string(a_);
			case Type.String:		return to!string(s_);
			case Type.Object:		return to!string(o_);
		}
	}

	void toJSON(OutputRange)(ref OutputRange o) const {

		void comma(ref OutputRange o, ref bool first) {
			if (first) 
				first = false;
			else 
				o.put(",");
		}

        void toJsonString(ref OutputRange o, string str) {
			o.put('"');
			foreach (dchar c; str) {
				switch(c) {
					case '"':  o.put("\\\""); break;
					case '\\': o.put("\\\\"); break;
					case '/':  o.put("\\/");  break;
					case '\b': o.put("\\b");  break;
					case '\f': o.put("\\f");  break;
					case '\n': o.put("\\n");  break;
					case '\r': o.put("\\r");  break;
					case '\t': o.put("\\t");  break;
					default:
						if (c > 0x007F) {
							o.put(`\u`);
							o.put(cast(char)(((c & 0xF000) >> 12) + '0'));
							o.put(cast(char)(((c & 0x0F00) >>  8) + '0'));
							o.put(cast(char)(((c & 0x00F0) >>  4) + '0'));
							o.put(cast(char)(((c & 0x000F) >>  0) + '0'));
						}
						else
							o.put(c);
				}
			}
			o.put('"');
        }

		final switch (type_) {
			case Type.Undefined:
				// Bad - cannot serialize undefined json value.
				throw new Exception("Serializing an undefined JSON value");
			case Type.Null:
				o.put("null");
				break;
			case Type.Boolean:
				o.put(b_ ? "true" : "false");
				break;
			case Type.Integer:		
				o.put(to!string(i_));
				break;
			case Type.Number:
				o.put(to!string(r_));
				break;
			case Type.String:		
				toJsonString(o, s_);
				break;
			case Type.Array:
				bool first = true;
				o.put('[');
				foreach (i, ref v; a_) {
					comma(o, first);
					v.toJSON(o);
				}
				o.put(']');
				break;
			case Type.Object:
				bool first = true;
				o.put('{');
				foreach (key, ref v; o_) {
					comma(o, first);
					toJsonString(o, key);
					o.put(':');
					v.toJSON(o);
				}
				o.put('}');
				break;
		}
	}

	Value* getMember(string name) {
		if (type_ == Type.Object) {
			return name in o_;
		}
		return null;
	}

	@property public T get(T)() {
		T value;
		this.get(value);
		return value;
	}

	public void get(T)(out T value) {
		static if ((is(T x : U[], U) || is(T x : U[N], size_t N)) && !isSomeString!T) {
			// Get value into an array of type U
			static if (is(T x : U[], U)) {
				// Dynamic array - set size
				auto count = (value.length = this.length);
			}
			else {
				// Static array - use size of smallest array
				auto count = min(value.length, this.length);
			}
			foreach (i; 0 .. count) {
				this[i].get(value[i]);
			}
		}
		else static if (is(T == Value)) {
			value = this;
		}
		else static if (is(T == struct) || is(T == class)) {
			// Assign value to a struct or class
			string assignTo(T)() {
				string a; // mixin string
				foreach (i, m; __traits(allMembers, T)) {
					if (!__traits(isFinalFunction, T, m) && !__traits(isStaticFunction, T, m)) {
						a ~= `{auto p = getMember("` ~ m ~ `");`;
						a ~= `if (p) p.get(value.` ~ m ~ `);}`;
					}
				}
				return a;
			}
			pragma (msg, "GENERATED CODE:" ~ assignTo!T());
			mixin(assignTo!T());
		}
		else static if (is(T == bool)) { 
			 if (type_ == Type.Boolean)
				value = b_;
		}
		else static if (is(T : long)) {
			if (type_ == Type.Integer)
				value = to!T(i_);
		}
		else static if (is(T : real)) { 
			if (type_ == Type.Number)
				value = to!T(r_);
			else if (type_ == Type.Integer)
				value = to!T(i_);
		}
		else static if (is(T == typeof(null))) {
			value = null;
		}
		else static if (is(T : const(char[])) || is(T : const(wchar[])) || is(T : const(dchar[]))) {
			value = to!T(s_);
		}
		else static if (is(T x: U[string], U)) {
			static if (!is(toJsonType!U == void)) {
				foreach (k, v; this) {
					v.get!U(value[key]);
				}
			}
		}
		else {
			static assert(false, "Unsupported type being asigned");
		}
	}

	public bool opEquals(T)(T rhs) if (!is(toJsonType!T == void) || is(T == Value)) {
		static if (is(T == Value)) {
			return this.opCmp(rhs) == 0;
		}
		else {
			if (type_ != toJsonTypeId!T)
				return false;
			static if (Type.Null == toJsonTypeId!T)
				return true;	// all nulls are equal
			else
				return get!T == rsh;
		}
	}

	public int opCmp(T)(ref const Value rsh) {
		if (type_ != rhs.type_)
			throw new Exception("Comparing JSON values of nonmatching types");
		return get!T < rsh ? -1 : (get!T == rsh ? 0 : 1);
	}

	public int opCmp(T)(ref const T rhs) if (!is(toJsonType!T == void)) {
		if (type_ != toJsonTypeId!T)
			throw new Exception(text("Comparing JSON value with nonmatching type ", T.stringof));
		return get!T < rhs ? -1 : (get!T == rhs ? 0 : 1);
	}
}

unittest {
	
	// A json-value that not have been given a value should be undefined
	auto a0 = Value();
	assert(a0.type == Type.Undefined);

	Value a1;
	assert(a1.type == Type.Undefined);

	// json null value
	Value a2 = null;
	auto a3 = Value(null);
	assert(a2 == null);
	assert(a3 == null);
	assert(a2.type == Type.Null);
	assert(a3.type == Type.Null);

	// object
	
	Value[string] o0 = [ "prop1": Value(12.6), "prop2": Value(3.14) ];
	Value o = o0;
	assert(o.type == Type.Object);


	
}

public Value parse(string jsonText) {
	JsonLexer lexer = JsonLexer(jsonText);
	JsonParser parser = new JsonParser;
	do {
		lexer.lex();
		parser.parse(lexer.yymajor, lexer.yyminor);
	}  while (lexer.yymajor > 0);
	return parser.result_;
}

unittest {
	auto jsons = [
		`null`,
		`true`,
		`false`,
		`0`,
		`123`,
		`-4321`,
		`0.23`,
		`-0.23`,
		`""`,
		`1.223e+24`,
		`"hello\nworld"`,
		`"\"\\\/\b\f\n\r\t"`,
		`[]`,
		`[12,"foo",true,false]`,
		`{}`,
		`{"a":1,"b":null}`,
		`{"hello":{"json":"is great","array":[12,null,{}]},"goodbye":[true,"or",false,["test",42,{"nested":{"a":23.54,"b":0.0012}}]]}`,
		`"\u003C\u003E"`,
		`"\u0391\u0392\u0393"`,
		`"\u2660\u2666"`
	];

	Value val;
	string result;
	foreach(json; jsons) {
		try {
			val = parse(json);
			auto a = appender!string();
			val.toJSON(a);
			writeln("Parsed value: ", a.data);
			//result = toJSON(&val);
			//assert(result == json, text(result, " should be ", json));
		}
		catch(Exception e) {
//			writefln(text(json, "\n", e.toString()));
		}
	}

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

	Point pt = { X: 1, Y: 23 };
	val.clear();
	val = pt;

	Point pt2;
	val.get(pt2);
	assert(pt2 == pt);

	auto a = appender!string();
	val.toJSON(a);
	writeln("Assigned value: ", a.data);

	Rect rc;
	rc.topLeft.X = 0;
	rc.topLeft.Y = 1;
	rc.bottomRight.X = 80;
	rc.bottomRight.Y = 24;

	val.clear();
	val = rc;
	a = a.init;
	val.toJSON(a);
	writeln("Assigned value: ", a.data);

	val.clear();
	val = polyline;
	a = a.init;
	val.toJSON(a);
	writeln("Assigned value: ", a.data);

	string v0 = "test string";
	Value a1 = "test string";
	string v1;
	a1.get(v1);
	assert(v1 == v0);
	assert(v1 is v0);

//    // Should be able to correctly interpret unicode entities
//    val = json.parse();
////	assert(val.toJSON() == "\"\&lt;\&gt;\"");
//    val = json.parse();
////	assert(toJSON(&val) == "\"\&Alpha;\&Beta;\&Gamma;\"");
//    val = json.parse(`"\u2660\u2666"`);
////	assert(toJSON(&val) == "\"\&spades;\&diams;\"");
//

}