module statsgenerator;

import std.stdio, std.string, std.file, std.algorithm, std.path;
import std.array, std.utf, core.time, std.exception;

import raijin.utils.string : formatNumber;

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
	size_t numBlankLines;
	size_t numCodeLines;
	size_t numCommentLines;
	size_t numFiles;
	size_t numLines;
	size_t numUnknowns;
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
				lineTotals_.numLines = lineTotals_.numLines + lines.length;

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
							++lineTotals_.numCommentLines;
						}
						else if(auto commentType = isMultiLineComment(line, language))
						{
							if(commentType == MultiLineCommentType.Open)
							{
								++currentLanguageTotals.comments;
								++lineTotals_.numCommentLines;

								inCommentBlock = true;
							}

							if(commentType == MultiLineCommentType.Close)
							{
								++currentLanguageTotals.comments;
								++lineTotals_.numCommentLines;

								inCommentBlock = false;
							}
						}
						else if(inCommentBlock)
						{
							++currentLanguageTotals.comments;
							++lineTotals_.numCommentLines;
						}
						else
						{
							++currentLanguageTotals.code;
							++lineTotals_.numCodeLines;
						}
					}
					else
					{
						++currentLanguageTotals.blank;
						++lineTotals_.numBlankLines;
					}
				}

				languageTotals_[language] = currentLanguageTotals;
			}
			else
			{
				if(!fileExtension.empty)
				{
					debug writeln("Unknown extension, ", fileExtension, " found!");
					++lineTotals_.numUnknowns;
				}
			}

			++lineTotals_.numFiles;
		}
	}

	void outputResults()
	{
		writeln("Total lines processed: ", lineTotals_.numLines.formatNumber);
		writeln("Total files ignored: ", lineTotals_.numUnknowns.formatNumber);
		 // TODO: Maybe add a list of ignored extensions as a command line argument.?
		writeHeader;

		foreach(key, currentLanguageTotals; languageTotals_)
		{
			writeField(key, Fields.language);
			writeField(currentLanguageTotals.files, Fields.files);
			writeField(currentLanguageTotals.blank, Fields.blank);
			writeField(currentLanguageTotals.comments, Fields.comments);
			writeField(currentLanguageTotals.code, Fields.code);
			writeDivider;
		}

		writeln;
		writeField("Total", Fields.language);
		writeField(lineTotals_.numFiles, Fields.files);
		writeField(lineTotals_.numBlankLines, Fields.blank);
		writeField(lineTotals_.numCommentLines, Fields.comments);
		writeField(lineTotals_.numCodeLines, Fields.code);
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
