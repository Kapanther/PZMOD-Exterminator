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
		Exterminator.OnEquipPrimary(getPlayer())
	end
end

local screenX = 65;
local screenY = 13;
local cache_zombieCount = 0;
local cache_gridZombieDensity = 0;
local cache_nearestZombieDistance = 0;
local text_count = "";
local text_density = "";
local text_spawned = "";
local floor = math.floor;
local primaryItem = "";
local secondaryItem = "";

function Exterminator.getZombieScanData(playerX,PlayerY)
	--print("EXM:getCellData")
	--Cell Data
	local zombieCount = getWorld():getCell():getZombieList():size();		
	if zombieCount then
		cache_zombieCount = zombieCount
		else
		cache_zombieCount = 0
	end
	local gridZombieDensity = getWorld():getMetaGrid():getZoneAt(playerX,PlayerY,0):getZombieDensity();
	if gridZombieDensity then
		cache_gridZombieDensity = gridZombieDensity
		else
		cache_gridZombieDensity = 99999
	end
	if zombieCount > 0 then
		local zombieList = getPlayer();
		--for zombies = 1,zombieCount do
			--zombie = zombieList:get(zombies);
			print("ClosestZombie")
		--end
		cache_nearestZombieDistance = 9999
	end
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
		text_zombieCount =  "Zcount = " .. cache_zombieCount
		text_nearestZombie =  "Nearest Zombie = " .. cache_nearestZombieDistance
		textManager:DrawString(UIFont.Large, screenX, screenY, text_zombieCount, 0.1, 0.8, 1, 1);
		textManager:DrawString(UIFont.Large, screenX, screenY + 30, text_nearestZombie, 0.1, 0.8, 1, 1);
	end
end

function Exterminator.OnEquipPrimary(player)
	--print("EXM:OnEquipPrimary")
	if not player:isLocalPlayer() then return end
		if Exterminator.isZombieScanner(getPlayer():getPrimaryHandItem()) then
			Events.OnPostUIDraw.Add(Exterminator.drawZombieCount)
		else
			Events.OnPostUIDraw.Remove(Exterminator.drawZombieCount)
		end	
end

function Exterminator.isZombieScanner(item)
	print("EXM:isZombieScanner")
    return instanceof(item, "DrainableComboItem")-- and item:getType()
end

Events.OnGameStart.Add(Exterminator.Initialize)






