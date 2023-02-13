---
--- Mod: Exterminator
--- Workshop: <Add Address
--- Author: Kuckpanther
--- Profile: <AddProfile
---
--- Redistribution of this mod without explicit permission from the original creator is prohibited
--- under any circumstances. This includes, but not limited to, uploading this mod to the Steam Workshop
--- or any other site, distribution as part of another mod or modpack, distribution of modified versions.
--- You are free to do whatever you want with the mod provided you do not upload any part of it anywhere.
---

Exterminator = Exterminator or {}
Exterminator.MOD_ID = "Exterminator"

Exterminator.ServerConfigFileName = 'ExterminatorServerConfig.lua'
Exterminator.DefaultServerConfig = {
	["ClearWorldMaxX"] = 15000,
	["ClearWorldMinX"] = 200,
	["ClearWorldMaxY"] = 13500,
	["ClearWorldMinY"] = 1200,
}

Exterminator.ClientConfigFileName = 'ExterminatorClientConfig.lua'
Exterminator.DefaultClientConfig = {
	["ClearWorldMaxX"] = 15000,
	["ClearWorldMinX"] = 200,
	["ClearWorldMaxY"] = 13500,
	["ClearWorldMinY"] = 1200,
}

require 'ISUI/Maps/ISWorldMap'
require 'ISUI/Maps/ISMiniMap'
MapSymbolDefinitions.getInstance():addTexture("EXMcleared", "media/ui/LootableMaps/EXMcleared.png")
MapSymbolDefinitions.getInstance():addTexture("EXMinfested", "media/ui/LootableMaps/EXMinfested.png")
MapSymbolDefinitions.getInstance():addTexture("EXMdiscovered", "media/ui/LootableMaps/EXMdiscovered.png")
MapSymbolDefinitions.getInstance():addTexture("EXMgridCleared", "media/ui/LootableMaps/EXMgridCleared.png")

local floor = math.floor
local cache_zombieCount = 0;
local cache_nearestZombieDistance = 9999;
local cache_groundtype --Debug for checking ground 
local clearedMarkersToWin = 1011;
local timeSinceLastBeep = -1;
local zombieDistanceLimitMk1 = 75 -- for mk1 scanner
local zombieDistanceLimitMk2 = 150 -- for mk2 scanner
local textureCleared = "EXMcleared";
local textureInfested = "EXMinfested";
local textureDiscovered = "EXMdiscovered";
local textureGridCleared = "EXMgridCleared";
local gridAsize = 2500
local gridBsize = 500
local gridCsize = 100
local currentGridA = nil;
local currentGridB = nil;
local currentGridBnodecount = 99;
local currentGridBcleared = false;
local currentGridClearedCount = 0
local currentGridBx = 0
local currentGridBy = 0
local currentGridC = nil;
local currentGridCx = 0
local currentGridCy = 0
local currentGridMinX = 0
local currentGridMaxX = 0
local currentGridMinY = 0
local currentGridMaxY = 0
local currentGridBMinX = 0
local currentGridBMaxX = 0
local currentGridBMinY = 0
local currentGridBMaxY = 0
local currentGrids = {}
local currentGridCount = 0
local currentMarkerGrid = "NotAGrid";
local currentMarkers = {}
local currentGridBMarkers = {}
local currentGridBMarkerClearedCount = 0
local currentZombies = {}
local getNewMapMarkers = false
local playerX = 0
local playerY = 0
--locals required for managing position of zombie count text etc.. 
local screenX = 65;
local screenY = 13;
local textManager = getTextManager();
local itemZscannerMK1 = "ZombieScannerMK1"
local itemZscannerMK2 = "ZombieScannerMK2"
local itemZScanner = nil
local zombieScannerUpdateInterval = 50; 
local zombieScannerTimeSinceLastUpdate = -1;
local isItemOn = false;
local isScannerEquipped = false
local lastHeldItem = ""
local showDebugUI = true

--starts the Zombie scanner mod
function Exterminator.Initialize()
	print("EXM:Initialize")
	-- check if we are the client and register for server commands
	if isClient() then
	Events.OnServerCommand.Add(Exterminator.onServerCommand)-- Client receiving message from server	
	--TODO do initial sync of cleared zones and markers before starting
	Exterminator.requestMarkerSync()
	end

	--add zombie scanner check to equip Primary or secondary
	Events.OnEquipPrimary.Add(Exterminator.OnEquipScanner)
	Events.OnEquipSecondary.Add(Exterminator.OnEquipScanner)	

	--check if we are currently holding a zombie scanner	
	if getPlayer() and getPlayer():getPrimaryHandItem() then		
		Exterminator.OnEquipScanner(getPlayer(),getPlayer():getPrimaryHandItem())
	end

	--Add the UI
	Events.OnPostUIDraw.Add(Exterminator.onUITick) 
