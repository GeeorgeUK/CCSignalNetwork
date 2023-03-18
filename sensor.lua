-- The global channel is where the server is located.
GlobChannel = 8190
-- MyChannel is the unique channel ID of this sensor.
MyChannel = os.getComputerID() + 8192
-- The global modem handler.
Modem = peripheral.find("modem")
Modem.open(MyChannel)
-- The current version of this sensor.
Version = {1,0,21}
-- A log of messages
Log = {}

local function log(message)
  --[[
    Add a messaage to the log table.
  ]]
  Log[#Log+1] = message

  -- Prune any really old log files to avoid using lots of RAM
  if #Log >= 100 then
    table.remove(Log, 1)
  end
end


local function show_log(here)

  --[[
    Displays the log data on the screen.
  ]]

  -- Set the cursor position to the top corner.
  local xSize, ySize = here.getSize()
  here.setCursorPos(1,1)
  here.clear()

  -- If we have a big logfile, we set an offset.
  offset = #Log - ySize

  -- Iterate over each log file
  for index, item in ipairs(Log) do

    -- Shorten long log entries for display
    if #item > xSize then
      item = string.sub(item, 1, xSize-4)
      item = item.."..."
    end

    -- Set the index location for log entry writing
    here.setCursorPos(1, index)

    -- Write
    if #Log <= ySize then
      here.write(item)
    else
      here.write(Log[offset+index])
    end
  end
end


function PingState()

  --[[
    We use this to tell the server when our sensor detects a signal change.
    Thats all a sensor does so this should be a simple machine.
  ]]

  Modem.transmit(GlobChannel, MyChannel {
    my_type="sensor",
    instruct="ping",
    state=rs.getInput("top"),
    version=Version
  })

end


function SaveWithBackup(data, filename)
  --[[
    Installs the update as a backup file.
    Just in case there's an error while installing.
  ]]

  -- If we dont have a file, we use the default startup name
  if not filename then
    filename = "startup.lua"
  end

  -- If the file exists, we create a backup
  if fs.exists(filename) then
    if not fs.isDir("old") then
      fs.makeDir("old")
    end

    if fs.exists("old/"..filename) then
      fs.delete("old/"..filename)
    end

    fs.move(filename, "old/"..filename)
  end

  -- Create a temporary file of the content, then move it.
  local file_handler = fs.open(".temp", "w")
  file_handler.write(data)
  file_handler.close()
  fs.move(".temp", filename)
end


log("Started Skyline "..table.concat(Version, ".").." sensor on channel "..MyChannel)
while true do

  -- Display the log
  show_log(term.native())

  -- Wait to continue
  local event = {os.pullEvent()}

  -- Received a message
  if event[1] == "modem_message" then
    if type(event[5]) == "table" then

      -- Our payload
      payload = event[5]

      if payload.instruct == "update" then
        if payload.your_type == "sensor" then
          -- Here we handle update files.
          SaveWithBackup(payload.data, "startup.lua")
          shell.run("startup.lua")
          return
        end
      end
    
    end
  elseif event[1] == "redstone" then
    PingState()
  end
end