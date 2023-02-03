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
MapSymbolDefinitions.getInstance():addTexture("EXMclearedDot", "media/ui/LootableMaps/EXMclearedDot.png")

local floor = math.floor
local cache_zombieCount = 0;
local cache_nearestZombieDistance = 9999;
local cache_groundtype --Debug for checking ground 
local clearedMarkersToWin = 3200;
local clearedMarkers = 1;
local timeSinceLastBeep = -1;
local zombieDistanceLimitMk1 = 75 -- for mk1 scanner
local zombieDistanceLimitMk2 = 150 -- for mk2 scanner
local clearedTexture = "EXMclearedDot";
local currentCellMinX = 0
local currentCellMaxX = 0
local currentCellMinY = 0
local currentCellMaxY = 0
local currentGridB = nil;
local currentGridBx = 0
local currentGridBy = 0
local currentGridC = nil;
local currentGridCx = 0
local currentGridCy = 0
local currentGrids = {}
--locals required for managing position of zombie count text etc.. 
local screenX = 65;
local screenY = 13;
local textManager = getTextManager();
local updateInterval = 10; 
local timeSinceLastUpdate = -1;
local isItemOn = false;
local lastHeldItem = ""

--starts the Zombie scanner mod
function Exterminator.Initialize()
	print("EXM:Initialize")
	-- check if we are the client and register for server commands
	if isClient() then
	Events.OnServerCommand.Add(Exterminator.onServerCommand)-- Client receiving message from server	
	--TODO do initial sync of cleared zones and markers before starting
	end

	--add zombie scanner check to equip Primary or secondary
	Events.OnEquipPrimary.Add(Exterminator.OnEquipPrimary)
	--Events.OnEquipSecondary.Add(OnEquipPrimary)	

	--check if we are currently holding a zombie scanner	
	if getPlayer() and getPlayer():getPrimaryHandItem() then		
		Exterminator.OnEquipPrimary(getPlayer(),getPlayer():getPrimaryHandItem())
	end
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
		for i=0,zombieCount-1,1 do
			--print("EXM:getZombieScanData:getZombieCountArray")
            zombie = zombieList:get(i); -- todo swithc back to i
			if zombie then
				local zombX = zombie:getX(); --get x
				local zombY = zombie:getY(); --get y
				local distanceToZombie = Exterminator.getDistanceToZombie(playerX,playerY,zombX,zombY)
				--local printZombtext = "Z." .. i .. "x = " .. zombX .. " y = " .. zombY .. "D = " .. distanceToZombie;
				--print(printZombtext) --DEBUGONLY
				if distanceToZombie<minDistanceToZombie then
					minDistanceToZombie = floor(distanceToZombie);
				end
			end
        end
		cache_nearestZombieDistance = minDistanceToZombie;
	end
end

function Exterminator.getDistanceToZombie(playerX,playerY,zombieX,zombieY)
	distanceToZombie = math.sqrt((math.pow(zombieX-playerX,2)+math.pow(zombieY-playerY,2)));
	return distanceToZombie
end

