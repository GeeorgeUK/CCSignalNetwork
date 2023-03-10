--[[
  A table containing all options available for installation.
]]
local options = {
  signal = {
    name = "Signal Controller",
    url = "",
  },
  timetable = {
    name = "Timetable Controller",
    url = ""
  },
  switch = {
    name = "Switch Controller",
    url = ""
  },
  sensor = {
    name = "Sensor Monitor",
    url = ""
  },
  server = {
    name = "Server",
    url = ""
  },
  cancel = {
    name = "Cancel Installation",
    url = ""
  }
}

function Select_Menu(items)
  local sel = 1
  while true do
    term.setTextColor(colours.white)
    term.setBackgroundColor(colours.black)
    term.clear()
    local xTop, yTop = term.getCursorPos()
    local xMax, yMax = term.getSize()
    for index, item in ipairs(items) do
      if index == sel then
        term.setBackgroundColor(colours.white)
        term.setTextColor(colours.black)
      else
        term.setBackgroundColor(colours.black)
        term.setTextColor(colours.white)
      end
      print(items[index].name)
    end
    local event, v1, v2, v3, v4, v5 = os.pullEvent()
    if event == "key" then
      if v1 == keys.up then
        sel = sel - 1
      elseif v1 == keys.down then
        sel = sel + 1
      elseif v1 == keys.enter then
        return items[sel]
      elseif v1 == keys.pageUp then
        sel = 1
      elseif v1 == keys.pageDown then
        sel = #items
      elseif 1 < v1 < #items then
        return items[v1]
      end
    end
  end
end

function FetchUpdate(url)
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
  local file_handler = fs.open(filename)
  file_handler.write(data)
  file_handler.close()
end

local result = Select_Menu(options)
local data = FetchUpdate(result.url)
SaveWithBackup(data, "startup")
disk.eject()
os.reboot()
