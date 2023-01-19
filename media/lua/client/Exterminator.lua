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

local isHoldingScanner = false
local textManager = getTextManager();

function Exterminator.Initialize()

	--add zombie scanner check to equip Primary or secondary
	Events.OnEquipPrimary.Add(Exterminator.checkZombieScannerEquipped)
	Events.OnEquipSecondary.Add(Exterminator.checkZombieScannerEquipped)

	--check if we are currently holding a zombie scanner	
	if getPlayer() then
		player = getPlayer()
		Exterminator.checkZombieScannerEquipped()
	end
end

local player = nil
local screenX = 65;
local screenY = 13;
local cache_celldata = 0
local cache_gridZombieDensity = 0
local cache_gridZombieSpawned = 0
local text_count = ""
local text_density = ""
local text_spawned = ""
local floor = math.floor
local primaryItem = ""
local secondaryItem = ""

function getCellData(playerX,PlayerY)	
	--Cell Data
	local celldata = getWorld():getCell():getZombieList():size();		
	if celldata then
		cache_celldata = celldata
		else
		cache_celldata = 0
	end
	local gridZombieDensity = getWorld():getMetaGrid():getZoneAt(playerX,PlayerY,0):getZombieDensity();
	if gridZombieDensity then
		cache_gridZombieDensity = gridZombieDensity
		else
		cache_gridZombieDensity = 99999
	end
	local gridZombiesSpawned = getWorld():getMetaGrid():getZoneAt(playerX,PlayerY,0).spawnedZombies
	if gridZombiesSpawned then
		cache_gridZombieSpawned = 11111 -- TODO get the acutal spawned from the hashmap
		else
		cache_gridZombieSpawned = 99999
	end
end

function Exterminator.drawZombieCount()
	--Check if they are holding a zombie scanner
	if player then		
		local playerX = floor(player:getX()); --because getX returns float
		local playerY = floor(player:getY());
		getCellData(playerX,playerY)
		text_count =  "Zcount = " .. cache_celldata
		text_density =  "Density = " .. cache_gridZombieDensity
		text_spawned =  "Spawned = " .. cache_gridZombieSpawned
		textManager:DrawString(UIFont.Large, screenX, screenY, text_count, 0.1, 0.8, 1, 1);
		textManager:DrawString(UIFont.Large, screenX, screenY + 30, text_density, 0.1, 0.8, 1, 1);
		textManager:DrawString(UIFont.Large, screenX, screenY + 60, text_spawned, 0.1, 0.8, 1, 1);
	end
end

function Exterminator.onRenderTick()
	Events.OnRenderTick.Add(function() 
	Events.OnPostUIDraw.Add(Exterminator.drawZombieCount);
	end)
end

function Exterminator.checkZombieScannerEquipped()
	if player then
		primaryItem = player:getPrimaryHandItem()
		secondaryItem = player:getSecondaryHandItem()
		--if primaryItem == "ZombieScannerMK1" then		
		    --TODO fix this so it is a function that can be added and removed
			Exterminator.onRenderTick()
			--return true
		--elseif secondaryItem == "ZombieScannerMK1" then
			--Events.OnPostUIDraw.Add(drawZombieCount); --TODO fix this so it is a function that can be added and removed
		--elseaaaaaaaa
			--return false
		--end
	end
end

Events.OnGameStart.Add(Exterminator.Initialize)






