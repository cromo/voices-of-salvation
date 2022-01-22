print("Hey there, this is lua")
-- local paths = GetZipPaths()
-- for i, value in ipairs(paths) do
--   print(i, value)
-- end

-- local audioIndexFile = io.open(".\\data\\audio\\index.txt")
-- local audioIndex = audioIndexFile:read("a")

local audioFiles = (function()
  local audioIndexFile = io.open(".\\data\\audio\\index.txt")
  local files = {}
  for line in audioIndexFile:lines() do
    if line ~= "" then
      files[#files + 1] = line
    end
  end
  audioIndexFile:close()
  return files
end)()

for i, value in ipairs(audioFiles) do print(i, value) end