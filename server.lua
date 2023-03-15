-- The channel of this server
GlobChannel = 8190
-- A global modem handler.
Modem = peripheral.find("modem")
-- The current version of this server.
Version = {1,0}
-- A log of messages.
Log = {}
-- All data about the network.
Network = {
  Signals = {},
  Switches = {}
}


-- Add a message to the log.
local function log(message)
  Log[#Log+1] = message
end


-- Displays the log on the screen, inside the terminal 'here'.
local function show_log(here)
  local xSize, ySize = here.getSize()
  here.setCursorPos(1,1)
  offset = #Log - ySize
  for index, item in ipairs(Log) do
    here.setCursorPos(1, index)
    here.clearLine()
    if #Log <= ySize then
      here.write(item)
    else
      here.write(Log[offset+index])
    end
  end
end


local function split(unprocessed, separator)

  --[[ 
    Split a string by a separator into a table.
  ]]

  -- This will be our output.
  local processed = {}
  -- If we have no separator, we should use a space character.
  local seperator = separator or " "
  -- This is the pattern of characters we will use to split the string.
  local pattern = string.format("([^%s]+)", separator)
  -- Process the unprocessed data using the pattern
  string.gsub(unprocessed, pattern, function(this_item) 
    processed[#processed + 1] = this_item 
  end)
  -- Return our processed result. We are done!
  return processed
end


local function contains(container, something)

  --[[
    Checks if something is inside the container
  ]]

  if type(container) == "table" then
    -- If we are checking a table for an entry, use this code block.
    -- Iterate across each item in the table until we find it
    for index, item in ipairs(container) do
      if item == something then
        return true
      end
    end
  elseif type(container) == "string" then
    -- If we are checking a string for a substring, Lua has an inbuilt method for this.
    -- (Why aren't you using string.match in the first instance?)
    return (string.match(container, something) ~= nil)
  end

  -- We received an invalid container type.
  return false
end


local function load_csv(file)

  --[[
    A function to parse a CSV (comma separated values) flatfile.
    Used by the Skyline server to store its data.
  ]]

  -- Each header is stored here.
  local headers = {} 
  -- Each entry is stored here as a split line.
  local entries = {}
  -- Handle the file.
  local handler = fs.open(file, "r")

  -- First, we must deal with the headers.
  local headers_line = handler.readLine()
  -- If the file is empty, we should return empty headers and entries.
  if not headers_line then return {}, {} end

  -- Populate our headers line by splitting our headers line.
  headers = split(headers_line, ",")

  -- Now we must load each line in the same manner.
  local next_line = handler.readLine()
  while next_line do
    entries[#entries+1] = split(next_line, ",")
  end

  -- Close the handler as we are done with it.
  handler.close()

  -- Return our headers table, and our entries table.
  return headers, entries
end


local function save_csv(headers, data, file)
  --[[
    A function to convert the data in the headers and data tables into a CSV.
    Used by the Skyline server to store its data.
  ]]
  -- Handle the file.
  local handler = fs.open(file, "w")

  -- Create the first line of the file from the headers table.
  local headers_line = table.concat(headers, ",")
  handler.writeLine(headers_line)
  
  -- Iterate through the rest of the lines and insert them
  for index, entry in ipairs(data) do
    local this_line = table.concat(entry, ",")
    handler.writeLine(this_line)
  end

  -- Save the file. We are done!
  handler.close()
end


local function is_valid(headers, line)

  --[[
    Check to make sure our line has a valid number of headers.
    In the future, this should be modified with additional checks.
  ]]

  -- Check each header is the same length
  if #line ~= #headers then
    return false
  end

  -- TODO: more checks for integrity
  return true
end


local function append_csv(line, file)

  --[[
    A function that appends to the end of the file instead of loading
    the whole thing and saving it again. Use is_valid to check line validity.
  ]]
  
  -- Handle the file.
  local handler = fs.open(file, "a")

  -- Create a string representation of this line
  local this_line = table.concat(line, ",")

  -- Write and save the line. We are done!
  handler.writeLine(this_line)
  handler.close()
end


function ParseRoute(file)
  --[[
    A route file is just a CSV with the following format:
      index,address,type,state 
    The parseroute iterates over each item in the route:
    - Runs SaveState on each item to save locally
  ]]
  if fs.exists(file) then
    local csv_data = {load_csv(file)}
    for index, item in ipairs(csv_data.entries) do
      SaveState(item[2], item[3], item[4])
    end
  end
end


-- Create the network database if it does not exist.
if not fs.exists("database.csv") then
  local db_handler = fs.open("database.csv", "w")
  db_handler.write("index,address,type,state,name")
  db_handler.close()
end

if not fs.isDir("routes") then
  fs.makeDir("routes")
end
if not fs.isDir("routes/autorun") then
  fs.makeDir("routes/autorun")
end


-- Create the network table from the database file.
Network = {load_csv("database.csv")}


function get_device(address)
  --[[
    Searches through the Network entries for the address.
  ]]
  for index, item in ipairs(Network.entries) do
    if item[2] == address then
      return index, item
    end
  end
  return 0, nil
end


function set_device_type(address, new_type, new_state)
  --[[
    Searches through the Network entries for the address, and updates it
  ]]
  for index, item in ipairs(Network.entries) do
    if item[2] == address then
      Network.entries[index][3] = new_type
      Network.entries[index][4] = new_state
    end
  end
end


function set_all_states(of_type, new_state)
  --[[
    Iterates through all Network entries of this type and sets them to the new state
  ]]
  for index, item in ipairs(Network.entries) do
    if item[3] == of_type then
      Network.entries[index][4] = new_state
    end
  end
end


function set_device_state(address, new_state)
  --[[
    Searches through the Network entries for the address, and updates it
  ]]
  for index, item in ipairs(Network.entries) do
    if item[2] == address then
      Network.entries[index][4] = new_state
      break
    end
  end
end


--[[
  *How the State system works*
  - Some PCs have an initial value based on their type.
    (signal) Yellow, or 7 [Sent as an integer; =Proceed with caution]
    (switch) Off, or 0 [Sent as an integer; =Switch leads forwards]
    (schedule) Welcome to SkyLine [Sent as a table; =List of strings]
    (sensor, server, and client are not applicable)
  - On start, a PC will request the latest value from the server.
  - The server will reply with the latest value.
  - When a value changes, we must both notify AND store.
]]


function SendState(address, their_type, new_state)
  --[[
    This function is used to inform a device as to their current state.
    - Switches will be told to set their switch state.
    - Signals will be told to set their light colour.
    - Schedules will be given an updated table of schedules.
    This function does not expect any response and will assume the state was set successfully.
  ]]
  modem.transmit(address, GlobChannel, {
    your_type=their_type,
    instruct="set",
    state=new_state,
    version=Version
  })
end


function SaveState(address, their_type, their_state)
  --[[
    This function sends the state and updates the state locally.
  ]]
  log("To "..their_type.."#"..address..": set is "..their_state)
  set_device_state(address, new_state)
  SendState(address, their_type, their_state)
end


-- Runtime environment
log("Started Skyline server on port "..GlobChannel)
monitor = peripheral.find("monitor")


while true do
  -- First, show the updated log on the monitor.
  if monitor ~= nil then
    show_log(monitor)
  end

  -- Then, show the log on the computer itself.
  show_log(term)

  -- Wait here until we receive a modem message event
  local e = {os.pullEvent()}

  if e[1] == "modem_message" then
    -- Make sure the message is valid
    if type(e[5]) == "table" then

      -- Grab the payload and the address from the message data
      local payload = e[5]
      local address = e[4]

      if payload.instruct == "ping" then
        -- This means a device is available, we should send their state.

        -- 1. Get the device details by its address
        local _, item = get_device(address)
        local their_type = item[3]
        local their_state = item[4]

        -- 2. To save on bandwidth, only send the change if it's different
        if payload.state == their_state then
          log("Info: "..their_type.."@"..address..": state is "..their_state.." as expected")
        else
          SendState(address, their_type, their_state)
          log("Send: "..their_type.."@"..address..": state is "..their_state)
        end

      elseif payload.instruct == "update" then
        -- This sends the update file to the client.
        ValidUpdateTypes = {"switch","signal","schedule","sensor","client"}
        UpdateFileLocations = {
          switch="/updates/switch.lua",
          signal="/updates/signal.lua",
          schedule="/updates/schedule.lua",
          sensor="/updates/sensor.lua",
          client="/updates/client.lua"
        }

        -- 1. What type did they say they were?
        if contains(ValidUpdateTypes, payload.my_type) then
          -- 2. Send the new file they should install
          local new_file = fs.open(UpdateFileLocations[payload.my_type], "r")
          content = new_file.readAll()
          Modem.transmit(address, GlobChannel, {
            instruct="update",
            data=content,
            version=Version
          })
          new_file.close()
        end
      
      elseif payload.instruct == "routes" then
        -- This returns a list of all routes

        -- 1. Get a list of all files in /routes/ and /routes/autorun
        -- 2. Send a state to the client with a list of all routes
      
      elseif payload.instruct == "active" then
        -- This returns a list of all active routes since the last reset.

        -- 1. Get a list of all routes in the active routes table
        -- 2. Send a state to the client with a list of all active routes
      
      elseif payload.instruct == "route" then
        -- This means a client is executing a route.

        -- 1. Send a pending state to the client
        Modem.transmit(address, GlobChannel, {
          instruct="pending"
        })
        -- 2. Call the ParseRoute on the file if it exists
        local this_route = payload.state
        if fs.exists("routes/"..this_route) then
          ParseRoute("routes/"..this_route)
          Modem.transmit(address, GlobChannel, {
            instruct="success",
            state="ok"
          })
        else
          -- 3. Send a state to the client depending on success
          Modem.transmit(address, GlobChannel, {
            instruct="failure",
            state="not_exist"
          })
        end
        -- 4. Add the route name to the active routes table
        ActiveRoutes[#ActiveRoutes+1] = this_route
     
      elseif payload.instruct == "add_route" then
        -- This means a client is creating a new route with the name.
        route_name = payload.name
        route_data = payload.data
        -- 1. Check the route name does not exist already
        if fs.exists("routes/"..route_name..".csv") then
          Modem.transmit(address, GlobChannel, {
            instruct="failure",
            state="exist"
          })
        else
          -- 2. Save the route file if we can
          local route_file = fs.open("routes/"..route_name..".csv", "w")
          route_file.write(route_data)
          route_file.close()
          -- 3. Send a state to the client depending on success
          Modem.transmit(address, GlobChannel, {
            instruct="success",
            state="ok"
          })
        end
      
      elseif payload.instruct == "reset" then
        -- The client has reset to the default.

        -- 1. Reset all signals and switches to off
        -- 2. Process the route default.csv

      end
    end
  end
end
