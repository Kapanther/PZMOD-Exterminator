require "Definitions/AttachedWeaponDefinitions"
-- attachments for zombie scanner

AttachedWeaponDefinitions.ZombieScannerMK1 = {
	id = "ZombieScanner",
	chance = 100,
	--outfit = {"AuthenticB4BEvangelo", "AuthenticB4BHoffman","AuthenticB4BMom", "AuthenticB4BHolly", "AuthenticB4BWalker"},
	weaponLocation = {"Zombie Scanner Left", "Zombie Scanner Right"},
	bloodLocations = nil,
	addHoles = false,
	daySurvived = 0,
	weapons = {    "Exterminator.ZombieScannerMK1",	"Exterminator.ZombieScannerMK2",},
}