end

function Exterminator.getZombieScanData(playerX,playerY)
	--print("EXM:getCellData")
	--Cell Data
	local zombieList = getWorld():getCell():getZombieList();
	local zombieCount = zombieList:size();		
	if zombieCount then
		cache_zombieCount = zombieCount
		else
		cache_zombieCount = 0
	end
	local zombie = nil;
	local minDistanceToZombie = 9999
	local distanceToZombie = 9999
	if zombieCount > 0 then
		currentZombies = {} --need to clear the list		
		for i=0,zombieCount-1,1 do
			--print("EXM:getZombieScanData:getZombieCountArray")
            zombie = zombieList:get(i); -- todo swithc back to i
			if zombie then
				local zombX = zombie:getX(); 
				local zombY = zombie:getY(); 
				local distanceToZombie = Exterminator.getDistanceToZombie(playerX,playerY,zombX,zombY) --needed for scanner to beep
				local zombieData = {zombX,zombY}
				currentZombies[i] = zombieData --writes zombie X-Y for analysis in grids later			
				if distanceToZombie<minDistanceToZombie then
					minDistanceToZombie = floor(distanceToZombie);
				end
			end
        end
		cache_nearestZombieDistance = minDistanceToZombie;
	end
end

function Exterminator.getDistanceToZombie(playerX,playerY,zombieX,zombieY)
	return math.sqrt((math.pow(zombieX-playerX,2)+math.pow(zombieY-playerY,2)));
end

function Exterminator.runZombieScanner()
	local player = getPlayer();

	--#check for player
	if player then
		playerX = floor(player:getX()); --floor required because getX returns a float
		playerY = floor(player:getY());	
		--RUNS ON A CUSTOM TICK (default = 10ms*10 = every 100ms).. to frequesnt will crash game	
		if zombieScannerTimeSinceLastUpdate < 0 then		
			--get the player check the zombie scanner is on.. it emits light as means of turning on			
			local itemOn = itemZScanner:isEmittingLight();
			local itemName = itemZScanner:getType();
			lastHeldItem = itemName;
			--Check if they are holding a zombie scanner and its turned on
			if itemOn then
				Exterminator.getZombieScanData(playerX,playerY) -- get zombie scan data from surroundins
				Exterminator.updateGridVisible(playerX,playerY) -- This gets the scan zones must be after zombie scan
				if currentGridC ~= currentMarkerGrid or getNewMapMarkers then
					getNewMapMarkers = false					
					Exterminator.getMapMarkers(currentGridMinX,currentGridMaxX,currentGridMinY,currentGridMaxY) --Checks Previous Markers outside the current cell and marks them active if zombies are in them.
					currentMarkerGrid = currentGridC
				end
				Exterminator.refreshMapMarkers(player) -- checks on the currently aquired map markers -- 
				--TODO after marker removal we may need to get markers again
				isItemOn = true;
			else
			isItemOn = false;
			end
			zombieScannerTimeSinceLastUpdate = zombieScannerUpdateInterval;
		else
			zombieScannerTimeSinceLastUpdate = zombieScannerTimeSinceLastUpdate - 1;
		end
	end

	-- RUN EVERY UI TICK (1tick = 10ms)
	if player and isItemOn then
			--if zombie count is less than zero else run the scanner logic
		if cache_zombieCount > 0 then
			--check which scanner is been help and run the zombie scanner
			if lastHeldItem == itemZscannerMK1 then
				Exterminator.ScannerFunctionMk1(cache_nearestZombieDistance)					
			else 
				if lastHeldItem == itemZscannerMK2 then
					Exterminator.ScannerFunctionMk2(cache_nearestZombieDistance)
				end
			end
		end
	end
end

