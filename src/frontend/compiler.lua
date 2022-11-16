local opcodes = require("src.common.opcode")
local token_type = require("src.common.token")
local match = require("src.util").match

-- Recusive function that compiles an AST into bytes and constants.
local function compile(ast, bytes_, constants_)
	local bytes = bytes_ or {}
	local constants = constants_ or {}

	match(ast.type, {
		__root__ = function()
			for _, statement in pairs(ast.statements) do
				compile(statement, bytes, constants)
			end
		end,
		block = function()
			for _, statement in pairs(ast.statements) do
				compile(statement, bytes, constants)
			end
		end,
		return_statement = function()
			compile(ast.expr, bytes, constants)
			table.insert(bytes, opcodes.freturn)
		end,
		var_statement = function()
			compile(ast.expr, bytes, constants)
			table.insert(constants, ast.name)
			table.insert(bytes, opcodes.set_global)
			table.insert(bytes, #constants)
		end,
		variable = function()
			table.insert(constants, ast.literal)
			table.insert(bytes, opcodes.get_global)
			table.insert(bytes, #constants)
		end,
		number = function()
			table.insert(constants, ast.literal)
			table.insert(bytes, opcodes.constant)
			table.insert(bytes, #constants)
		end,
		string = function()
			table.insert(constants, ast.literal)
			table.insert(bytes, opcodes.constant)
			table.insert(bytes, #constants)
		end,
		binary_expr = function()
			compile(ast.left, bytes, constants)
			compile(ast.right, bytes, constants)
			table.insert(
				bytes,
				match(ast.operator, {
					[token_type.star] = opcodes.mul,
					[token_type.slash] = opcodes.div,
					[token_type.plus] = opcodes.add,
					[token_type.minus] = opcodes.sub,
					[token_type.greater] = opcodes.greater,
					[token_type.less] = opcodes.less,
				})
			)
		end,
	})

	return { bytes = bytes, constants = constants }
end

return compile
