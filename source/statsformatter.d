module statsformatter;
import std.stdio, std.string, std.file, std.algorithm, std.path, std.exception;
import std.range, std.conv, std.parallelism, std.array, std.utf, core.time;

import raijin.utils.string : formatNumber;

enum COLUMN_WIDTH = 80;

enum Fields
{
	language = 20,
	files = 15,
	code = 15,
	blank = 15,
	comments = 15
}

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
