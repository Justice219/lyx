lyx = lyx

--[[
.____                     __      __      ___.    
|    |    ___.__.___  ___/  \    /  \ ____\_ |__  
|    |   <   |  |\  \/  /\   \/\/   // __ \| __ \ 
|    |___ \___  | >    <  \        /\  ___/| \_\ \
|_______ \/ ____|/__/\_ \  \__/\  /  \___  >___  /
        \/\/           \/       \/       \/    \/ 

Provides simple functions for sending and requesting
web requests, aswell as functions for things like discord
or retrieving certain bits of data from the internet.

]]--

function lyx:WebPost(url, data)
    -- Lets post some data to a url
    http.Post(url, data.params,
        function(body, len, headers, code)
            data.callback(body, len, headers, code)
            lyx:Log("Web Post: " .. url .. " - " .. code)
        end,
        function(err)
            data.errback(err)
            lyx:Log("Web Post Error: " .. err)
        end,
        data.headers or {}
    )
end

function lyx:WebGet(url, data)
    http.Fetch(url,
        function(body, len, headers, code)
            data.callback(body, len, headers, code)
            lyx:Log("Web Get: " .. url .. " - " .. code)
        end,
        function(err)
            data.errback(err)
            lyx:Log("Web Get Error: " .. err)
        end,
        data.headers or {}
    )
end

function lyx:DiscordWebhook(webhook, data)
    local t_post = {
        content = data.text,
        username = data.username,
        avatar_url = data.avatar_url,
    }
    local t_struct = {
        failed = function(err)
            lyx:Log("Discord Webhook Error: " .. err)
        end,
        method = "post",
        url = webhook,
        parameters = t_post,
        type = "application/json; charset=utf-8",
    }

    HTTP(t_struct)
    lyx:Log("Discord Webhook: " .. webhook)
end

--[[ Example on using the web functions
-------------------------------------------------------------------------
lyx:WebPost("https://google.com", {
    params = {
        q = "lyx"
    },
    callback = function(body, len, headers, code)
        print(body)
    end,
    errback = function(err)
        print(err)
    end,
})
lyx:WebGet("https://google.com", {
    callback = function(body, len, headers, code)
        print(body)
    end,
    errback = function(err)
        print(err)
    end,
})
lyx:DiscordWebhook("https://discord.com/api/webhooks/1003451834205208657/Axh1hzYqfKMzob7_ivzuGNr10L3B2hFTve-1otsp_0DO5hBhfOWDm0X3Tahn3iNHnlrN", {
    username = "LyxLibrary",
    content = "Hello World!",
    avatar_url = "https://i.imgur.com/XyqQZ.png"
})
-------------------------------------------------------------------------]]