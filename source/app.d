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
	immutable bool helpRequested = generateGetOptCode!Options(arguments, options);

	if(!helpRequested)
	{
		gen.scan();

		auto endTime = MonoTime.currTime;
		auto timeTaken = endTime - startTime;

		writeln;
		writeln("Time taken: ", timeTaken);
		gen.outputResults(options.sort);
	}
}