function Exterminator.runZombieScanner()
	local player = getPlayer();
	local playerX --floor required because getX returns a float
	local playerY 	
	--get the player position
	if player then
		playerX = floor(player:getX()); --floor required because getX returns a float
		playerY = floor(player:getY());		
		if timeSinceLastUpdate < 0 then		
			--get the player check the zombie scanner is on.. it emits light as means of turning on			
			local itemOn = player:getPrimaryHandItem():isEmittingLight();
			local itemName = player:getPrimaryHandItem():getType();
			lastHeldItem = itemName;
			--Check if they are holding a zombie scanner and its turned on
			if itemOn then
				-- get zombie scan data from surroundins
				Exterminator.getZombieScanData(playerX,playerY)
				isItemOn = true;
				Exterminator.updateGridVisible(playerX,playerY) -- This gets the scan zones 
			else
			isItemOn = false;
			end
			timeSinceLastUpdate = updateInterval;
		else
			timeSinceLastUpdate = timeSinceLastUpdate - 1;
		end
	end
	-- will update every UI tick
	-- DEBUG ONLY -- display zombie count and distance by un commenting these next 6 lines
	local text_zombieCount =  "Zombie Count = " .. cache_zombieCount;
	local clearedPercentage = floor(clearedMarkers/clearedMarkersToWin);
	local text_clearedPerctange = "Cleared Area = " .. tostring(clearedPercentage) .. "% (" .. clearedMarkers .. "/" .. clearedMarkersToWin .. ")";	
	local text_playerPos = "Current Position = X " .. playerX .. " Y " .. playerY;
	textManager:DrawString(UIFont.Large, screenX, screenY, text_zombieCount, 0.1, 0.8, 1, 1);
	textManager:DrawString(UIFont.Large, screenX, screenY + 30, text_clearedPerctange, 0.1, 0.8, 1, 1);
	textManager:DrawString(UIFont.Large, screenX, screenY + 60, tostring(timeSinceLastBeep), 0.1, 0.8, 1, 1);
	textManager:DrawString(UIFont.Large, screenX, screenY + 90, tostring(timeSinceLastUpdate), 0.1, 0.8, 1, 1);
	textManager:DrawString(UIFont.Large, screenX, screenY + 120, tostring(isItemOn), 0.1, 0.8, 1, 1);
	textManager:DrawString(UIFont.Large, screenX, screenY + 150, text_playerPos, 0.1, 0.8, 1, 1);

	if player and isItemOn then
		local playerX = floor(player:getX()); --floor required because getX returns a float
		local playerY = floor(player:getY());
			--if zombie count is less than zero else run the scanner logic
		if cache_zombieCount > 0 then
			--check which scanner is been help and run the zombie scanner
			if lastHeldItem == "ZombieScannerMK1" then
				Exterminator.ScannerFunctionMk1(cache_zombieCount,cache_nearestZombieDistance)					
			else 
				if lastHeldItem == "ZombieScannerMK2" then
					Exterminator.ScannerFunctionMk2(cache_zombieCount,cache_nearestZombieDistance)
				end
			end
			else
			Exterminator.addClearedMarker(player,playerX,playerY)
		end
	end
end

function Exterminator.ScannerFunctionMk1(zombieCount,zombieDistance)

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

function Exterminator.ScannerFunctionMk2(zombieCount,zombieDistance)
	--display zombie scanner text
	local text_nearestZombie =  "Nearest Zombie = " .. zombieDistance .. " m";
	textManager:DrawString(UIFont.Large, screenX, screenY + 30, text_nearestZombie, 0.1, 0.8, 1, 1);

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

function Exterminator.OnEquipPrimary(character,item)
	--print("EXM:OnEquipPrimary")
	if not character:isLocalPlayer() then return end

	--Draw UI if scanner is equipped
	if Exterminator.isZombieScanner(item) then
		Events.OnPostUIDraw.Add(Exterminator.runZombieScanner)
	else
		Events.OnPostUIDraw.Remove(Exterminator.runZombieScanner)	
	end	
end

function Exterminator.isZombieScanner(item)
	if item then
		local itemName = item:getType();
		--local debugprint = "EXM:isZombieScanner Type =" .. itemName;
		--print(debugprint)	
		if itemName == "ZombieScannerMK1" or itemName == "ZombieScannerMK2" then			
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

function Exterminator.updateGridVisible(playerX,playerY)
	local gridAsize = 2500
	local gridBsize = 500
	local gridCsize = 100
	currentGridBx = floor(playerX/gridBsize)*gridBsize
	currentGridBy = floor(playerY/gridBsize)*gridBsize
	currentGridB = "B" .. currentGridBx .. '_' .. currentGridBy	
	currentGridCx = floor(playerX/gridCsize)*gridCsize
	currentGridCy = floor(playerY/gridCsize)*gridCsize
	currentGridC = currentGridBx .. '_' .. currentGridBy
	local gridCount = 1
	for i=-1,1,1 do
		currentgrids[i] = {}
		local iGridX = currentGridCx + (i*gridCsize)		
		for j=-1,1,1 do
			local iGridY = currentGridCy + (j*gridCsize)
			--test if point is valud
			local gridRef = iGridX .. "_" .. iGridY
			if  Exterminator.isGridPointValid(gridRef) then
			currentgrids[gridCount] = gridRef
			gridCount = gridCount + 1
			end
		end
	end	

end

function Exterminator.isGridPointValid(gridRef,gridX,gridY)
--TODO get Grid a
-- TODO get Grid B1
--TODO check grid exists
if ExterminatorGrid[gridRef] then

end

