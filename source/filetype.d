module filetype;

import std.algorithm : find, startsWith, canFind;
import textrecords;

enum MultiLineCommentType
{
	None,
	Open,
	Close,
	OpenAndClose
}

struct Record
{
	string languageName;
	string extensions;
	string singleLineComment;
	string multiLineCommentOpen;
	string multiLineCommentClose;
}

TextRecords!Record _LanguageRecords;

shared static this()
{
	immutable string languageData = import("language.tr");
	_LanguageRecords.parse(languageData);
}

MultiLineCommentType isMultiLineComment(const string line, const string language)
{
	auto found = _LanguageRecords.findByLanguageName(language);
	// FIXME: Really need a better check.
	if(found.singleLineComment.length)
	{
		immutable string commentOpen = found.multiLineCommentOpen;
		immutable string commentClose = found.multiLineCommentClose;

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
	// TODO: Handle comments that appear at middle/end of line.
	string singleLineComment;
	auto found = _LanguageRecords.findByLanguageName(language);

	if(found.singleLineComment.length)
	{
		singleLineComment = found.singleLineComment;
	}

	if(singleLineComment.length && line.find(singleLineComment).length)
	{
		return true;
	}

	return false;
}

string getLanguageFromFileExtension(const string extension)
{
	foreach(entry; _LanguageRecords)
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
