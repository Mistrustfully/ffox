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
local function enum(enums, return_reverse)
	local enum_table = {}
	local reverse_table = {}

	for i, name in ipairs(enums) do
		enum_table[name] = i - 1
		reverse_table[i - 1] = name
	end

	if return_reverse then
		return enum_table, reverse_table
	else
		return enum_table
	end
end

--- Pretty prints tables and other values.
local function pprint(value, index, tabs_)
	local tabs = tabs_ or 0
	local indentation = ("    "):rep(tabs)

	if type(value) == "table" then
		local index_string = ""
		if index then
			index_string = tostring(index) .. " = "
		end

		print(indentation .. index_string .. "{")
		for i, v in pairs(value) do
			if type(v) == "table" then
				pprint(v, i, tabs + 1)
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

local function merge(t1, t2)
	local merged = {}
	for _, v in ipairs(t1) do
		table.insert(merged, v)
	end
	for _, v in pairs(t2) do
		table.insert(merged, v)
	end
	return merged
end

return { match = match, enum = enum, pprint = pprint, merge = merge }
