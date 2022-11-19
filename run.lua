#!/usr/bin/luajit
local ffox = require("src.init")
local pprint = require("src.util").pprint
local decompile_bytes = require("src.debug")

local file = io.open(arg[1])
if not file then
	print("File doesn't exist!")
	return
end

local source = file:read("a")

local tokens = ffox.lexer(source)
pprint(tokens, "tokens")

local ast = ffox.parser(tokens)
pprint(ast, "ast")

local bytecode = ffox.compiler(ast)
decompile_bytes(bytecode.bytes, bytecode.constants)

local result = ffox.vm.run(bytecode.bytes, bytecode.constants)
print("result = " .. tostring(result))