function Exterminator.CheckExistingCleared(symAPI,playerX,playerY)
  local distanceClearance = 175
  local isNew = true;
  local cnt = symAPI:getSymbolCount()

  --TODO need to count the total cleared here to get area cleared
  for i = 0, cnt - 1 do
	local sym = symAPI:getSymbolByIndex(i)
	local sym_x = sym:getWorldX();
	local sym_y = sym:getWorldY();
	local sym_texture = sym:getSymbolID();
	if sym_texture == clearedTexture then
		local distToSymbol = Exterminator.getDistanceToSymbol(playerX,playerY,sym_x,sym_y)
		if distToSymbol < distanceClearance then
			isNew = false;
			return isNew;
		end
	end
  end
	return isNew
end

function Exterminator.countCleared(symAPI)
	local countCleared = 0
	local cnt = symAPI:getSymbolCount()
	for i = 0, cnt - 1 do
		local sym = symAPI:getSymbolByIndex(i)
		local sym_texture = sym:getSymbolID();
		--local printDebug = "Exterminator.countCleared " .. sym_texture .. " " .. clearedTexture;
		--print(printDebug);
		if sym_texture == clearedTexture then
			countCleared = countCleared + 1
		end
	end
	clearedMarkers = countCleared;
end

function Exterminator.addClearedMarker (player,playerX,playerY)

	-- get current markers on map and count
	local symAPI = Exterminator.getSymAPI(item)
	local symbolCount = symAPI:getSymbolCount()	
	local isNew = Exterminator.CheckExistingCleared(symAPI,playerX,playerY)
	--local printDebug = "Exterminator.addClearedMarker SC=" .. symbolCount .. " isNew = " .. tostring(isNew);
	if isNew then
		local newSymbol = symAPI:addTexture(clearedTexture,playerX,playerY)
		if newSymbol then
			newSymbol:setAnchor(0.5, 0.5)
			newSymbol:setScale(0.5) --DEBUG set scale to 0.01 so it cant be deleted by player
			newSymbol:setRGBA(51, 255, 48, 200)
			Exterminator.ClearedAreaBeep() --play sound for area cleared
			Exterminator.countCleared(symAPI) -- recount the cleared markers
			if isClient() then
			sendClientCommand(player,Exterminator.MOD_ID,'AddClearedMarker',{playerX,playerY})
			print('Exterminator.addClearedMarker:SendClientCommand')
			end
		else
			print('Exterminator.addClearedMarker:Failed to create marker')
		end
	end
	--print(printDebug)
end

function Exterminator.recieveClearedMarker (playerX,playerY)

	-- get current markers on map and count
	local symAPI = Exterminator.getSymAPI(item)
	local symbolCount = symAPI:getSymbolCount()	
	local isNew = Exterminator.CheckExistingCleared(symAPI,playerX,playerY)
	--local printDebug = "Exterminator.addClearedMarker SC=" .. symbolCount .. " isNew = " .. tostring(isNew);
	if isNew then
		local newSymbol = symAPI:addTexture(clearedTexture,playerX,playerY)
		newSymbol:setAnchor(0.5, 0.5)
		newSymbol:setScale(5)
		newSymbol:setRGBA(51, 255, 48, 200)
		Exterminator.ClearedAreaBeep() --play sound for area cleared
		Exterminator.countCleared(symAPI) -- recount the cleared markers		
	end
	--print(printDebug)
end

function Exterminator.makeKey(x, y)
  return string.format("%.5f_%.5f", x, y)
end

function Exterminator.existingLookup(tabl, x, y)
  local key = Exterminator.makeKey(x, y)
  return tabl[key]
end

function Exterminator.getDistanceToSymbol(playerX,playerY,symbolX,symbolY)
	distanceToZombie = math.sqrt((math.pow(symbolX-playerX,2)+math.pow(symbolY-playerY,2)));
	return distanceToZombie
end

function Exterminator.getVisibleCleareanceGrids(playerX,playerY)
	--TODO
end

function Exterminator.onServerCommand(module, command, args)
	--Check if this command if for our mod otherwise exit
	if module ~= Exterminator.MOD_ID then
		return
	end

	-- debug
	print( ('Exterminator.onServerCommand Command= "%s"'):format(command) )

	--add a cleared marker to the players map from another player.
	if command == 'AddClearedMarker' then
	print('Exterminator.onServerCommand.recieveClearedMarker')
	Exterminator.recieveClearedMarker(args[1],args[2])
	end
end

--required to initialise the mod
Events.OnGameStart.Add(Exterminator.Initialize)






