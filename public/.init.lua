local json = require "dkjson"
require "fun"()

print("Hey there, this is lua")

local audioIndexFile = io.open(".\\data\\audio\\index.json")
local audioFiles = json.decode(audioIndexFile:read("*a"))
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
