module filetype;

import std.container : Array;
import std.string : removechars, lineSplitter;
import std.container : Array;
import std.regex : Regex, ctRegex, matchFirst;
import std.parallelism : parallel;
import std.algorithm : filter, startsWith, canFind;

import textrecords;

enum LanguageData = import("language.sdl");

struct Record
{
	string name;
	string extensions;
	string singleLineComment;
	string multiLineCommentOpen;
	string multiLineCommentClose;
}

alias RecordArray = Array!Record;
RecordArray _DatArray;

shared static this()
{
	TextRecords!Record collector;
	_DatArray = collector.parseRaw(LanguageData);
}

enum MultiLineCommentType { None, Open, Close, OpenAndClose }

MultiLineCommentType isMultiLineComment(const string line, const string language)
{
	auto found = _DatArray[].filter!(a => a.name == language);

	if(!found.empty)
	{
		immutable string commentOpen = found.front.multiLineCommentOpen;
		immutable string commentClose = found.front.multiLineCommentClose;

		if(commentOpen.length && (line.startsWith(commentOpen) && line.canFind(commentClose)))
		{
			return MultiLineCommentType.OpenAndClose;
		}

		if(commentOpen.length && line.startsWith(commentOpen))
		{
			return MultiLineCommentType.Open;
		}

		if(commentClose.length && line.canFind(commentClose))
		{
			return MultiLineCommentType.Close;
		}
	}

	return MultiLineCommentType.None;
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
