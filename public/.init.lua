local json = require "dkjson"

print("Hey there, this is lua")

local audioIndexFile = io.open(".\\data\\audio\\index.json")
local audioFiles = json.decode(audioIndexFile:read("*a"))
audioIndexFile:close()
for i, value in ipairs(audioFiles) do print(i, value) end