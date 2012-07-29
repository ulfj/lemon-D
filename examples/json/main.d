import std.stdio;
import parser;
import scanner;
import json;

int main(string[] argv)
{
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

	json.Value arr = json.parse(q"([1,2,3,3.14,"txt"])");
	foreach (v; arr) {
		writeln("Value: ", v);
	}

	json.Value x = json.parse("3.14");
	writeln("Value: ", x);

	json.Value y = json.parse("1234");
	writeln("Value: ", y);

	json.Value z = json.parse(q"("a json test string")");
	writeln("Value: ", z);

	return 0;
}
