require "ISUI/ISUIElement"

ISscannerPanel = ISPanel:derive("ISscannerPanel")

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)

local COLORS = {
	none = Color.new(0,0,0,0),
	untreated = Color.new(1,0,0,1),
	bandaged = Color.new(0.78,0.69,0.6,1),
	healed = Color.new(0.8,1,0.6),
	dirty = Color.new(1,0.57,0.11,1),
}

function ISscannerPanel:new(playerIndex,player,enabled)
	local bw = 160 --Width of scanner back
	local bh = 200 -- height of scanner backgroiund

	local panelInstance = {}
	panelInstance = ISPanel:new(25, getCore():getScreenHeight() - bh - 25, bw, bh)
	setmetatable(panelInstance, self)
	self.__index = self

	panelInstance.playerIndex = playerIndex
	panelInstance.player = player
	panelInstance.player_isDead = false	

	panelInstance.colour = {r=0,g=1,b=0}
	panelInstance.alpha = 1.0
	panelInstance.bgAlpha = 0
	panelInstance.blinkTime = 0
	panelInstance.blinkAlpha = 0
	panelInstance.isHover = false
	panelInstance.baseWidth = bw
	panelInstance.baseHeight = bh
	panelInstance.canHide = false
	panelInstance.hideTimer = 100
	panelInstance.isOpen = true

	--Key Zombie Scanner Variables
	panelInstance.currentGridStatus = "No Data"
	panelInstance.scannerEquipped = "No Scanner Equipped"
	panelInstance.zombieCount = "Z = 0"
	panelInstance.nearestZombieDistance = " XX m"
	panelInstance.nearestZombieAngle = 135
	panelInstance.batteryRemaining = 0.1	
	panelInstance.totalClearedStatus = "No Data"

	panelInstance.moveWithMouse = true	
	panelInstance.rightMouseDown = false
	panelInstance.dragging = false

	panelInstance.backgroundColor = 	{r=0.0, g=0.0, b=0.0, a=0.5}
	panelInstance.borderColor = 		{r=0.4, g=0.4, b=0.4, a=1}
	panelInstance.colour_black = 		{r=0.0, g=0.0, b=0.0, a=1.0}

	panelInstance.outlineTex = getTexture("media/ui/ScannerOutline.png")
	panelInstance.backgroundTex = getTexture("media/ui/ScannerBackground.png")
	panelInstance.directionTex = getTexture("media/ui/ScannerDirection.png")
	panelInstance.batteryOutlineTex = getTexture("media/ui/BatteryOutline.png")
	

	panelInstance.bottomHeight = getTextManager():getFontHeight(UIFont.Small)

	panelInstance.CONFIG_VERSION = 1
	panelInstance.alwaysShow = false	
    panelInstance.settingsPanel = nil	

	panelInstance.enabled = enabled
	panelInstance:setVisible(enabled)

	return panelInstance
end

function ISscannerPanel:initialize()
	ISUIElement.initialise(self)

    self.cacheColor = Color.new(  1.0,  1.0, 1.0, 1.0 )

	--possibly make the connection ot variables here TODO
end

function ISscannerPanel:createChildren()
	local btnWid = 25
	local btnHgt = getTextManager():getFontHeight(UIFont.Small) - 1

    self.topPanel = ISPanel:new(0, 0, self.baseWidth, btnHgt)
    self.topPanel.backgroundColor =  {r=0.0, g=0.0, b=0.0, a=0.0}
    self.topPanel.borderColor = 		{r=0.0, g=0.0, b=0.0, a=0.0}
    self:addChild(self.topPanel)
    self.topPanel:setVisible(false)

    self.gearButton = ISButton:new(0, 0, btnWid, btnHgt, "", self, ISscannerPanel.onGearButton)
    self.gearButton:initialise()
	self.gearButton.borderColor = {r=0.4, g=0.4, b=0.4, a=1}
    self.gearButton:setImage(getTexture("media/ui/Panel_Icon_Gear.png"))
	self.topPanel:addChild(self.gearButton)
end

function ISscannerPanel:addSettingsPanel()
    local panel

    panel = ISscannerPanelSettings:new(self:getX(),self:getY()+self:getHeight()+2,self:getWidth())
    panel:initialise();
	panel:instantiate();
	panel:createChildren();
    panel:populateOptions();
	panel:addToUIManager();
	panel:setOpen(false);

    self.settingsPanel = panel
end

