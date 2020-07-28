module statsgenerator;

import std.stdio, std.string, std.file, std.algorithm, std.path;
import std.array, std.utf, core.time, std.exception, std.conv, std.typecons;
import core.atomic, std.parallelism, std.range;

import progress;
import colored;
import asciitable;

import filetype;
import statsformatter;
import dstringutils.utils : removeChars;

struct LanguageTotals
{
	size_t total;
	LineTotals totals;

	alias totals this;
}

struct LineTotals
{
	size_t blank;
	size_t code;
	size_t comments;
	size_t files;
	size_t lines;
}

struct StatsGenerator
{
	void scanFile(const DirEntry e)
	{
		immutable string name = buildNormalizedPath(e.name);
		immutable string fileExtension = e.name.baseName.extension.removeChars(".");
		immutable string language = getLanguageFromFileExtension(fileExtension);

		if(language != "Unknown")
		{
			LanguageTotals currentLanguageTotals;
			immutable string text = readText(name).ifThrown!UTFException("");
			immutable auto lines = text.lineSplitter().array;
			bool inCommentBlock;

			lineTotals_.lines = lineTotals_.lines + lines.length;

			if(language in languageTotals_)
			{
				currentLanguageTotals = languageTotals_[language];
			}

			++currentLanguageTotals.files;

			foreach(rawLine; lines)
			{
				immutable string line = rawLine.strip.chompPrefix("\t");

				//if(!line.empty || inCommentBlock) // Maybe as an option to count blanks if inside comment block
				if(!line.empty)
				{
					if(isSingleLineComment(line, language))
					{
						++currentLanguageTotals.comments;
						++lineTotals_.comments;
					}
					else if(auto commentType = isMultiLineComment(line, language))
					{
						if(commentType == MultiLineCommentType.Open)
						{
							++currentLanguageTotals.comments;
							++lineTotals_.comments;

							inCommentBlock = true;
						}

						if(commentType == MultiLineCommentType.Close)
						{
							++currentLanguageTotals.comments;
							++lineTotals_.comments;

							inCommentBlock = false;
						}

						if(commentType == MultiLineCommentType.OpenAndClose)
						{
							++currentLanguageTotals.comments;
							++lineTotals_.comments;
						}
					}
					else if(inCommentBlock)
					{
						++currentLanguageTotals.comments;
						++lineTotals_.comments;
					}
					else
					{
						++currentLanguageTotals.code;
						++lineTotals_.code;
					}
				}
				else
				{
					++currentLanguageTotals.blank;
					++lineTotals_.blank;
				}

				++currentLanguageTotals.total;
			}

			languageTotals_[language] = currentLanguageTotals;
		}
		else
		{
			if(!fileExtension.empty)
			{
				++unknowns_;
				unknownFileExtensions_ ~= fileExtension;
			}
		}

		++lineTotals_.files;
	}

	void scanFiles()
	{
		auto files = getcwd.dirEntries(SpanMode.depth)
			.filter!(a => (!isHiddenFileOrDir(a) && a.isFile)).array;

		immutable size_t numberOfFilesToScan = files.length;
		ChargingBar progress = new ChargingBar();

		writeln("Found ", numberOfFilesToScan, " files to scan:");

		progress.message = { return "Scanning"; };
		progress.suffix = { return format("%0.0f", progress.percent).to!string ~ "% "; };
		progress.width = 64;
		progress.max = numberOfFilesToScan;

		//foreach(e; parallel(files)) // FIXME: Very buggy atm. Needs more research to find out why.
		foreach(e; files)
		{
			scanFile(e);
			progress.next();
		}

		progress.finish();
	}

	void outputResults(const bool sortByLanguage)
	{
		auto table = new StatsFormatter(6);

		table.writeHeader("Language", "Files", "Blank", "Comments", "Code", "Total");

		// FIXME: Has column dividers at the moment.
		//table.addBlankRow();

		writeln("Total lines processed: ", lineTotals_.lines.formatNumber);
		writeln("Total files ignored: ", unknowns_.formatNumber);

		if(sortByLanguage)
		{
			Tuple!(string, LanguageTotals)[] pairs;

			foreach(pair; languageTotals_.byPair)
			{
				pairs ~= pair;
			}

			sort!q{ a[0] < b[0] }(pairs);

			foreach(index, currentLanguageTotals; pairs)
			{
				// The key is index 0 and value(LanguageTotals structure is at index 1).
				table.addRow(currentLanguageTotals[0], currentLanguageTotals[1].files, currentLanguageTotals[1].blank,
				currentLanguageTotals[1].comments, currentLanguageTotals[1].code, currentLanguageTotals[1].total);
			}
		}
		else
		{
			foreach(key, currentLanguageTotals; languageTotals_)
			{
				table.addRow(key, currentLanguageTotals.files, currentLanguageTotals.blank,
				currentLanguageTotals.comments, currentLanguageTotals.code, currentLanguageTotals.total);
			}
		}

		table.addRow("Total", lineTotals_.files, lineTotals_.blank, lineTotals_.comments, lineTotals_.code,
		lineTotals_.lines);

		table.render();
	}

	void listUnknownFileExtensions()
	{
		debug
		{
			string[] uniqueFileExtensions = unknownFileExtensions_.sort.uniq.array;

			writeln("Found ", uniqueFileExtensions.length, " unknown file extensions:");
			writeln(uniqueFileExtensions);
		}
		else
		{
			writeln("Feature only available in debug build!");
		}
	}

private:
	LineTotals lineTotals_;
	size_t unknowns_;
	LanguageTotals[string] languageTotals_;
	string[] unknownFileExtensions_;
}

bool isHiddenFileOrDir(DirEntry entry)
{
	auto dirParts = entry.name.pathSplitter;

	foreach(dirPart; dirParts)
	{
		if(dirPart.startsWith("."))
		{
			return true;
		}
	}

	return false;
}
