--- Matches `match` with one of the indexes in `matches`
local function match(matchee, matches)
	local fn = matches[matchee]

	if fn == nil then
		fn = matches.default
	end

	if type(fn) == "function" then
		return fn()
	else
		return fn
	end
end

--- Generates an enum table with an array of strings.
local function enum(enums)
	local enum_table = {}
	local reverse_table = {}

	for i, name in ipairs(enums) do
		enum_table[name] = i - 1
		reverse_table[i - 1] = name
	end

	return enum_table, reverse_table
end

--- Pretty prints tables and other values.
local function pprint(value, tabs_)
	local tabs = tabs_ or 0
	local indentation = ("    "):rep(tabs)

	if type(value) == "table" then
		print(indentation .. "{")
		for i, v in pairs(value) do
			if type(v) == "table" then
				pprint(v, tabs + 1)
			else
				local print_v = tostring(v)
				if type(v) == "string" then
					print_v = '"' .. print_v .. '"'
				end

				print(indentation .. "    " .. tostring(i) .. " = " .. print_v .. ",")
			end
		end
		print(indentation .. "},")
	else
		print(value)
	end
end

return { match = match, enum = enum, pprint = pprint }
