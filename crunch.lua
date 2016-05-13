-- crunch.lua
-- written by apemanzilla
-- combines a bunch of files into one runnable file
-- intended to be used to package multiple dependencies together with a program

assert(_HOST or _CC_VERSION, "CC 1.74+ is required")

local options = {}

options.libpath = settings and settings.get("crunch.libpath") or ".:lib:/lib"
options.libext = settings and settings.get("crunch.libext") or "lua"

options.output = true
options.run = false

-- parse args
local args = {...}
while #args > 0 do
	local arg = table.remove(args, 1)
	if arg:sub(1,1) == "-" then
		-- flag
		if arg == "-h" or arg == "-?" then
			print("Usage: crunch [options]")
			print("Options:")
			print(" -h: show usage")
			print(" -d: do not write output to file")
			print(" -r: run output (all args following -r will be passed to program)")
			print("Examples:")
			print(" 'crunch' - builds program and saves to output.lua")
			print(" 'crunch -d' - builds program but does not save")
			print(" 'crunch -d -r myarg' - builds program and runs with argument \"myarg\"")
			return
		elseif arg == "-d" then
			-- debug flag
			options.output = false
		elseif arg == "-r" then
			options.run = {}
			while #args > 0 do
				table.insert(options.run, table.remove(args, 1))
			end
		end
	else

	end
end

if not options.main then
	for i, v in ipairs({"main.lua", "main"}) do
		if fs.exists(fs.combine(shell.dir(), v)) then
			options.main = fs.combine(shell.dir(), v)
			break
		end
	end
end

assert(options.main, "no main file present")

local function resolve(base, path)
	if path:sub(1,1) == "/" or path:sub(1,1) == "\\" then
		return path
	else
		return fs.combine(base, path)
	end
end

local function findLib(name, from)
	for lp in options.libpath:gmatch("([^:]+)") do
		lp = fs.combine(resolve(from, lp), name)
		for ext in options.libext:gmatch("([^:]+)") do
			if fs.exists(lp .. "." .. ext) then return lp .. "." .. ext end
		end
		if fs.exists(lp) then return lp end
	end
end

local pttrn = "@include[ \t]+([%w%d_-%./\\]+)"

local function crunch(file)
	local f = fs.open(file, "r")
	local data = f.readAll()
	f.close()

	local included = {}
	local ct = 0
	for include in data:gmatch(pttrn) do
		local lib = findLib(include, fs.getDir(file))
		if lib then
			included[include] = lib
			ct = ct + 1
		else
			error(("missing library %s, required by %s"):format(include, fs.getName(file)), 0)
		end
	end

	if ct == 0 then
		-- syntax check
		local f, e = load(data, fs.getName(file))
		if not f then
			error(e, 0)
		end

		return data
	else
		-- syntax check
		local f, e = load(data:gsub(pttrn, ""), fs.getName(file))
		if not f then
			error(e, 0)
		end

		for k, v in pairs(included) do
			local crunched = ("%q"):format(crunch(v):gsub("%%", "%%%%"))

			-- ugliest piece of code i've ever written
			local name = k:match("([^/\\]+)$")
			data = data:gsub("@include[ \t]+("..k..")", "do local e = setmetatable({}, {__index = _G}) e._ENV = e _ENV[\""..name.."\"] = load("..crunched..", \""..name.."\", nil, e)() end")
		end

		return data
	end
end

local output = crunch(options.main)
local header = "-- this file was generated using crunch by apemanzilla\n-- you should probably look for the source code elsewhere before attempting to read this file\n\n"

if options.output then
	local f = fs.open(fs.combine(fs.getDir(options.main), "output.lua"), "w")
	f.write(header .. output)
	f.close()
end

if options.run then
	local env = setmetatable({}, {__index = _G}) env._ENV = env
	local f, e = load(output, fs.getName(options.main), nil, env)
	if not f then error(e, 0) end
	local ok, e = pcall(f, unpack(options.run))
	if not ok then error(e, 0) end
end
