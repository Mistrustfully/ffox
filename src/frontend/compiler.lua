local opcodes = require("src.common.opcode")[1]
local token_type = require("src.common.token")
local match = require("src.util").match

-- Recusive function that compiles an AST into bytes and constants.
local function compile(ast, bytes_, constants_, state_)
	local bytes = bytes_ or {}
	local constants = constants_ or {}
	local state = state_ or {
		depth = 0,
		locals = {},
	}

	local function call(statement)
		return compile(statement, bytes, constants, state)
	end

	local function fold_constants(node)
		if node.type == "number" then
			return node
		end

		if node.type == "binary_expr" then
			if
				(node.left.type ~= "binary_expr" and node.left.type ~= "number")
				or (node.right.type ~= "binary_expr" and node.right.type ~= "number")
			then
				return node
			end
			local result_left = fold_constants(node.left)
			local result_right = fold_constants(node.right)

			if result_left.type == "number" and result_right.type == "number" then
				local left = result_left.literal
				local right = result_right.literal

				local literal = match(node.operator, {
					[token_type.star] = left * right,
					[token_type.slash] = left / right,
					[token_type.plus] = left + right,
					[token_type.minus] = left - right,
					[token_type.less] = left < right,
					[token_type.less_equal] = left <= right,
					[token_type.greater] = left > right,
					[token_type.greater_equal] = left >= right,
					[token_type.equal_equal] = left == right,
				})

				return {
					type = type(literal) == "number" and "number" or "literal",
					literal = literal,
				}
			end
		end

		return node
	end

	local function resolve_local(name)
		for i = #state.locals, 1, -1 do
			local local_ = state.locals[i]
			if local_.name == name then
				return i
			end
		end

		return -1
	end

	local function call_statements(statements)
		for _, statement in pairs(statements) do
			call(statement)
		end
	end

	local function make_jump(type, location)
		table.insert(bytes, type or opcodes.jump)
		table.insert(bytes, location or 0)
		return #bytes
	end

	local function patch_jump(location)
		bytes[location] = #bytes + 1
	end

	match(ast.type, {
		__root__ = function()
			call_statements(ast.statements)
		end,
		block = function()
			state.depth = state.depth + 1
			call_statements(ast.statements)
			state.depth = state.depth - 1
			while #state.locals > 1 and state.locals[#state.locals - 1].depth > state.depth do
				table.remove(state.locals)
				table.insert(bytes, opcodes.pop)
			end
		end,
		return_statement = function()
			call(ast.expr)
			table.insert(bytes, opcodes.freturn)
		end,
		var_statement = function()
			call(ast.expr)
			if state.depth == 0 then
				-- Globals
				table.insert(constants, ast.name)
				table.insert(bytes, opcodes.set_global)
				table.insert(bytes, #constants)
			else
				-- Locals
				table.insert(state.locals, { name = ast.literal, depth = state.depth })
				table.insert(bytes, opcodes.set_local)
				table.insert(bytes, #state.locals)
			end
		end,
		variable = function()
			local arg = resolve_local(ast.lex)
			if arg ~= -1 then
				-- Local
				table.insert(bytes, opcodes.get_local)
				table.insert(bytes, arg)
			else
				-- Global
				table.insert(constants, ast.literal)
				table.insert(bytes, opcodes.get_global)
				table.insert(bytes, #constants)
			end
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
		literal = function()
			table.insert(
				bytes,
				match(ast.literal, {
					[true] = opcodes.ftrue,
					[false] = opcodes.ffalse,
					default = opcodes.fnil,
				})
			)
		end,
		binary_expr = function()
			local node = fold_constants(ast)
			if node.type ~= "binary_expr" then
				call(node)
				return
			end

			call(node.left)
			call(node.right)

			table.insert(
				bytes,
				match(node.operator, {
					[token_type.star] = opcodes.mul,
					[token_type.slash] = opcodes.div,
					[token_type.plus] = opcodes.add,
					[token_type.minus] = opcodes.sub,
					[token_type.greater] = opcodes.greater,
					[token_type.less] = opcodes.less,
					[token_type.equal_equal] = opcodes.equal,
					default = function()
						if ast.operator == token_type.less_equal then
							table.insert(bytes, opcodes.greater)
							return opcodes.fnot
						elseif ast.operator == token_type.greater_equal then
							table.insert(bytes, opcodes.less)
							return opcodes.fnot
						end
						error("Invalid binary operator!")
					end,
				})
			)
		end,
		if_statement = function()
			call(ast.expr)
			local jump = make_jump(opcodes.jump_if_false)
			call_statements(ast.if_branch)
			patch_jump(jump)
			if #ast.else_branch > 0 then
				local else_jump = make_jump()
				patch_jump(jump)
				call_statements(ast.else_branch)
				patch_jump(else_jump)
			end
		end,
		while_statement = function()
			local location = #bytes
			call(ast.expr)
			local break_jump = make_jump(opcodes.jump_if_false)
			call_statements(ast.statements)

			make_jump(opcodes.jump, location + 1)
			bytes[break_jump] = #bytes + 1
		end,
		expr_statement = function()
			call(ast.expr)
		end,
	})

	return { bytes = bytes, constants = constants }
end

return compile
