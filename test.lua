#!/usr/bin/luajit
local ffox = require("src.init")

local function for_each_file(dir, fn)
	local p = io.popen('find "' .. dir .. '" -type f') --Open directory look for files, save data in p. By giving '-type f' as parameter, it returns all files.
	if p then
		for file in p:lines() do --Loop through all files
			local opened_file = io.open(file, "r")
			fn(opened_file, file)
		end
	else
		error("Directory doesn't exist!")
	end
end

for_each_file("test", function(file, file_name_)
	local file_name = file_name_:gsub("test/", "")

	local source = file:read("a")
	local result = ffox.run(source)

	if result then
		print("\27[1;32m  [PASS]  \27[0;1m" .. file_name)
	else
		print("\27[1;31m [FAILED] \27[0;1m" .. file_name)
	end
end)
