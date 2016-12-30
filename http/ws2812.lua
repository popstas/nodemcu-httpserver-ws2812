-- http://axonflux.com/handy-rgb-to-hsl-and-rgb-to-hsv-color-model-c

--[[
 * Converts an RGB color value to HSL. Conversion formula
 * adapted from http://en.wikipedia.org/wiki/HSL_color_space.
 * Assumes r, g, and b are contained in the set [0, 255] and
 * returns h, s, and l in the set [0, 1].
 *
 * @param   Number  r       The red color value
 * @param   Number  g       The green color value
 * @param   Number  b       The blue color value
 * @return  Array           The HSL representation
]]
function rgbToHsl(r, g, b, a)
  r, g, b = r / 255, g / 255, b / 255

  local max, min = math.max(r, g, b), math.min(r, g, b)
  local h, s, l

  l = (max + min) / 2

  if max == min then
    h, s = 0, 0 -- achromatic
  else
    local d = max - min
    if l > 0.5 then s = d / (2 - max - min) else s = d / (max + min) end
    if max == r then
      h = (g - b) / d
      if g < b then h = h + 6 end
    elseif max == g then h = (b - r) / d + 2
    elseif max == b then h = (r - g) / d + 4
    end
    h = h / 6
  end

  return h, s, l, a or 255
end

--[[
 * Converts an HSL color value to RGB. Conversion formula
 * adapted from http://en.wikipedia.org/wiki/HSL_color_space.
 * Assumes h, s, and l are contained in the set [0, 1] and
 * returns r, g, and b in the set [0, 255].
 *
 * @param   Number  h       The hue
 * @param   Number  s       The saturation
 * @param   Number  l       The lightness
 * @return  Array           The RGB representation
]]
function hslToRgb(h, s, l, a)
  local r, g, b

  if s == 0 then
    r, g, b = l, l, l -- achromatic
  else
    function hue2rgb(p, q, t)
      if t < 0   then t = t + 1 end
      if t > 1   then t = t - 1 end
      if t < 1/6 then return p + (q - p) * 6 * t end
      if t < 1/2 then return q end
      if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
      return p
    end

    local q
    if l < 0.5 then q = l * (1 + s) else q = l + s - l * s end
    local p = 2 * l - q

    r = hue2rgb(p, q, h + 1/3)
    g = hue2rgb(p, q, h)
    b = hue2rgb(p, q, h - 1/3)
  end

  return r * 255, g * 255, b * 255, a * 255
end

local function change_color(connection, r, g, b)
    --buffer:fill(r, g, b)
    buffer:fill(g, r, b)
    ws2812.write(buffer)

    -- Send back JSON response.
    connection:send("HTTP/1.0 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: application/json\r\nCache-Control: private, no-store\r\n\r\n")
    connection:send('{"error":0, "message":"OK"}')

end

function reverse_shift()
    --print('stop shifting...')
    local delay_target = 1000
    local interval = delay_ms
    local multiplier = 0.5
    
    -- slows
    tmr.alarm(1, 1000, tmr.ALARM_AUTO, function()
        interval = interval / multiplier
        tmr.interval(0, interval)
        --print('interval', interval)
        if multiplier > 1 and interval <= delay_target
        or multiplier < 1 and interval >= delay_target then
            --print('shifting reversed')
            shift_direction = shift_direction * -1
            tmr.interval(0, delay_ms)
            tmr.unregister(1)
        end
    end)
end

function random_method()
    method = math.random(0, 2)
    --method = 1
    return method
end

local function newyear_on()
    local i = 0
    tmr.alarm(0, 15, tmr.ALARM_AUTO, function()
        buffer:shift(shift_direction, ws2812.SHIFT_CIRCULAR)
        ws2812.write(buffer)
    
        local pos = i % led_count
        
        -- full strip cycle
        if pos == 0 then
            method = random_method()
            print('method: ', method)
            --print_power(buffer)
            ws2812.write(buffer)
            color_random_cycle = math.random(1, 255) / 255
        end
    
        -- fill method
        if method == 0 then
            -- rainbow
            color = i % 255 / 255
        elseif method == 1 then
            -- waterfall
            color = math.random(1, 255) / 255
        else
            -- solid
            color = color_random_cycle
        end
    
        -- add pixel for fill shifted
        buffer:set(1, hslToRgb(color, s, l, 1))
    
        -- dead pixel after each led strip full cycle
        if pos == 0 then
            buffer:set(1, 0, 0, 0)
        end
    
        -- reverse flow effect
        if reverse_chance > 0 and math.random(0, led_count / reverse_chance) == 1 then
            reverse_shift()
        end
    
        -- dead pixel effect
        if dead_picel_chance > 0 and math.random(0, led_count / dead_picel_chance) == 1 then
            local color_pixel
            if method == 1 then
                -- черный пиксель, иначе будет не видно
                color_pixel = {0, 0, 0}
            else
                -- рандомный цвет пикселя (потемнее, чтобы видно было)
                color_pixel = {hslToRgb(math.random(1, 255) / 255 , s , l / 2, 1)}
            end
            buffer:set(1, color_pixel)
            --print('random dead pixel')
        end
        
        i = i + 1
    end)
end

local function newyear_off()
    tmr.unregister(0)
end

return function (connection, req, post)
    if post.action == 'newyear' then
         newyear_on()
    else
        newyear_off()

        print('Color changing to', post.r, post.g, post.b)
        if post.r and post.g and post.b then
            change_color(connection, post.r, post.g, post.b)
        else
            connection:send("HTTP/1.0 200 OK\r\nContent-Type: application/json\r\nCache-Control: private, no-store\r\n\r\n")
            connection:send('{"error":-1, "message":"Bad color"}')
        end
    end
end
