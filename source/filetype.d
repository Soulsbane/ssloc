module filetype;

import std.stdio : writeln;
import std.container;
import std.string : lineSplitter;
import std.algorithm.searching : findSplit, canFind;
import std.conv : to;

import sdlang;

private enum LanguageData = import("language.sdl");

private struct FileTypeData
{
	string language;
	string extensions;
}

private alias FileTypeDataArray  = Array!FileTypeData;
private FileTypeDataArray fileTypeDataArray_;

shared static this()
{
	loadFileTypeData();
}

private void loadFileTypeData()
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
		import std.array : split;
		immutable auto parts = entry.extensions.split(",");

		foreach(part; parts)
		{
			if(part == extension)
			{
				return entry.language;
			}
		}
	}

	return "Unknown";
}
