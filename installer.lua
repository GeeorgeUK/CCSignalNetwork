--[[
  A table containing all options available for installation.
]]
local options =  {
  {
    name = "Signal",
    url = "https://raw.githubusercontent.com/GeeorgeUK/CCSignalNetwork/main/signal.lua",
  },
  {
    name = "Switch",
    url = ""
  },
  {
    name = "Timetable",
    url = ""
  },
  {
    name = "Sensor",
    url = ""
  },
  {
    name = "Server",
    url = ""
  },
  {
    name = "Cancel",
    url = ""
  }
}

--[[
  A menu allowing the selection of an item.
  Requires a table of entries, where each entry is a table:
  - .name | Represents the display name of the item
  Other fields can be provided as part of the menu, and will be returned
  in the result.
]]
function Select_Menu(items)
  sel = 1
  while true do
    -- Set our initial colours and clear the display
    term.setTextColor(colours.white)
    term.setBackgroundColor(colours.black)
    term.setCursorPos(1,1)
    term.clear()
    -- Iterate through each item in the list, highlighting the selection
    for index, item in ipairs(items) do
      if index == sel then
        term.setBackgroundColor(colours.white)
        term.setTextColor(colours.black)
      else
        term.setBackgroundColor(colours.black)
        term.setTextColor(colours.white)
      end
      term.clearLine()
      print(items[index].name)
    end
    -- Wait for any event, but we only want to update on key presses
    while true do
      local event, v1, v2, v3, v4, v5 = os.pullEvent()
      if event == "key" then
        -- Move the cursor up
        if v1 == keys.up then
          sel = sel - 1
        -- Move the cursor down
        elseif v1 == keys.down then
          sel = sel + 1
        -- Return our current selection
        elseif v1 == keys.enter then
          return items[sel]
        -- Move to the top of the selection
        elseif v1 == keys.pageUp then
          sel = 1
        -- Move to the bottom of the selection
        elseif v1 == keys.pageDown then
          sel = #items
        -- Use number keys to select an index between 1 and 10, or num items
        elseif 1 <= v1 and v1 <= 10 then
          if sel <= #items then
            -- We already have this item selected, so return it
            if sel == v1 then
              return items[sel]
            -- Select this new index without returning it
            else
              sel = v1
            end
          end
        end
        -- This keeps the selection within range
        if sel < 1 then sel = #items end
        if sel > #items then sel = #items end
        -- Break the loop to allow the items list to update
        break
      end
    end
  end
end

-- We grab our update using the power of the internet!
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

local result = Select_Menu(options)
if result.name == "Cancel" then
  os.pullEvent("disk_eject")
  os.reboot()
end
local data = FetchUpdate(result.url)
SaveWithBackup(data, "startup")
os.pullEvent("disk_eject", "peripheral_detach")
os.reboot()