function ISscannerPanel:settingsPanelPos()
	local x = self:getX()
	local y = self:getY()-self.settingsPanel:getHeight()-2
	local width = self:getWidth()

	if y < 1 then
		y = self:getY() + self:getHeight() + 2
	end

	return x,y,width
end

function ISscannerPanel:onGearButton()
    if not self.player_isDead then
		local x,y,width = self:settingsPanelPos()

        if self.settingsPanel:getOpen() == false then
            self.settingsPanel:setOpen(true, x ,y , width)
        else
            self.settingsPanel:setOpen(false, 0, 0 , 0)
        end
    end
end

function ISscannerPanel:toggleAlwaysShow(selected)
    self.alwaysShow = selected
end

function ISscannerPanel:toggleLock(selected)
	self.moveWithMouse = selected
end

function ISscannerPanel:prerender()
	-- draws the outside frame of the panel
	self:drawRectStatic(0, 0, self.width, self.height, self.backgroundColor.a * self.bgAlpha, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
	self:drawRectBorderStatic(0, 0, self.width, self.height, self.borderColor.a * self.bgAlpha, self.borderColor.r, self.borderColor.g, self.borderColor.b);
	
	-- draws the background texture of the panel
	self:drawTexture(self.backgroundTex,0,0, 0.5 * self.alpha, 0, 0, 0)
	
	-- drawings the rings
	local outlineColor = 200 --TODOa consider changing the color of ring based on distance to zombie
	self:drawTexture(self.outlineTex,0,0, 1 * self.alpha, 1, outlineColor, outlineColor)
	


	
	-- enables disables background on mouse hover

	if self:isMouseOver() or self.settingsPanel:getOpen() then
		self.isHover = true
		self.bgAlpha = 1
		self.hideTimer = 30
		self.alpha = 1
        self.topPanel:setVisible(true)
	else
		self.isHover = false
		self.bgAlpha = 0
        self.topPanel:setVisible(false)
	end
end

function ISscannerPanel:render()
	
	local blinking = 0

	--TODO blinking battery light
	if blinking > 0 then
		self.blinkTime = self.blinkTime + 1
		self.blinkAlpha = math.abs(math.sin(self.blinkTime/10))
	else
		self.blinkTime = 0
		self.blinkAlpha = 0
	end

	-- add the zombie direction marker
	local angleColor = 100
	self:DrawTextureAngle(self.directionTex,80,80,self.nearestZombieAngle,0,angleColor,0,1)

	-- place the zombie stat text
	self:drawTextCentre(self.zombieCount,80,50,0,250,0,1)
	self:drawTextCentre(self.nearestZombieDistance,80,85,0,250,0,1)

	-- place the zombie cleareance text
	self:drawText(self.currentGridStatus,25,self.baseHeight-43,0,250,0,1)
	self:drawText(self.totalClearedStatus,25,self.baseHeight-23,0,250,0,1)

	--TODO battery outline
	--TODO change color and blink if about to die
	local batteryMax = 22	
	local batteryHeight = batteryMax * self.batteryRemaining*-1
	local batteryColor = math.floor(252 * self.batteryRemaining)
	local batteryWarningColor = 254
	if self.batteryRemaining < 0.1 then
		batteryWarningColor = 0
	end
	self:drawTexture(self.batteryOutlineTex,1,self.baseHeight-36,1 * self.alpha,254,batteryWarningColor,batteryWarningColor) --draws outline	
	self:drawRectStatic( 4,self.baseHeight-3,8,batteryHeight,0.5 * self.alpha,100,batteryColor,0)		
	
		-- hide back ground
	if not self.isHover then
		if self.hideTimer <= 0 then
			self.alpha = math.max(self.alpha - 0.05,0)
		else
			self.alpha = math.min(self.alpha + 0.05,1)
		end
	end
end


function ISscannerPanel:update()
	--This is where the update panel code getBodyParts
	--print("PANELMANupdating")

end

-- ===== Handle player death =====

function ISscannerPanel:getPlayer()
	return self.player
end

function ISscannerPanel:setPlayerIsDead(isDead)
	self.player_isDead = isDead

    if self.settingsPanel:getOpen() then
        self.settingsPanel:setOpen(false, 0, 0, 0)
    end
end

function ISscannerPanel:getPlayerIsDead()
	return self.player_isDead
end

function ISscannerPanel:setPlayer(playerIndex,player)
	self.playerIndex = playerIndex
	self.player = player
	self:setPlayerIsDead(false)	
end

-- ===== Handle screen resolution change =====
function ISscannerPanel:checkNewResolution()
	local screenH = getCore():getScreenHeight()
	local screenW = getCore():getScreenWidth()

	local posX = self.x
	local posY = self.y
	local width = self.width
	local height = self.height

	if (posX + width) > screenW then
		self:setX(screenW - width)
	end

	if (posY + height) > screenH then
		self:setY(screenH - height)
	end
end

-- ===== Open health panel (and prevent it if moving the mini panel) =====

function ISscannerPanel:onMouseDown(x,y)
	self.rightMouseDown = true

	ISPanel.onMouseDown(self, x, y)
end

function ISscannerPanel:onRightMouseUp(x,y, ...)
	if not self.player_isDead then
		--
	end
end

function ISscannerPanel:onMouseMove(dx, dy)
	if self.rightMouseDown == true then
		self.dragging = true
	end

	if self.dragging then
		if self.settingsPanel:getOpen() then
			local x,y = self:settingsPanelPos()
			self.settingsPanel:setX(x)
			self.settingsPanel:setY(y)
		end
	end

	ISPanel.onMouseMove(self, dx, dy)
end

function ISscannerPanel:onMouseUp(x,y)

	if not self.dragging and not self.player_isDead then
		getSoundManager():playUISound("UISelectListItem")		
	end

	self.dragging = false
	self.rightMouseDown = false

	ISPanel.onMouseUp(self, x, y)
end

-- ===== Config =====

function ISscannerPanel:initConfig()
	if panelInstance:readConfig() == true then
		panelInstance:writeConfig()
	end

	-- TODO [possibly store other stats here in the future]
end

function ISscannerPanel:readConfig()
	local fileStream, readLine, splitLine, failed, readConfigVersion;
	failed = true;
	readConfigVersion = false;

	fileStream = getFileReader("EXMScanner_conf.ini", true);
	if fileStream ~= nil then
		print("ISscannerPanel(): config file for reading...")
		readLine = fileStream:readLine();

		if readLine ~= nil then
			failed = false;

			while readLine ~= nil do
				--print("ISExpBar(): Read line as: ", readLine);

				splitLine = string.split(readLine, "=");
				if splitLine~=nil and #splitLine==2 then
					if not readConfigVersion then
						if splitLine[1] == "CONFIG_VERSION" and tonumber(splitLine[2]) == self.CONFIG_VERSION then
							readConfigVersion = true;
							print("ISscannerPanel(): Read CONFIG_VERSION as current version:", splitLine[2], self.CONFIG_VERSION);
						else
							print("ISscannerPanel(): Read CONFIG_VERSION as incorrect version:", splitLine[2], self.CONFIG_VERSION);
							failed = true;
							break;
						end
					else

						if splitLine[1] == "pos_x" then
							local posX = tonumber(splitLine[2])
							self:setX(posX)
						elseif splitLine[1] == "pos_y" then
							local posY = tonumber(splitLine[2])
							self:setY(posY)
						elseif splitLine[1] == "alwaysShow" and splitLine[2] == "true" then
							self.alwaysShow = true
						elseif splitLine[1] == "moveWithMouse" and splitLine[2] == "false" then
							self.moveWithMouse = false
						end
					end

				else
					print("ISscannerPanel(): Could not parse line: ", splitLine);
				end
				readLine = fileStream:readLine();
			end
		else
			print("ISscannerPanel():: Failed to read config file...")
		end

		fileStream:close();
		print("ISscannerPanel(): Closed config file.")
	else
		print("ISscannerPanel(): Failed to open config file for reading...")
	end

	return failed;
end

function ISscannerPanel:writeConfig()
	local fileStream;
	fileStream = getFileWriter("EXMScanner_conf.ini", true, false);

	if fileStream ~= nil then
		print("ISscannerPanel(): Opened config file for writing...")
		
		fileStream:write("CONFIG_VERSION="..tostring(self.CONFIG_VERSION).."\n");
		fileStream:write("pos_x="..tostring(self:getX()).."\n");
		fileStream:write("pos_y="..tostring(self:getY()).."\n");
		fileStream:write("alwaysShow="..tostring(self.alwaysShow).."\n");		
		fileStream:write("moveWithMouse="..tostring(self.moveWithMouse).."\n");

		fileStream:close();
		print("ISscannerPanel(): Closed config file.")
	else
		print("ISscannerPanel(): Failed to open config file for writing...")
	end

end