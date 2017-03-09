import std.stdio, std.string, std.file, std.algorithm, std.path, std.exception;
import std.range, std.conv, std.parallelism, std.array, std.utf, core.time;

import filetype;
import statsformatter;
import statsgenerator;

void main()
{
	auto startTime = MonoTime.currTime;
	StatsGenerator gen;

	gen.scan();

	auto endTime = MonoTime.currTime;
	auto timeTaken = endTime - startTime;

	writeln;
	writeln("Time taken: ", timeTaken);
	gen.outputResults();
}
