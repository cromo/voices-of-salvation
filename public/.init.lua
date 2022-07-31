package.path = package.path .. ";public/.lua/?.lua"

require "fun"()
local sqlite3 = require "lsqlite3"
local unix = require "unix"
local fm = require "fullmoon"
print("sqlite version: " .. sqlite3.version())

function listFilesRecursive(startDir, listing)
  listing = listing or {}
  for name, kind in assert(unix.opendir(startDir)) do
    if kind == unix.DT_DIR then
      if not (name == "." or name == "..") then
        listFilesRecursive(startDir .. "/" .. name, listing)
      end
    else
      listing[#listing + 1] = startDir .. "/" .. name
    end
  end
  return listing
end

function removePrefix(prefixPattern)
  return function(str)
    str = str:gsub("^" .. prefixPattern, "")
    return str
  end
end

audioFiles = totable(map(removePrefix("data"), listFilesRecursive("data/audio")))
each(print, take(4, audioFiles))

fm.setTemplate("hello", "Hello, {%& name %}")
fm.setRoute("/hello/:name", function(r)
  return fm.serveContent("hello", {name = r.params.name})
end)
fm.setRoute("/", "/index.html")
fm.run()