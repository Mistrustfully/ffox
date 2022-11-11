#!/usr/bin/luajit

local lang = require("src.init")
local opcode = require("src.common.opcode")

local result = lang.vm.run({
	opcode.constant,
	1,
	opcode.set_global,
	2,
	opcode.get_global,
	2,
	opcode.constant,
	4,
	opcode.add,
	opcode.set_global,
	2,
	opcode.get_global,
	2,
	opcode.print,
	opcode.get_global,
	2,
	opcode.constant,
	3,
	opcode.equal,
	opcode.jump_if_false,
	-16,
	opcode.get_global,
	2,
	opcode.print,
}, { 0, "i", 10, 1 })
print(result)
