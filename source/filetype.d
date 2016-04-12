module filetype;

import std.stdio : writeln;
import std.container;
import std.string : lineSplitter;
import std.algorithm.searching : findSplit, canFind;
import std.conv : to;

import sdlang;

enum LanguageData = import("language.sdl");

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
	Tag root;
	root = parseSource(LanguageData.to!string);

	foreach(tag; root.tags["language"])
	{
		FileTypeData data;

		foreach(pair; tag.tags)
		{
			final switch(pair.name)
			{
				case "name":
					data.language = pair.values[0].get!string;
					break;
				case "extensions":
					data.extensions = pair.values[0].get!string;
					break;
			}
		}

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
