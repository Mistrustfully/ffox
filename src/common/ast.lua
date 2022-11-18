--- Addition, Subtraction, etc. Binary operations with two operands.
local function binary_expr(left, right, operator)
	return { type = "binary_expr", left = left, right = right, operator = operator }
end

--- Unary operations like not and negatives.
local function unary_expr(operand, operator)
	return { type = "unary_expr", operator = operator, operand = operand }
end

--- Number literals.
local function number_expr(literal)
	return { type = "number", literal = tonumber(literal) }
end

local function string_expr(literal)
	return { type = "string", literal = string.sub(literal, 2, #literal - 1) }
end

local function literal_expr(literal)
	return { type = "literal", literal = literal }
end

local function variable_expr(name, assign_value)
	return { type = "variable", name = name, assign_value = assign_value }
end

local function return_statement(expr)
	return { type = "return_statement", expr = expr }
end

local function var_statement(name, expr, constant)
	return { type = "var_statement", name = name, expr = expr, constant = constant }
end

local function expr_statement(expr)
	return { type = "expr_statement", expr = expr }
end

local function block_statement(statements)
	return { type = "block", statements = statements }
end

local function if_statement(expr, if_branch, else_branch)
	return { type = "if_statement", expr = expr, if_branch = if_branch, else_branch = else_branch }
end

local function while_statement(expr, statements)
	return { type = "while_statement", expr = expr, statements = statements }
end

local function for_statement(initial, conditional, increment, statements)
	return {
		type = "for_statement",
		conditional = conditional,
		initial = initial,
		increment = increment,
		statements = statements,
	}
end

return {
	expr = {
		binary = binary_expr,
		unary = unary_expr,
		number = number_expr,
		string = string_expr,
		literal = literal_expr,
		variable = variable_expr,
	},
	statement = {
		freturn = return_statement,
		var = var_statement,
		expr = expr_statement,
		block = block_statement,
		if_statement = if_statement,
		while_statement = while_statement,
		for_statement = for_statement,
	},
}
