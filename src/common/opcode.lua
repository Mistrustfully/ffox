local enum = require("src.util").enum

return enum({
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

	-- Others
	"freturn",
	"print",
	"pop",
})
