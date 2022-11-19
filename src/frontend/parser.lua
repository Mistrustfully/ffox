local token_type = require(script.Parent.Parent.common.token)
local util = require(script.Parent.Parent.util)
local ast = require(script.Parent.Parent.common.ast)

local pprint, enum, match = util.pprint, util.enum, util.match
local expr, statement = ast.expr, ast.statement

local precedence_enum = enum({
	"none",
	"assignment",
	"equality",
	"comparison",
	"term",
	"factor",
	"unary",
	"grouping",
})

local rules
local function get_rule(type)
	return rules[type] or { precedence = precedence_enum.none }
end

local function number(parser)
	return expr.number(parser.previous().lex)
end

local function string(parser)
	return expr.string(parser.previous().lex)
end

local function literal(parser)
	return expr.literal(match(parser.previous().lex, {
		["true"] = true,
		["false"] = false,
		["nil"] = nil,
		default = function()
			error("Unknown literal!")
		end,
	}))
end

local function binary(parser, left)
	local operator = parser.previous()
	local right = parser.parse_precendence(get_rule(operator.type).precedence + 1)
	return expr.binary(left, right, operator.type)
end

local function grouping(parser)
	local exp = parser.parse_precendence()
	parser.advance()
	return exp
end

local function call(parser, callee)
	local expressions = {}
	if parser.peek().type ~= token_type.r_paren then
		repeat
			if parser.peek().type == token_type.comma then
				parser.advance()
			end
			table.insert(expressions, parser.parse_precendence())
		until parser.peek().type ~= token_type.comma
	end
	parser.consume(token_type.r_paren, "no r paren??")
	return expr.call(callee, expressions)
end

local function unary(parser)
	local operator = parser.previous()
	local operand = parser.parse_precendence(precedence_enum.unary)
	return expr.unary(operand, operator.type)
end

local function variable(parser, canAssign)
	if canAssign and parser.peek().type == token_type.equal then
		local name = parser.previous().lex
		parser.advance()
		return expr.variable(name, parser.parse_precendence())
	else
		return expr.variable(parser.previous().lex)
	end
end

rules = {
	[token_type.string] = { prefix = string },
	[token_type.number] = { prefix = number },
	[token_type.ftrue] = { prefix = literal },
	[token_type.ffalse] = { prefix = literal },
	[token_type.fnil] = { prefix = literal },

	[token_type.star] = { infix = binary, precedence = precedence_enum.factor },
	[token_type.slash] = { infix = binary, precedence = precedence_enum.factor },
	[token_type.plus] = { infix = binary, precedence = precedence_enum.term },
	[token_type.minus] = { prefix = unary, infix = binary, precedence = precedence_enum.term },

	[token_type.greater] = { infix = binary, precedence = precedence_enum.comparison },
	[token_type.less] = { infix = binary, precedence = precedence_enum.comparison },
	[token_type.greater_equal] = { infix = binary, precedence = precedence_enum.comparison },
	[token_type.less_equal] = { infix = binary, precedence = precedence_enum.comparison },
	[token_type.equal_equal] = { infix = binary, precedence = precedence_enum.comparison },

	[token_type.l_paren] = { prefix = grouping, infix = call, precedence = precedence_enum.grouping },
	[token_type.eof] = { precedence = precedence_enum.none },
	[token_type.bang] = { prefix = unary, precedence = precedence_enum.unary },
	[token_type.identifier] = { prefix = variable, precedence = precedence_enum.none },
}

