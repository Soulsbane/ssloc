module filetype;

import std.stdio : writeln;
import std.container;
import std.string : lineSplitter;
import std.algorithm.searching : findSplit;
import std.conv : to;

enum LanguageData = import("language.dat");

struct FileTypeData
{
	string language;
	string extensions;
}

alias FileTypeDataArray  = Array!FileTypeData;
FileTypeDataArray fileTypeDataArray_;

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
	string language;
	return language;
}
