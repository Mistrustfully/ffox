#!/usr/bin/luajit

local lang = require("src.init")
local opcode = require("src.common.opcode")

local result = lang.vm.run({ opcode.constant, 1, opcode.constant, 2, opcode.equal, opcode.print }, { "hello", "hello" })
print(result)