--- Takes an array of tokens and converts it into an AST, via pratt parsing.
local function parse(tokens)
	local self = { current_token = 1, tokens = tokens }

	local function block()
		local statements = {}
		while self.peek().type ~= token_type.r_brace and self.peek().type ~= token_type.eof do
			table.insert(statements, self.statement())
		end
		self.consume(token_type.r_brace, "Expected '}' to close block!")
		return statements
	end

	function self.advance()
		local t = tokens[self.current_token]
		self.current_token = self.current_token + 1
		return t
	end

	function self.consume(type, err)
		local token = self.advance()
		if token.type ~= type then
			error(err)
		end
		return token
	end

	function self.previous()
		return tokens[self.current_token - 1]
	end

	function self.peek()
		return tokens[self.current_token]
	end

	function self.parse_precendence(precedence_)
		local precedence = precedence_ or precedence_enum.assignment
		local next_token = self.advance()
		local prefix_rule = get_rule(next_token.type).prefix
		if prefix_rule == nil then
			pprint(next_token)
			error("expect expression!")
			return
		end

		local canAssign = precedence <= precedence_enum.assignment
		local expression = prefix_rule(self, canAssign)

		while self.peek() and get_rule(self.peek().type).precedence >= precedence do
			next_token = self.advance()
			local infix_rule = get_rule(next_token.type).infix
			if infix_rule then
				expression = infix_rule(self, expression)
			end
		end

		return expression
	end

	function self.statement()
		local token = self.peek()

		return match(token.type, {
			[token_type["return"]] = function()
				self.advance()
				return statement.freturn(self.parse_precendence())
			end,
			[token_type.let] = function()
				self.advance()
				local var_name = self.consume(token_type.identifier, "Expected variable name after let!")
				self.consume(token_type.equal, "Expected equal sign after identifier name!")
				return statement.var(var_name.lex, self.parse_precendence(), false)
			end,
			[token_type.const] = function()
				self.advance()
				local var_name = self.consume(token_type.identifier, "Expected variable name after const!")
				self.consume(token_type.equal, "Expected equal sign after identifier name!")
				return statement.var(var_name.lex, self.parse_precendence(), true)
			end,
			[token_type.l_brace] = function()
				self.advance()
				return statement.block(block())
			end,
			[token_type.if_] = function()
				self.advance()

				local expression = self.parse_precendence()
				self.consume(token_type.l_brace, "Expected '{' after if statement expression!")
				local statements = block()
				local else_statements = {}

				if self.peek().type == token_type.else_ then
					self.advance()
					self.consume(token_type.l_brace, "Expected '{' after if statement expression!")
					else_statements = block()
				end

				return statement.if_statement(expression, statements, else_statements)
			end,
			[token_type["while"]] = function()
				self.advance()
				local expression = self.parse_precendence()
				self.consume(token_type.l_brace, "Expected '{' after while loop expression!")
				local statements = block()

				return statement.while_statement(expression, statements)
			end,
			[token_type["for"]] = function()
				self.advance()

				local initial
				if self.peek().type ~= token_type.comma then
					initial = self.statement()
				end
				self.consume(token_type.comma, "Expected a ','!")

				local conditional
				if self.peek().type ~= token_type.comma then
					conditional = self.parse_precendence()
				end
				self.consume(token_type.comma, "Expected a ','!")

				local increment
				if self.peek().type ~= token_type.l_brace then
					increment = self.parse_precendence()
				end
				self.consume(token_type.l_brace, "Expected '{' after increment expression!")

				local statements = block()
				return statement.for_statement(initial, conditional, increment, statements)
			end,
			[token_type.fn] = function()
				self.advance()
				local name = self.consume(token_type.identifier, "Expected function name!").lex
				local arguments = {}
				self.consume(token_type.l_paren)
				if self.peek().type ~= token_type.r_paren then
					repeat
						if self.peek().type == token_type.comma then
							self.advance()
						end

						table.insert(arguments, self.consume(token_type.identifier, "Expected identifier"))
					until self.peek().type ~= token_type.comma
				end
				self.consume(token_type.r_paren)
				self.consume(token_type.l_brace)
				local statements = block()
				return statement.fn(name, arguments, statements)
			end,
			default = function()
				return statement.expr(self.parse_precendence())
			end,
		})
	end

	local root = { type = "__root__", statements = {} }
	while self.peek().type ~= token_type.eof do
		table.insert(root.statements, self.statement())
	end
	return root
end

return parse
