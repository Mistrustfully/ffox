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

local function variable_expr(literal)
	return { type = "variable", literal = literal }
end

local function return_statement(expr)
	return { type = "return_statement", expr = expr }
end

local function var_statement(name, expr, constant)
	return { type = "var_statement", name = name, expr = expr, constant = constant }
end

return {
	expr = { binary = binary_expr, unary = unary_expr, number = number_expr, variable = variable_expr },
	statement = { freturn = return_statement, var = var_statement },
}
