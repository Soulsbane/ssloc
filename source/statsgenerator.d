module statsgenerator;

import std.stdio, std.string, std.file, std.algorithm, std.path;
import std.array, std.utf, core.time, std.exception, std.conv, std.typecons;

import filetype;
import statsformatter;

struct LanguageTotals
{
	size_t files;
	size_t code;
	size_t blank;
	size_t comments;
}

struct LineTotals
{
	size_t blank;
	size_t code;
	size_t comment;
	size_t files;
	size_t lines;
	size_t unknowns;
}

struct StatsGenerator
{
	void scan()
	{
		auto files = getcwd.dirEntries(SpanMode.depth)
			.filter!(a => (!isHiddenFileOrDir(a) && a.isFile));

		//foreach(e; parallel(files)) // FIXME: Very buggy atm. Needs more research to find out why.
		foreach(e; files)
		{
			immutable string name = buildNormalizedPath(e.name);
			immutable string fileExtension = e.name.baseName.extension.removechars(".");
			immutable string language = getLanguageFromFileExtension(fileExtension);

			if(language != "Unknown")
			{
				LanguageTotals currentLanguageTotals;
				immutable string text = readText(name).ifThrown!UTFException("");
				auto lines = text.lineSplitter().array;

				if(language in languageTotals_)
				{
					currentLanguageTotals = languageTotals_[language];
				}

				++currentLanguageTotals.files;
				lineTotals_.lines = lineTotals_.lines + lines.length;

				bool inCommentBlock;

				foreach(rawLine; lines)
				{
					immutable string line = rawLine.strip.chompPrefix("\t");

					//if(!line.empty || inCommentBlock) // Maybe as an option to count blanks if inside comment block
					if(!line.empty)
					{
						if(isSingleLineComment(line, language))
						{
							++currentLanguageTotals.comments;
							++lineTotals_.comment;
						}
						else if(auto commentType = isMultiLineComment(line, language))
						{
							if(commentType == MultiLineCommentType.Open)
							{
								++currentLanguageTotals.comments;
								++lineTotals_.comment;

								inCommentBlock = true;
							}

							if(commentType == MultiLineCommentType.Close)
							{
								++currentLanguageTotals.comments;
								++lineTotals_.comment;

								inCommentBlock = false;
							}

							if(commentType == MultiLineCommentType.OpenAndClose)
							{
								++currentLanguageTotals.comments;
								++lineTotals_.comment;
							}
						}
						else if(inCommentBlock)
						{
							++currentLanguageTotals.comments;
							++lineTotals_.comment;
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
				}

				languageTotals_[language] = currentLanguageTotals;
			}
			else
			{
				if(!fileExtension.empty)
				{
					debug writeln("Unknown extension, ", fileExtension, " found!");
					++lineTotals_.unknowns;
				}
			}

			++lineTotals_.files;
		}
	}

	void outputResults(const bool sortByLanguage)
	{
		writeln("Total lines processed: ", lineTotals_.lines.formatNumber);
		writeln("Total files ignored: ", lineTotals_.unknowns.formatNumber);
		 // TODO: Maybe add a list of ignored extensions as a command line argument.?
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
				writeDivider;
			}
		}

		writeln;
		writeField("Total", Fields.language);
		writeField(lineTotals_.files, Fields.files);
		writeField(lineTotals_.blank, Fields.blank);
		writeField(lineTotals_.comment, Fields.comments);
		writeField(lineTotals_.code, Fields.code);
		writeDivider;
		writeln;
	}

private:
	LineTotals lineTotals_;
	LanguageTotals[string] languageTotals_;
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
