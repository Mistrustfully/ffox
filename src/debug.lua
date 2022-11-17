local opcode = require("src.common.opcode")[1]
local opcode_reverse = require("src.common.opcode")[2]
local match = require("src.util").match

local function decompile_bytes(bytes, constants)
	local i = 0
	while i < #bytes do
		i = i + 1
		local output = tostring(i) .. " " .. opcode_reverse[bytes[i]]
		match(bytes[i], {
			[opcode.constant] = function()
				i = i + 1
				output = output .. " constant: " .. tostring(constants[bytes[i]])
			end,
			[opcode.get_global] = function()
				i = i + 1
				output = output .. " name: " .. tostring(constants[bytes[i]])
			end,
			[opcode.jump] = function()
				i = i + 1
				output = output .. " - to: " .. tostring(bytes[i])
			end,
			[opcode.jump_if_false] = function()
				i = i + 1
				output = output .. " - to: " .. tostring(bytes[i])
			end,
		})

		print(output)
	end
end

return decompile_bytes
