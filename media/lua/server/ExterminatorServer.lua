local server_config = {};

local function onServerStart() --TODO server config
    
end

local function onClientCommand(module, command, player, args)
    if module ~= "Exterminator" then --TODO this is hard  coded right now consider linking the mod ID to to it
        return
    end

    print( ('Exterminator - Received command "%s" from client "%s"'):format(command, player:getUsername()) )

    if command == 'AddClearedMarker' then
        sendServerCommand(module, 'AddClearedMarker', args)
    end
end

if isServer() then
    Events.OnServerStarted.Add(onServerStart)
    Events.OnClientCommand.Add(onClientCommand) --// a client sends to server
end