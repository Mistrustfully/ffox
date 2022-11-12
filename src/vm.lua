local util = require("src.util")
local opcode = require("src.common.opcode")

local match, pprint = util.match, util.pprint
local fnil = {}

local function run(source, constants)
	local ip = 0
	local stack = {}
	local globals = {}

	local skip = 1

	local function read_byte()
		skip = 2
		return source[ip + 1]
	end

	local function read_constant()
		return constants[read_byte()]
	end

	local function pop_as(type_check)
		local value = table.remove(stack)

		if type(value) ~= type_check then
			error("Value is not " .. type_check .. "!")
		end

		if value == fnil then
			error("Value is nil!")
		end

		return value
	end

	local function binary_op(op)
		local v2 = pop_as("number")
		local v1 = pop_as("number")

		table.insert(
			stack,
			match(op, {
				["+"] = function()
					return v1 + v2
				end,

				["-"] = function()
					return v1 - v2
				end,

				["*"] = function()
					return v1 * v2
				end,

				["/"] = function()
					return v1 / v2
				end,

				[">"] = function()
					return v1 > v2
				end,

				["<"] = function()
					return v1 < v2
				end,
			})
		)
	end

	while ip < #source do
		ip = ip + skip
		skip = 1

		local instruction = source[ip]

		local v = match(instruction, {
			[opcode.fnil] = function()
				table.insert(stack, fnil)
			end,

			[opcode.ftrue] = function()
				table.insert(stack, true)
			end,

			[opcode.ffalse] = function()
				table.insert(stack, false)
			end,

			[opcode.constant] = function()
				table.insert(stack, read_constant())
			end,

			[opcode.print] = function()
				pprint(table.remove(stack))
			end,

			[opcode.add] = function()
				if type(stack[#stack]) == "string" and type(stack[#stack - 1]) == "string" then
					local v2 = table.remove(stack)
					local v1 = table.remove(stack)

					table.insert(stack, v1 .. v2)
				else
					binary_op("+")
				end
			end,

			[opcode.sub] = function()
				binary_op("-")
			end,

			[opcode.mul] = function()
				binary_op("*")
			end,

			[opcode.div] = function()
				binary_op("/")
			end,

			[opcode.greater] = function()
				binary_op(">")
			end,

			[opcode.less] = function()
				binary_op("<")
			end,

			[opcode.equal] = function()
				table.insert(stack, table.remove(stack) == table.remove(stack))
			end,

			[opcode.jump] = function()
				skip = read_byte()
			end,

			[opcode.jump_if_false] = function()
				local jump = read_byte()
				if not table.remove(stack) then
					skip = jump
				end
			end,

			[opcode.get_global] = function()
				local name = read_constant()
				local value = globals[name]
				if not value then
					error(("Undefined global %s!"):format(name))
				end

				table.insert(stack, value)
			end,

			[opcode.set_global] = function()
				local name = read_constant()
				local value = table.remove(stack)
				globals[name] = value
			end,

			[opcode.freturn] = function()
				return table.remove(stack)
			end,

			[opcode.call] = function()
				local fn = table.remove(stack)
				run(fn[1], fn[2])
			end,

			default = function()
				error(("Missing OpCode %s!"):format(instruction))
			end,
		})

		if v then
			return v
		end
	end
end

return { run = run }
