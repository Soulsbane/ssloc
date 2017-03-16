import std.stdio, core.time;

import config;
import filetype;
import statsformatter;
import statsgenerator;

void main(string[] arguments)
{
	auto startTime = MonoTime.currTime;
	StatsGenerator gen;
	Options options;

	options.sort = true;
	generateGetOptCode!Options(arguments, options);
	gen.scan();

	auto endTime = MonoTime.currTime;
	auto timeTaken = endTime - startTime;

	writeln;
	writeln("Time taken: ", timeTaken);
	gen.outputResults(options.sort);
}
