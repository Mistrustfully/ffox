#!/usr/bin/luajit

local lang = require("src.init")
local opcode = require("src.common.opcode")
local pprint = require("src.util").pprint

local lex = require("src.frontend.lex")
local tokens = lex([[
let b = "hello"
b = b + b
return b
]])
local parse = require("src.frontend.parser")
local ast = parse(tokens)

local c = lang.compiler(ast)
pprint(ast)
pprint(c.bytes)
pprint(c.constants)
local res = lang.vm.run(c.bytes, c.constants)
print(res)
