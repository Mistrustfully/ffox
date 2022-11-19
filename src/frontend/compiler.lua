local opcodes = require(script.Parent.Parent.common.opcode)[1]
local token_type = require(script.Parent.Parent.common.token)
local util = require(script.Parent.Parent.util)

local match, merge = util.match, util.merge

-- Recusive function that compiles an AST into bytes and constants.
local function compile(ast, bytes_, constants_, state_)
	if not ast then
		return {} -- Return an empty table to fix warnings
	end

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

	local function enter_scope()
		state.depth = state.depth + 1
	end

	local function exit_scope()
		state.depth = state.depth - 1

		while #state.locals > 0 and state.locals[#state.locals].depth > state.depth do
			table.remove(state.locals)
			table.insert(bytes, opcodes.pop)
		end
	end

	match(ast.type, {
		__root__ = function()
			call_statements(ast.statements)
		end,
		block = function()
			enter_scope()
			call_statements(ast.statements)
			exit_scope()
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
				local local_ = resolve_local(ast.name)
				if local_ == -1 then
					table.insert(state.locals, { name = ast.name, depth = state.depth })
					local_ = #state.locals
				end

				table.insert(bytes, opcodes.set_local)
				table.insert(bytes, local_)
			end
		end,
		variable = function()
			local arg = resolve_local(ast.name)
			local setter
			local getter

			if arg ~= -1 then
				-- Local
				setter = opcodes.set_local
				getter = opcodes.get_local
			else
				-- Global
				setter = opcodes.set_global
				getter = opcodes.get_global

				table.insert(constants, ast.name)
				arg = #constants
			end

			if ast.assign_value then
				call(ast.assign_value)
				table.insert(bytes, setter)
			else
				table.insert(bytes, getter)
			end

			table.insert(bytes, arg)
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
				return node
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
		for_statement = function()
			enter_scope()
			call(ast.initial)
			local to_conditional = #bytes + 1

			-- If there is no conditional, we loop infinitely.
			if ast.conditional then
				call(ast.conditional)
			else
				call({ type = "literal", literal = true })
			end

			local out_conditional = make_jump(opcodes.jump_if_false)
			call_statements(ast.statements)
			call(ast.increment)
			make_jump(opcodes.jump, to_conditional)
			patch_jump(out_conditional)
			exit_scope()
		end,
		fn_statement = function()
			local fn_bytes = {}
			local fn_arguments = {}
			for i = #ast.arguments, 1, -1 do
				local v = ast.arguments[i]
				table.insert(fn_arguments, { name = v.lex, depth = state.depth + 1 })
			end

			local program = compile(
				{ type = "__root__", statements = ast.statements },
				fn_bytes,
				nil,
				{ locals = merge(fn_arguments, state.locals), depth = state.depth + 1 }
			)
			call({
				type = "var_statement",
				name = ast.name,
				expr = {
					type = "number",
					literal = {
						bytes = program.bytes,
						constants = program.constants,
						name = ast.name,
						arity = #ast.arguments,
					},
				},
				constant = false,
			}) -- Declare the function as a value
		end,
		call = function()
			call_statements(ast.expressions)
			call(ast.callee)
			table.insert(bytes, opcodes.call)
			table.insert(bytes, #ast.expressions)
		end,
		expr_statement = function()
			call(ast.expr)
		end,
	})

	return { bytes = bytes, constants = constants }
end

return compile
