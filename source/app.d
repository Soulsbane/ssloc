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

size_t[string] _LineData;

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
}

void main()
{
	scan();
}
