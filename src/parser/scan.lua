local token_type = require("src.parser.token")
local match = require("src.util").match

local function is_whitespace(char)
	return char:find("%s") ~= nil
end

local function is_digit(char, match_dot, match_underscore)
	return char:find("%d") ~= nil or (match_dot and char == ".") or (match_underscore and char == "_")
end

local function is_alpha(char)
	return char:find("%w") ~= nil or char == "_"
end

--- Takes a source file and returns an array of tokens.
local function scan(source)
	local tokens = {}
	local start = 0
	local current = 0
	local line = 0

	local function at_end()
		return #source <= current
	end

	local function advance()
		current = current + 1
		return source:sub(current, current)
	end

	local function peek()
		return source:sub(current + 1, current + 1)
	end

	local function advance_until(fn)
		while fn(peek()) and not at_end() do
			advance()
		end
	end

	local function new_token(t, str)
		return { type = t, lex = str or source:sub(start, current), start = start, current = current, line = line }
	end

	while not at_end() do
		-- Skip all whitespace
		if is_whitespace(peek()) then
			advance_until(function(p)
				if p == "\n" then
					line = line + 1
					return true
				end
				if is_whitespace(p) then
					return true
				end
				if p == "/" and source:sub(current + 2, current + 2) == "/" then
					advance_until(function(np)
						return not (np == "\n" or at_end())
					end)
					return true
				end
				return false
			end)

			if at_end() then
				break
			end
		end

		local char = advance()
		start = current

		-- Check if number
		if is_digit(char) or (is_digit(char, true) and is_digit(peek())) then
			local foundDot = false
			advance_until(function(p)
				local res = is_digit(p, not foundDot, true) and not at_end()
				if p == "." then
					foundDot = true
				end
				return res
			end)

			table.insert(tokens, new_token(token_type.number, source:sub(start, current):gsub("_", "")))
		elseif is_alpha(char) then
			-- Identifier
			advance_until(function(p)
				return (is_alpha(p) or is_digit(p))
			end)

			table.insert(
				tokens,
				new_token(match(source:sub(start, current), {
					const = token_type.const,
					let = token_type.let,
					["return"] = token_type["return"],
					["break"] = token_type["break"],
					["fn"] = token_type.fn,
					default = token_type.identifier,
				}))
			)
		else
			-- Other Token
			local made_token = match(char, {
				['"'] = function()
					local type = token_type.string
					local str

					advance_until(function(p)
						if at_end() or p == "\n" then
							type = token_type.error
							str = "Unterminated string!"
							return false
						end
						return p ~= '"'
					end)

					advance()

					return new_token(type, str)
				end,

				["{"] = token_type.l_brace,
				["}"] = token_type.r_brace,
				["("] = token_type.l_paren,
				[")"] = token_type.r_paren,
				["["] = token_type.l_bracket,
				["]"] = token_type.r_bracket,
				["="] = function()
					if peek() == "=" then
						advance()
						return token_type.equal_equal
					end
					return token_type.equal
				end,

				default = function()
					error(("Invalid token '%s'"):format(char))
				end,
			})

			local token
			if type(made_token) == "number" then
				token = new_token(made_token)
			else
				token = made_token
			end

			table.insert(tokens, token)
		end
	end

	return tokens
end

return scan
