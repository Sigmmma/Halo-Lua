-- Command-line script that statically checks a script for errors
SCRIPT = arg[1]

if not SCRIPT then
	print(string.format("Usage: lua %s <script_to_check>", arg[0]))
	os.exit(0)
end

-- Dumb hack that lets us pass a file name without disturbing Busted
arg = {}
require "busted.runner"()

dofile("./shared/static.lua")
RunStaticTests(SCRIPT)
