module filetype;

import std.container : Array;
import std.string : removechars, lineSplitter;
import std.container : Array;
import std.regex : Regex, ctRegex, matchFirst;
import std.parallelism : parallel;

enum LanguageData = import("language.sdl");
Regex!char _Pattern = ctRegex!(r"\s+(?P<key>\w+)\s+(?P<value>.*)");

struct Record
{
	string name;
	string extensions;
}

alias RecordArray = Array!Record;
alias StringArray = Array!string;

RecordArray _DatArray;

shared static this()
{
	loadFileTypeData();
}

private Record convertToRecord(StringArray strArray)
{
	Record data;

	foreach(line; strArray)
	{
		auto re = matchFirst(line, _Pattern);

		if(!re.empty)
		{
			immutable string key = re["key"].removechars("\"");
			immutable string value = re["value"].removechars("\"");

			final switch(key)
			{
				case "name":
					data.name = value;
					break;
				case "extensions":
					data.extensions = value;
					break;
			}
		}
	}

	return data;
}

private void loadFileTypeData()
{
	import std.algorithm : canFind;
	auto lines = LanguageData.lineSplitter();

	StringArray strArray;

	foreach(line; lines)
	{
		if(line.canFind("{"))
		{
			strArray.clear();
		}
		else if(line.canFind("}"))
		{
			_DatArray.insert(convertToRecord(strArray));
		}
		else
		{
			strArray.insert(line);
		}
	}
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
