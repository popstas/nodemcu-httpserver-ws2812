local function change_color(connection, r, g, b)
    --buffer:fill(r, g, b)
    buffer:fill(g, r, b)
    ws2812.write(buffer)

    -- Send back JSON response.
    connection:send("HTTP/1.0 200 OK\r\nAccess-Control-Allow-Origin: *\r\nContent-Type: application/json\r\nCache-Control: private, no-store\r\n\r\n")
    connection:send('{"error":0, "message":"OK"}')

end

return function (connection, req, post)
    print('post:', post)
    print('Color changing to', post.r, post.g, post.b)
    if post.r and post.g and post.b then
        change_color(connection, post.r, post.g, post.b)
    else
        connection:send("HTTP/1.0 400 OK\r\nContent-Type: application/json\r\nCache-Control: private, no-store\r\n\r\n")
        connection:send('{"error":-1, "message":"Bad color"}')
    end
end