function Exterminator.onUITick()
	-- DEBUG ONLY -- display zombie count and distance by un commenting these next 6 lines

	--persistent UI
	-- 001 CURRENT GRID CLEARNACE
	local text_currentGridCleared = 'No Grid Data Detected - Equip a zombie scanner to start'
	local thisGridclearedPercentage = 0
	if currentGridB then
		thisGridclearedPercentage = floor(currentGridClearedCount/currentGridBnodecount*100);
		text_currentGridCleared = 'Current Grid = ' .. currentGridB .. ' Cleared ' .. thisGridclearedPercentage .. ' % (' .. currentGridClearedCount .. '/' .. currentGridBnodecount .. ')'; 
	end			
	textManager:DrawString(UIFont.Large, screenX, screenY, text_currentGridCleared, 0.1, 0.8, 1, 1);

	-- 002 CURRENT MAP CLEARNACE
	local text_currentMapCleared = 'No Map Data Detected - Equip a zombie scanner to start'
	local clearedMapMarkers = 0
	local clearedPercentage = 0
	if currentGridBMarkers then
		clearedPercentage = floor(currentGridBMarkerClearedCount/clearedMarkersToWin*100);		
		text_currentMapCleared = 'Map Cleared ' .. clearedPercentage .. ' % (' .. currentGridBMarkerClearedCount .. '/' .. clearedMarkersToWin .. ')'; 
	end	
	textManager:DrawString(UIFont.Large, screenX, screenY + 30, text_currentMapCleared, 0.1, 0.8, 1, 1);

	--003 ZOMBIE SCANNER COUNT
	local text_zombieScannerReadout = "(No Zombie Scanner Equipped)"
	if isItemOn then
		if lastHeldItem == itemZscannerMK1 then
			text_zombieScannerReadout =  "Z Count = " .. cache_zombieCount;	
		else
			text_zombieScannerReadout = "Z Count = " .. cache_zombieCount .. ' Nearest Z = ' .. cache_nearestZombieDistance .. ' m';	
		end
			
	end
	textManager:DrawString(UIFont.Large, screenX, screenY + 60, text_zombieScannerReadout, 0.1, 0.8, 1, 1);
	

	--Debug UI ONLY
	if showDebugUI then
		local text_playerPos = "Current Position = X " .. playerX .. " Y " .. playerY;		
		local countMarkers = 99999
		local next = next
		local text_currentGridCount = "Current Grid Count = " .. currentGridCount
		if currentMarkers == {} then
			countMarkers = 9999
		else
			countMarkers = 0
			for i,v in pairs(currentMarkers) do
				countMarkers = countMarkers + 1
			end
		end
		local text_currentMarkers = "Marker Count: " .. countMarkers
		local text_currentBGridExtents = "Current Grid Extents = X " .. currentGridBMinX .. ',Y' .. currentGridBMaxX .. " : " .. currentGridBMinY .. ',' .. currentGridBMaxY
		textManager:DrawString(UIFont.Large, screenX, screenY + 90, tostring(timeSinceLastBeep), 0.1, 0.8, 1, 1);
		textManager:DrawString(UIFont.Large, screenX, screenY + 120, tostring(zombieScannerTimeSinceLastUpdate), 0.1, 0.8, 1, 1);
		textManager:DrawString(UIFont.Large, screenX, screenY + 150, tostring(isItemOn), 0.1, 0.8, 1, 1);
		textManager:DrawString(UIFont.Large, screenX, screenY + 180, text_playerPos, 0.1, 0.8, 1, 1);		
		textManager:DrawString(UIFont.Large, screenX, screenY + 210, text_currentMarkers, 0.1, 0.8, 1, 1);
		textManager:DrawString(UIFont.Large, screenX, screenY + 240, text_currentGridCount, 0.1, 0.8, 1, 1);
		textManager:DrawString(UIFont.Large, screenX, screenY + 270, text_currentBGridExtents, 0.1, 0.8, 1, 1);
	end
end

function Exterminator.ScannerFunctionMk1(zombieDistance)

	--beep the scanner or reset the timed to next beep
	local distanceMultiplier = 0.5
	if zombieDistance < zombieDistanceLimitMk1 then	
		if timeSinceLastBeep < 0 then
		--TODO beep the scanner and reset timer
		Exterminator.ScannerBeep()
		timeSinceLastBeep = floor(zombieDistance) * distanceMultiplier;
		else
		timeSinceLastBeep = timeSinceLastBeep - 1;
		end
	end
end

function Exterminator.ScannerFunctionMk2(zombieDistance)

	--beep the scanner or reset the timed to next beep
	local distanceMultiplier = 0.5
	if zombieDistance < zombieDistanceLimitMk2 then	
		if timeSinceLastBeep < 0 then
		--TODO beep the scanner and reset timer
		Exterminator.ScannerBeep()
		timeSinceLastBeep = floor(zombieDistance) * distanceMultiplier;
		else
		timeSinceLastBeep = timeSinceLastBeep - 1;
		end
	end
end

function Exterminator.ScannerBeep()
	--print("Exterminator.ScannerBeep") --DEBUG run beep sound
	local soundManager = getSoundManager()
	soundManager:PlaySound("ZombieScannerBeep",false,7)
