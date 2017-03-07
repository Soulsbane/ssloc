import std.stdio, std.string, std.file, std.algorithm, std.path, std.exception;
import std.range, std.conv, std.parallelism, std.array, std.utf, core.time;

import raijin.utils.string : formatNumber;

import filetype;

enum COLUMN_WIDTH = 80;

enum Fields
{
	language = 20,
	files = 15,
	code = 15,
	blank = 15,
	comments = 15
}

size_t _TotalBlankLines;
size_t _TotalCodeLines;
size_t _TotalCommentLines;
size_t _TotalNumberOfFiles;
size_t _TotalNumberOfLines;
size_t _TotalNumberOfUnknowns;

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
	immutable string strValue = value.to!string.formatNumber;
	immutable size_t numberOfSpaces = field - strValue.length;

	if(field == Fields.code)
	{
		write(" ".repeat(numberOfSpaces).join);
		write(strValue);
	}
	else
	{
		write(strValue);
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
		immutable string language = getLanguageFromFileExtension(fileExtension);

		if(language != "Unknown")
		{
			LanguageData data;
			immutable string text = readText(name).ifThrown!UTFException("");
			auto lines = text.lineSplitter().array;

			if(language in _ParseResults)
			{
				data = _ParseResults[language];
			}

			++data.files;
			_TotalNumberOfLines = _TotalNumberOfLines + lines.length;

			bool inCommentBlock;

			foreach(rawLine; lines)
			{
				immutable string line = rawLine.strip.chompPrefix("\t");

				//if(!line.empty || inCommentBlock) // Maybe as an option to count blanks if inside comment block
				if(!line.empty)
				{
					if(isSingleLineComment(line, language))
					{
						++data.comments;
						++_TotalCommentLines;
					}
					else if(auto commentType = isMultiLineComment(line, language))
					{
						if(commentType == MultiLineCommentType.Open)
						{
							++data.comments;
							++_TotalCommentLines;

							inCommentBlock = true;
						}

						if(commentType == MultiLineCommentType.Close)
						{
							++data.comments;
							++_TotalCommentLines;

							inCommentBlock = false;
						}
					}
					else if(inCommentBlock)
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
				++_TotalNumberOfUnknowns;
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
	auto startTime = MonoTime.currTime;

	scan();

	auto endTime = MonoTime.currTime;
	auto timeTaken = endTime - startTime;

	writeln;
	writeln("Time taken: ", timeTaken);
	writeln("Total lines processed: ", _TotalNumberOfLines.formatNumber);
	writeln("Total files ignored: ", _TotalNumberOfUnknowns.formatNumber);
	 // TODO: Maybe add a list of ignored extensions as a command line argument.?
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
