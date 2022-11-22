package.path = package.path .. ";public/.lua/?.lua"

require "fun"()
local sqlite3 = require "lsqlite3"
local unix = require "unix"
local fm = require "fullmoon"
print("sqlite version: " .. sqlite3.version())

local databaseFile = "voices-of-salvation.db"

function setupDb()
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
  
  local db = sqlite3.open(databaseFile)
  db:exec[[
    CREATE TABLE IF NOT EXISTS transcriptions (
      filename TEXT PRIMARY KEY CHECK (typeof(filename) = 'text'),
      character TEXT CHECK (typeof(character) = 'text' OR character IS NULL),
      transcription TEXT CHECK (typeof(transcription) = "text" OR transcription IS NULL),
      isDistorted INTEGER CHECK (typeof(isDistorted) = "integer" or isDistorted IS NULL)
    );
  ]]
  local insert = db:prepare("INSERT OR IGNORE INTO transcriptions (filename) VALUES (?);")
  for i, filename in ipairs(audioFiles) do
    insert:bind_values(filename)
    local result = insert:step()
    if i % 100 == 0 or i == #audioFiles or result ~= sqlite3.DONE then
      print("%d/%d %d %s" % {i, #audioFiles, result, filename})
    end
    insert:reset()
  end
  db:close()
end
if not unix.stat(databaseFile) then
  setupDb()
end

function openDb()
  return sqlite3.open(databaseFile)
end

fm.setRoute("/api/audio", function(r)
  local db = openDb()
  rows = {}
  for row in db:nrows("SELECT filename, character, transcription, isDistorted FROM transcriptions") do
    rows[#rows + 1] = row
  end
  return fm.serveResponse(200, {ContentType = "application/json"}, EncodeJson(rows))
end)

fm.setRoute(fm.GET "/api/audio/*", function(r)
  local path = "/audio/" .. r.params.splat
  local db = openDb()
  local select = db:prepare([[
    SELECT filename, character, transcription, isDistorted
    FROM transcriptions
    WHERE filename = ?
  ]])
  select:bind_values(path)
  rows = {}
  for row in select:nrows() do
    rows[#rows + 1] = row
  end
  select:finalize()
  return fm.serveResponse(200, {ContentType = "application/json"}, EncodeJson(rows[1]))
end)

fm.setRoute(fm.POST "/api/audio/*", function(r)
  local path = "/audio/" .. r.params.splat
  local body = DecodeJson(r.body)
  local db = openDb()
  local update = db:prepare([[
    UPDATE transcriptions
    SET
      character = ?,
      transcription = ?,
      isDistorted = ?
    WHERE filename = ?
  ]])
  update:bind_values(body.character, body.transcription, body.isDistorted, path)
  local result = update:step()
  if result ~= sqlite3.DONE then
    print("Update returned", result)
    return fm.serveResponse(500, {ContentType = "application/json"}, EncodeJson({error = "Update failed"}))
  end
  return fm.serveResponse(200, {ContentType = "application/json"}, EncodeJson({
    filename = path,
    character = body.character,
    transcription = body.transcription,
    isDistorted = body.isDistorted,
  }))
end)

fm.setRoute("/", function(r)
  return fm.serveAsset("index.html")
end)
fm.setRoute("/main.js", fm.serveAsset)
fm.setRoute("/main.css", fm.serveAsset)
fm.setRoute("/audio/*", fm.serveAsset)

fm.run()
