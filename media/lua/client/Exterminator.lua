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
		cache_nearestZombieDistance = minDistanceToZombie;
	end
end

function Exterminator.getDistanceToZombie(playerX,playerY,zombieX,zombieY)
	distanceToZombie = math.sqrt((math.pow(zombieX-playerX,2)+math.pow(zombieY-playerY,2)));
	return distanceToZombie
end

function Exterminator.drawZombieCount()
	--print("EXM:drawZombieCount")
	local player = getPlayer()
	--Check if they are holding a zombie scanner
	if player then
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
		if Exterminator.isZombieScanner(item) then
			Events.OnPostUIDraw.Add(Exterminator.drawZombieCount)
		else
			Events.OnPostUIDraw.Remove(Exterminator.drawZombieCount)
		end	
end



function Exterminator.isZombieScanner(item)
	if item then
		local itemName = item:getType();		
		local debugprint = "EXM:isZombieScanner Type =" .. itemName;
		print(debugprint)	
	end
	return instanceof(item, "DrainableComboItem")-- and item:getType
end

Events.OnGameStart.Add(Exterminator.Initialize)






