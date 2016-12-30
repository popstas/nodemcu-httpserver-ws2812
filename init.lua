led_count         = 300 -- count of
delay_ms          = 15  -- one frame delay, do not set bellow 15 ms
brightness        = 0.6 -- brightness of strip, 0 to 1, at 1 will be absolutely white
saturation        = 1   -- 0 to 1, more for more contrast
lightness         = 100 -- smaller darker and more color difference
reverse_chance    = 0.1 -- chance of reverse (0 to 1)
dead_picel_chance = 5   -- chance of dead pixel (0 to 10)

shift_direction = 1

local initStrip = function()
    ws2812.init()
    -- used in http/ws2812.lua
    buffer = ws2812.newBuffer(300, 3)

    h, s, l = math.random(), saturation, brightness

    buffer:fill(0, 0, 0)
    ws2812.write(buffer)
end

local wifiInit = function()
    local wifiConfig = dofile('httpserver-conf-wifi.lc')
    wifi.sta.sethostname(wifiConfig.stationPointConfig.hostname)
    wifi.setmode(wifiConfig.mode)
    wifi.sta.config(wifiConfig.stationPointConfig.ssid, wifiConfig.stationPointConfig.pwd, 1)
end

local function saveIp(ip)
    file.open('http/ip.js', 'w')
    local w = file.writeline
    w('window.ws2812_ip = "'..ip..'";')
    file.close()
end

local compileAndRemoveIfNeeded = function(f)
   if file.open(f) then
      file.close()
      print('Compiling:', f)
      node.compile(f)
      file.remove(f)
      collectgarbage()
   end
end

local serverFiles = {
   'httpserver.lua',
   'httpserver-b64decode.lua',
   'httpserver-basicauth.lua',
   'httpserver-conf.lua',
   'httpserver-conf-wifi.lua',
   'httpserver-connection.lua',
   'httpserver-error.lua',
   'httpserver-header.lua',
   'httpserver-request.lua',
   'httpserver-static.lua',
}
for i, f in ipairs(serverFiles) do compileAndRemoveIfNeeded(f) end


--


print('chip: ',node.chipid())
print('heap: ',node.heap())
print('Client MAC: ',wifi.sta.getmac())

compileAndRemoveIfNeeded = nil
serverFiles = nil
collectgarbage()

initStrip()
initStrip = nil

wifiInit()
wifiInit = nil

collectgarbage()


-- Connect to the WiFi access point and start the HTTP server
local joinCounter = 0
local joinMaxAttempts = 5
tmr.alarm(0, 3000, 1, function()
   local ip = wifi.sta.getip()
   if ip == nil and joinCounter < joinMaxAttempts then
      print('Connecting to WiFi Access Point ...')
      joinCounter = joinCounter +1
   else
      if joinCounter == joinMaxAttempts then
         print('Failed to connect to WiFi Access Point.')
      else
         print('IP: ',ip)
         saveIp(ip)
         dofile("httpserver.lc")(80)
      end
      tmr.stop(0)
      joinCounter = nil
      joinMaxAttempts = nil
      collectgarbage()
   end
end)

