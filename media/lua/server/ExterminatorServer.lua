local server_config = {};

local function Exterminator.onServerStart() --TODO server config
    
end

local function Exterminator.onClientCommand(module, command, player, args)
    if module ~= Exterminator.MOD_ID then
        return
    end

    print( ('Exterminator - Received command "%s" from client "%s"'):format(command, player:getUsername()) )

    if command == 'AddClearedMarker' then
        sendServerCommand(module, 'AddClearedMarker', args)
    end
end

if isServer() then
    Events.OnServerStarted.Add(Exterminator.onServerStart)
    Events.OnClientCommand.Add(Exterminator.onClientCommand) --// a client sends to server
end