local enum = require(script.Parent.Parent.util).enum

return
	{
		enum({
			-- Constants
			"fnil",
			"ftrue",
			"ffalse",
			"constant",

			-- Arithmetic
			"fnot",
			"negate",
			"add",
			"sub",
			"mul",
			"div",

			-- Comparators
			"equal",
			"greater",
			"less",

			-- Jumps
			"jump",
			"jump_if_false",

			-- Setters & Getters
			"get_global",
			"set_global",
			"get_local",
			"set_local",

			-- Others
			"freturn",
			"print",
			"call",
			"pop",
		}),
	}
