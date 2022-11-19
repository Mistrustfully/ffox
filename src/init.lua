local compile = require("src.frontend.compiler")
local parse = require("src.frontend.parser")
local lex = require("src.frontend.lex")
local vm = require("src.vm")

local function run(source)
	local program = compile(parse(lex(source)))
	return vm.run(program.bytes, program.constants)
end

return {
	lex = lex,
	parse = parse,
	compile = compile,
	vm = vm,
	run = run,
}