end

function Exterminator.ClearedAreaBeep()
	--print("Exterminator.ClearedAreaBeep") --DEBUG run beep sound
	local soundManager = getSoundManager()
	soundManager:PlaySound("ClearedAreaBeep",false,10)
end

function Exterminator.OnEquipScanner(character,item)
	--print("EXM:OnEquipScanner")
	if not character:isLocalPlayer() then return end

	--Draw UI if scanner is equipped	
	if Exterminator.isZombieScanner(item) then
			if isScannerEquipped == false then
			Events.OnPostUIDraw.Add(Exterminator.runZombieScanner)
			itemZScanner = item
			isScannerEquipped = true
			end
	else
			Events.OnPostUIDraw.Remove(Exterminator.runZombieScanner)
			itemZScanner = nil
			isItemOn = false; --required to cleanup TODO maybe this could be cleaner
			isScannerEquipped = false	
		
	end	
end

function Exterminator.isZombieScanner(item)
	if item then
		local itemName = item:getType();
		--local debugprint = "EXM:isZombieScanner Type =" .. itemName;
		--print(debugprint)	
		if itemName == itemZscannerMK1 or itemName == itemZscannerMK2 then			
			return true;
		else			
			return false;
		end
	else	
	return false;
	end
end

function Exterminator.getmapAPI(map_item)
  local map_api

  if map_item then
    map_api = UIWorldMap.new(nil):getAPIv1()
    map_api:setMapItem(map_item)
  -- NOTE: we have to use the global instance to avoid inconsistencies on hitCheck
  elseif ISWorldMap_instance then
    map_api = ISWorldMap_instance.javaObject:getAPIv1()
  else -- NOTE: we don't have a global instance yet, but we need to use the MapItem singleton
    map_api = UIWorldMap.new(nil):getAPIv1()
    map_api:setMapItem(MapItem:getSingleton())
  end

  return map_api
end

function Exterminator.getSymAPI(map_item)
  map_api = Exterminator.getmapAPI(map_item)

  return map_api:getSymbolsAPI()
end

function Exterminator.isMarkerInCurrentBgrid(testX,testY)
	if testX > currentGridBMinX and testX < currentGridBMaxX then
		if testY > currentGridBMinY and testY < currentGridBMaxY then
			return true
		end	
	end
	return false

end

function Exterminator.getMapMarkers(minX,maxX,minY,maxY)
	--cycle through each of the current map markers
	local symAPI = Exterminator.getSymAPI()
	local cnt = symAPI:getSymbolCount() 
	local markerCountCleared = 0 --user for counted cleared markers in current B zone 	
	local markerCount = 1 --used for writing makrers to current markers
	local markerBcount = 1 --used for writing B markers
	currentMarkers = {} -- need to reset the markers
	currentGridBMarkers = {}
  
	--TODO is this getting the markers correctly? i think the count might be wrong
	for i=0,cnt-1,1 do 
		--TODO doesnt seem to get symbol fials on null
		local sym = symAPI:getSymbolByIndex(i) 
		if sym then
			local sym_x = sym:getWorldX();
			if sym_x <= maxX and sym_x >= minX then
				local sym_y = sym:getWorldY();
				if sym_y <= maxY and sym_y >= minY then
					--add symbol data to the monitored markers
					local sym_texture = sym:getSymbolID();
					if sym_texture == textureDiscovered or sym_texture == textureCleared or sym_texture == textureInfested then
						local markerEntry = {i,sym_x,sym_y,sym_texture}
						currentMarkers[markerCount] = markerEntry --MarkerTAble = index,X,Y,Texture
						markerCount = markerCount + 1
						if Exterminator.isMarkerInCurrentBgrid(sym_x,sym_y) and sym_texture == textureCleared then
							markerCountCleared = markerCountCleared + 1							
						end
					elseif sym_texture == textureGridCleared then
						local markerBEntry = {i,sym_x,sym_y,sym_texture}
						currentGridBMarkers[markerBcount] = markerBEntry --MarkerBTAble = index,X,Y,Texture
						markerBcount = markerBcount + 1						
					end
				end
			end
		end		
	end
	currentGridBMarkerClearedCount = markerBcount - 1
	currentGridClearedCount = markerCountCleared
	getNewMapMarkers = false
end

