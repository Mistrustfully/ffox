local opcode = require("src.common.opcode")[1]
local opcode_reverse = require("src.common.opcode")[2]
local match = require("src.util").match

local function red(str)
	return "\027[31;1;5m" .. str .. "\027[0m"
end

local function green(str)
	return "\027[32;1;5m" .. str .. "\027[0m"
end

local function purple(str)
	return "\027[35;1;5m" .. str .. "\027[0m"
end

local function grey(str)
	return "\027[30m" .. str .. "\027[0m"
end

local function decompile_bytes(bytes, constants, _tabs, _name)
	local tabs = _tabs or ""
	local dash = "──────"
	print(purple(tabs .. "╭" .. dash .. "<" .. " " .. (_name or "main") .. " <" .. dash))
	-- Scan the program for functions
	for _, v in pairs(constants) do
		if type(v) == "table" and v.bytes then
			decompile_bytes(v.bytes, v.constants, tabs .. "│", v.name)
		end
	end

	local i = 0
	while i < #bytes do
		i = i + 1
		local output = purple("│")
			.. purple(tabs)
			.. red("[" .. tostring(i) .. "]")
			.. grey(" (" .. tostring(bytes[i] .. ") "))
			.. opcode_reverse[bytes[i]]

		local function jump()
			i = i + 1
			output = output .. green(" @[" .. tostring(bytes[i]) .. "]")
		end

		local function global()
			i = i + 1
			output = output .. green(' "' .. tostring(constants[bytes[i]]) .. '"')
		end

		local function local_()
			i = i + 1
			output = output .. green(" @" .. tostring(bytes[i]))
		end

		match(bytes[i], {
			[opcode.constant] = function()
				i = i + 1
				output = output .. green(" @" .. tostring(bytes[i]) .. ":" .. tostring(constants[bytes[i]]))
			end,
			[opcode.get_global] = global,
			[opcode.set_global] = global,
			[opcode.jump] = jump,
			[opcode.jump_if_false] = jump,
			[opcode.get_local] = local_,
			[opcode.set_local] = local_,
			[opcode.call] = function()
				i = i + 1
				output = output .. green(" #" .. tostring(bytes[i]))
			end,
		})

		print(output)
	end

	print(purple(tabs .. "╰" .. dash .. "> " .. (_name or "main") .. " >" .. dash))
end

return decompile_bytes
