module filetype;

import std.string : removechars, lineSplitter;
import std.container : Array;
import std.regex : Regex, ctRegex, matchFirst;
import std.parallelism : parallel;
import std.algorithm : startsWith, canFind;

import textrecords;

enum LanguageData = import("language.tr");

struct Record
{
	string languageName;
	string extensions;
	string singleLineComment;
	string multiLineCommentOpen;
	string multiLineCommentClose;
}

alias RecordArray = Array!Record;
TextRecords!Record _LanguageRecords;

shared static this()
{
	_LanguageRecords.parse(LanguageData);
}

enum MultiLineCommentType { None, Open, Close, OpenAndClose }

MultiLineCommentType isMultiLineComment(const string line, const string language)
{
	auto found = _LanguageRecords.findByLanguageName(language);

	if(found.length == 1)
	{
		immutable string commentOpen = found[0].multiLineCommentOpen;
		immutable string commentClose = found[0].multiLineCommentClose;

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
	auto found = _LanguageRecords.findByLanguageName(language);

	if(found.length == 1)
	{
		singleLineComment = found[0].singleLineComment;
	}

	if(singleLineComment.length && line.startsWith(singleLineComment))
	{
		return true;
	}

	return false;
}

string getLanguageFromFileExtension(const string extension)
{
	auto records = _LanguageRecords.getRecordsRaw();

	foreach(entry; records)
	{
		import std.array : split;
		immutable auto parts = entry.extensions.split(",");

		foreach(part; parts)
		{
			if(part == extension)
			{
				return entry.languageName;
			}
		}
	}

	return "Unknown";
}
