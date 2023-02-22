Distributions = Distributions or {};

-- Function made by star -- 
local function AddProcLoot(proc_name, item_name, chance)
	local data = ProceduralDistributions.list
	if not data then
		 return print('Exterminator ERROR: procedure distributions not found!')
	end
	local c = data[proc_name];
	if not c then
		 return print('Exterminator ERROR: cant add '..item_name..' to procedure '..proc_name)
	end
	table.insert(c.items, item_name);
	table.insert(c.items, chance);
end

--Mining Helmet
AddProcLoot("ArmyStorageElectronics",	"BetterFlashlights.Hat_HardHat_Miner_With_Light", 3.0); 
AddProcLoot("ArmySurplusTools",			"BetterFlashlights.Hat_HardHat_Miner_With_Light", 0.1); 
AddProcLoot("ArmySurplusHeadwear",	"BetterFlashlights.Hat_HardHat_Miner_With_Light", 3.0);  	
AddProcLoot("ToolStoreMisc",		"BetterFlashlights.Hat_HardHat_Miner_With_Light", 1.0);
AddProcLoot("ToolStoreTools",		"BetterFlashlights.Hat_HardHat_Miner_With_Light", 0.01);             
AddProcLoot("FactoryLockers",		"BetterFlashlights.Hat_HardHat_Miner_With_Light", 0.2);       
AddProcLoot("GarageTools",			"BetterFlashlights.Hat_HardHat_Miner_With_Light", 0.01);         	
AddProcLoot("GigamartTools",		"BetterFlashlights.Hat_HardHat_Miner_With_Light", 0.2);      		