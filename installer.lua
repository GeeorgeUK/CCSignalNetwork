local prefix = "https://raw.githubusercontent.com/GeeorgeUK/CCSignalNetwork/main/"
local items = {
    {
        "startup.lua",
        "server.lua"
    },
    {
        "routes/default.csv",
        "default.csv"
    },
    {
        "updates/switch.lua",
        "switch.lua",
    },
    {
        "updates/signal.lua",
        "signal.lua",
    },
    {
        "updates/sensor.lua",
        "sensor.lua",
    },
    {
        "updates/schedule.lua",
        "schedule.lua",
    },
    {
        "updates/client.lua",
        "client.lua",
    }
}

if not fs.isDir("updates") then
    fs.makeDir("updates")
end
if not fs.isDir("routes") then
    fs.makeDir("routes")
end

for index, item in ipairs(items) do
    if fs.exists(item[1]) then
        fs.delete(item[1])
    end
    local site = http.get(prefix..item[2])
    local file = fs.open(item[1], "w")
    file.write(site.readAll())
    file.close()
    sleep(0.05)
end
print("Complete. Press any key to exit")
os.pullEvent("char")