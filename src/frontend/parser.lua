local token_type = require("src.common.token")
local util = require("src.util")
local ast = require("src.common.ast")

local pprint, enum, match = util.pprint, util.enum, util.match
local expr, statement = ast.expr, ast.statement

local precedence_enum = enum({
	"none",
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

local function binary(parser, left)
	local operator = parser.previous()
	local right = parser.parse_precendence(get_rule(operator.type).precedence + 1)
	return expr.binary(left, right, operator.type)
end

local function grouping(parser)
	local exp = parser.parse_precendence(precedence_enum.term)
	parser.advance()
	return exp
end

local function unary(parser)
	local operator = parser.previous()
	local operand = parser.parse_precendence(precedence_enum.unary)
	return expr.unary(operand, operator.type)
end

local function variable(parser)
	return expr.variable(parser.previous().lex)
end

rules = {
	[token_type.number] = { prefix = number, precedence = precedence_enum.none },

	[token_type.star] = { infix = binary, precedence = precedence_enum.factor },
	[token_type.slash] = { infix = binary, precedence = precedence_enum.factor },
	[token_type.plus] = { infix = binary, precedence = precedence_enum.term },
	[token_type.minus] = { prefix = unary, infix = binary, precedence = precedence_enum.term },
	[token_type.l_paren] = { prefix = grouping, precedence = precedence_enum.grouping },
	[token_type.eof] = { precedence = precedence_enum.none },
	[token_type.bang] = { prefix = unary, precedence = precedence_enum.unary },
	[token_type.identifier] = { prefix = variable, precedence_enum.none },
}

--- Takes an array of tokens and converts it into an AST, via pratt parsing.
local function parse(tokens)
	local self = { current_token = 1, tokens = tokens }

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
		local precedence = precedence_ or precedence_enum.term
		local next_token = self.advance()
		local prefix_rule = get_rule(next_token.type).prefix
		if prefix_rule == nil then
			error("expect expression!")
		end

		local expression = prefix_rule(self)
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
		local root = { type = "__root__", statements = {} }
		while self.peek().type ~= token_type.eof do
			local token = self.peek()
			table.insert(
				root.statements,
				match(token.type, {
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
					default = function()
						return self.parse_precendence()
					end,
				})
			)
		end
		return root
	end

	return self.statement()
end

return parse