function Exterminator.refreshMapMarkers(player)
	
	local removeMarkers = {}
	local removeMarkersCount = 1
	local addMarkers = {}
	local addMarkersCount = 1

	--cycle through each of the current map markers against the grids
	--GridTable = GridRef,GridX,GridY,HasZombies,GridB
	--MarkerTAble = index,X,Y,Texture
	for iGrid,vGrid in pairs(currentGrids) do
		local gCgrid = vGrid[1]
		local gX = vGrid[2]
		local gY = vGrid[3]
		local gHasZombies = vGrid[4]
		local gBgrid = vGrid[5]
		local markerExists = false		
		if currentMarkers == {} then
			markerExists = false
		else
			for iMarker,vMarker in pairs(currentMarkers) do
				local mIndex = vMarker[1]
				local mX = vMarker[2]
				local mY = vMarker[3]
				local mTexture = vMarker[4]
				if gX == mX then --X check
					if gY == mY then --y check
						--TODO consider ignoring marker 
						markerExists = true;						
						if gHasZombies then -- zone has zombies
							if mTexture == textureCleared or mTexture == textureDiscovered then
								-- Queue marker for Deletion								
								removeMarkers[removeMarkersCount] = {mIndex,mX,mY}--RemoveMarkerTable = Index,X,Y
								removeMarkersCount = removeMarkersCount + 1
								--add new marker textureInfested
								addMarkers[addMarkersCount] = {gX,gY,textureInfested}--AddMarkerTable = X,Y,Texture
								addMarkersCount = addMarkersCount + 1	
							end							
							else
							if gCgrid == currentGridC and mTexture ~= textureCleared then
								-- Queue marker for Deletion
								removeMarkers[removeMarkersCount] = {mIndex,mX,mY}--RemoveMarkerTable = Index,X,Y
								removeMarkersCount = removeMarkersCount + 1
								--add new marker textureInfested
								addMarkers[addMarkersCount] = {gX,gY,textureCleared} --AddMarkerTable = X,Y,Texture
								addMarkersCount = addMarkersCount + 1								
							end
						end											
					end
				end
			end	
		end		
		if markerExists == false then			
			if gHasZombies then
				--Create infested marker
				addMarkers[addMarkersCount] = {gX,gY,textureInfested} --AddMarkerTable = X,Y,Texture
				addMarkersCount = addMarkersCount + 1
				else
				if gCgrid == currentGridC then
					--Create cleared marker
					addMarkers[addMarkersCount] = {gX,gY,textureCleared} --AddMarkerTable = X,Y,Texture
					addMarkersCount = addMarkersCount + 1
					currentGridClearedCount = currentGridClearedCount + 1
					else
					--Create undiscovered marker
					addMarkers[addMarkersCount] = {gX,gY,textureDiscovered} --AddMarkerTable = X,Y,Texture
					addMarkersCount = addMarkersCount + 1
				end
			end
		end
	end	
	if currentGridClearedCount >= currentGridBnodecount then 
		if currentGridBcleared then
			-- do nother currentGridBcleared is alreayd cleared no need to check maekrs
			else
				currentGridBcleared = true			
				--add a grid cleared marker at the grid B location
				addMarkers[addMarkersCount] = {currentGridBx,currentGridBy,textureGridCleared}
				addMarkersCount = addMarkersCount + 1
		end
	else
		currentGridBcleared = false
		-- check if there are markers that match and delete them
		if currentGridBMarkers then
			for iBmark,vBmark in pairs(currentGridBMarkers) do
				local vBmarkIndex = vBmark[1]
				local vBmarkX = vBmark[2]
				local vBmarkY = vBmark[3]
				if vBmarkX == currentGridBx and vBmarkY == currentGridBy then
					--set for Deletion
					removeMarkers[removeMarkersCount] = {vBmarkIndex,vBmarkX,vBmarkY}--RemoveMarkerTable = Index,X,Y
					removeMarkersCount = removeMarkersCount + 1
				end
			end
		end
	end
	-- loop through the queue to add markers then remove markers
	local symAPI = Exterminator.getSymAPI()	
	if addMarkers then
		for iNewMaker,vNewMarker in pairs(addMarkers) do
			Exterminator.addMarker(symAPI,vNewMarker[3],vNewMarker[1],vNewMarker[2])
		end
		getNewMapMarkers = true
	end
	if removeMarkers then
		local prevMarkerIndex = 99999
		for iRemoveMaker,vRemoveMarker in pairs(removeMarkers) do
			local rIndex = vRemoveMarker[1]
			--remove the marker	
			if prevMarkerIndex < rIndex then		
			symAPI:removeSymbolByIndex((rIndex-1))
			prevMarkerIndex = rIndex
			else
			symAPI:removeSymbolByIndex(rIndex)
			prevMarkerIndex = rIndex
			end
		end
	end
	-- send marker changes over network
	if isClient() then
		if getNewMapMarkers then
			local username = player:getUsername()
			local markerExtents = {currentGridMinX,currentGridMaxX,currentGridMinY,currentGridMaxY}
			sendClientCommand(Exterminator.MOD_ID,'sendMarkerUpdates',{addMarkers,markerExtents,username}) 		 
		end
	end
