local enum = require("src.util").enum

return enum({
	-- literals
	"string",
	"number",
	"identifier",

	-- arithmetic
	"bang",
	"plus",
	"minus",
	"star",
	"slash",

	-- comparators
	"less",
	"greater",
	"equal_equal",
	"less_equal",
	"greater_equal",
	"bang_equal",

	-- symbols
	"dot",
	"comma",
	"equal",
	"r_brace",
	"l_brace",
	"r_paren",
	"l_paren",
	"r_bracket",
	"l_bracket",

	-- keywords
	"const",
	"let",
	"fn",
	"return",
	"break",

	-- other
	"error",
})
