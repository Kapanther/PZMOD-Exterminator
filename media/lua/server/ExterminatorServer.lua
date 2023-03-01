local server_config = {};
local EXMmodule = "Exterminator"
local syncTimer = -1
local syncInterval = 2000
local playerSyncRequests = 0
local playerSyncRequestsRecieved = 0
local markerTables = {}
local currentPlayer
local currentMarkers = {}
local debugMarkerOutput = 'MarkerOutput.txt' -- wrties into the c:\users\<username>\zomboid\lua folder (you can write anywhere else)

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
            sendServerCommand(module, 'requestMarkerSync', args)
            playerSyncRequests = playerCount
        else
            unpauseGame()
        end
    end

    if command == 'sendMarkerSync' then        
        playerSyncRequestsRecieved = playerSyncRequestsRecieved + 1
        --sendServerDebugMsg("sendMarkerSync sync Recieved by PC=".. playerSyncRequestsRecieved .. '/' .. playerSyncRequests .. ' from ' .. args[1]) -- DEBUG
        --DEBUG write table to file        

        -- add the data to memory on the server
        local playername =  args[1];
        markerTables[playername] = args[2]

        if playerSyncRequestsRecieved >= playerSyncRequests then
            --sendServerDebugMsg("sendMarkerSync:readToSyNC sync Recieved by PC=".. playerSyncRequestsRecieved .. '/' .. playerSyncRequests .. ' from ' .. args[1]) -- DEBUG
            doMarkerSyncChecks()         
            unpauseGame()
        end
    end
end

function writeToDebugLog(stringToWrite)
    local debugLog = getFileWriter(debugMarkerOutput,true,true)

    
    debugLog:write(stringToWrite)
    debugLog:close()
end

function writeTableToLogo(tableToWrite)
    local debugLog = getFileWriter(debugMarkerOutput,true,true)
    
    debugLog:write(stringToWrite)
    debugLog:close()
end

function doMarkerSyncChecks()
    --local debugMSG3 = "EXMServer:doMarkerSyncChecks"
    --print(debugMSG3)
    --sendServerCommand(EXMmodule, 'serverDebug', {debugMSG3}) --DEBUGONLY
    for i,v in pairs(markerTables) do
        currentPlayer = i
            local differenceGrid = {} -- resets the difference grid to empty

            if isTableEmpty(v) then
                if isTableEmpty(currentMarkers) then  
                    --Do nothing becasue this table is empty and so is the current markers
                    else
                    --TODO Need to complete redo the logic here
                    differenceGrid = currentMarkers
                    --assert( table.save( differenceGrid, debugMarkerOutput, "BOTHEMPTY" ) == nil ) --DEBUG
                    
                end
            else
                if isTableEmpty(currentMarkers) then            
                    --sendServerDebugMsg("doMarkerSyncChecks:currentMarkers") -- DEBUG
                    --assert( table.save( v, debugMarkerOutput, "INITIAL" ) == nil ) --DEBUG
                    -- add the first markers to base grid to compare                   
                    currentMarkers = writeToTable(v)
                    sendServerCommand(EXMmodule,'sendDiffSync',currentMarkers) -- DEBUG
                            
                else       
                    -- the current markers are already populated and the new markers are difference lets do the check
                    --sendServerDebugMsg("doMarkerSyncChecks:differenceGridrunning") -- DEBUG
                    differenceGrid = difference(currentMarkers,v)
                    --assert( table.save( differenceGrid, debugMarkerOutput, "DIFFGRID"  ) == nil )--DEBUG
                end  
            if isTableEmpty(differenceGrid) then else
                sendServerCommand(EXMmodule,'sendDiffSync',differenceGrid)
                --sendServerDebugMsg("doMarkerSyncChecks:differenceGridSent")--DEBUG
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

function sendServerDebugMsg(message)
    local debugMSG = "EXMSERVERDEBUG:" .. message
    print(debugMSG)
    sendServerCommand(EXMmodule, 'serverDebug', {debugMSG}) --DEBUGONLY
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
		local gridA = iA
		local markerFound = false
		local countB = 1
		for iB,vB in pairs(Gb) do
            local gridB
            local clearedB
            for vB1,vB2 in pairs(vB) do
                gridB = vB1
                clearedB = vB2
            end					
			if gridA == gridB then
				markerFound = true
				local clearedA = vA				
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
	for iB,vB in pairs(Gb) do
        local gridB
        local clearedB
        for vB1,vB2 in pairs(vB) do
            gridB = vB1
            clearedB = vB2
        end	
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

function writeToTable(  tableIn )
    local tableOut = {}

    -- initiate variables for save procedure
    for i,v in pairs( tableIn ) do
        if i == nil then else
            if v == nil then else
				--for x,y in pairs(v) do
                    tableOut[i] = v
				--end
            end
        end
    end
   
    return tableOut
end

function table.save(  tbl,filename,reason )
    local file = getFileWriter(filename,true,true)  

    local count = 1
    -- initiate variables for save procedure
    for i,v in pairs( tbl ) do
        if i == nil then else
            if v == nil then else
				--for x,y in pairs(v) do
					local stringToWrite = reason .. ' - ' .. count .. ',' .. i  .. ',' .. v  .. "\n"
                	file:write( stringToWrite )
				--end
                count = count + 1
            end
        end
    end
   
    file:close()
end

if isServer() then
    Events.OnServerStarted.Add(onServerStart)
    Events.OnClientCommand.Add(onClientCommand) --// a client sends to server
    local sandboxOptions = getSandboxOptions()
    sandboxOptions:set("ZombieConfig.RespawnHours", 0) -- should prevent respawns on server
elseif isClient() == false then
    local sandboxOptions = getSandboxOptions()
    sandboxOptions:set("ZombieConfig.RespawnHours", 0)    
end
local sandboxOptions = getSandboxOptions()
local test = sandboxOptions:getOptionByName("ZombieConfig.RespawnHours")
--print(test:asConfigOptions():getValueAsString())
