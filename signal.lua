-- The global channel is where the server is located.
GlobChannel = 8190
-- MyChannel is the unique channel ID of this signal.
MyChannel = os.getComputerID() + 8192
-- A global modem handler.
Modem = peripheral.find("modem")
-- The current version of this signal.
Version = {1,0}

-- If we do not have a saved state, create a new default one.
if not fs.exists("state") then
  local state_file = fs.open("state", "w")
  state_file.write(7)
  state_file.close()
end

local state_file = fs.open("state", "r")
State = tonumber(state_file.readAll())

function GetState()    
  --[[
    Returns an object representing the state:
    {
      your_type="signal",
      instruct=set,
      state=integer
    }
  ]]
  Modem.transmit(GlobChannel, MyChannel, {
    my_type="signal",
    instruct="get",
    version=Version
  })
end

function PutState()
  --[[
    We use this to tell the server what we are doing right now.
  ]]
  Modem.transmit(GlobChannel, MyChannel, {
    my_type="signal",
    instruct="put",
    state=State,
    version=Version
  })
end

--[[
  Not necessary to function, but this is an important reference to
  what each state values mean.
]]
Signal = {
  off=0,
  red=1,
  yellow=7,
  green=15
}

-- Applies the state of the signal
function SetState(signal)
  redstone.setAnalogOutput("top", signal)
  redstone.setAnalogOutput("left", signal)
  local state_file = fs.open("state", "w")
  state_file.write(tostring(signal))
  state_file.close()
  State = signal
  PutState()
end

-- Grabs the update from the URL. Designed as a fallback, just in case.
function FetchUpdate(url)
  local randomid = tostring(math.random(1,16384))
  local url_handler = http.get(url.."?cache="..randomid)
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
  local file_handler = fs.open(filename)
  file_handler.write(data)
  file_handler.close()
end

-- We set the default signal to Yellow: Proceed with caution.
SetState(State)

print("Welcome to Skyline - SIGNAL #"..MyChannel)
while true do
  local event, v1, v2, v3, v4, v5 = os.pullEvent()
  if event == "modem_message" then
    if type(v4) == "table" then
      if v4.instruct == "update" then
        if type(v4.data) == "string" then
          -- If it's a string, we treat it like a URL
          local data = FetchUpdate(v4.data)
          SaveWithBackup(data, "startup")
        elseif type(v4.data) == "table" then
          SaveWithBackup(v4.data, "startup")
        end
        os.reboot()
      elseif v4.instruct == "get" then
        if v4.my_type == "signal" then
          -- Makes sure we've set the correct state
          SetState(v4.state)
        end
      end
    end
  end
end