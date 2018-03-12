module config;

public import ctoptions.getoptmixin;

struct Options
{
	@GetOptOptions("Determines whether the results table is sorted by programming language.")
	bool sort = true;
	@GetOptOptions("Will only search the passed file name.")
	string file;
}
