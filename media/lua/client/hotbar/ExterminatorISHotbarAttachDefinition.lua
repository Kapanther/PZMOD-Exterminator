require "Hotbar/ISHotbarAttachDefinition"

if not ISHotbarAttachDefinition then
    return
end

--taken from better flashlights mode.. thank you!!
local MiningHelmet = {
	type = "MiningHelmet",
	name = "Mining Helmet with Mount",
	animset = "back",
	attachments = {
		HeadLight			= "OnMiningHelmetHeadLight",
	},
}
table.insert(ISHotbarAttachDefinition, MiningHelmet);