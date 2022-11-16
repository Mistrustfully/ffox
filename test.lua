#!/usr/bin/luajit

local lang = require("src.init")
local opcode = require("src.common.opcode")
local pprint = require("src.util").pprint

local lex = require("src.frontend.lex")
local tokens = lex([[
	const jo_balls = (10 / 10 * (-4 + 5))
	let jo_two = jo_balls * jo_balls
	return jo_balls
]])
local parse = require("src.frontend.parser")
pprint(parse(tokens))
