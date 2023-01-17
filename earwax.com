-- every new line is a new element
local ANNOUNCMENT = {
    "V2",
    "run \"hide\" to hide all exploits",
    "you can now target 1 player with aimbot",
    "by doing aimbot target [playername]",
    "do aimbot toggle to target everyone",
}

-- Flip announcment
for i = 1, math.floor(#ANNOUNCMENT/2) do
   local j = #ANNOUNCMENT - i + 1
   ANNOUNCMENT[i], ANNOUNCMENT[j] = ANNOUNCMENT[j], ANNOUNCMENT[i]
end

--[[
#################################################################
####################### GUI ###################################
#############################################################
--]]

local staminaFrame = game:GetService("Players").LocalPlayer.PlayerGui.MainMenu.StaminaFrame 

local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Log = Instance.new("Frame")
local UIListLayout = Instance.new("UIListLayout")

local CommandLine = Instance.new("TextBox")

--Properties:

ScreenGui.Parent = game.CoreGui

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.BorderSizePixel = 0

MainFrame.Position = staminaFrame.Position + UDim2.new(0, 215, 0, -68)

MainFrame.Size = UDim2.new(0, 177, 0, 39)

CommandLine.Name = "CommandLine"
CommandLine.Parent = MainFrame
CommandLine.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
CommandLine.BorderSizePixel = 0
CommandLine.Size = UDim2.new(0, 177, 0, 39)
CommandLine.Font = Enum.Font.SourceSans
CommandLine.PlaceholderText = "//"
CommandLine.Text = ""
CommandLine.TextColor3 = Color3.fromRGB(197, 197, 197)
CommandLine.TextScaled = true
CommandLine.TextSize = 14.000
CommandLine.TextWrapped = true
CommandLine.TextXAlignment = Enum.TextXAlignment.Left

Log.Name = "Log"
Log.Parent = ScreenGui
Log.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Log.BackgroundTransparency = 1.000
Log.Position = MainFrame.Position + UDim2.new(0, 48, 0, -115)
Log.Size = UDim2.new(0, 129, 0, 108)

--[[
#################################################################
####################### MAIN ###################################
###############################################################
--]]

local player = game:GetService("Players").localPlayer

local isFarming = false 

local aux = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Upbolt/Hydroxide/revision/ohaux.lua"))()

local normalPlayerStam = player:WaitForChild("PlayerData"):WaitForChild("Stats"):WaitForChild("Stamina").Value

-- clears the screen
function clearLog()
    Log:ClearAllChildren()
end

-- write single text into the screen
function Write(text)
    local message = Instance.new("TextLabel")
    message.Text = text
    message.TextColor3 = Color3.new(255,255,255)
    message.Parent = Log
    message.Position = UDim2.new(0,30,0,100)
end

-- write multiple text into the screen 
function MultipleWrite(texts)
    local offset = 0
        
    for _, v in pairs(texts) do 
        local message = Instance.new("TextLabel")
        message.Text = v
        message.TextColor3 = Color3.new(255,255,255)            
        message.Parent = Log
        message.Position = UDim2.new(0,30,0,offset+100)
        offset = offset - 20
    end
end
MultipleWrite(ANNOUNCMENT)

-- Sets stam
function setStam(VALUE)
    local scriptPath = game:GetService("Players").LocalPlayer.PlayerGui.MainMenu.MenuControl
    local closureName = "CurrentStamina"
    local upvalueIndex = 1
    local closureConstants = {
    	[1] = "StaminaBar",
    	[2] = "Size",
    	[3] = "X",
    	[4] = "Scale",
    	[5] = 2,
    	[6] = "Player"
    }
    
    local closure = aux.searchClosure(scriptPath, closureName, upvalueIndex, closureConstants)
    local value = VALUE
    
    debug.setupvalue(closure, upvalueIndex, value)
end

local function getCurrentMaxHealth(frame)
    local split = string.split(frame.Text, '/')
    return tonumber(string.gsub(split[2], '%)', ''), 10)
end 

local function getHealth(frame)
    local split = string.split(frame.Text, '/')
    return tonumber(string.split(split[1], '(')[2], 10)
end

local normalPlayerHealth = nil

-- Set health
function setHealth(value)
    local character = player.Character
    local itemsFolder = game:GetService("ReplicatedStorage").ItemsFolder
    local inventory = player.PlayerData.Inventory
    local helmets = {}
    for i,v in pairs(itemsFolder:GetChildren()) do 
        if v.Type.Value == "Helmet" then 
           table.insert(helmets, v.Name) 
        end
    end
    
    local healthFrame = player.PlayerGui.MainMenu.HealthFrame.Title
    normalPlayerHealth = getHealth(healthFrame)
    
    local ohString1 = "Equip"
    local ohTable2 = {
    	["ItemType"] = "Helmet",
    	["Slot"] = ""
    }
    
    local ohString3 = "Unequip"
    local ohTable4 = {
    	["ItemType"] = "Helmet"
    }
    
    local helmet = ""
    
    for i,v in pairs(inventory:GetChildren()) do 
        local slotName = v.Name 
        local helmetName = v.Value 
        
        if table.find(helmets, helmetName) then 
           ohTable2.Slot = slotName
           helmet = helmetName
           break 
        end
    end
    
    if helmet == "" then 
       MultipleWrite({
           "Note: Also works with masks",
           "Go buy a helmet and try again",
           "ERROR: You dont own a helmet..."
       })
       return 
    end

    while getCurrentMaxHealth(healthFrame) < value do
        if getHealth(healthFrame) <= 0 then 
           break 
        end
        -- Display
        clearLog()
        Write(healthFrame.Text)
        -- Equip
        game:GetService("ReplicatedStorage").NetworkFolder.GameFunction:InvokeServer(ohString1, ohTable2)
        -- Delete 
        character:FindFirstChild("Helmet"):Destroy()
        -- Unequip
        game:GetService("ReplicatedStorage").NetworkFolder.GameFunction:InvokeServer(ohString3, ohTable4)
        -- Wait 
        wait()
    end
    
    local Time = tick()
    local dots = ''
    while getHealth(healthFrame) < getCurrentMaxHealth(healthFrame) do 
        if getHealth(healthFrame) <= 0 then
           break 
        end
        clearLog()
        MultipleWrite({healthFrame.Text, "Healing"..dots})
        if tick() - Time > 1 then
            if dots ~= '...' then 
               dots = dots .. '.'
            else 
                dots = ''
            end
            Time = tick()
        end
        wait()
    end
    
    clearLog()
end

-- Auto farming 
function autoFarm(level)
    local character = player.Character 
    local hrp = character:WaitForChild("HumanoidRootPart")
    local playerLevel = player.PlayerData.Stats.Level
    
    character:WaitForChild("BattlerHealth"):Destroy()
    character:WaitForChild("Head"):WaitForChild("Nametag"):Destroy()
    
    -- Quest Data
    local npc = workspace.QuestNPCs
    local questData = {
        {
            Name = "EarthQuest3",
            Steps = 3,
            Position = npc.EarthNPC3[""].Head.CFrame
        },
        {
            Name = "EarthQuest2",
            Steps = 4,
            Position = npc.EarthNPC1[""].Head.CFrame 
        }
    }
    local ohString1 = "AdvanceStep"
    local ohTable2 = {
    	["QuestName"] = "",
    	["Step"] = 0
    }
    
    isFarming = true
    while isFarming do
        clearLog()
        MultipleWrite({
            tostring("Progress: "..math.floor(playerLevel.Value / level * 100) .. "% / 100%"),
            "This autofarm WONT ban you!",
            "run: farm stop to stop it",
            "Autofarming to level " .. tostring(level)
        })
        for _, quest in pairs(questData) do 
            if isFarming == false or playerLevel.Value >= level then 
                isFarming = false 
                return
            end
            hrp.CFrame = quest.Position -- teleport
            wait(0.5) -- delay
            
            -- Do Quest
            ohTable2.QuestName = quest.Name
            for i=1, quest.Steps do 
                if isFarming == false or playerLevel.Value >= level then 
                    isFarming = false 
                    return
                end
                ohTable2.Step = i
                game:GetService("ReplicatedStorage").NetworkFolder.GameFunction:InvokeServer(ohString1, ohTable2)
                wait(2)
            end
        end  
    end 
    isFarming = false
end 

-- Sets player avatar to default
local function setDefaultAvatar()
    local ohString1 = "ChangeClothes"
    local ohTable2 = {
    	["Selections"] = {
    		["Elements"] = "Earth",
    		["Special"] = "Sand",
    		["Facial Hair"] = "1",
    		["Shirt"] = "1",
    		["Skin"] = "1",
    		["Hair Color"] = "255,255,255",
    		["Mouth"] = "1",
    		["Hair 2 Color"] = "255,255,255",
    		["Eye Color"] = "255,255,255",
    		["Special2"] = "None",
    		["Eyes"] = "1",
    		["ScrollType"] = "None",
    		["Pants"] = "1",
    		["Scar"] = "1",
    		["Hair 2"] = "1",
    		["Facial Hair Color"] = "255,255,255",
    		["Hair"] = "1"
    	}
    }
    game:GetService("ReplicatedStorage").NetworkFolder.GameFunction:InvokeServer(ohString1, ohTable2)
end

-- Copies a players avatar
local function copyPlayerAvatar(target)
    local apperance = target.PlayerData.Appearance 
    
    local ohString1 = "ChangeClothes"
    local ohTable2 = {
    	["Selections"] = {
    		["Elements"] = "Earth",
    		["Special"] = "Sand",
    		["Facial Hair"] = "1",
    		["Shirt"] = "1",
    		["Skin"] = "1",
    		["Hair Color"] = "255,255,255",
    		["Mouth"] = "1",
    		["Hair 2 Color"] = "255,255,255",
    		["Eye Color"] = "255,255,255",
    		["Special2"] = "None",
    		["Eyes"] = "1",
    		["ScrollType"] = "None",
    		["Pants"] = "1",
    		["Scar"] = "1",
    		["Hair 2"] = "1",
    		["Facial Hair Color"] = "255,255,255",
    		["Hair"] = "1"
    	}
    }
    for _,v in pairs(apperance:GetChildren()) do 
        if v.Name ~= "Element" and v.Name ~= "Scroll" then 
            ohTable2["Selections"][v.Name] = v.Value
        end
    end
    game:GetService("ReplicatedStorage").NetworkFolder.GameFunction:InvokeServer(ohString1, ohTable2)
end

-- Finds the scroll in the game
function findScroll()
    local scroll = workspace:FindFirstChild("ScrollModel")
    local globalShop = game:GetService("ReplicatedStorage").Shops.Global
    local scrollExist = false
    local Status = {"There is no scroll"}
    if scroll then 
        Status[1] = "Scroll on ground found"
        scrollExist = true
    end
    for _,v in pairs(globalShop:GetChildren()) do 
        if string.match(v.Name:lower(), "scroll") then 
            table.insert(Status, "Scroll on shop found")
            scrollExist = true
            break
        end
    end
    
    return scrollExist, Status
end

--[[
    ########################################################################################################
    ###################################### GUI HANDLER ####################################################
    ######################################################################################################
--]]

-- HITBOX EXTENDER 
local hitboxExtenderList = {}
local Hitboxsize = 10

function extendHitbox(target, size)
    local hrp = target.Character:WaitForChild("HumanoidRootPart")
    hrp.Size = Vector3.new(size, size, size)
    
    local selectionBox = Instance.new("SelectionBox")
    selectionBox.Adornee = hrp 
    selectionBox.Parent = hrp 
    selectionBox.Name = "xuz"
    
    local element = target:WaitForChild("PlayerData"):WaitForChild("Appearance"):WaitForChild("Elements").Value 
        
    if element == "Fire" then 
        selectionBox.Color3 = Color3.new(255,0,0)
    elseif element == "Earth" then 
        selectionBox.Color3 = Color3.new(0, 255, 0)
    elseif element == "Water" then 
        selectionBox.Color3 = Color3.new(0, 0, 255)
    elseif element == "Air" then 
        selectionBox.Color3 = Color3.new(255,255,255)
    else
        selectionBox.Color3 = Color3.new(0,0,0)
    end
    
    hrp.CanCollide = false
    local mouse = player:GetMouse()
    mouse.TargetFilter = hrp
end

local function extendForCharacter(player) 
    if table.find(hitboxExtenderList, player) then 
        return 
    end
    player.CharacterAdded:Connect(function()
        if table.find(hitboxExtenderList, player) then
            extendHitbox(player, Hitboxsize)
        end
    end)
end

-- AIMBOT

-- Aimbot settings
local aimbot = false 
local moveFilter = {
    "Swing Kick"
}
local target = nil
local hitbox = true
local playerList = game:GetService("Players"):GetChildren()

-- Gets keybinds/abilities
local ohString1 = "GetAbilities"
local abilities = game:GetService("ReplicatedStorage").NetworkFolder.GameFunction:InvokeServer(ohString1)
local abilitiesTable = {}
local keybinds = player.PlayerData.Keybinds:GetChildren()
    
for i,v in pairs(abilities) do 
    if v["Key"]~=nil and v["Title"]~=nil then
        table.insert(abilitiesTable, {v["Key"], v["Title"]})
    end
end

-- Gets the Normal Keybind name from a Custom keybind 
local function normalKeyBindFromCustom(Custom)
    for i,v in ipairs(keybinds) do 
        if v.Value == Custom then 
            return v.Name
        end
    end
end

-- Gets a move from a normal keybind
local function getMoveFromNormalKeybind(Normal) 
    for i,v in ipairs(abilitiesTable) do 
        if v[1] == Normal then 
            return v[2]
        end
    end
end

-- Returns a a move from a keybind
local function getMove(keybind)
    return getMoveFromNormalKeybind(normalKeyBindFromCustom(keybind)) 
end

local strikePosition = nil
local function getAimPosition(move) 
    -- Find the aim position using the target object
    local position = nil
    if move == "Thunder Strike" then 
        if strikePosition == nil then 
           return target.Position - Vector3.new(0, 5, 0) 
        else 
           return strikePosition
        end
    else 
        position = target.Position
    end
    return position
end

local OldNameCall = nil
OldNameCall = hookmetamethod(game, "__namecall", function(Self, ...)
    local Args = {...}
    local NamecallMethod = getnamecallmethod()

    if not checkcaller() and NamecallMethod == "InvokeServer" then
        if Args[1] == "ProcessKey" then
            local data = Args[2]
            local key = data.Key 
            local move = getMove(key)
            
            -- Ignore Moves that are filtered off
            if target ~= nil then
                if not table.find(moveFilter, move) then 
                    data.AimPos = getAimPosition(move)
                end
            end
                
            Args[2] = data
        end
    end
    return OldNameCall(Self, table.unpack(Args))
end)

local oldTarget = nil
local targetSelectionBox = Instance.new("SelectionBox")
local mouse = player:GetMouse()
function findTarget()
    for _, player in pairs(playerList) do
        if player ~= game:GetService("Players").LocalPlayer then
            local character = player.Character 
            local ut = character:FindFirstChild("UpperTorso")
            if ut ~= nil then 
               if oldTarget ~= nil then
                   -- Calculate distance from old target using mouse
                   
                   local mousePosition = mouse.Hit.p
                   local distanceFromOldTarget = math.abs((mousePosition - oldTarget.Position).Magnitude)
                   local distanceFromTarget = math.abs((mousePosition - ut.Position).Magnitude)
                   
                   if distanceFromTarget <= distanceFromOldTarget then 
                       target = ut 
                       oldTarget = ut
                   end
               else 
                   oldTarget = ut 
               end
            end
        end
    end
    targetSelectionBox.Adornee = target 
    targetSelectionBox.Parent = target
    
    local rayOrigin = target.Position
    local rayDirection = Vector3.new(0, -100, 0)
        
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = target.Parent:GetDescendants()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    strikePosition = raycastResult.Position
end

game:GetService("Players").PlayerAdded:Connect(function(player)
   table.insert(playerList, player) 
end)

game:GetService("Players").PlayerRemoving:Connect(function(player)
   table.remove(playerList, table.find(playerList, player)) 
end)

local RunService = game:GetService("RunService")

-- Handles the GUI and calls the functions for each command
function commandLineHandler(text) 
    clearLog()
    
    local command = string.split(text, ' ')
    
    if command[1]:lower() == "stam" then 
        if command[2] ~= nil and command[2]:lower() == "max" then 
           setStam(500) 
        elseif command[2] ~= nil and command[2]:lower() == "set" then 
            stamValue = tonumber(command[3])
            if stamValue ~= nil then 
                setStam(stamValue) 
            else
                Write("stam set takes in a number")
            end
        elseif command[2] ~= nil and command[2]:lower() == "set2" then 
            stamValue = tonumber(command[3])
            if stamValue ~= nil then 
                player.PlayerData.Stats.Stamina.Value = stamValue
            else
                Write("stam set2 takes in a number")
            end
        else
            MultipleWrite({
                "stam set [amount] -> set your stam",
                "stam max -> get max stam",
                "List of stam commands:"
            })
        end
    elseif command[1]:lower() == "stats" then 
        local playerName = command[2]
        local player = game:GetService("Players"):FindFirstChild(playerName)
        
        if not player then 
            for _,v in pairs(game:GetService("Players"):GetChildren()) do 
                if v.Name:lower():find('^'..playerName:lower()) then 
                   player = v 
                end
            end 
        end
        
        if player then 
            local strenght = player.PlayerData.Stats.Strength 
            local defense = player.PlayerData.Stats.Defense
            local stamina = player.PlayerData.Stats.Stamina
            local coins = player.PlayerData.Stats.Money5
               
            local stats = {strenght, defense, stamina, coins}
            local offset = 0
            local messages = {}
            
            for _, v in pairs(stats) do 
                table.insert(messages, v.Name .. ' | ' .. tostring(v.Value))
            end
            table.insert(messages, player.Name)
            
            MultipleWrite(messages)
        else 
            MultipleWrite({
                "stats [name] -> gives you the player stats",
                "List of stat commands:"
            })
        end
    elseif command[1]:lower() == "tp" then 
        local playerName = command[2]
        local player = game:GetService("Players"):FindFirstChild(playerName)
        
        if not player then 
            for _,v in pairs(game:GetService("Players"):GetChildren()) do 
                if v.Name:lower():find('^'..playerName:lower()) then 
                   player = v 
                end
            end 
        end
        
        if player then
            local position = player.Character.HumanoidRootPart.CFrame 
            
            game:GetService("Players").LocalPlayer.Character.HumanoidRootPart.CFrame = position
        else 
            MultipleWrite({
                "tp [name] - tps to the player",
                "List of teleport commands:"
            })
        end
    elseif command[1]:lower() == "farm" then 
        if command[2] ~= nil and tonumber(command[2]) then 
            level = tonumber(command[2])
            autoFarm(level)
        elseif command[2] ~= nil and command[2]:lower() == "stop" then 
            isFarming = false
        else
            MultipleWrite({
                "farm stop -> stops farming",
                "farm [level] -> starts farming until level",
                "List of AutoFarming commands: "
            })
        end
    elseif command[1]:lower() == "health" then 
        if command[2] ~= nil and command[2]:lower() == "set" then 
            healthValue = tonumber(command[3])
            if healthValue ~= nil then 
                setHealth(healthValue) 
            else
                Write("health set takes in a number")
            end
        elseif command[2] ~= nil and command[2]:lower() == "max" then 
            setHealth(500)
        else 
            MultipleWrite({
                "health set [amount] -> sets health",
                "health max -> gives you max health (500)",
                "You cannot set health lower only higher",
                "YOU NEED TO OWN A HELMET (ANY)",
                "Best place to run is loading screen",
                "Note: Hide when running these command",
                "Health commands:"
            })
        end
    elseif command[1]:lower() == "avatar" then 
        if command[2] ~= nil and command[2]:lower() == "default" then 
           setDefaultAvatar()
        elseif command[2] ~= nil and command[2]:lower() == "copy" then 
            local playerName = command[3]
            local player = game:GetService("Players"):FindFirstChild(playerName)
        
            if not player then 
                for _,v in pairs(game:GetService("Players"):GetChildren()) do 
                    if v.Name:lower():find('^'..playerName:lower()) then 
                       player = v 
                    end
                end 
            end
            
            if player then
                copyPlayerAvatar(player)
            else
                Write("Player not found")
            end
        else 
            MultipleWrite({
                "avatar deafult -> gives you default avatar",
                "avatar copy [player] -> copies players avatar",
                "Avatar commands:"
            })
        end
    elseif command[1]:lower() == "scroll" then 
        if command[2] ~= nil and command[2]:lower() == "status" then 
            local _, Status = findScroll()
            MultipleWrite(Status)
        elseif command[2] ~= nil and command[2]:lower() == "find" then 
            local exists, Status = findScroll()
            
            if exists then 
                local character = player.Character 
                local hrp = character.HumanoidRootPart
                if table.find(Status, "Scroll on ground found") then 
                   hrp.CFrame = workspace:FindFirstChild("ScrollModel").Center.CFrame
                else 
                    local shop = workspace.GlobalShop[""]
                    hrp.CFrame = shop.HumanoidRootPart.CFrame
                end
            else 
                MultipleWrite(Status)
            end
        else 
            MultipleWrite({
                "scroll status -> scroll exists?",
                "scroll find -> TP's to scroll (or shop)",
                "Scroll commands:"
            })
        end
    elseif command[1]:lower() == "hitbox" then 
        if command[2] ~= nil and command[2] == "extend" then 
            local playerName = command[3]
            
            if playerName:lower() == "all" then 
                for _,v in pairs(game:GetService("Players"):GetChildren()) do
                    if v ~= player then 
                        print("Extending for: " .. v.Name)
                        extendHitbox(v, Hitboxsize)
                        extendForCharacter(v)
                        table.insert(hitboxExtenderList, v)
                    end
                end
                return
            end
            
            local player = game:GetService("Players"):FindFirstChild(playerName)
        
            if not player then 
                for _,v in pairs(game:GetService("Players"):GetChildren()) do 
                    if v.Name:lower():find('^'..playerName:lower()) then 
                       player = v 
                    end
                end 
            end
            if player then 
               extendHitbox(player, Hitboxsize)
               extendForCharacter(player)
               table.insert(hitboxExtenderList, player)
            end
        elseif command[2] ~= nil and command[2] == "size" then
            value = tonumber(command[3])
            if value ~= nil then 
                Hitboxsize = value
                for _,v in pairs(game.Players:GetChildren()) do 
                    if v ~= player then
                        if table.find(hitboxExtenderList, v) then 
                           extendHitbox(v, Hitboxsize)
                        end
                    end
                end
            else
                Write("hitbox size takes in a number")
            end
        else 
            MultipleWrite({
                "hitbox extend [number] -> extends",
                "hitbox size [number] -> size",
                "Hitbox commands:"
            })
        end
    elseif command[1]:lower() == "aimbot" then 
        if command[2] ~= nil and command[2]:lower() == "toggle" then
            aimbot = not aimbot
            if aimbot then 
               RunService:BindToRenderStep("Aimbot", 1, findTarget)
            else 
                targetSelectionBox.Adornee = nil
                targetSelectionBox.Parent = nil
                target = nil 
                oldTarget = nil 
                RunService:UnbindFromRenderStep("Aimbot")
            end
        elseif command[2] ~= nil and command[2]:lower() == "target" then 
            local playerName = command[3]
            local player = workspace:FindFirstChild(playerName)
            if not player then 
                for _,v in pairs(game:GetService("Players"):GetChildren()) do 
                    if v.Name:lower():find('^'..playerName:lower()) then 
                       player = v 
                    end
                end 
            end
            if player then 
                RunService:UnbindFromRenderStep("Aimbot")
                target = player.Character:FindFirstChild("UpperTorso")
                targetSelectionBox.Adornee = target 
                targetSelectionBox.Parent = target
                MultipleWrite({
                    "Do target toggle to stop targeting",
                    "targeting: " .. player.Name
                })
            else 
                Write("Player not found.")
            end
        end
    elseif command[1]:lower() == "hide" then 
        -- Hide the gui 
        MainFrame.Visible = false 
        -- Clear the logs 
        clearLog()
        -- Set stamina to normal 
        player.PlayerData.Stats.Stamina.Value = normalPlayerStam 
        -- Set health to normal
        if normalPlayerHealth ~= nil then
            player.PlayerGui.MainMenu.HealthFrame.Title.Text = "HEALTH ("..tostring(normalPlayerHealth).."/"..tostring(normalPlayerHealth)
        end
        -- Toggle aimbot off 
        if aimbot then aimbot = false end 
        targetSelectionBox.Adornee = nil 
        targetSelectionBox.Parent = nil 
        -- Toggle hitbox extenders off 
        for _,v in ipairs(game:GetService("Players"):GetChildren()) do 
           local character = v.Character 
           local hrp = character:FindFirstChild("HumanoidRootPart")
           if hrp then
              local box = hrp:FindFirstChild("xuz")
              if box then box:Destroy() end
           end
        end
    end
end

-- List of commands
local commands = {
    "stam set [number]",
    "stam max",
    "stam set2 [number] (cap is 400)",
    "health set [number]",
    "health max",
    "stats [player]",
    "tp [player]",
    "farm [level]",
    "farm stop",
    "avatar copy [player]",
    "avatar default",
    "scroll status",
    "scroll find",
    "hitbox extend [name/all]",
    "hitbox size [number]",
    "aimbot toggle",
    "aimbot target [name]",
    "aimbot filter [move or playername]",
    "aimbot moves",
    "aimbot players",
    "hide",
}

-- Command guide while typing
CommandLine:GetPropertyChangedSignal("Text"):Connect(function()
    local text = CommandLine.Text 
    local found = false
    local board = {}
    for _,v in ipairs(commands) do 
        if string.match(v, "^"..text) then 
           table.insert(board, v)
           found = true
        end
    end
    if found then 
       clearLog()
       MultipleWrite(board)
    end
end)

-- Calls the command 
local function onFocusLost(enterPressed, inputThatCausedFocusLost)
    if enterPressed then
        commandLineHandler(CommandLine.Text)
    end
end
CommandLine.FocusLost:Connect(onFocusLost)

-- Hides the GUI when "shift + ." is pressed
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input,isTyping) -- input is for the key
    if isTyping then return end
	if input.KeyCode == Enum.KeyCode.Period then 
	    MainFrame.Visible = not MainFrame.Visible
	end
end)
