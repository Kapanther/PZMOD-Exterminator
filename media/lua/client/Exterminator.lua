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

local textManager = getTextManager();

function Exterminator.Initialize()
	print("EXM:Initialize")
	--add zombie scanner check to equip Primary or secondary
	Events.OnEquipPrimary.Add(Exterminator.OnEquipPrimary)
	--Events.OnEquipSecondary.Add(OnEquipPrimary)	

	--check if we are currently holding a zombie scanner	
	if getPlayer() and getPlayer():getPrimaryHandItem() then		
		Exterminator.OnEquipPrimary(getPlayer(),getPlayer():getPrimaryHandItem())
	end
end

local screenX = 65;
local screenY = 13;
local cache_zombieCount = 0;
local cache_gridZombieDensity = 0;
local cache_nearestZombieDistance = 9999;
local text_count = "";
local text_density = "";
local text_spawned = "";
local floor = math.floor;
local primaryItem = "";
local secondaryItem = "";

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
	local gridZombieDensity = getWorld():getMetaGrid():getZoneAt(playerX,playerY,0):getZombieDensity();
	if gridZombieDensity then
		cache_gridZombieDensity = gridZombieDensity
		else
		cache_gridZombieDensity = 99999
	end
	local zombie = nil;
	local minDistanceToZombie = 99999
	local distanceToZombie = 99999
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
					minDistanceToZombie = distanceToZombie;
				end
			end
        end
	else
		--zombie count is zero add marker to map
	end
	cache_nearestZombieDistance = minDistanceToZombie;
end

function Exterminator.getDistanceToZombie(playerX,playerY,zombieX,zombieY)
	distanceToZombie = math.sqrt((math.pow(zombieX-playerX,2)+math.pow(zombieY-playerY,2)));
	return distanceToZombie
end

function Exterminator.drawZombieCount()
	--print("EXM:drawZombieCount")
	local player = getPlayer();	
	local itemOn = getPlayer():getPrimaryHandItem():isEmittingLight();
	local printDebug = "EXM:drawZombieCount:ItemOn = " .. tostring(itemOn);
	print(printDebug)
	--Check if they are holding a zombie scanner
	if player and itemOn then
		--print("EXM:drawZombieCount:playerFound")
		local playerX = floor(player:getX()); --because getX returns float
		local playerY = floor(player:getY());
		Exterminator.getZombieScanData(playerX,playerY)
		text_zombieCount =  "Zombie Count = " .. cache_zombieCount
		text_nearestZombie =  "Nearest Zombie = " .. cache_nearestZombieDistance .. " m"
		textManager:DrawString(UIFont.Large, screenX, screenY, text_zombieCount, 0.1, 0.8, 1, 1);
		textManager:DrawString(UIFont.Large, screenX, screenY + 30, text_nearestZombie, 0.1, 0.8, 1, 1);
	end
end

function Exterminator.OnEquipPrimary(character,item)
	--print("EXM:OnEquipPrimary")
	if not character:isLocalPlayer() then return end

	--Draw UI if scanner is equipped
	if Exterminator.isZombieScanner(item) then
		Events.OnPostUIDraw.Add(Exterminator.drawZombieCount)
	else
		Events.OnPostUIDraw.Remove(Exterminator.drawZombieCount)	
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

function Exterminator.getSymAPI(map_item)
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

  return map_api:getSymbolsAPI()
end

function Exterminator.existingTable(symAPI)
  local existing = {}
  local cnt = symAPI:getSymbolCount()
  for i = 0, cnt - 1 do
    local sym = symAPI:getSymbolByIndex(i)
    local key = Lib.makeKey(sym:getWorldX(), sym:getWorldY())
    existing[key] = {i, sym}
  end
  return existing
end

function Exterminator.addClearedMarker (player,playerX,playerY)
	-- get current markers on map
	local worldMarkers = getWorldMarkers();
	--local clearedPoints = worldMarkers:getHomingPoint
	--if no makrers continue
	--if worldMarkers 
		--if markers check we are furthern than 100m from a marker..
		--if we are add a marker



end

Events.OnGameStart.Add(Exterminator.Initialize)






