---@class LLib
LLib = {}
local BASE_MENU <const> = {
	white = {228, 233, 228}, -- Better white for RedM
	black = {0,0,0},
	KeyFilter = 0x3B24C470,
	defaultButton = { { name = "None" } },
	GlobalX = .24,
	GlobalY = .17,
	GlobalWeight = .225,
	GlobalHeight = .035,
	SpriteW = .225,
	SpriteH = .0785,
	SliderSize = .25,
	Text = { 
		Filter = "Filter",
		Amount = "Amount",
		Variations = "Variations",
		Opacity = "Opacity",
    },
    UseDisabledControls = true,
    UseSounds = true
}

local GetControlNormal <const> = GetControlNormal
local SetMouseCursorThisFrame <const> = SetMouseCursorThisFrame
local DrawSprite <const> = DrawSprite
local IsControlPressed <const> = IsControlPressed
local DrawRect <const> = DrawRect
local UpdateOnscreenKeyboard <const> = UpdateOnscreenKeyboard
local AddTextEntry <const> = AddTextEntry
local DisableControlAction <const> = DisableControlAction
local DisplayOnscreenKeyboard <const> = DisplayOnscreenKeyboard
local GetOnscreenKeyboardResult <const> = GetOnscreenKeyboardResult
local CreateVarString <const> = CreateVarString
local SetTextCentre <const> = SetTextCentre
local SetTextDropshadow <const> = SetTextDropshadow
local SetTextFontForCurrentCommand <const> = SetTextFontForCurrentCommand
local SetTextColor <const> = SetTextColor
local RequestStreamedTextureDict <const> = RequestStreamedTextureDict
local SetStreamedTextureDictAsNoLongerNeeded <const> = SetStreamedTextureDictAsNoLongerNeeded
local IsDisabledControlPressed <const> = IsDisabledControlPressed
local IsDisabledControlJustPressed <const> = IsDisabledControlJustPressed

---@param name1 string
---@param name2 string
---@param p2 boolean
local function PlaySoundFrontend2(name1, name2, p2)
    if BASE_MENU.UseSounds then
        Citizen.InvokeNative(0x67C540AA08E4A6F5, name1, name2, p2, 0)
    end
end

---@param group number
---@param control number
---@return boolean
local function IsDisabledControlJustPressed2(group, control)
	if BASE_MENU.UseDisabledControls then 
		return IsDisabledControlJustPressed(group, control)
	end
	return false
end

