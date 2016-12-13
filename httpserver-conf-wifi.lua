local wifiConfig = {}
wifiConfig.mode = wifi.STATION
wifiConfig.stationPointConfig = {}
wifiConfig.stationPointConfig.hostname = 'ws2812-strip-1' -- Hostname
wifiConfig.stationPointConfig.ssid     = 'wifi-name'      -- Name of the WiFi network you want to join
wifiConfig.stationPointConfig.pwd      = 'wifi-password'  -- Password for the WiFi network
return wifiConfig