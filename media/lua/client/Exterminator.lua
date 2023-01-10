if EXM then
	return print("ERROR: Can't enable Exterminator MOD because it is already enabled!")
end
EXM = {}
local EXM_DATA = EXM

local textManager = getTextManager();

local screenX = 65;
local screenY = 13;

local cache_celldata = 0
local cache_cnt_room_sq = 0

local function getCellData()	
	--Cell Data
	local celldata = getWorld():getCell():getZombieList():size();
	EXM_DATA.celldata = celldata	
	if celldata then
		cache_celldata = celldata
		else
		cache_celldata = 0
	end
end

local cache_count = ""

local function drawZombieCount()	
	if cache_celldata then	
		cache_count =  "Zcount = " .. cache_celldata
		textManager:DrawString(UIFont.Large, screenX, screenY, cache_count, 0.1, 0.8, 1, 1);
	end
end

Events.OnGameStart.Add(function()
	Events.OnPostUIDraw.Add(drawZombieCount);
end)

Events.OnCreatePlayer.Add(function()
	CellData = getCellData()	
end)


