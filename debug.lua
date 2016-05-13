-- debug.lua
-- runs crunch in debug mode

if shell.resolveProgram("crunch") then
	shell.run("crunch", "-d", "-r", ...)
elseif shell.resolveProgram("crunch.lua") then
	shell.run("crunch.lua", "-d", "-r", ...)
else
	error("failed to find crunch")
end
