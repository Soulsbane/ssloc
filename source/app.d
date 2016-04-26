import std.stdio : writeln, write;
import std.string : join, removechars, lineSplitter, empty;
import std.range : repeat;
import std.file : dirEntries, DirEntry, getcwd, SpanMode;
import std.algorithm : filter, startsWith;

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
	import std.conv : to;

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
	import std.parallelism : parallel;
	import std.file : getcwd, dirEntries, SpanMode, readText;
	import std.array : array;

	auto files = getcwd.dirEntries(SpanMode.depth)
		.filter!(a => (!isHiddenFileOrDir(a)))
		.array
		.filter!(a => (a.isFile));

	//foreach(e; parallel(files)) // FIXME: Very buggy atm. Needs more research to find out why.
	foreach(e; files)
	{
		import std.path : baseName, buildNormalizedPath, extension;

		auto name = buildNormalizedPath(e.name);
		immutable string fileExtension = e.name.baseName.extension.removechars(".");

		if(e.isFile && !e.name.baseName.startsWith("."))
		{
			import std.utf : UTFException;
			import std.exception : ifThrown;

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
					import std.string : strip, chompPrefix;
					immutable string line = rawLine.strip.chompPrefix("\t");

					if(!line.empty)
					{
						import std.algorithm : canFind;

						if(line.startsWith("//"))
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
				debug writeln("Unknown extension, ", fileExtension, " found!");
			}
		}

		++_TotalNumberOfFiles;
	}
}

bool isHiddenFileOrDir(DirEntry entry)
{
	import std.path : pathSplitter;
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
}
