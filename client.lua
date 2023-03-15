-- The Global Channel 
GlobChannel = 8190
-- MyChannel is the unique channel of this Client
MyChannel = os.getComputerID() + 8192
-- The global modem handler
Modem = peripheral.find("modem")
-- The global version identifier. If it does not match the server, we update
Version = {1,0}
-- A local log of messages
Log = {}
-- A local input cursor and table
Cursor = 1
Input = {}

-- Adds an entry to the log
local function log(message)
  Log[#Log+1] = message
end


-- Adds an entry to the log
local function show_log(here)
  local xSize, ySize = here.getSize()
  here.setCursorPos(1,1)
  offset = #Log - ySize
  for index, item in ipairs(Log) do
    here.setCursorPos(1, index)
    here.clearLine()
    if #Log <= ySize then
      here.write(item)
    end
  end
end


local function show_input(here)
  local xSize, ySize = here.getSize()
  here.setCursorPos(1,1)
  here.write(table.concat(Input, ""))
end


function FetchUpdate(url)
  local randomid = tostring(math.random(1,16384))
  local url_handler = http.get(url)
  return url_handler.readAll()
end


function SaveWithBackup(data, filename)
  if not filename then filename = "startup" end
  if fs.exists(filename) then
    if not fs.isDir("old") then
      fs.makeDir("old")
    end
    if fs.exists("old/" .. filename) then
      fs.delete("old/" .. filename)
    end
    fs.move(filename, "old/filename")
  end
  -- Write to a temporary update file, just in case there's a failure.
  local file_handler = fs.open(".temp", "w")
  file_handler.write(data)
  file_handler.close()
  fs.move(".temp", filename)
end

-- Create windows for the log and input displays
local xSize, ySize = term.getSize()
LogDisplay = window.create(
  term.native(), 
  1, 1,
  xSize, ySize-1,
  true
)
InputDisplay = window.create(
  term.native(),
  1, ySize,
  xSize, 1,
  true
)

-- Clear the log and input displays
LogDisplay.clear()
InputDisplay.setBackgroundColour(colours.grey)
InputDisplay.setTextColour(colours.white)
InputDisplay.clear()

function ParseCommand(command)
  -- Handle the command so it's not all in the loop
  -- TODO
end

while true do
  -- Update the log display and the input display
  show_log(LogDisplay)
  show_input(InputDisplay)

  -- Wait to continue
  local event = {os.pullEvent()}
  if event[1] == "modem_message" then
    -- Update the log
    
  elseif event[1] == "char" then
    -- Add the character to the input table
    Input[#Input+1] = event[2]
    Cursor = Cursor + 1
  elseif event[1] == "key" then
    if event[2] == keys.enter then
      -- If valid, send the command
      
      -- Reset the Input global variable
      Input = {}
      Cursor = 1
    elseif event[2] == keys.left then
      Cursor = Cursor - 1
    elseif event[2] == keys.right then
      Cursor = Cursor + 1
    end
    if Cursor <= 1 then Cursor = 1 end
    if Cursor >= #Input+1 then Cursor = #Input+1 end
  end
end