end

function Exterminator.updateGridVisible(playerX,playerY)
	currentGrids = {}	
	currentGridA = Exterminator.getGridRef('A',playerX,playerY)
	currentGridB = Exterminator.getGridRef('B',playerX,playerY)
	currentGridBx = Exterminator.getGridRef('Bx',playerX,playerY)	
	currentGridBy = Exterminator.getGridRef('By',playerX,playerY)
	currentGridBnodecount = Exterminator.getBGridValidPoints(currentGridA,currentGridB)	
	currentGridC = Exterminator.getGridRef('C',playerX,playerY)
	currentGridCx = Exterminator.getGridRef('Cx',playerX,playerY)	
	currentGridCy = Exterminator.getGridRef('Cy',playerX,playerY)		
	local gridRange = 1	-- total distance from center to get grids
	local gridCount = 1 -- used for writing the grid table	

	--populate min max X yet for marker grabs 
	--TODO this needs to get the 5x5 grid for the b Square
	local checkMinX = currentGridCx - ((gridCsize * gridRange) + 50)
	local checkMaxX = currentGridCx + ((gridCsize * gridRange) + 50)
	local checkMinY = currentGridCy - ((gridCsize * gridRange) + 50)
	local checkMaxY = currentGridCy + ((gridCsize * gridRange) + 50)	
	currentGridBMinX = currentGridBx - ((gridBsize/2) + 50)
	currentGridBMaxX = currentGridBx + ((gridBsize/2) + 50)
	currentGridBMinY = currentGridBy - ((gridBsize/2) + 50)
	currentGridBMaxY = currentGridBy + ((gridBsize/2) + 50)
	if checkMinX < currentGridBMinX then
		currentGridMinX = checkMinX
	else
		currentGridMinX = currentGridBMinX
	end
	if checkMaxX > currentGridBMaxX then
		currentGridMaxX = checkMaxX
	else
		currentGridMaxX = currentGridBMaxX
	end
	if checkMinY < currentGridBMinY then
		currentGridMinY = checkMinY
	else
		currentGridMinY = currentGridBMinY
	end
	if checkMaxY > currentGridBMaxY then
		currentGridMaxY = checkMaxY
	else
		currentGridMaxY = currentGridBMaxY
	end
	
	for i=-gridRange,gridRange,1 do
		--currentgrids[i+2] = {}
		local iGridX = playerX + (i*gridCsize)		
		for j=-gridRange,gridRange,1 do
			local iGridY = playerY + (j*gridCsize)
			--test if point is valud
			local iGridA = Exterminator.getGridRef('A',iGridX,iGridY)
			local iGridB = Exterminator.getGridRef('B',iGridX,iGridY)	
			local iGridC = Exterminator.getGridRef('C',iGridX,iGridY)
			local iGridXfix = Exterminator.getGridRef('Cx',iGridX,iGridY)	
			local iGridYfix = Exterminator.getGridRef('Cy',iGridX,iGridY)
			local hasZombies = false			
			if  Exterminator.isGridPointValid(iGridA,iGridB,iGridC) then
				if currentZombies then
					for index,value in pairs(currentZombies) do
						hasZombies = Exterminator.isZombieInGrid(iGridXfix,iGridYfix,value[1],value[2])
						if hasZombies == true then
							break
						end
					end
				end				
				local gridWrite = {iGridC,iGridXfix,iGridYfix,hasZombies,iGridB}
				--GridTable = GridRef,GridX,GridY,HasZombies,GridB
				currentGrids[gridCount] = gridWrite	
				gridCount = gridCount + 1 		
			end
		end
	end
	currentGridCount = gridCount - 1 --DEBUG remove later	
end

function Exterminator.isZombieInGrid(gridX,gridY,zombX,zombY)	
	local gridOffset = gridCsize/2	
	if zombX <= gridX+gridOffset and zombX >= gridX-gridOffset and zombY <= gridY+gridOffset and zombY >= gridY-gridOffset then
		return true		
	else		
		return false
	end
end

