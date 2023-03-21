-- The Global Channel 
GlobChannel = 8190

-- MyChannel is the unique channel of this Client
MyChannel = os.getComputerID() + 8192

-- The global modem handler
Modem = peripheral.find("modem")
Modem.open(MyChannel)

-- The global version identifier. If it does not match the server, we update
Version = {1,0,22,3}

-- A local log of messages
Log = {}

-- A local input cursor and table
Cursor = 1
Input = {}


local function log(message)

  --[[
    Add a message to the log table.
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

  -- set the cursor position to the top corner.
  local xSize, ySize = here.getSize()
  here.setCursorPos(1,1)
  here.clear()

  -- If we have a big logfile, we set an offset.
  local offset = #Log - ySize

  -- Iterate over each log file.
  for index, item in ipairs(Log) do

    -- Shorten long log entries for display.
    if #item > xSize then
      item = string.sub(item, 1, xSize-4)
      item = item.."..."
    end

    -- Set our index location for log entry writing
    here.setCursorPos(1, index)

    -- Write
    if #Log <= ySize then
      here.write(item)
    else
      here.write(Log[offset+index])
    end

  end
end


local function show_input(here)
  -- Get the size of this window
  local xSize, ySize = here.getSize()
  here.setCursorPos(1,1)
  here.clearLine()

  -- Write the input to this window.
  here.write(table.concat(Input, ""))
  here.setCursorPos(Cursor,1)
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


local function split(unprocessed, separator)

  -- Store the result here
  local result = {}

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

Callbacks = {}
Commands = {
  "help", "route", "platforms", "zones", "zone",
  "reset", "routes", "update", "active", "clear", 
  "set", "get", "directions", "panic", "override",
  "add"
}
table.sort(Commands)
Command = {}

Command.help = {}
Command.help.usage = "help [topic?]"
Command.help.desc = "Show commands."
Command.help.help = "Use this command to learn how to use commands."
function Command.help.run(args)
  --[[
    Function for the /help command.
    This displays a list of available commands.
  ]]
  if #args == 0 or args == nil then
    log("There are #"..#Commands.." commands:")
    for index, command in ipairs(Commands) do
      log(Command[command].usage..": "..Command[command].desc)
    end
  else
    if contains(Commands, args[1]) then
      log("Showing help for "..args[1]..":")
      log("Usage: "..Command[args[1]].usage)
      log(Command[args[1]].help)
    else
      log("Unknown command: '"..args[1].."'")
    end
  end
end

Command.zone = {}
Command.zone.usage = "zone <zone> [?direction] <platform>"
Command.zone.desc = "Set the path of a zone"
Command.zone.help = "Configures a zone to have a specific configuration."
function Command.zone.run(args)
  --[[
    Function for the /zone command.
    This executes a routefile on the server, contained in the zones folder.
  ]]
  if #args == 2 or #args == 3 then
    -- Don't check this zone for a direction
    Modem.transmit(GlobChannel, MyChannel, {
      instruct="zone",
      state=table.concat(args, "/")..".csv",
      my_type="client"
    })
  else
    log("Usage: "..Command.zone.usage..": "..Command.zone.desc)
  end
end

Command.zones = {}
Command.zones.usage = "zones"
Command.zones.desc = "Get a list of zones"
Command.zones.help = "Returns a list of every available zone space"
function Command.zones.run(args)
  Modem.transmit(GlobChannel, MyChannel, {
    instruct="zones",
    my_type="client"
  })
end

Command.directions = {}
Command.directions.usage = "directions <zone>"
Command.directions.desc = "Get a zone's directions"
Command.directions.help = "Returns a list of directions available in a zone"
function Command.directions.run(args)
  --[[
    Function for the /directions command.
    This retrieves a list of available directions for a particular zone.
  ]]
  if #args == 1 then
    Modem.transmit(GlobChannel, MyChannel, {
      instruct="directions",
      state=args[1],
      my_type="client"
    })
  else
    log("Usage: "..Command.directions.usage)
  end
end

Command.platforms = {}
Command.platforms.usage = "platforms <zone>"
Command.platforms.desc = "Get a list of platforms in a zone"
Command.platforms.help = "Returns a list of platforms available in a zone"
function Command.platforms.run(args)
  --[[
    Function for the /platforms command.
    This retrieves a list of available platforms for a particular zone.
  ]]

  if #args == 1 then
    Modem.transmit(GlobChannel, MyChannel, {
      instruct="platforms",
      state=args[1],
      my_type="client"
    })
  else
    log("Usage: "..Command.platforms.usage)
  end
end

Command.route = {}
Command.route.usage = "route <routeName>"
Command.route.desc = "Execute a route."
Command.route.help = "Tells the server we need to run a route, if it exists."
function Command.route.run(args)
  --[[
    Function for the /route command.
    This executes a routefile on the server, contained in the routes folder.
  ]]
  if #args == 0 then
    log("Usage: "..Command.route.usage)
  else
    Modem.transmit(GlobChannel, MyChannel, {
      instruct="route",
      state=args[1],
      my_type="client"
    })
    log("Requested route '"..args[1].."'")
  end
end

Command.add = {}
Command.add.usage = "add <type> <name>"
Command.add.desc = "Download a route or zone."
Command.add.help = "Downloads a route or zone from github, and sends it to the server."
function Command.add.run(args)
  --[[
    Function for the /addroute command.
    This creates a route file, then sends it to the server.
  ]]

  -- Check for a valid number of arguments
  if #args ~= 2 then
    log("Usage: "..Command.addroute.usage)
    log("Valid typs: 'route', 'zone'")
  else

    if args[1] == "route" then
      -- Downloading a route is simple, provided it exists
      log("Attempting download of route")
      local prefix = "https://raw.githubusercontent.com/GeeorgeUK/CCSignalNetwork/main/routes/"
      local site = http.get(prefix..args[2])

      if site then
        -- Send the route data to the server
        Modem.transmit(GlobChannel, MyChannel, {
          instruct="addroute",
          my_type="client",
          state=args[2],
          data=site.readAll()
        })
      else
        log("Failed to download route")
      end

    elseif args[1] == "zone" then
      -- Downloading a zone is less simple, so we have a zone register to help us!
      log("Attempting download of zone")
      local prefix = "https://raw.githubusercontent.com/GeeorgeUK/CCSignalNetwork/main/zones/"
      
      -- Grab the zone file, and require it so we get our ZoneRegistry table
      local site = http.get("https://raw.githubusercontent.com/GeeorgeUK/CCSignalNetwork/main/zoneregistry.lua")
      local downloadable_zones = site.readAll()
      local zone_name = args[2]
      local tmp_file = fs.open(".temp_zones", "w")
      tmp_file.write(downloadable_zones)
      tmp_file.close()
      require(".temp_zones")
      if not ZoneRegistry then
        return log("Registry failed to initialise")
      end

      -- Check if it exists in the table
      if ZoneRegistry[zone_name] == nil then
        return log("No zone data exists for "..zone_name)
      end

      -- Check if the entry is enabled in the table
      if not ZoneRegistry[zone_name].enabled then
        return log("The zone "..zone_name.." is disabled")
      end

      local this_zone_data = ZoneRegistry[zone_name]
      local presend_data = {}

      -- Iterate through each platform and download the file
      for _, platform in ipairs(this_zone_data.platforms) do

        if #this_zone_data.directions > 0 then

          for _, direction in ipairs(this_zone_data.directions) do
            local this_site = http.get(prefix.."/"..zone_name.."/"..direction.."/"..platform)
            table.insert(presend_data, {
              data=this_site.readAll(),
              platform=platform,
              direction=direction
            })
          end

        else
          local this_site = http.get(prefix.."/"..zone_name.."/"..platform)
          table.insert(presend_data, {
            data=this_site.readAll(),
            direction=direction
          })
        end
      end

      Modem.transmit(GlobChannel, MyChannel, {
        instruct="add_zone",
        my_type="client",
        name=zone_name
      })

      if fs.exists(".temp_zones") then fs.delete(".temp_zones") end
    else
      log("Valid first args: 'route', 'zone'")
    end
  end
end

Command.reset = {}
Command.reset.usage = "reset"
Command.reset.desc = "Reset all routes."
Command.reset.help = "Sets all machines to the default value, then runs default.csv"
function Command.reset.run(args)
  --[[
    Function for the /reset command.
    Resets routes to their default.
  ]]
  Modem.transmit(GlobChannel, MyChannel, {
    instruct="reset",
    my_type="client"
  })
  log("Sending reset request")
end

Command.override = {}
Command.override.usage = "override"
Command.override.desc = "Allow proceeding with caution"
Command.override.help = "Sets all signal machines to yellow, which allows trains to proceed if safe."
function Command.override.run(args)
  --[[
    Function for the /override command.
    Sets all signals to yellow.
  ]]
  Modem.transmit(GlobChannel, MyChannel, {
    instruct="override",
    my_type="client"
  })
end

Command.active = {}
Command.active.usage = "active"
Command.active.desc = "List active routes."
Command.active.help = "Gets a list of all activated routes since the last reset"
function Command.active.run(args)
  --[[
    Function for the /active command.
    Grabs a list of activated routes since the last reset.
  ]]
  Modem.transmit(GlobChannel, MyChannel, {
    instruct="active",
    my_type="client"
  })
  log("Requesting active routes")
end

Command.routes = {}
Command.routes.usage = "routes"
Command.routes.desc = "List all routes."
Command.routes.help = "Gets a list of all available routes to the server"
function Command.routes.run(args)
  --[[
    Function for the /routes command.
    Grabs a list of all routes available to the server.
  ]]
  Modem.transmit(GlobChannel, MyChannel, {
    instruct="routes",
    my_type="client"
  })
  log("Requesting all routes")
end

Command.update = {}
Command.update.usage = "update"
Command.update.desc = "Updates the client."
Command.update.help = "Updates your client to the latest version"
function Command.update.run(args)
  --[[
    Function for the /update command.
    Grabs the client update file from the server and updates.
  ]]
  Modem.transmit(GlobChannel, MyChannel, {
    instruct="update",
    my_type="client"
  })
  log("Requesting client update")
end

Command.clear = {}
Command.clear.usage = "clear"
Command.clear.desc = "Clear all logs."
Command.clear.help = "Clears all the logs to make it easier to read the screen"
function Command.clear.run(args)
  --[[
    Function for the /clear command.
    Creates a new log global variable.
  ]]
  while #Log > 0 do
    table.remove(Log, 1)
  end
end

Command.get = {}
Command.get.usage = "get <address>"
Command.get.desc = "Get machine details"
Command.get.help = "Get detailed information about the machine at this address"
function Command.get.run(args)
  --[[
    Function for the /get command.
    Grabs information about a specific machine.
  ]]
  if #args ~= 1 then
    log("Usage: "..Command.get.usage)
  else
    log("Fetching machine details")
    Modem.transmit(GlobChannel, MyChannel, {
      instruct="get",
      my_type="client",
      address=tonumber(args[1])
    })
  end
end

Command.set = {}
Command.set.usage = "set <address> <state>"
Command.set.desc = "Override a machine"
Command.set.help = "Change what a machine is meant to be doing"
function Command.set.run(args)
  --[[
    Function for the /set command.
    Changes the state of a particular machine.
  ]]
  if #args ~= 2 then
    log("Usage: "..Command.get.usage)
  else
    log("Sending state change request")
    Modem.transmit(GlobChannel, MyChannel, {
      instruct="set",
      my_type="client",
      address=tonumber(args[1]),
      state=args[2]
    })
  end
end

Command.panic = {}
Command.panic.usage = "panic"
Command.panic.desc = "Turns all signals to red"
Command.panic.help = "Turns all signals to red when they become available."
function Command.panic.run(args)
  --[[
    Function for the /panic command.
    Turns all signals to red to encourage players to stop their trains.
  ]]
  Modem.transmit(GlobChannel, MyChannel, {
    instruct="panic",
    my_type="client"
  })
end


log("Started Skyline "..table.concat(Version, ".").." client on channel "..MyChannel)
while true do
  -- Update the log display and the input display
  show_log(LogDisplay)
  show_input(InputDisplay)
  InputDisplay.setCursorBlink(true)

  -- Wait to continue
  local event = {os.pullEvent()}
  if event[1] == "modem_message" then

    -- This means it's a response
    local payload = event[5]

    -- If it's a callback, then we check for that here. Callbacks contain a callback field.
    if payload.callback ~= nil then
      
      local this_check = {
        "route", "add_route"
      }
      local other_check = {
        "get", "set"
      }
      local final_check = {
        "success", "failed"
      }

      if contains(this_check, payload.callback) then
        log("Reply: "..payload.callback.." '"..payload.state.."' : "..payload.instruct)
      elseif contains(other_check, payload.callback) then
        if payload.state == "failed" then
          log("Failed: Machine was not found in the database.")
        else
          log(payload.data[3].."@"..payload.data[2])
          log("state = "..payload.data[4])
        end
      elseif contains(final_check, payload.instruct) then
        log(payload.callback..": "..payload.instruct)
      end
    
    end

    local this_check = {
      "all_routes", "active_routes", "all_zones", 
      "all_platforms", "all_directions" 
    }

    if contains(this_check, payload.instruct) then
      log("Result ("..#payload.data.."):")
      local index = 1
      if not pocket then
        while true do
          if payload.data[index+2] == nil then
            if payload.data[index+1] == nil then
              if payload.data[index] == nil then
                break
              end
              log("  '"..payload.data[index].."'")
              break
            end
            log("  '"..payload.data[index].."';  '"..payload.data[index+1].."'")
            break
          end
          log("  '"..payload.data[index].."';  '"..payload.data[index+1].."';  '"..payload.data[index+2].."'")
          index = index + 3
        end
      else
        for index, item in ipairs(payload.data) do
          log("  '"..item.."'")
        end
      end
    end

    if payload.instruct == "update" then
      -- Update our client
      if payload.your_type == "client" then
        SaveWithBackup(payload.data, "startup.lua")
        os.reboot()
      end
    end

  elseif event[1] == "char" then

    table.insert(Input, Cursor, event[2])
    Cursor = Cursor + 1

  elseif event[1] == "key" then
      
    if event[2] == keys.enter and #Input >= 1 then
      -- 1. Build a string of the input.
      local this_input = table.concat(Input)

      -- 2. Split the input string into each word; Word 1 is the command.
      local this_input = split(this_input, " ")
      local this_command = this_input[1]

      -- All other words are the arguments, which are passed to the function.
      local this_arguments = {}
      if #this_input > 1 then
        table.remove(this_input, 1)
        this_arguments = this_input
      end

      -- 3. Search in Commands for the command.
      if contains(Commands, this_command) then

        -- 4. Execute the function in the Command.<command> table, using the remaining arguments as parameters.
        Command[this_command].run(this_arguments)

      else
        -- Log if the command does not exist.
        log("Invalid command '"..this_input[1].."'.")
      end

      -- 5. Reset both the Input and the Cursor global variables.
      Input = {}
      Cursor = 1

    elseif event[2] == keys.left then

      -- Move the cursor left by 1 if we can.
      Cursor = Cursor - 1

    elseif event[2] == keys.right then

      -- Move the cursor right by 1 if we can.
      Cursor = Cursor + 1
    
    elseif event[2] == keys.backspace then

      -- Clear the character in the input table before the cursor.
      if Cursor > 1 then
        table.remove(Input, Cursor-1)
      end
    
    elseif event[2] == keys.delete then

      -- Clear the character in the input table after the cursor.
      if Cursor <= #Input then
        table.remove(Input, Cursor)
      end
    
    end

    -- Fix the position of the cursor if we are out of range.
    if Cursor <= 1 then Cursor = 1 end
    if Cursor >= #Input+1 then Cursor = #Input+1 end

  end
end