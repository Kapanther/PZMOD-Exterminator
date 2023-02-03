local doZombieDebugScan = true -- set to true to run giant map scan
local lastDebugScan = -1
local lastDebugScanInterval = 2 -- time in ms to do debugscan
local debugScanMinX = 0
local debugScanMaxX = 19800
local debugScanMinY = 0
local debugScanMaxY = 15900
local debugScanStartX = 50
local debugScanStartY = 50
local debugScanCurrentX = debugScanStartX
local debugScanCurrentY = debugScanStartY
local debugScanMoveIntervalX = 100
local debugScanMoveIntervalY = 100
local debugFileOutputPath = 'TileDataScan.txt'

function Exterminator.ZombieDebugScan()
	if lastDebugScan < 0 then
	-- get the player
	local player = getSpecificPlayer(0);
		if player then
			currentZ = 0 --needs to be a field to work.
			--run the scan
			Exterminator.getZombieScanData(debugScanCurrentX,debugScanCurrentY)
			--get total zombies
			local stat_totalZombies = cache_zombieCount
			--get valid tile check (water is accesible etc)
			local world = getWorld();
			local zoneName = debugScanCurrentX .. debugScanCurrentY;
			local zone = getWorld():registerZone(zoneName,"EXM",debugScanCurrentX,debugScanCurrentY,currentZ,debugScanMoveIntervalX,debugScanMoveIntervalY);
			local square = getSquare(debugScanCurrentX,debugScanCurrentY,currentZ);
			local stat_groundType 
			if square then
			local hasWater = square:getFloor():hasWater();
				if hasWater then
					stat_groundType = "Water";	
				else
					stat_groundType = "Ground";
				end
			else
			stat_groundType = "Unknown";
			end

			--get zombie density
			local stat_zombieDensity = zone:getZombieDensity()

			--dispose zone
			zone:Dispose();

			--write to log and file 
			local debugLog = getFileWriter(debugFileOutputPath,true,true)

			local stat_logtext = zoneName .."," .. debugScanCurrentX .."," .. debugScanCurrentY .."," .. stat_groundType .."," .. stat_totalZombies .."," .. stat_zombieDensity .. "\n";
			debugLog:write(stat_logtext)
			debugLog:close()
			print(stat_logtext)
			
			--next tile logic
			debugScanCurrentX = debugScanCurrentX + debugScanMoveIntervalX
			if debugScanCurrentX > debugScanMaxX then
				debugScanCurrentX = debugScanStartX
				debugScanCurrentY = debugScanCurrentY + debugScanMoveIntervalY
				if debugScanCurrentY > debugScanMaxY then
					--end the scan
					Events.OnPostUIDraw.Remove(Exterminator.ZombieDebugScan)
				end
			end
			lastDebugScan = lastDebugScanInterval
			Exterminator.TeleportPlayer(debugScanCurrentX,debugScanCurrentY)
		end
	else
	lastDebugScan = lastDebugScan - 1
	end
end

function Exterminator.TeleportPlayer(playerX,playerY)
	local player = getPlayer();
		if player then
			currentX = floor(playerX)
			currentY = floor(playerY)
			currentZ = 0
			--teleport the player to currentX Y
			player:setX(currentX) 
			player:setY(currentY)
			player:setZ(currentZ)
			player:setLx(currentX) 
			player:setLy(currentY)
			player:setLz(currentZ)
		end
end