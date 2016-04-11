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

import filetype;

enum COLUMN_WIDTH = 80;

// TODO: Possibly add blank lines count.
enum Fields
{
	language = 40,
	files = 20,
	lines = 20
}

struct LanguageData
{
	string language;
	size_t numberOfFiles;
	size_t numberOfLines;
}

alias LanguageDataArray = Array!LanguageData;

void writeDivider()
{
	writeln("-".repeat(COLUMN_WIDTH).join);
}

void writeField(const string value, Fields field)
{
	size_t length = value.length;
	size_t numberOfSpaces = field - length;

	if(field == Fields.lines)
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
	writeField("Language", Fields.language);
	writeField("Files", Fields.files);
	writeField("Lines", Fields.lines);
	writeln;
	writeDivider;
}

void scan()
{
	size_t count;

	foreach(DirEntry e; std.parallelism.parallel(dirEntries(".", "*.*", SpanMode.breadth)))
	{
		auto name = buildNormalizedPath(e.name);

		if(e.isFile && !name.startsWith("."))
		{
			immutable string text = readText(name).ifThrown!UTFException("");
			auto lines = text.lineSplitter();

			foreach(line; lines)
			{
				if(!line.empty)
				{
					++count;
				}
			}

		}
	}

	writeln("Number of lines: ", count);
	writeDivider();
}

void main()
{
	scan();
/*	writeHeader;
	writeField("Dlang", Fields.language);
	writeField("534", Fields.files);
	writeField("35678", Fields.lines);
	writeln;
	writeDivider;*/
}
