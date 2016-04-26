module filetype;

import std.container : Array;
import std.string : removechars, lineSplitter;
import std.container : Array;
import std.regex : Regex, ctRegex, matchFirst;
import std.parallelism : parallel;

import raijin.types.records;

enum LanguageData = import("language.sdl");

struct Record
{
	string name;
	string extensions;
}

alias RecordArray = Array!Record;
RecordArray _DatArray;

shared static this()
{
	RecordCollector!Record collector;
	_DatArray = collector.parse(LanguageData);
}

string getLanguageFromFileExtension(const string extension)
{
	foreach(entry; _DatArray)
	{
		import std.array : split;
		immutable auto parts = entry.extensions.split(",");

		foreach(part; parts)
		{
			if(part == extension)
			{
				return entry.name;
			}
		}
	}

	return "Unknown";
}
