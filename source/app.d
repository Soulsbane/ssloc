import std.stdio, core.time;
import std.datetime.stopwatch;
import std.file;

import config;
import statsgenerator;
import dapplicationbase;

class SslocApplication: Application!SSLocOptions
{
	this()
	{
		stopWatch_ = StopWatch(AutoStart.yes);
	}

	void scanFile(DirEntry e)
	{
		statsGenerator_.scanFile(e);
		stopWatch_.stop();

		writeln("Time taken: ", stopWatch_.peek());
		statsGenerator_.outputResults(Options.sort);
	}

	void scanFiles()
	{
		statsGenerator_.scanFiles();
		stopWatch_.stop();

		writeln("Time taken: ", stopWatch_.peek());
		statsGenerator_.outputResults(Options.sort);
	}

	void listUnknownFileExtensions()
	{
		if(Options.hasListUnknowns())
		{
			statsGenerator_.listUnknownFileExtensions();
		}
	}

	override void onValidArguments()
	{
		if(Options.hasFile()) // --file argument was passed
		{
			immutable string fileName = Options.getFile();

			scanFile(DirEntry(fileName));
			listUnknownFileExtensions();
		}
		else
		{
			scanFiles();
			listUnknownFileExtensions();
		}
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

	writeln("Gathering files for scanning...");
	app.create("Raijinsoft", "ssloc", arguments);
}
