
--***********************************************************
--**                    EXTERMINATOR                       **
--***********************************************************
-- Custom Functions for battery removal and insertion dismantiing etc..
--Recipe = Recipe or {}
-- Recipe.OnTest = Recipe.OnTest or {}
-- Recipe.OnCreate = Recipe.OnCreate or {}

-- Return true if recipe is valid, false otherwise
function Recipe.OnTest.ZombieScannerBatteryRemoval (sourceItem, result)
	return sourceItem:getUsedDelta() > 0;
end

-- When creating item in result box of crafting panel.
function Recipe.OnCreate.ZombieScannerBatteryRemoval(items, result, player)
	for i=0, items:size()-1 do
		local item = items:get(i)
		-- we found the battery, we change his used delta according to the battery
		if item:getType() == "ZombieScannerMK1" or item:getType() == "ZombieScannerMK2" then
			result:setUsedDelta(item:getUsedDelta());
			-- then we empty the torch used delta (his energy)
			item:setUsedDelta(0);
		end
	end
end

-- Return true if recipe is valid, false otherwise
function Recipe.OnTest.ZombieScannerBatteryInsert(sourceItem, result)
	if sourceItem:getType() == "ZombieScannerMK1" or sourceItem:getType() == "ZombieScannerMK2" then
		return sourceItem:getUsedDelta() == 0; -- Only allow the battery inserting if the zombie scanner has no battery left in it.
	end
	return true -- the battery
end

-- When creating item in result box of crafting panel.
function Recipe.OnCreate.ZombieScannerBatteryInsert(items, result, player)
  for i=0, items:size()-1 do
	-- we found the battery, we change his used delta according to the battery
	if items:get(i):getType() == "Battery" then
		result:setUsedDelta(items:get(i):getUsedDelta());
	end
  end
end

function Recipe.OnCreate.DismantleZombieScanner(items, result, player)
	for i=1,items:size() do
		local item = items:get(i-1)
		if item:getType() == "ZombieScannerMK1" or item:getType() == "ZombieScannerMK2" then
			if item:getUsedDelta() > 0 then
				local battery = player:getInventory():AddItem("Base.Battery")
				if battery then
					battery:setUsedDelta(item:getUsedDelta())
				end
			end
			break
		end
	end
end

-- You can't dismantle favorite item
function Recipe.OnTest.DismantleZombieScanner(sourceItem, result)
	local typeName = sourceItem:getType();
	if typeName == "ZombieScannerMK1" or typeName == "ZombieScannerMK2" then return true end
    return not sourceItem:isFavorite()
end