function Exterminator.getGridRef(gridType,gridX,gridY)
	local coordSep = '_'
	if gridType == 'C' then
		local Cx = (Exterminator.RoundUpToInt((gridX/gridCsize),0)*gridCsize)-(gridCsize/2)
		local Cy = (Exterminator.RoundUpToInt(((gridY)/gridCsize),0)*gridCsize)-(gridCsize/2) -- 300 offset on y grid
		local Cref = Cx .. coordSep .. Cy
		return Cref
	end
	if gridType == 'B' then
		local Bx = (Exterminator.RoundUpToInt((gridX/gridBsize),0)*gridBsize)-(gridBsize/2)
		local By = (Exterminator.RoundUpToInt(((gridY-300)/gridBsize),0)*gridBsize) + 50 -- 300 offset on y grid
		local Bref = 'B' .. Bx .. coordSep .. By
		return Bref
	end
	if gridType == 'Cx' then
		local Cx = (Exterminator.RoundUpToInt((gridX/gridCsize),0)*gridCsize)-(gridCsize/2)		
		return Cx
	end
	if gridType == 'Cy' then		
		local Cy = (Exterminator.RoundUpToInt(((gridY)/gridCsize),0)*gridCsize)-(gridCsize/2) -- 300 offset on y grid		
		return Cy
	end
	if gridType == 'Bx' then
		local Bx = (Exterminator.RoundUpToInt((gridX/gridBsize),0)*gridBsize)-(gridBsize/2)		
		return Bx
	end
	if gridType == 'By' then		
		local By = (Exterminator.RoundUpToInt(((gridY-300)/gridBsize),0)*gridBsize) + 50 -- 300 offset on y grid		
		return By
	end	 	     
	if gridType == 'A' then
		local Ax = (Exterminator.RoundUpToInt((gridX/gridAsize),0)*gridAsize)-(gridAsize/2)
		local Ay = (Exterminator.RoundUpToInt(((gridY-300)/gridAsize),0)*gridAsize)-(gridAsize/2) + 300 -- 300 offset on y grid
		local Aref = 'A' .. Ax .. coordSep .. Ay
		return Aref
	end 
end

function Exterminator.getBGridValidPoints(gridA,gridB)
	local validPoints = 99
	if ExterminatorGrid[gridA][gridB] then		
		validPoints = 0
		for index,value in pairs(ExterminatorGrid[gridA][gridB]) do			
			validPoints = validPoints + 1
		end				
	end
	--DEBUG ONLY print("getBGridValidPoints:" .. gridA .. "." .. gridB .. ' - ' .. validPoints)
	return validPoints
end

function Exterminator.RoundUpToInt(num)
	local numDecimalPlaces = 0
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor((num+0.5) * mult + 0.5) / mult
end

function Exterminator.isGridPointValid(gridA,gridB,gridRef)	
	if ExterminatorGrid[gridA][gridB] then
		for index,value in pairs(ExterminatorGrid[gridA][gridB]) do
			if value == gridRef then
				return true
			end
		end
	else
		return false
	end
	return false
end

function Exterminator.addMarker (symAPI,markerType,gridX,gridY)	
	
	local newSymbol = symAPI:addTexture(markerType,gridX,gridY)
	if newSymbol then
		if markerType == textureGridCleared then
			newSymbol:setAnchor(0.5, 0.5)
			newSymbol:setScale(9) --these ones actually show up (somehwere betwen 9 - 9.5 is good to show isometric)
			newSymbol:setRGBA(51, 255, 48, 200)
			--TODO only beep if full grid is cleared rather than jsut one area
			Exterminator.ClearedAreaBeep() --play sound for area cleared		
		else
			-- createa a regualr marker
			newSymbol:setAnchor(0.5, 0.5)
			newSymbol:setScale(1) --DEBUG set scale to 0.01 so it cant be deleted by player easily
			newSymbol:setRGBA(51, 255, 48, 200)
			--TODO only beep if full grid is cleared rather than jsut one area			
		end
	else
		print('Exterminator.addClearedMarker:Failed to create marker')
	end
end

