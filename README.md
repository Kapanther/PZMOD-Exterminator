# Exterminator - Project Zomboid Mod
## Overview 
Exterminator is a Project Zomboid mod that will add mechanics to the game to allow players to remove all of the zombies from the map as a victory condition. This includes various zombie scanners and lures as well as Map features to track clearance of zombies.

The plan is to develop the following
- Modify game settings to ensure clearance is possible
- A means of recording on the in game map that a grid zone has been cleared
- A notification to players that the victory condition has been met
- Devices that can be crafted, 
  -"Zombie Scanner". This device might have two versions, the MK1 jsut beeps, and the MK2 gives a count or shows bleeps on a minimap within a certain raidius
  -"Zombie Lure". This device might attract the zombies and explode. Maybe it has a minor chance of turning a zombie into a runner zombie.

## Modified Game Settings
The following settings will need to be modified/checked to ensure the mod can work correctly.
- No Zombie respawns
- Maximum Amount of zombies (Population modified will need to be reduced or capped to ensure not to many spawn) 
  a modifier value of 1 supposedly generateds 52000 zombies map-wide. So im guessing you would not want to go over about 3.
- Possibly other map settings will need to be modified
- Add option to have an "Escape from the city" start. (This could mean performance problems with the server though.) 

## In Game Map - Cleared Status
The maps has grid squares 300x300 tiles that can be cleared by players exterminating all the zombies. This is managed by the mod by adding a colour or outline to each map grid to indicate it has been cleared. Zombies from other grid squares may wander into these squares again. (consider handling for this later)

## Notificaion of Victory Conditions
Notify players when all zombies have been Exterminated

## Zombie Scanner
The scanner will required the electronics skill to create and the an electronics workbench. Plus key components listed below.

##Zombie Scanner - MK1
###Features
Beeps get closer together as you get closer to a zombie
70m range

###Required Tools / Ingredients / Skills
- 1x Powercord
- 1x Radio
- 1x Computer
- 1x Metal Tool Box
- 1x Battery

##Zombie Scanner - MK2
###Features
Beeps get closer together as you get closer to a zombie
A count is displayed to the user of zombies present
100m range

###Required Tools / Ingredients / Skills
- 1x Powercord
- 1x Radio
- 1x Ham Radio
- 2x Computer
- 1x Metal Tool Box
- 1x Battery

## Installation Instructions
Copy all of these files into the 

""c:\users\<username>\Zomboid\Mods\Exterminator" 

folder (create folder if it doesnt exist)
