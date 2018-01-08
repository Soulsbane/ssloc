import std.stdio, core.time;

import config;
import filetype;
import statsformatter;
import statsgenerator;
import dapplicationbase;

class SslocApplication: Application!Options
{
	this()
	{
		startTime_ = MonoTime.currTime;
	}

	void scanFiles()
	{
		statsGenerator_.scanFiles();

		auto endTime = MonoTime.currTime;
		auto timeTaken = endTime - startTime_;

		writeln;
		writeln("Time taken: ", timeTaken);
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
	MonoTime startTime_;
}

void main(string[] arguments)
{
	auto app = new SslocApplication;
	app.create("Raijinsoft", "ssloc", arguments);
}
