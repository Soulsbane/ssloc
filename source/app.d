import std.stdio, core.time;

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
