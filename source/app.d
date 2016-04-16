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

import filetype;

enum COLUMN_WIDTH = 80;

// TODO: Possibly add blank lines count.
enum Fields
{
	language = 40,
	files = 20,
	code = 20
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
	writeField("Code", Fields.code);
	writeDivider;
}

void scan()
{
	foreach(DirEntry e; std.parallelism.parallel(dirEntries(".", "*.*", SpanMode.breadth)))
	{
		auto name = buildNormalizedPath(e.name);
		immutable string fileExtension = e.name.extension.removechars(".");

		if(e.isFile && !name.startsWith("."))
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
		writeField(data.code, Fields.code);
		writeDivider;
	}
}
