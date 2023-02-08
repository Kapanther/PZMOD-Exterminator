local server_config = {};
local syncTimer = -1
local syncInterval = 2000

--TODO server config
local function onServerStart() 
    
end

local function onClientCommand(module, command, player, args)
    --TODO this is hard  coded right now consider linking the mod ID to to it
    if module ~= "Exterminator" then
        return
    end

    print( ('Exterminator - Received command "%s" from client "%s"'):format(command, player:getUsername()) )

    if command == 'sendMarkerUpdates' then
        sendServerCommand(module, 'sendMarkerUpdates', args)
    end

    if command == 'requestMarkerSync' then
        sendServerCommand(module, 'requestMarkerSync', args)
    end

    if command == 'sendMarkerSync' then
        sendServerCommand(module, 'sendMarkerSync', args)
    end
end

if isServer() then
    Events.OnServerStarted.Add(onServerStart)
    Events.OnClientCommand.Add(onClientCommand) --// a client sends to server
end