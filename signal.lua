-- The global channel is where the server is located.
GlobChannel = 8190
-- MyChannel is the unique channel ID of this signal.
MyChannel = os.getComputerID() + 8192
-- A global modem handler.
Modem = peripheral.find("modem")
Modem.open(MyChannel)
-- The current network version.
Version = {1,0,15}
-- A log of messages
Log = {}
-- Default state of this machine (Red Signal)
DefaultState = 1


local function log(message)
  --[[
    Add a message to the log table.
  ]]
  Log[#Log+1] = message
end


local function show_log(here)

  --[[
    Displays the log data on the screen.
  ]]

  -- set the cursor position to the top corner.
  local xSize, ySize = here.getSize()
  here.setCursorPos(1,1)
  here.clear()

  -- If we have a big logfile, we set an offset.
  offset = #Log - ySize

  -- Iterate over each log file.
  for index, item in ipairs(Log) do

    -- Shorten long log entries for display.
    if #item > xSize then
      item = string.sub(item, 1, xSize-4)
      item = item.."..."
    end

    -- Set our index location for log entry writing
    here.setCursorPos(1, index)

    -- Remove any existing characters from this line, then write.
    here.clearLine()
    if #Log <= ySize then
      here.write(item)
    else
      here.write(Log[offset+index])
    end
  end
end


Signal = {}
Signal[0] = "off"
Signal[1] = "red"
Signal[7] = "yellow"
Signal[15] = "green"


-- If we do not have a saved state, create a new default one.
if not fs.exists("state") then
  local state_file = fs.open("state", "w")
  state_file.write(DefaultState)
  state_file.close()
end


-- Load any saved state, whatever it may be.
local state_file = fs.open("state", "r")
State = tonumber(state_file.readAll())
state_file.close()


function PingState()

  --[[
    We use this to tell the server what we are doing right now.
    The server will then respond with updated instructions if that is incorrect.
  ]]

  Modem.transmit(GlobChannel, MyChannel, {
    my_type="signal",
    instruct="ping",
    state=State,
    version=Version
  })

end


function SaveState()

  --[[
    Saves the state to file.
  ]]

  local state_file = fs.open("state", "w")
  state_file.write(State)
  state_file.close()

end


function ApplyState()

  --[[
    Applies the state to the analogue redstone output.
  ]]

  redstone.setAnalogOutput("top", State)
  redstone.setAnalogOutput("left", State)
  log("Setting state to "..Signal[State])

end


function UpdateState()

  --[[
    Applies the state, then saves the state.
  ]]

  ApplyState()
  SaveState()

end



function FetchUpdate(url)

  --[[
    Grabs the update from the URL. Designed as a fallback, just in case.
  ]]

  local randomid = tostring(math.random(1,16384))
  local url_handler = http.get(url)
  return url_handler.readAll()

end


function SaveWithBackup(data, filename)
  -- Installs the update.
  if not filename then filename = "startup" end
  if fs.exists(filename) then
    if not fs.isDir("old") then
      fs.makeDir("old")
    end
    if fs.exists("old/" .. filename) then
      fs.delete("old/" .. filename)
    end
    fs.move(filename, "old/" .. filename)
  end
  -- Write to a temporary update file, just in case there's a failure.
  local file_handler = fs.open(".temp", "w")
  file_handler.write(data)
  file_handler.close()
  fs.move(".temp", filename)
end


-- Either applies the saved state, or applies the default state.
ApplyState()
PingState()


log("Started Skyline "..table.concat(Version, ".").." signal on channel "..MyChannel)
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

        if payload.your_type == "signal" then
          -- Here we handle update files.
          SaveWithBackup(payload.data, "startup.lua")
          os.reboot()
        end

      elseif payload.instruct == "set" then

        if payload.your_type == "signal" then
          -- Here we handle signals.
          State = payload.state
          UpdateState()
        end

        -- Automatically update if our version does not match
        if (
          payload.version[3] > Version[3] or
          payload.version[2] > Version[2] or
          payload.version[1] > Version[1] 
        ) then
          Modem.transmit(GlobChannel, MyChannel, {
            my_type = "signal",
            instruct = "update"
          })
        end

      end
    end
  end
end
