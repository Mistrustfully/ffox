#!/usr/bin/luajit
local lang = require("src.init")
local opcode = require("src.common.opcode")
local pprint = require("src.util").pprint

local function for_each_file(dir, fn)
	local p = io.popen('find "' .. dir .. '" -type f') --Open directory look for files, save data in p. By giving '-type f' as parameter, it returns all files.
	if p then
		for file in p:lines() do --Loop through all files
			local opened_file = io.open(file, "r")
			fn(opened_file, file)
		end
	else
		warn("Directory doesn't exist!")
	end
end

for_each_file("test", function(file, file_name)
	local source = file:read("a")
	local tokens = lang.lexer(source)
	local ast = lang.parser(tokens)
	local program = lang.compiler(ast)
	local result = lang.vm.run(program.bytes, program.constants)

	if result then
		print("\27[1;32m [PASS] \27[0m" .. file_name)
	else
		print("\27[1;31m [FAILED] \27[0m" .. file_name)
	end
end)