function Exterminator.getAllMarkersForSync()
	--cycle through each of the current map markers
	local minX = 0
	local maxX = 20000
	local minY = 0
	local maxY = 20000
	local symAPI = Exterminator.getSymAPI()
	local cnt = symAPI:getSymbolCount() 
	local markerCount = 1 
	local allMarkers = {} -- need to reset the markers
  
	--TODO is this getting the markers correctly? i think the count might be wrong
	for i=0,cnt-1,1 do 
		local sym = symAPI:getSymbolByIndex(i)
		local sym_x = sym:getWorldX();
		local sym_y = sym:getWorldY();		
		local sym_texture = sym:getSymbolID();
		if sym_texture == textureCleared or sym_texture == textureDiscovered or sym_texture == textureInfested then
			local thisGridRef = "C" .. Exterminator.getGridRef('C',sym_x,sym_y) --zTODO i have added a C in front of the string instead of changing the grid... it only happens on initial sync
			local markerEntry = {thisGridRef= sym_texture}
			allMarkers[markerCount] = markerEntry --MarkerTAble = index,X,Y,Texture
			markerCount = markerCount + 1
		elseif sym_texture == textureGridCleared then
			local thisGridBRef = Exterminator.getGridRef('B',sym_x,sym_y)
			local markerEntry = {thisGridBRef = sym_texture}
			allMarkers[markerCount] = markerEntry --MarkerTAble = index,X,Y,Texture
			markerCount = markerCount + 1
		end
	end

	local sortedMarkers = Exterminator.sortMarkers(allMarkers)
	return sortedMarkers
end

function Exterminator.pairsByKeys (t, f)
    local a = {}
    for n in pairs(t) do table.insert(a, n) end
    table.sort(a, f)
    local i = 0      -- iterator variable
    local iter = function ()   -- iterator function
      i = i + 1
      if a[i] == nil then return nil
      else return a[i], t[a[i]]
      end
    end
    return iter
end

function Exterminator.requestMarkerSync()	
	local username = getPlayer():getUsername();	
	sendClientCommand(Exterminator.MOD_ID,'requestMarkerSync',{username})
end

function Exterminator.sortMarkers (markersToSort)
	local sorted = {}
	local count = 1
	for name, line in Exterminator.pairsByKeys(markersToSort) do
		  sorted[count] = {name,line}
		  count = count + 1
	end
	return sorted
end

function Exterminator.sendMarkerSync()
	local username = getPlayer():getUsername();	
	local currentMarkers = Exterminator.getAllMarkersForSync()
	sendClientCommand(Exterminator.MOD_ID,'sendMarkerSync',{username,currentMarkers})
end

function Exterminator.recieveMarkerUpdates (markersToAdd,markerExtents)

	-- get current markers on map and count
	local symAPI = Exterminator.getSymAPI()
	
    -- get markers in extents only then cycle over them.
	local markersToCheck = Exterminator.getAllMarkersForSync()

	--AddMarkerTable = X,Y,Texture	
	if markersToAdd then
		local prevMarkerIndex = 99999		
		for iNewMaker,vNewMarker in pairs(markersToAdd) do
			local markerExists = false
			local mTexture = vNewMarker[3]
			local mX = vNewMarker[1]
			local mY = vNewMarker[2]
			for iOldMarker,vOldMarker in pairs(markersToCheck) do
				local oIndex = vOldMarker[1]				
				local oTexture = vOldMarker[4]
				local oX = vOldMarker[2]
				local oY = vOldMarker[3]
				--checkX
				if oX == mX then
					if oY == mY then
						markerExists = true
						if oTexture == mTexture then
							--marker is the same do nothing
							else
							--Rremove the old marker
							if prevMarkerIndex < oIndex then		
								symAPI:removeSymbolByIndex((oIndex-1))
								prevMarkerIndex = oIndex							
								else
								symAPI:removeSymbolByIndex(oIndex)
								prevMarkerIndex = oIndex							
							end
							--add the marker
							Exterminator.addMarker(symAPI,mTexture,mX,mY)
							print("recieveMarkerUpdates:ADD X:" .. mX .. "Y:" .. mY .. " Tex:" .. mTexture)	
						end
					end
				end
			end
			if markerExists == false then
				Exterminator.addMarker(symAPI,mTexture,mX,mY)
				print("recieveMarkerUpdates:ADD X:" .. mX .. "Y:" .. mY .. " Tex:" .. mTexture)			
			end
		end
		getNewMapMarkers = true
	end
end

function Exterminator.onServerCommand(module, command, args)
	--Check if this command if for our mod otherwise exit
	if module ~= Exterminator.MOD_ID then
		return
	end

	-- debug
	print( ('Exterminator.onServerCommand Command= "%s"'):format(command) )

	--update markers from network
	if command == 'sendMarkerUpdates' then		
		local sentName = args[3]
			print('Exterminator.onServerCommand.recieveMarkerUpdates sent by ' .. sentName)
			Exterminator.recieveMarkerUpdates(args[1],args[2])
	end

	if command == 'requestMarkerSync' then
		
	end
end

--required to initialise the mod
Events.OnGameStart.Add(Exterminator.Initialize)

