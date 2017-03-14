module statsformatter;

import std.stdio, std.algorithm, std.conv, std.range;

enum COLUMN_WIDTH = 80;

enum Fields
{
	language = 20,
	files = 15,
	code = 15,
	blank = 15,
	comments = 15
}

string formatNumber(T)(T number)
{
	import std.regex : regex, replaceAll;

	auto re = regex(`(?<=\d)(?=(\d\d\d)+\b)`,"g");

	static if(is(typeof(T) == string))
	{
		return number.replaceAll(re, ",");
	}
	else
	{
		return number.to!string.replaceAll(re, ",");
	}
}

void writeDivider()
{
	writeln;
	writeln("-".repeat(COLUMN_WIDTH).join);
}

void writeField(T)(const T value, Fields field)
{
	immutable string strValue = value.formatNumber;
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
