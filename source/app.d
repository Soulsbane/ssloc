import std.stdio, core.time;
import std.datetime.stopwatch;

import config;
import filetype;
import statsformatter;
import statsgenerator;
import dapplicationbase;

class SslocApplication: Application!Options
{
	this()
	{
		stopWatch_ = StopWatch(AutoStart.yes);
	}

	void scanFiles()
	{
		statsGenerator_.scanFiles();
		stopWatch_.stop();

		writeln("Time taken: ", stopWatch_.peek());
		statsGenerator_.outputResults(options.sort);
	}

	override void onValidArguments()
	{
		scanFiles();
	}

	override void onNoArguments()
	{
		scanFiles();
	}

private:
	StatsGenerator statsGenerator_;
	StopWatch stopWatch_;
}

void main(string[] arguments)
{
	auto app = new SslocApplication;
	app.create("Raijinsoft", "ssloc", arguments);
}
