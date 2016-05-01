module filetype;

import std.container : Array;
import std.string : removechars, lineSplitter;
import std.container : Array;
import std.regex : Regex, ctRegex, matchFirst;
import std.parallelism : parallel;
import std.algorithm : filter, startsWith;

import raijin.types.records;

enum LanguageData = import("language.sdl");

struct Record
{
	string name;
	string extensions;
	string singleLineComment;
}

alias RecordArray = Array!Record;
RecordArray _DatArray;

shared static this()
{
	RecordCollector!Record collector;
	_DatArray = collector.parse(LanguageData);
}

bool isSingleLineComment(const string line, const string language)
{
	string singleLineComment;
	auto found = _DatArray[].filter!(a => a.name == language);

	if(!found.empty)
	{
		singleLineComment = found.front.singleLineComment;
	}

	if(singleLineComment.length && line.startsWith(singleLineComment))
	{
		return true;
	}

	return false;
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
