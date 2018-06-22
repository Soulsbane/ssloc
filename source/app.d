import std.stdio, core.time;
import std.datetime.stopwatch;
import std.file;

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

	void scanFile(DirEntry e)
	{
		statsGenerator_.scanFile(e);
		stopWatch_.stop();

		writeln("Time taken: ", stopWatch_.peek());
		statsGenerator_.outputResults(options.sort);
	}

	void scanFiles()
	{
		statsGenerator_.scanFiles();
		stopWatch_.stop();

		writeln("Time taken: ", stopWatch_.peek());
		statsGenerator_.outputResults(options.sort);
	}

	void listUnknownFileExtensions()
	{
		if(options.hasListUnknowns())
		{
			statsGenerator_.listUnknownFileExtensions();
		}
	}

	override void onValidArguments()
	{
		if(options.hasFile()) // --file argument was passed
		{
			immutable string fileName = options.getFile();

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
	//TODO: Add progressbar when scanning files.
	auto app = new SslocApplication;
	app.create("Raijinsoft", "ssloc", arguments);
}
