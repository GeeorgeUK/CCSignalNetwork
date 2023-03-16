-- The channel of this server
GlobChannel = 8190
-- A global modem handler.
Modem = peripheral.find("modem")
Modem.open(GlobChannel)
-- The current network version.
Version = {1,0,13}
-- A log of messages.
Log = {}
-- All data about the network.
Network = {}
-- Our route history
ActiveRoutes = {}


local function log(message)
  --[[ 
    Add a message to the log database.
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
  
  -- If we have a big logfile, we set our offset.
  offset = #Log - ySize

  -- Iterate over each log file.
  for index, item in ipairs(Log) do

    -- Shorten long log entries for display.
    if #item > xSize then
      item = string.sub(item, 1, xSize-4)
      item = item.."..."
    end

    -- Set our index location for log entry writing.
    here.setCursorPos(1, index)

    -- Remove any existing characters from this line, then write.
    here.clearLine()

    -- Finally, write the entries we need to write.
    if #Log <= ySize then
      here.write(item)
    else
      here.write(Log[offset+index])
    end
  end
end


local function split(unprocessed, separator)

  -- Store the result here
  local result = {}

  -- Make sure we have a separator
  separator = separator or " "

  -- Add the separator to the end of the file
  unprocessed = unprocessed..separator

  -- Match each instance in the string with a separator at the end, removing the separator
  for item in string.gmatch(unprocessed, "(.-)"..separator) do

    -- Add each result to the table
    table.insert(result, item)
  end

  -- Finally, return the result
  return result
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
    next_line = handler.readLine()
  end

  -- Close the handler as we are done with it.
  handler.close()

  -- Return our headers table, and our entries table.
  return headers, entries
end


local function save_csv(headers, entries, file)
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
  for index, entry in ipairs(entries) do
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
  if fs.exists("routes/"..file) then
    RouteHistory[#RouteHistory+1] = file
    local csv_data = {load_csv(file)}
    for index, item in ipairs(csv_data.entries) do
      SaveState(item[2], item[3], item[4])
    end
  end
end


-- Create the network database if it does not exist.
if not fs.exists("database.csv") then
  local db_handler = fs.open("database.csv", "w")
  db_handler.write("index,address,type,state")
  db_handler.close()
end

if not fs.isDir("routes") then
  fs.makeDir("routes")
  if not fs.exists("routes/default.csv") then
    local routes_file = fs.open("routes/default.csv", "w")
    routes_file.writeLine("index,address,type,state")
    routes_file.close()
  end
end

if not fs.isDir("updates") then
  fs.makeDir("updates")
end


-- Create the network table from the database file.
Network = {}
Network.headers, Network.entries = load_csv("database.csv")


function add_device(address, this_type, state)
  --[[
    Adds the device to the database
  ]]
  table.insert(Network.entries, {
    #Network.entries+1, address, this_type, state
  })
  return {#Network.entries, address, this_type, state}
end


function get_device(address)
  --[[
    Searches through the Network entries for the address.
  ]]
  for index, item in ipairs(Network.entries) do
    if item[2] == address then
      return item
    end
  end
  return nil
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
    Will also send the state to the device in question.
  ]]
  for index, item in ipairs(Network.entries) do
    if item[3] == of_type then
      Network.entries[index][4] = new_state
      SendState(item[2], of_type, new_state)
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
  Modem.transmit(tonumber(address), GlobChannel, {
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
term.clear()
term.setCursorPos(1,1)
log("Started Skyline "..table.concat(Version, ".").." server on port "..GlobChannel)
Monitor = peripheral.find("monitor")
if Monitor ~= nil then
  Monitor.clear()
  Monitor.setCursorPos(1,1)
  Monitor.setTextScale(0.5)
end


while true do
  -- First, show the updated log on the monitor.
  if Monitor ~= nil then
    show_log(Monitor)
  end

  -- Then, show the log on the computer itself.
  show_log(term.native())

  -- Wait here until we receive a modem message event
  local e = {os.pullEvent()}
  if e[1] == "key" then
    if e[2] == keys.space then
      -- Reinstalls.
      shell.run("installer.lua")
    end
  elseif e[1] == "modem_message" then
    -- Make sure the message is valid
    if type(e[5]) == "table" then

      -- Grab the payload and the address from the message data
      local payload = e[5]
      local address = e[4]

      if payload.instruct == "ping" then
        -- This means a device is available, we should send their state.

        -- 1. Get the device details by its address
        local item = get_device(address)
        if item == nil then
          item = add_device(address, payload.my_type, payload.state)
        end
        local their_type = item[3]
        local their_state = item[4]

        -- 2. To save on bandwidth, only send the change if it's different
        -- (We should send if the version is different to trigger an update)
        if payload.state == their_state and (
          payload.version[3] == Version[3]
          and payload.version[2] == Version[2]
          and payload.version[1] == Version[1]
        ) then
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
        log("A "..payload.my_type.."@"..address.." requested an update")

        -- 1. What type did they say they were?
        if contains(ValidUpdateTypes, payload.my_type) then
          -- 2. Send the new file they should install
          local new_file = fs.open(UpdateFileLocations[payload.my_type], "r")
          content = new_file.readAll()
          Modem.transmit(address, GlobChannel, {
            instruct="update",
            your_type=payload.my_type,
            data=content
          })
          new_file.close()
          log("Sent update file to "..payload.my_type)
        end
      
      elseif payload.instruct == "routes" then
        -- This returns a list of all routes

        log("A "..payload.my_type.."@"..address.." requested all routes")

        -- 1. Get a list of all files in /routes/ and /routes/autorun
        local files = fs.list("routes")
        
        -- 2. Send a state to the client with a list of all routes
        Modem.transmit(address, GlobChannel, {
          instruct="all_routes",
          data = files
        })
      
      elseif payload.instruct == "active" then
        -- This returns a list of all active routes since the last reset.

        log("A "..payload.my_type.."@"..address.." requested active routes")

        -- 1. Send our ActiveRoutes table
        Modem.transmit(address, GlobChannel, {
          instruct="active_routes",
          data = RouteHistory
        })
      
      elseif payload.instruct == "route" then
        -- This means a client is executing a route.

        log("A "..payload.my_type.."@"..address.." is executing a route")

        -- 1. Send a pending state to the client
        Modem.transmit(address, GlobChannel, {
          instruct="pending"
        })
        -- 2. Call the ParseRoute on the file if it exists
        local this_route = payload.state
        if this_route ~= nil then
          if fs.exists("routes/"..this_route) then
            ParseRoute("routes/"..this_route)
            Modem.transmit(address, GlobChannel, {
              instruct="success",
              callback="route",
              state=this_route
            })
            log("Success, the route has been executed")
          else
            -- 3. Send a state to the client depending on success
            Modem.transmit(address, GlobChannel, {
              instruct="failed",
              callback="route",
              state=this_route
            })
            log("Failed, as the route does not exist")
          end
        else
          log("Failed, as the route was corrupted or missing")
        end
        -- 4. Add the route name to the active routes table
        ActiveRoutes[#ActiveRoutes+1] = this_route
     
      elseif payload.instruct == "add_route" then

        log("A "..payload.my_type.."@"..address.." is adding a new route")

        -- This means a client is creating a new route with the name.
        route_name = payload.name
        route_data = payload.data
        -- 1. Check the route name does not exist already
        if fs.exists("routes/"..route_name..".csv") then
          Modem.transmit(address, GlobChannel, {
            instruct="failed",
            callback="add_route",
            state=route_name
          })
          log("Failed, the route already exists.")
        else
          -- 2. Save the route file if we can
          local route_file = fs.open("routes/"..route_name..".csv", "w")
          route_file.write(route_data)
          route_file.close()
          -- 3. Send a state to the client depending on success
          Modem.transmit(address, GlobChannel, {
            instruct="success",
            callback="add_route",
            state=route_name
          })
          log("Success, the route has been added")
        end
      
      elseif payload.instruct == "reset" then
        -- The client has reset to the default.

        log("A "..payload.my_type.."@"..address.." requested a reset")

        -- 1. Set all signals to red
        set_all_states("signal", 1)
        -- 2. Set all switches to off
        set_all_states("switch", 0)
        -- 3. Save the Network data to file
        save_csv(Network.headers, Network.entries, "database.csv")
        -- 4. Reset the RouteHistory table
        RouteHistory = {}
        -- 5. Process the route default.csv
        ParseRoute("routes/default.csv")
        Modem.transmit(address, GlobChannel, {
          instruct="success",
          callback="reset"
        })

        log("Reset is complete")

      end
    end
  end
end
