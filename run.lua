#!/usr/bin/luajit
local ffox = require("src.init")
local pprint = require("src.util").pprint
local decompile_bytes = require("src.debug").decompile

local file = io.open(arg[1])
if not file then
	print("File doesn't exist!")
	return
end

local source = file:read("a")

local tokens = ffox.lex(source)
pprint(tokens, "tokens")

local ast = ffox.parse(tokens)
pprint(ast, "ast")

local bytecode = ffox.compile(ast)
decompile_bytes(bytecode.bytes, bytecode.constants)

local result = ffox.vm.run(bytecode.bytes, bytecode.constants)
print("result = " .. tostring(result))
