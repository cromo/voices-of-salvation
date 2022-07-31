package.path = package.path .. ";public/.lua/?.lua"
require "fun"()
local sqlite3 = require "lsqlite3"
print("sqlite version: " .. sqlite3.version())

print("Hey there, this is lua")

local audioIndexFile = io.open(".\\data\\audio\\index.json")
local audioFiles = DecodeJson(audioIndexFile:read("*a"))
audioIndexFile:close()

function posixPathFromWindowsPath(path)
  path = path:gsub("\\", "/")
  return path
end

function removePrefix(prefixPattern)
  return function(str)
    str = str:gsub("^" .. prefixPattern, "")
    return str
  end
end

audioFiles = totable(map(removePrefix("./data"), map(posixPathFromWindowsPath, audioFiles)))

each(print, take(4, audioFiles))
