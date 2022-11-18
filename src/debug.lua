local opcode = require("src.common.opcode")[1]
local opcode_reverse = require("src.common.opcode")[2]
local match = require("src.util").match

local function red(str)
	return "\027[31;1;5m" .. str .. "\027[0m"
end

local function green(str)
	return "\027[32;1;5m" .. str .. "\027[0m"
end

local function decompile_bytes(bytes, constants)
	local i = 0
	while i < #bytes do
		i = i + 1
		local output = red("[" .. tostring(i) .. "]") .. " " .. opcode_reverse[bytes[i]]

		local function jump()
			i = i + 1
			output = output .. green(" @[" .. tostring(bytes[i]) .. "]")
		end

		local function global()
			i = i + 1
			output = output .. green(' "' .. tostring(constants[bytes[i]]) .. '"')
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
		})

		print(output)
	end
end

return decompile_bytes