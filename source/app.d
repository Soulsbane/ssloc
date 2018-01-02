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
	immutable string message = generateGetOptCode!Options(arguments, options);

	if(message != string.init)
	{
		writeln(message);
	}
	else
	{
		gen.scanFiles();

		auto endTime = MonoTime.currTime;
		auto timeTaken = endTime - startTime;

		writeln;
		writeln("Time taken: ", timeTaken);
		gen.outputResults(options.sort);
	}
}
