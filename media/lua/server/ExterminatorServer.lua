--local mysql = require "luasql.mysql"

local server_config = {};
--local env  = mysql:mysql()
--local conn = env:connect("C:\Users\bkant\Zomboid\mods\Exterminator\media\db\DefaultGridDatabase.db",'main','Grid')
--print(env,conn)


local function onServerStart() --TODO server config
    
end

local function onClientCommand(module, command, player, args)
    if module ~= "Exterminator" then --TODO this is hard  coded right now consider linking the mod ID to to it
        return
    end

    print( ('Exterminator - Received command "%s" from client "%s"'):format(command, player:getUsername()) )

    if command == 'sendMarkerUpdates' then
        sendServerCommand(module, 'recieveMarkerUpdates', args)
    end
end

if isServer() then
    Events.OnServerStarted.Add(onServerStart)
    Events.OnClientCommand.Add(onClientCommand) --// a client sends to server
end