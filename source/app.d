import std.stdio;
import std.parallelism;
import std.file;
import std.string;
import std.path;
import std.array;
import std.conv;
import std.encoding;
import std.utf;
import std.exception;
import std.range : repeat;
import std.container;
import std.conv;
import std.algorithm;

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
		.filter!(a => (!a.name.startsWith(".") && a.isFile));

	foreach(e; parallel(files))
	{
		auto name = buildNormalizedPath(e.name);
		immutable string fileExtension = e.name.baseName.extension.removechars(".");

		if(e.isFile && !e.name.baseName.startsWith("."))
		{
			immutable string text = readText(name).ifThrown!UTFException("");
			auto lines = text.lineSplitter();
			immutable string language = getLanguageFromFileExtension(fileExtension);
			LanguageData data;

			if(language in _ParseResults)
			{
				data = _ParseResults[language];
			}

			++data.files;

			foreach(line; lines)
			{
				if(!line.empty)
				{
					++data.code;
				}
				else
				{
					++data.blank;
				}
			}

			_ParseResults[language] = data;

		}
	}
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
}
