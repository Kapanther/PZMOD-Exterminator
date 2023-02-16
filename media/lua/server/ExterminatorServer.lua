local server_config = {};
local EXMmodule = "Exterminator"
local syncTimer = -1
local syncInterval = 2000
local playerSyncRequests = 0
local playerSyncRequestsRecieved = 0
local markerTables = {}
local currentPlayer
local currentMarkers = {}

--TODO server config
function onServerStart() 
    
end

function onClientCommand(module, command, player, args)
    --TODO this is hard  coded right now consider linking the mod ID to to it
    if module ~= EXMmodule then
        return
    end

    if command == 'sendMarkerUpdates' then
        sendServerCommand(module, 'sendMarkerUpdates', args)
    end

    if command == 'requestMarkerSync' then
        --pause all the clients while the marker sync happens
        
        --PauseAllClients()
        --TODO consider sending a message to let players know the game is sycing markers 

        -- request the player markers        
        local playerCount =  getOnlinePlayers():size();    

        if playerCount > 1 then
            local debugMSG2 = "EXMServer:Sync Player Count > 1 PC= " .. playerCount
            sendServerCommand(module, 'serverDebug', {debugMSG2}) --DEBUGONLY        
            sendServerCommand(module, 'requestMarkerSync', args)
            playerSyncRequests = playerCount
        else
            unpauseGame()
        end
    end

    if command == 'sendMarkerSync' then        
        playerSyncRequestsRecieved = playerSyncRequestsRecieved + 1
        local debugMSG = "EXMServer:sendMarkerSync sync Recieved by PC=".. playerSyncRequestsRecieved .. '/' .. playerSyncRequests .. ' from ' .. args[1]
        sendServerCommand(module, 'serverDebug', {debugMSG}) --DEBUGONLY

        -- add the data to memory on the server
        local playername =  args[1];
        markerTables[playerSyncRequestsRecieved] = {playername,args[2]}

        if playerSyncRequestsRecieved >= playerSyncRequests then
            local debugMSG2 = "EXMServer:sendMarkerSync:readToSyNC sync Recieved by PC=".. playerSyncRequestsRecieved .. '/' .. playerSyncRequests .. ' from ' .. args[1];
            sendServerCommand(module, 'serverDebug', {debugMSG2}) --DEBUGONLY
            doMarkerSyncChecks()
            local debugMSG3 = 'EXMServer:aboutToUnpauseGame ' .. args[1];
            sendServerCommand(module, 'serverDebug', {debugMSG3}) --DEBUGONLY            
            unpauseGame()
        end
    end
end

function doMarkerSyncChecks()
    --local debugMSG3 = "EXMServer:doMarkerSyncChecks"
    --print(debugMSG3)
    --sendServerCommand(EXMmodule, 'serverDebug', {debugMSG3}) --DEBUGONLY
    for i,v in pairs(markerTables) do
        local differenceGrid = {}
        if isTableEmpty(currentMarkers) then            
            local debugMSG5 = "EXMServer:doMarkerSyncChecks:currentMarkers" .. v[1]
            print(debugMSG5)
            sendServerCommand(EXMmodule, 'serverDebug', {debugMSG5}) --DEBUGONLY
            -- add the first markers to base grid to compare
            currentPlayer = v[1]
            currentMarkers = v[2]            
        else
            -- we are now on the second player lets start the comparison
            local otherMarkers = v[2]
            differenceGrid = difference(currentMarkers,otherMarkers)
            --send the differend markers
            local debugMSG6 = "EXMServer:doMarkerSyncChecks:sendDiffSync" .. v[1]
            print(debugMSG6)
            sendServerCommand(EXMmodule, 'serverDebug', {debugMSG6}) --DEBUGONLY
            if isTableEmpty(differenceGrid) then else
            sendServerCommand(EXMmodule,'sendDiffSync',differenceGrid)
             --update current makrers
                for k,v in pairs (differenceGrid) do
                local grid = v[1]
                local cleared = v[2]            
                currentMarkers[grid] = cleared
                end
            end
           

        end
    end
end

function unpauseGame()
    -- unpause the game
    playerSyncRequests = 0
    playerSyncRequestsRecieved = 0
    currentPlayer = {}
    currentMarkers = {}
    markerTables = {}
    --UnPauseAllClients()    
end

function difference(Ga, Gb)
    local pairsToUpdate = {}
	local pairsCount = 1
    local countA = 1    
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
					pairsToUpdate[gridA] = "Cleared"
					pairsCount = pairsCount + 1
                    table.remove(currentMarkers,countA)	--remove countA marker and readdit after sync			
					elseif clearedA == "Infested" or clearedB == "Infested" then
					pairsToUpdate[gridA] = "Infested"
					pairsCount = pairsCount + 1
                    table.remove(currentMarkers,countA)	--remove countA marker and readdit after sync	
					else
					pairsToUpdate[gridA] = "Discovered"
					pairsCount = pairsCount + 1
                    table.remove(currentMarkers,countA)	--remove countA marker and readdit after sync	
				end				
			end
			countB = countB + 1
		end
		if markerFound == false then
		--add markers it wasnt found
		pairsToUpdate[gridA] = vA[2]
		pairsCount = pairsCount + 1
		end
        countA = countA + 1
	end
    --TODO This is not splitting the grid differences by the two players we are jsut sending all the diffs and letting the clients resolve the differences... A Bit yucky.. but im lazy
	for iB,VB in pairs(Gb) do
        local gridB = vB[1]
        local clearedB = vB[2]
        pairsToUpdate[gridB] = clearedB
        pairsCount = pairsCount + 1
    end   
    return pairsToUpdate
end

function isTableEmpty(t)
    for _, _ in pairs(t) do
        return false
      end
    return true
end

if isServer() then
    Events.OnServerStarted.Add(onServerStart)
    Events.OnClientCommand.Add(onClientCommand) --// a client sends to server    
end