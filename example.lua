local exampleSlider = {"Morning", "Afternoon", "Evening", "Night"}
local TableMenu = {
    name = "Exemple menu",
    subtitle = "This a Light Lib menu",
    ForcedOpen = false,
    Data = { currentMenu = "Main" },
    Menu = {
        ["Main"] = {
            {name = "Price", rightLabel = "100$", Events = {
                onSelected = function(CurrentMenu, currentButtonPlacement)
                    print("Test", CurrentMenu, currentButtonPlacement)
                end
            }},

            -- Todo, When the description is too long it must go to the line
            {name = "Description", description = "This is a description for this button", Events = {
                onSelected = function()
                    print("Test2")
                end
            }},
            
            {name = "Opacity/Variation", opacity = 0.5, variations = {1,3}, Events = {
                onSelected = function()
                    print("Pressed Enter")
                end,
                onChangeOpacity = function(newOpacity) ---@param newOpacity number
                    print("Change opacity", newOpacity)
                end,
                onChangeVariation = function(variation) ---@param variation number
                    print("Change variation", variation)
                end
            }},

            {name = "Slider", slider = exampleSlider, Events = {
                onSlide = function(menuData, boutton, currentButton, currentSlt)
                    print(menuData.currentMenu) -- -> Return the current menu (in this case "Main")
                    print(boutton.name) -- -> Return the name of the slider (in this case "Slider")
                    print(boutton.slidenum) -- -> Return the slider number
                    print(exampleSlider[boutton.slidenum]) -- -> Return the value of the slider
                    if exampleSlider[boutton.slidenum] == "Morning" then
                        NetworkClockTimeOverride(6, 0, 0, 0)
                    elseif exampleSlider[boutton.slidenum] == "Afternoon" then
                        NetworkClockTimeOverride(12, 0, 0, 0)
                    elseif exampleSlider[boutton.slidenum] == "Evening" then
                        NetworkClockTimeOverride(18, 0, 0, 0)
                    elseif exampleSlider[boutton.slidenum] == "Night" then
                        NetworkClockTimeOverride(0, 0, 0, 0)
                    end
                end,
                onSelected = function(CurrentMenu, currentButtonPlacement)
                    print(CurrentMenu, currentButtonPlacement)
                end
            }},

            {name = "CheckBox", checkbox = false, Events = {
                setCheckbox = function(Result, CurrentMenu, currentButtonPlacement) ---@param Result boolean
                    print("Checkbox", Result)
                end
            }},

            {name = "Price", rightLabel = "100$", Events = {
                onSelected = function(CurrentMenu, currentButtonPlacement)
                    
                end
            }, subMenu = "Submenu"},
        },
        ["Submenu"] = {
            {name = "I Want everything", rightLabel = "100$", description = "Hello everyone", opacity = 1.0, variations = {1,50}, Events = {
                onSelected = function(CurrentMenu, currentButtonPlacement)
                    
                end
            }},
            {name = "This is a button", Events = {
                onSelected = function(CurrentMenu, currentButtonPlacement)
                    
                end
            }},
            {name = "Opacity", opacity = 0.1, Events = {
                onSelected = function(CurrentMenu, currentButtonPlacement)
                    
                end
            }},
            {name = "Variation", variations = {1,50}, Events = {
                onSelected = function(CurrentMenu, currentButtonPlacement)
                    
                end
            }},
        },
    }
}

LLib.onClose = function(MenuName)
    print("Closed menu", MenuName)
end

LLib.onBack = function()
    print("onBack")
end

LLib.onOpened = function(MenuName)
    print("Opened menu", MenuName)
end

RegisterCommand("openmenu", function()
    LLib:openMenu(TableMenu)
end)

------------------------------------------------------------------------------------------
----------------------------------    EVENTS    ------------------------------------------
------------------------------------------------------------------------------------------

-----------------------------------  Listeners  ------------------------------------------

-- LLib.onClose				-- When the menu is closed
-- LLib.onOpened				-- On menu opened
-- LLib.onBack				-- When your in a submenu and you're going back to main

---------------------------------   INSIDE MENU   ----------------------------------------

-- onSlide				-- When you change the slide of a slider
-- onSelected			-- When a button is selected
-- setCheckbox          -- When the checkbox changes
-- onChangeOpacity		-- When the opacity changes
-- onChangeVariation	-- When the variation changes

------------------------------------------------------------------------------------------