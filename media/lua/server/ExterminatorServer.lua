local server_config = {};
local syncTimer = -1
local syncInterval = 2000
local playerSyncRequests = 0
local playerSyncRequestsRecieved = 0
local markerTables = {}
local currentPlayer
local currentMarkers = {}

--TODO server config
local function onServerStart() 
    
end

local function onClientCommand(module, command, player, args)
    --TODO this is hard  coded right now consider linking the mod ID to to it
    if module ~= "Exterminator" then
        return
    end

    if command == 'sendMarkerUpdates' then
        sendServerCommand(module, 'sendMarkerUpdates', args)
    end

    if command == 'requestMarkerSync' then
        --pause all the clients while the marker sync happens
        PauseAllClients()
        --TODO consider sending a message to let players know the game is sycing markers 

        -- request the player markers
        local playerList = getPlayers()
        local playerCount = getPlayers():size()

        if playerCount > 1 then        
            sendServerCommand(module, 'requestMarkerSync', args)
            playerSyncRequests = playerCount
        else
            restartGame()
        end
    end

    if command == 'sendMarkerSync' then        
        playerSyncRequestsRecieved = playerSyncRequestsRecieved + 1

        -- add the data to memory on the server
        local playername =  args[1]
        markerTables[playerSyncRequestsRecieved] = {playername,args[2]}

        if playerSyncRequestsRecieved == playerSyncRequests then
            doMarkerSyncChecks()            
        end
    end
end

function doMarkerSyncChecks()
    for i,v in pairs(markerTables) do
        local differenceGrid = {}
        if currentMarkers == {} then
            -- add the first markers to base grid to compare
            currentPlayer = v[1]
            currentMarkers = v[2]            
        else
            -- we are now on the second player lets start the comparison
            local otherMarkers = v[2]
            differenceGrid = difference(currentMarkers,otherMarkers)

        end
    end
end

function unpauseGame()
    -- unpause the game
    UnPauseAllClients()
    playerSyncRequests = 0
    playerSyncRequestsRecieved = 0
end

function difference(Ga, Gb)
    local pairsToUpdate = {}
	local pairsCount = 1	
    for iA,vA in pairs(Ga) do
		local gridA = vA[1]
		local markerFound = false
		local countB = 1
		for iB,vB in pairs(Gb) do
			local gridB = vB[1]
			
			if gridA == gridB then
				markerFound = true
				local clearedA = vA[2]
				local clearedB = vB[2]
				--remove table entries as they are both found
				table.remove(Gb,countB)
				if clearedA == clearedB then
				--Do nothing there the same
				elseif clearedA == "Cleared" or clearedB == "Cleared" then
					--they dont match but one is cleared
					pairsToUpdate[pairsCount] = {gridA,"Cleared"}
					pairsCount = pairsCount + 1					
					--TODO remove the Bgrid line for performance
					elseif clearedA == "Infested" or clearedB == "Infested" then
					pairsToUpdate[pairsCount] = {gridA,"Infested"}
					pairsCount = pairsCount + 1
					--TODO remove the Bgrid line for performance
					else
					pairsToUpdate[pairsCount] = {gridA,"Discovered"}
					pairsCount = pairsCount + 1
					--TODO remove the Bgrid line for performance
				end				
			end
			countB = countB + 1
		end
		if markerFound == false then
		--add markers it wasnt found
		pairsToUpdate[pairsCount] = {gridA,vA[2]}
		pairsCount = pairsCount + 1
		end
	end
	local bGrid = Gb   
    return {pairsToUpdate,bGrid}
end

if isServer() then
    Events.OnServerStarted.Add(onServerStart)
    Events.OnClientCommand.Add(onClientCommand) --// a client sends to server
end