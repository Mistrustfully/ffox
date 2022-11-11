--- Matches `match` with one of the indexes in `matches`
local function match(match, matches)
	local fn = matches[match]

	if fn == nil then
		if matches.default then
			return matches.default()
		end

		return nil
	end

	return fn()
end

--- Generates an enum table with an array of strings.
local function enum(enums)
	local enum_table = {}

	for i, name in ipairs(enums) do
		enum_table[name] = i - 1
	end

	return enum_table
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
				print(indentation .. "    " .. tostring(i) .. " = " .. tostring(v))
			end
		end
		print(indentation .. "}")
	else
		print(value)
	end
end

return { match = match, enum = enum, pprint = pprint }