-- Splits a string
---@param mainstr string
---@param sep string
---@return table
local function SplitString(mainstr, sep)
	if sep == nil then 
		sep = "%s"
	end
    local t={}
    for str in string.gmatch(mainstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

-- Get the width of a string
---@param str string
---@return string, number
local function GetStringWidth(str)
	return str, #SplitString( str, "\n" )
end

-- Get the mouse 2D position in the screen
---@param X number
---@param Y number
---@param Width number
---@param Height number
---@return boolean
local function GetMouseInBounds(X, Y, Width, Height)
	local MyX, MyY = GetControlNormal(0, 0xD6C4ECDC) + Width / 2, GetControlNormal(0, 0xE4130778) + Height / 2
	return (MyX >= X and MyX <= X + Width) and (MyY > Y and MyY < Y + Height)
end

-- Reset the menu when the menu is closed or opened
function LLib:refreshMenu()
	self.Data = { back = {}, currentMenu = "" }
	self.ButtonsData = { 1, 10, 1, 1 }
	self.Base = {
		Color = BASE_MENU.black,
		HeaderColor = BASE_MENU.black,
		Checkbox = { Textures = { [0] = {"generic_textures", "tick_box", "generic_textures", "tick_box"}, [1] = {"generic_textures", "tick", "generic_textures", "tick_box"} } }
	}
	self.Title = ""
	self.SubTitle = ""
	self.Menu = {}
	self.Events = {}
	self.historyData = {}
	self.IsVisible = false
end

---@return boolean
function LLib:IsMenuOpened()
	return self.IsVisible
end

---@return boolean
function LLib:IsMenuVisible()
	return self.IsVisible
end

---@param visible boolean
function LLib:SetMenuVisible(visible)
    PlaySoundFrontend2("SELECT", "HUD_SHOP_SOUNDSET", true)
	self.IsVisible = visible
end

---@param force? boolean
function LLib:CloseMenu(force)
	if self.IsVisible and (not self.Base.ForcedOpen or force) then		
		self.IsVisible = false
		if self.onClose then self.onClose(self.Data.currentMenu) end
        PlaySoundFrontend2("QUIT", "HUD_SHOP_SOUNDSET", true)
		self:SetMenuVisible(false)
		self:refreshMenu()
	end
end

-- Helper function to generate a range of numbers
---@param from number
---@param to number
---@return table
local function range(from, to)
    local t = {}
    for i = from, to do
        t[#t + 1] = i
    end
    return t
end

---@param customMenu? string Optional custom menu identifier
---@return table, number Filtered buttons and their count
function LLib:GetButtons(customMenu)
    local menu = customMenu or self.Data.currentMenu
    local menuData = self.Menu and self.Menu[menu]
    local allButtons = menuData
    if not allButtons then return {}, 0 end

    allButtons = type(allButtons) == "function" and allButtons(self) or allButtons
    if not allButtons or type(allButtons) ~= "table" then return {}, 0 end

    local tblFilter = {}
    for _, v in pairs(allButtons) do
        if v and type(v) == "table" and (not menuData.filter or string.find(v.name:lower(), menuData.filter)) then
            local max = type(v.slider) == "function" and v.slider(v, self) or v.slider
            if type(max) == "number" then
                max = { table.unpack(range(0, max)) }
            end
            if max then
                v.slidenum = v.slidenum or 1
                local slideName = max[v.slidenum]
                if slideName then
                    v.slidename = type(slideName) == "table" and slideName.name or tostring(slideName)
                end
            end
            tblFilter[#tblFilter + 1] = v
        end
    end

    if #tblFilter == 0 then tblFilter = BASE_MENU.defaultButton end
    self.historyData = { tblFilter, #tblFilter }
    return tblFilter, #tblFilter
end

---@param stringName string
---@param boolBack boolean
function LLib:NavigateToMenu(stringName, boolBack, HoveredId)
	if stringName and not self.Menu[stringName] then print("[LLib] The menu " .. stringName .. " does not exist.") return end
    local newButtons, currentButtonsCount = self:GetButtons(stringName)
    if self.Data.currentMenu then
        if not boolBack and self.Data and self.Data.back then
            PlaySoundFrontend2("SELECT", "HUD_SHOP_SOUNDSET", true)
            self.Data.back[#self.Data.back + 1] = self.Data.currentMenu
        end
    end
    if boolBack then
        PlaySoundFrontend2("QUIT", "HUD_SHOP_SOUNDSET", true)
		self.Data.back[#self.Data.back] = nil
	end
    -- If HoveredId is provided, it will be used as the new hovered button when navigating to the old menu onBack
    local HoveredId = (HoveredId or (boolBack and self.ButtonsData[4] or 1))
	local max = math.max(10, math.min(HoveredId))
	self.ButtonsData = { max - 9, max, HoveredId, self.ButtonsData[3] or 1 }
	self.historyData = { newButtons, currentButtonsCount }
	self.Data.currentMenu = stringName
end

function LLib:Back()
	local historyCount = #self.Data.back
	if self.GetParentMenu == self.Data.currentMenu and (not self.Base.ForcedOpen) then 
		self:CloseMenu()
	end
	if historyCount == 0 and (not self.Base.ForcedOpen) then
		self:CloseMenu()
	elseif historyCount > 0 then
		self:NavigateToMenu(self.Data.back[#self.Data.back], true, self.ButtonsData[4])
		if self.onBack and self.onBack() then self.onBack(self.Data, self) end
	end
end

---@param tableMenu table The menu configuration
function LLib:openMenu(tableMenu)
    if not tableMenu or (self.Base and self.IsVisible and LLib:IsMenuOpened()) then
        print("[LLib] The menu cannot be created because another one already exists")
        return
    end

    if not self.IsVisible then
        self:refreshMenu()

		RequestStreamedTextureDict("generic_textures")
		RequestStreamedTextureDict("feeds")
        for k, v in pairs(tableMenu.Base or {}) do
            self.Base[k] = v
        end

        for k, v in pairs(tableMenu.Data or {}) do
            self.Data[k] = v
        end

        self.Base.ForcedOpen = tableMenu.ForcedOpen or false
        self.GetParentMenu = self.Data.currentMenu

        for k, v in pairs(tableMenu.Events or {}) do
            self.Events[k] = v
        end

        for k, v in pairs(tableMenu.Menu or {}) do
            self.Menu[k] = v
        end

        self.Title = tableMenu.name or tableMenu.Title
        self.SubTitle = tableMenu.SubTitle or tableMenu.subtitle
        self:NavigateToMenu(self.Data.currentMenu)

        self.IsVisible = true
        self:SetMenuVisible(self.IsVisible)

        if self.IsVisible and self.onOpened then
            self.onOpened(self.Data.currentMenu)
        end
    else
        self:CloseMenu(true)
    end
end

---@param num number
---@param numRoundNumber? number
---@return number
local function round(num, numRoundNumber)
	local mult = 10^(numRoundNumber or 0)
	return math.floor(num * mult + 0.5) / mult
end

-- Process the controls of the menu
function LLib:ProcessControl()
    local UPKey = IsControlPressed(1, 0x6319DB71) or (BASE_MENU.UseDisabledControls and IsDisabledControlPressed(1, 0x6319DB71))
    local DOWNKey = IsControlPressed(1, 0x05CA7C52) or (BASE_MENU.UseDisabledControls and IsDisabledControlPressed(1, 0x05CA7C52))
    local RIGHTKey = IsControlPressed(1, 0xDEB34313) or (BASE_MENU.UseDisabledControls and IsDisabledControlPressed(1, 0xDEB34313))
    local LEFTKey = IsControlPressed(1, 0xA65EBAB4) or (BASE_MENU.UseDisabledControls and IsDisabledControlPressed(1, 0xA65EBAB4))
    local currentMenu = self.Menu and self.Menu[self.Data.currentMenu]

    local currentButtons, currentButtonsCount = table.unpack(self.historyData)
    local currentButton = currentButtons and currentButtons[self.ButtonsData[3]]

    if (UPKey or DOWNKey) and currentButtonsCount and self.ButtonsData[3] then
        PlaySoundFrontend2("NAV_DOWN", "HUD_DOMINOS_SOUNDSET", true)
        if DOWNKey and (self.ButtonsData[3] < currentButtonsCount) or UPKey and (self.ButtonsData[3] > 1) then
            self.ButtonsData[3] = self.ButtonsData[3] + (DOWNKey and 1 or -1)
            if currentButtonsCount > 10 and (UPKey and (self.ButtonsData[3] < self.ButtonsData[1]) or (DOWNKey and (self.ButtonsData[3] > self.ButtonsData[2]))) then
                self.ButtonsData[1] = self.ButtonsData[1] + (DOWNKey and 1 or -1)
                self.ButtonsData[2] = self.ButtonsData[2] + (DOWNKey and 1 or -1)
            end
        else
            self.ButtonsData = { UPKey and currentButtonsCount - 9 or 1, UPKey and currentButtonsCount or 10, DOWNKey and 1 or currentButtonsCount, self.ButtonsData[4] or 1 }
            if currentButtonsCount > 10 and (UPKey and (self.ButtonsData[3] > self.ButtonsData[2]) or (DOWNKey and (self.ButtonsData[3] < self.ButtonsData[1]))) then
                self.ButtonsData[1] = self.ButtonsData[1] + (DOWNKey and -1 or 1)
                self.ButtonsData[2] = self.ButtonsData[2] + (DOWNKey and -1 or 1)
            end
        end
        Wait(125)
    end

    if (LEFTKey or RIGHTKey) and currentButton then
        local slideEvent = currentButton.slide or currentButton.Events.onSlide
        if currentButton.slider or currentButton.Events.onSlide or slideEvent then
            local sliderSource = currentButton.slider and currentButton
            if sliderSource then
                currentButton.slidenum = currentButton.slidenum or 0
                local max = type(sliderSource.slider) == "function" and (sliderSource.slider(currentButton, self) or 0) or sliderSource.slider
                if type(max) == "number" then
                    max = { table.unpack(range(0, max)) }
                end
                currentButton.slidenum = currentButton.slidenum + (RIGHTKey and 1 or -1)
                if (RIGHTKey and (currentButton.slidenum > #max) or LEFTKey and (currentButton.slidenum < 1)) then
                    currentButton.slidenum = RIGHTKey and 1 or #max
                end
                local slideName = max[currentButton.slidenum]
                currentButton.slidename = slideName and type(slideName) == "table" and slideName.name or tostring(slideName)
                local _, offset = GetStringWidth(currentButton.slidename)
                currentButton.offset = offset
                if slideEvent then slideEvent(self.Data, currentButton, self.ButtonsData[3], self) end
                Wait(200)
            end
        end
    end

    if currentMenu and currentButton and currentButton.opacity then
        if currentButton.variations and IsDisabledControlPressed(0, 24) then
            local x, y, w = table.unpack(self.Data.variations)
            local left, right = GetMouseInBounds(x - 0.01, self.Height, .015, .03), GetMouseInBounds(x - w + 0.01, self.Height, .015, .03)
            if left or right then
                local advPadding = 1
                currentButton.variations[3] = math.max(currentButton.variations[1], math.min(currentButton.variations[2], right and currentButton.variations[3] - advPadding or left and currentButton.variations[3] + advPadding))
                self.Events["onAdvSlide"](self, self.Data, currentButton, self.ButtonsData[3], currentButtons)
            end
            Wait(75)
        end
    end

    if IsControlJustPressed(1, 0x156F7119) or IsDisabledControlJustPressed2(1, 0x156F7119) or IsControlJustPressed(1, 0x308588E6) or IsDisabledControlJustPressed2(1, 0x308588E6) or IsControlJustPressed(1, 0x8E90C7BB) or IsDisabledControlJustPressed2(1, 0x8E90C7BB) and UpdateOnscreenKeyboard() ~= 0 then
        self:Back()
        Wait(100)
    else
        if self.ButtonsData[3] and currentButtonsCount and self.ButtonsData[3] > currentButtonsCount then
            self.ButtonsData = { 1, 10, 1, self.ButtonsData[4] or 1 }
        end
    end
end

---@param font number
---@param text string
---@param scale number
---@param x number
---@param y number
---@param color table
---@param shadow? boolean
---@param intAlign? number
local function DrawText2(font, text, scale, x, y, color, shadow, intAlign)
	local str = CreateVarString(10, "LITERAL_STRING", text)
	SetTextColor(color[1], color[2], color[3], 255)
	SetTextFontForCurrentCommand(font)
	SetTextScale(scale, scale)
	if shadow then
		SetTextDropshadow(1, 0, 0, 0, 255)
	end
	if intAlign then
		SetTextCentre(intAlign)
    end
	DisplayText(str, x, y)
end

---@param button table The button configuration
---@param MenuX number The X position of the menu
---@param MenuY number The Y position of the menu
---@param Hovered boolean Whether the button is hovered
---@param Width number The width of the button
---@param Height number The height of the button
---@param ID number The ID of the button
function LLib:drawMenuButton(button, MenuX, MenuY, Hovered, Width, Height, ID)
    local currentMenuData = self.Menu[self.Data.currentMenu]
    local tableColor = Hovered and {104, 106, 105, 250} or {0, 0, 0, 100}
    DrawSprite("feeds", "help_text_bg", MenuX, MenuY, Width, Height, 0, tableColor[1], tableColor[2], tableColor[3], tableColor[4])
    
    tableColor = BASE_MENU.white
    DrawText2(6, (button.name or ""), .300, MenuX - Width / 2 + .008, MenuY - Height / 2 + .0025, tableColor)

    local CheckboxExist = currentMenuData and currentMenuData.checkbox or button.checkbox
    local slide = button.slider and button or currentMenuData
    local slideExist = slide and slide.slider
     
    if CheckboxExist ~= nil then
        local boolean = CheckboxExist and CheckboxExist == true and 1 or 0
        local successIcon = self.Base.Checkbox.Textures and self.Base.Checkbox.Textures[boolean]
        if successIcon then
            local checkboxColor = Hovered and BASE_MENU.black or BASE_MENU.white
            DrawSprite(successIcon[1], successIcon[2], MenuX + (Width - 0.13), MenuY, .012, .023, 0.0, checkboxColor[1], checkboxColor[2], checkboxColor[3], 255)
            if boolean and successIcon[3] and successIcon[4] then
                DrawSprite(successIcon[3], successIcon[4], MenuX + (Width - 0.13), MenuY, .012, .023, 0.0, checkboxColor[1], checkboxColor[2], checkboxColor[3], 255)
            end
            return
        end
    elseif slideExist then
        local max = slideExist and slide and (type(slide.slider) == "function" and slide.slider(button, self) or slide.slider)
        if (max and type(max) == "number" and max > 0 or type(max) == "table" and #max > 0) or not slideExist then
            local defaultIndex = 1
            local slideText = (button.slidename or (type(max) == "number" and (defaultIndex - 1) or type(max[defaultIndex]) == "table" and max[defaultIndex].name or tostring(max[defaultIndex])))
            slideText = tostring(slideText)
            if Hovered and slideExist then
                DrawSprite("generic_textures", "selection_arrow_right", MenuX + (Width / 2) - .01025, MenuY + 0.0004, .009, .018, 0.0, tableColor[1], tableColor[2], tableColor[3], 255)
                local length = (slideText:len() / 1000) + 0.001
                button.offset = 0.0345 + length
                DrawSprite("generic_textures", "selection_arrow_left", MenuX + (Width / 2) - button.offset - .016, MenuY + 0.0004, .009, .018, 0.0, tableColor[1], tableColor[2], tableColor[3], 255)
            end
            local length2 = 0.012 + slideText:len() / 1000
            local textX = (not Hovered or button.ask) and -.008 or -.0135
            DrawText2(6, slideText, .275, (MenuX + Width / 2 + textX) - length2, MenuY - Height / 2 + .00375, tableColor, false, 2)
            MenuX = Hovered and MenuX - .0275 or MenuX - .0125
        end
    end
    
    local rightLabel = button.rightLabel
    if rightLabel and rightLabel:len() > 0 then
        DrawText2(6, rightLabel, .275, MenuX + (Width / 2) - .0175, MenuY - Height / 2 + .00375, tableColor, true, 2)
    end
end

---@param buttonsTable table The table containing button configurations
function LLib:DrawButtons(buttonsTable)
    for buttonID, buttonData in ipairs(buttonsTable) do
        local shouldDraw = buttonID >= self.ButtonsData[1] and buttonID <= self.ButtonsData[2]
        if shouldDraw then
            local isHovered = buttonID == self.ButtonsData[3]
            self:drawMenuButton(buttonData, self.Width - BASE_MENU.GlobalWeight / 2, self.Height, isHovered, BASE_MENU.GlobalWeight, BASE_MENU.GlobalHeight - 0.005, buttonID)
            self.Height = self.Height + 0.03

            if isHovered and buttonData.name and buttonData.name ~= "None" and (IsDisabledControlJustPressed2(1, 0xC7B5340A) or IsControlJustPressed(1, 0xC7B5340A)) then
                PlaySoundFrontend2("SELECT", "HUD_SHOP_SOUNDSET", true)

                local slideEvent = buttonData.slide
                if slideEvent or buttonData.checkbox ~= nil then
                    if not slideEvent then
                        buttonData.checkbox = not buttonData.checkbox
                        if buttonData.Events and buttonData.Events.setCheckbox then
                            buttonData.Events.setCheckbox(buttonData.checkbox, self.Data.currentMenu, self.ButtonsData[3])
                        end
                    else
                        slideEvent(self.Data, buttonData, buttonID, self)
                    end
                end

                local selectFunc = buttonData.Events.onSelected
                local shouldContinue = false
                if selectFunc then 
                    if buttonData.slider and not buttonData.slidenum and type(buttonData.slider) == "table" then 
                        buttonData.slidenum = 1 
                        buttonData.slidename = buttonData.slider[1] 
                    end
                    buttonData.slidenum = buttonData.slidenum or 1
                    shouldContinue = selectFunc(self.Data.currentMenu, self.ButtonsData[3])
                    if buttonData.subMenu then 
                        self:NavigateToMenu(buttonData.subMenu)
                    end
                end

                if (not shouldContinue) and self.Menu[buttonData.name:lower()] then
                    self:NavigateToMenu(buttonData.name:lower())
                end
            end
        end
    end
end

---@param buttonCount number The number of buttons
function LLib:DrawHeader(buttonCount)
    local currentMenu = self.Menu[self.Data.currentMenu]
    local stringCounter = string.format("%s/%s", self.ButtonsData[3], buttonCount)
    local headerHeight = BASE_MENU.SpriteH

    DrawSprite("feeds", "help_text_bg", self.Width - BASE_MENU.SpriteW / 2, self.Height - headerHeight / 2, BASE_MENU.SpriteW, headerHeight, 0.0, self.Base.HeaderColor[1] or 0, self.Base.HeaderColor[2] or 0, self.Base.HeaderColor[3] or 0, 215)
    self.Height = self.Height - 0.03

    DrawText2(6, self.Title, 0.7, (self.Width - BASE_MENU.SpriteW / 2) - 0.10, (self.Height - headerHeight / 2 + 0.0125) - 0.0048, BASE_MENU.white, false, 0)
    self.Height = self.Height + 0.06

    local rectWidth, rectHeight = BASE_MENU.GlobalWeight, BASE_MENU.GlobalHeight - 0.005
    DrawSprite("feeds", "help_text_bg", self.Width - rectWidth / 2, self.Height - rectHeight / 2, rectWidth, rectHeight, 0, self.Base.Color[1] or 0, self.Base.Color[2] or 0, self.Base.Color[3] or 0, 255)
    self.Height = self.Height + 0.005

    DrawText2(6, self.SubTitle or self.Data.currentMenu:gsub("^%l", string.upper), 0.275, (self.Width - rectWidth + 0.005) + 0.0035, self.Height - rectHeight - 0.0015, BASE_MENU.white, true)
    self.Height = self.Height + 0.005

    DrawText2(6, stringCounter, 0.275, (self.Width - rectWidth / 2 + 0.11) - 0.013, self.Height - BASE_MENU.GlobalHeight, BASE_MENU.white, true, 2)
    self.Height = self.Height + 0.005
end

---@param tableButtons table
function LLib:DrawHelpers(tableButtons)
	local MENU = self.Menu[self.Data.currentMenu]
	if MENU and MENU[self.ButtonsData[3]].Description or MENU[self.ButtonsData[3]].description then
		local Height, scale = 0.0275, 0.275
		self.Height = self.Height - 0.015
		local nwHeight = Height + (1 and 0 or (1 * 0.0075))
		self.Height = self.Height + Height / 2
		DrawSprite("generic_textures", "inkroller_1a", self.Width - BASE_MENU.GlobalWeight / 2, self.Height + nwHeight / 2 - 0.015, BASE_MENU.GlobalWeight, nwHeight, .0, 16, 16, 16, 165)
		DrawText2(6, (MENU[self.ButtonsData[3]].Description or MENU[self.ButtonsData[3]].description), scale, self.Width - BASE_MENU.GlobalWeight + .010, self.Height - 0.01, BASE_MENU.white)
	end
end

---@param buttonsTable table The table containing button configurations
function LLib:DrawExtra(buttonsTable)
    SetMouseCursorThisFrame()
    DisableControlAction(0, 0xA987235F, true) -- INPUT_LOOK_LR
    DisableControlAction(0, 0xD2047988, true) -- INPUT_LOOK_UD
    DisableControlAction(0, 0x07CE1E61, true) -- INPUT_ATTACK
    DisableControlAction(0, 0xF84FA74F, true) -- INPUT_AIM

    local button = buttonsTable[self.ButtonsData[3]]
    -- If the button has a description, increase the height of the menu
    if button and button.description then
        self.Height = self.Height + 0.023
    end

    -- Draw and process the opacity slider
    if button and button.opacity ~= nil then
        if button.opacity > 1.0 then button.opacity = button.opacity/100 end
        local width, height = BASE_MENU.GlobalWeight, 0.055
        self.Height = self.Height - 0.01
        local blackColor = BASE_MENU.black
        DrawSprite("generic_textures", "inkroller_1a", self.Width - width / 2, self.Height + height / 2, width, height, 0.0, blackColor[1], blackColor[2], blackColor[3], 120)
        self.Height = self.Height + 0.005
        DrawText2(6, "0%", 0.275, self.Width - BASE_MENU.GlobalWeight + .015, self.Height, BASE_MENU.white, false, 1)
        DrawText2(6, BASE_MENU.Text.Opacity, 0.275, (self.Width - BASE_MENU.GlobalWeight / 2) - .0165, self.Height, BASE_MENU.white, false, 0)
        DrawText2(6, "100%", 0.275, self.Width - 0.023, self.Height, BASE_MENU.white, false, 2)
        self.Height = self.Height + .033
        local rectWidth, rectHeight = .205, 0.015
        local customWidth = rectWidth * button.opacity
        local rectX, rectY = self.Width - rectWidth / 2 - 0.011, self.Height
        local customX = rectX - (rectWidth - customWidth) / 2
        DrawRect(rectX, rectY, rectWidth, rectHeight, 87, 87, 87, 255)
        DrawRect(customX, rectY, customWidth, rectHeight, 245, 245, 245, 255)

        if (IsDisabledControlPressed(0, 0xB28318C0) or IsControlJustPressed(0, 0xB28318C0)) and GetMouseInBounds(rectX, rectY, rectWidth + 0.1, rectHeight) then
            local mouseXPos = GetControlNormal(0, 0xD6C4ECDC) - height / 2
            button.opacity = round(math.max(0.0, math.min(1.0, mouseXPos / rectWidth)), 2)
            if button.Events and button.Events.onChangeOpacity then
                button.Events.onChangeOpacity(button.opacity)
            end
        end
        self.Height = self.Height + 0.025
    end

    -- Draw and process the variations slider
    if button and button.variations ~= nil then
        local width, height = BASE_MENU.GlobalWeight, 0.055
        local blackColor = BASE_MENU.black
        DrawSprite("generic_textures", "inkroller_1a", self.Width - width / 2, self.Height + height / 2, width, height, 0.0, blackColor[1], blackColor[2], blackColor[3], 120)
        self.Height = self.Height + 0.005
        DrawText2(6, tostring(button.variations[1]), 0.275, self.Width - BASE_MENU.GlobalWeight + .021, self.Height, BASE_MENU.white, false, 1)
        DrawText2(6, BASE_MENU.Text.Variations, 0.275, (self.Width - BASE_MENU.GlobalWeight / 2) - .0215, self.Height, BASE_MENU.white, false, 0)
        DrawText2(6, tostring(button.variations[2]), 0.275, self.Width - 0.023, self.Height, BASE_MENU.white, false, 2)
        self.Height = self.Height + .03
        DrawSprite("generic_textures", "selection_arrow_right", self.Width - 0.0135, self.Height, .010, .03, 0.0, 255, 255, 255, 255)
        DrawSprite("generic_textures", "selection_arrow_left", self.Width - width + 0.0135, self.Height, .010, .03, 0.0, 255, 255, 255, 255)
        
        local rectWidth, rectHeight = .185, 0.015
        local variationIndex = (button.currentVariation or button.variations[1])
        local totalVariations = button.variations[2]
        local customWidth = rectWidth / totalVariations
        local rectX, rectY = (self.Width - rectWidth / 2 - 0.02), self.Height
        local customX = (rectX - rectWidth / 2 + (variationIndex - 1) * customWidth + customWidth / 2)

        DrawRect(rectX, rectY, rectWidth, rectHeight, 87, 87, 87, 255)
        DrawRect(customX, rectY, customWidth, rectHeight, 245, 245, 245, 255) -- white

        self.Data.variations = { self.Width, self.Height, width }
        
        if (IsControlJustPressed(0, 0xB28318C0)) and GetMouseInBounds(rectX, rectY, rectWidth + 0.1, rectHeight) then
            local arrowWidth = 0.07
            local leftArrowX = rectX - rectWidth / 2
            local rightArrowX = rectX + rectWidth / 2

            if GetMouseInBounds(leftArrowX, rectY, arrowWidth, rectHeight) then
                button.currentVariation = (button.currentVariation or button.variations[1]) - 1
                if button.currentVariation < 1 then
                    button.currentVariation = 1
                end
                if button.Events and button.Events.onChangeVariation then
                    button.Events.onChangeVariation(button.currentVariation)
                end
            elseif GetMouseInBounds(rightArrowX, rectY, arrowWidth, rectHeight) then
                button.currentVariation = (button.currentVariation or button.variations[1]) + 1
                if button.currentVariation > totalVariations then
                    button.currentVariation = totalVariations
                end
                if button.Events and button.Events.onChangeVariation then
                    button.Events.onChangeVariation(button.currentVariation)
                end
            end
        end
    end
end

---@param callback function
---@param name string
---@param lenght number
---@param default string
local function AskEntry(callback, name, lenght, default)
	AddTextEntry('FMMC_KEY_TIP8', name or BASE_MENU.Text.Amount)
	DisplayOnscreenKeyboard(false, "FMMC_KEY_TIP8", "", default, "", "", "", lenght or 30)
	while UpdateOnscreenKeyboard() == 0 do
		Wait(10)
		if UpdateOnscreenKeyboard() >= 1 then
			callback(GetOnscreenKeyboardResult())
			break
		end
	end
end

-- Draw the current menu
function LLib:Draw()
    local buttonsTable, buttonCount = table.unpack(self.historyData)
    self.Height = BASE_MENU.GlobalY
    self.Width = BASE_MENU.GlobalX

    if buttonsTable and buttonCount then
        self:DrawHeader(buttonCount)
        self:DrawButtons(buttonsTable)
        self:DrawHelpers(buttonsTable)
        
        local currentMenu = self.Menu[self.Data.currentMenu]
        local currentButton = self.ButtonsData[3] and buttonsTable and buttonsTable[self.ButtonsData[3]]
        
        if currentMenu and ((currentButton and currentButton.opacity) or (currentButton and currentButton.variations)) then
            self:DrawExtra(buttonsTable)
        end
        
        if currentMenu then
            DisableControlAction(1, BASE_MENU.KeyFilter, true)
            if IsDisabledControlJustPressed2(1, BASE_MENU.KeyFilter) then
                AskEntry(function(input)
                    currentMenu.filter = input and input:len() > 0 and input:lower() or false
                    self:GetButtons()
                end, BASE_MENU.Text.Filter, nil, (currentMenu.filter or ""))
            end
        end
    end
end

CreateThread(function()
	while true do
		Wait(1)
		if LLib.IsVisible then 
            LLib:Draw()
		end
	end
end)

CreateThread(function()
	while true do
		Wait(1)
		if LLib.IsVisible then 
            LLib:ProcessControl()
        end
    end
end)