module statsgenerator;

import std.stdio, std.string, std.file, std.algorithm, std.path;
import std.array, std.utf, core.time, std.exception, std.conv, std.typecons;
import core.atomic, std.parallelism, std.range;

import progress;

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

			if(language in languageTotals_)
			{
				currentLanguageTotals = languageTotals_[language];
			}

			++currentLanguageTotals.files;
			lineTotals_.lines = lineTotals_.lines + lines.length;

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
		writeln("Total lines processed: ", lineTotals_.lines.formatNumber);
		writeln("Total files ignored: ", unknowns_.formatNumber);
		writeHeader;

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
				writeField(currentLanguageTotals[0], Fields.language);
				writeField(currentLanguageTotals[1].files, Fields.files);
				writeField(currentLanguageTotals[1].blank, Fields.blank);
				writeField(currentLanguageTotals[1].comments, Fields.comments);
				writeField(currentLanguageTotals[1].code, Fields.code);
				writeField(currentLanguageTotals[1].total, Fields.total);
				writeDivider;
			}
		}
		else
		{
			foreach(key, currentLanguageTotals; languageTotals_)
			{
				writeField(key, Fields.language);
				writeField(currentLanguageTotals.files, Fields.files);
				writeField(currentLanguageTotals.blank, Fields.blank);
				writeField(currentLanguageTotals.comments, Fields.comments);
				writeField(currentLanguageTotals.code, Fields.code);
				writeField(currentLanguageTotals.code, Fields.total);
				writeDivider;
			}
		}

		writeln;
		writeField("Total", Fields.language);
		writeField(lineTotals_.files, Fields.files);
		writeField(lineTotals_.blank, Fields.blank);
		writeField(lineTotals_.comments, Fields.comments);
		writeField(lineTotals_.code, Fields.code);
		writeField(lineTotals_.lines, Fields.total);
		writeDivider;
		writeln;
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
