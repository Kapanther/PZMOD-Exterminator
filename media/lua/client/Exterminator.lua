if EXM then
	return print("ERROR: Can't enable Exterminator MOD because it is already enabled!")
end
EXM = {}
local EXM_DATA = EXM

local textManager = getTextManager();
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
local isScannerOnMK1 = false
local eventUI = ""

local function getCellData(playerX,PlayerY)	
	--Cell Data
	local celldata = getWorld():getCell():getZombieList():size();
	EXM_DATA.celldata = celldata	
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

local function drawZombieCount()
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
		textManager:DrawString(UIFont.Large, screenX, screenY + 90, tostring(isScannerOnMK1), 0.1, 0.8, 1, 1);
	end
end

local function checkZombieScannerMK1(player_)

	if player_ then
		local primaryItem = player_:GetPrimaryEquippedCache():getName();
		local secondaryItem = player_:GetSecondaryEquippedCache():getName();
		if primaryItem == "ZombieScannerMK1" then
			return true
		elseif secondaryItem == "ZombieScannerMK1" then
			return true
		else
			return false
		end
	else
	return false
	end
end

Events.OnEquipPrimary.Add(function()
	isScannerOnMK1 = checkZombieScannerMK1(player)
end)

Events.OnEquipSecondary.Add(function()
	isScannerOnMK1 = checkZombieScannerMK1(player)
end)

Events.OnGameStart.Add(function()
	Events.OnPostUIDraw.Add(drawZombieCount);
end)

Events.OnCreatePlayer.Add(function()
	player = getPlayer()	
end)



