import std.stdio : writeln, write;
import std.string : join, removechars, lineSplitter, empty, strip, chompPrefix;
import std.range : repeat;
import std.file : dirEntries, DirEntry, getcwd, SpanMode, readText;
import std.algorithm : filter, startsWith, canFind;
import std.path : baseName, buildNormalizedPath, extension, pathSplitter;
import std.conv : to;
import std.parallelism : parallel;
import std.array : array;
import std.utf : UTFException;
import std.exception : ifThrown;

import filetype;

enum COLUMN_WIDTH = 60;

enum Fields
{
	language = 20,
	files = 10,
	code = 10,
	blank = 10,
	comments = 10
}

size_t _TotalBlankLines;
size_t _TotalCodeLines;
size_t _TotalCommentLines;
size_t _TotalNumberOfFiles;

struct LanguageData
{
	size_t files;
	size_t code;
	size_t blank;
	size_t comments;
}

LanguageData[string] _ParseResults;

void writeDivider()
{
	writeln;
	writeln("-".repeat(COLUMN_WIDTH).join);
}

void writeField(T)(const T value, Fields field)
{
	immutable string strValue = value.to!string;
	immutable size_t length = strValue.length;
	size_t numberOfSpaces = field - length;

	if(field == Fields.code)
	{
		write(" ".repeat(numberOfSpaces).join);
		write(value);
	}
	else
	{
		write(value);
		write(" ".repeat(numberOfSpaces).join);
	}
}

void writeHeader()
{
	writeln;
	writeField("Language", Fields.language);
	writeField("Files", Fields.files);
	writeField("Blank", Fields.blank);
	writeField("Comments", Fields.comments);
	writeField("Code", Fields.code);
	writeDivider;
}

void scan()
{
	auto files = getcwd.dirEntries(SpanMode.depth)
		.filter!(a => (!isHiddenFileOrDir(a)))
		.array
		.filter!(a => (a.isFile));

	//foreach(e; parallel(files)) // FIXME: Very buggy atm. Needs more research to find out why.
	foreach(e; files)
	{
		auto name = buildNormalizedPath(e.name);
		immutable string fileExtension = e.name.baseName.extension.removechars(".");
		immutable string text = readText(name).ifThrown!UTFException("");
		auto lines = text.lineSplitter();
		immutable string language = getLanguageFromFileExtension(fileExtension);

		if(language != "Unknown")
		{
			LanguageData data;

			if(language in _ParseResults)
			{
				data = _ParseResults[language];
			}

			++data.files;

			foreach(rawLine; lines)
			{
				immutable string line = rawLine.strip.chompPrefix("\t");

				if(!line.empty)
				{
					if(isSingleLineComment(line, language))
					{
						++data.comments;
						++_TotalCommentLines;
					}
					else
					{
						++data.code;
						++_TotalCodeLines;
					}
				}
				else
				{
					++data.blank;
					++_TotalBlankLines;
				}
			}

			_ParseResults[language] = data;
		}
		else
		{
			if(!fileExtension.empty)
			{
				debug writeln("Unknown extension, ", fileExtension, " found!");
			}
		}

		++_TotalNumberOfFiles;
	}
}

bool isHiddenFileOrDir(DirEntry entry)
{
	auto dirParts = entry.name.pathSplitter;

	foreach(dirPart; dirParts)
	{
		if(dirPart.startsWith("."))
		{
			return true;
		}
	}

	return false;
}

void main()
{
	scan();
	writeHeader;

	foreach(key, data; _ParseResults)
	{
		writeField(key, Fields.language);
		writeField(data.files, Fields.files);
		writeField(data.blank, Fields.blank);
		writeField(data.comments, Fields.comments);
		writeField(data.code, Fields.code);
		writeDivider;
	}

	writeln;
	writeField("Total", Fields.language);
	writeField(_TotalNumberOfFiles, Fields.files);
	writeField(_TotalBlankLines, Fields.blank);
	writeField(_TotalCommentLines, Fields.comments);
	writeField(_TotalCodeLines, Fields.code);
	writeDivider;
	writeln;
}
