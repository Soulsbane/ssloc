module filetype;

import std.stdio : writeln;
import std.container;
import std.string : lineSplitter;
import std.algorithm.searching : findSplit, canFind;
import std.conv : to;

enum LanguageData = import("language.dat");

struct FileTypeData
{
	string language;
	string extensions;
}

alias FileTypeDataArray  = Array!FileTypeData;
FileTypeDataArray fileTypeDataArray_;

shared static this()
{
	loadFileTypeData();
}

void loadFileTypeData()
{
	auto lines = LanguageData.lineSplitter();

	foreach(wholeLine; lines)
	{
		auto line = findSplit(wholeLine.to!string, ";");
		FileTypeData data;

		data.extensions = line[0];
		data.language = line[2];

		fileTypeDataArray_.insert(data);
	}
}

string getLanguageFromFileExtension(const string extension)
{
	foreach(entry; fileTypeDataArray_)
	{
		if(entry.extensions.canFind(extension))
		{
			return entry.language;
		}
	}

	return "Unknown";
}
