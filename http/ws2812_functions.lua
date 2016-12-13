function get_power(buffer)
    local led_current_ma = 20
    local p = buffer:power() / 255 * led_current_ma
    return p
end

function print_power(buffer)
    local psu_max_ma = 40000
    local power_ma = get_power(buffer)
    local power_percent = power_ma * 100 / psu_max_ma
    print(
        'power: ', power_ma, ' ma, ',
        (power_ma / 1000), ' A, ',
        power_percent, '%, ',
        power_ma * 5 / 1000, ' W'
    )
end

function random_method()
    local method = math.random(0, 2)
    --method = 1
    return method
end
