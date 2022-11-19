# ffox, a simple scripting language
_written with :heart: in lua_

### running tests
running the tests requires LuaJit to be installed.
```sh
./tests.lua
```

### using

there are two ways we can use ffox

the convoluted way:
```lua
local ffox = require(--[[ffox src path]])
local tokens = ffox.lex("return true") -- get the tokens of the program
local ast = ffox.parse(tokens) -- parse the tokens and output an ast
local bytecode = ffox.compile(ast) -- compile the ast into bytes and constants
local result = ffox.vm.run(bytecode.bytes, bytecode.constants) -- run the bytecode and get the result

print("result", result) -- We now can print the result!!
```

the simple way:
```lua
local ffox = require(--[[ffox src path]])
local result = ffox.run("return true")

print("result", result) -- We got the result without all the boilerplate!
```

### goals
