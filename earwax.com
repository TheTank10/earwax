-- EARWAX --

-- There are only 4 colors. White Red Green Blue and Black

local ANNOUNCMENT = {
    "Earwax Revamped",
    "V 2.0",
    "Fixed hitbox extenders",
    "You can now turn off extenders",
    "Using hitbox extend none",
    "Players who join/respawn will extend",
    "Many other fixes were made."
}

-- Flip announcment
for i = 1, math.floor(#ANNOUNCMENT/2) do
   local j = #ANNOUNCMENT - i + 1
   ANNOUNCMENT[i], ANNOUNCMENT[j] = ANNOUNCMENT[j], ANNOUNCMENT[i]
end

-- Getting the player and all that 
local player = game:GetService("Players").LocalPlayer 
local function getCharacter() return player.Character or player.CharacterAdded:Wait() end

-- Loading in the GUI
local staminaFrame = game:GetService("Players").LocalPlayer.PlayerGui.MainMenu.StaminaFrame
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local Log = Instance.new("Frame")
local UICorner = Instance.new("UICorner")

local CommandLine = Instance.new("TextBox")

ScreenGui.Parent = game.CoreGui

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
MainFrame.BackgroundTransparency = 1.000
MainFrame.Size = UDim2.new(0, 183, 0, 36)

MainFrame.Position = staminaFrame.Position + UDim2.new(0, 215, 0, -68)

MainFrame.Size = UDim2.new(0, 177, 0, 39)

CommandLine.Name = "CommandLine"
CommandLine.Parent = MainFrame
CommandLine.BackgroundColor3 = Color3.fromRGB(52, 52, 52)
CommandLine.BorderColor3 = Color3.fromRGB(0, 0, 0)
CommandLine.Size = UDim2.new(0, 183, 0, 36)
CommandLine.Font = Enum.Font.SourceSans
CommandLine.PlaceholderText = "Earwax"
CommandLine.Text = ""
CommandLine.TextColor3 = Color3.fromRGB(255, 255, 255)
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

UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = CommandLine

-- Handling the GUI 

function clearLog()
    --[[
        Function used to clear the logs
    --]]
    Log:ClearAllChildren()
end

function Write(texts, color)
    --[[
        Function used to write text into the logs
    --]]
    local offset = 0
        
    for _, v in pairs(texts) do 
        local message = Instance.new("TextLabel")
        message.Text = v
        if color == "White" then
            message.TextColor3 = Color3.new(255,255,255)     
        elseif color == "Red" then 
            message.TextColor3 = Color3.new(255,0,0)   
        elseif color == "Green" then 
            message.TextColor3 = Color3.new(0,255,0)
        elseif color == "Blue" then 
            message.TextColor3 = Color3.new(0,0,255)  
        elseif color == "Black" then 
            message.TextColor3 = Color3.new(0,0,0)  
        end
        message.Parent = Log
        message.Position = UDim2.new(0,30,0,offset+100)
        offset = offset - 20
    end
end
Write(ANNOUNCMENT, "White")

local function findPlayer(playerName) 
    --[[
        Finds a player with a small portion of their name
    --]]
    for _,v in pairs(game:GetService("Players"):GetChildren()) do 
        if v.Name:lower():find('^'..playerName:lower()) then 
            return v
        end
    end
    return nil
end

local function TP(args)
   --[[
        TP's to a player 
   --]]
   local playerName = args[2]

   if playerName == nil then 
       Write({"tp requires a player name"}, _G.EarwaxSettings.ErrorColor)
   end
   
   local targetPlayer = findPlayer(playerName)
   
   if targetPlayer == nil then 
       Write({"tp requires a valid player"}, _G.EarwaxSettings.ErrorColor)
       return
   end
   
   local character = getCharacter()
   local targetCharacter = targetPlayer.Character 
   
   character.HumanoidRootPart.CFrame = targetCharacter.HumanoidRootPart.CFrame
end

local aux = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Upbolt/Hydroxide/revision/ohaux.lua"))()
local normalStam = player.PlayerData.Stats.Stamina.Value
local function STAM(args)
    --[[
        Function used to set a players stam
    --]]
    
    if args[2] ~= nil and args[2]:lower() == "set" then 
        local value = tonumber(args[3])
        if value ~= nil then 
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
            
            debug.setupvalue(closure, upvalueIndex, value)
        else 
            Write({"stam set requires a number"}, _G.EarwaxSettings.ErrorColor)
        end
    elseif args[2] ~= nil and args[2]:lower() == "set2" then 
        local value = tonumber(args[3])
        if value ~= nil then 
           if value > 400 then value = 400 end
           player.PlayerData.Stats.Stamina.Value = value
        else 
            Write({"stam set2 requires a valid number"}, _G.EarwaxSettings.ErrorColor)
        end
    else 
        Write({"stam set [number]", "stam set2 [number(max=400)]", "stam commands:"}, "White")
    end
end

local function getCurrentMaxHealth(frame)
    local split = string.split(frame.Text, '/')
    return tonumber(string.gsub(split[2], '%)', ''), 10)
end 

local function getHealth(frame)
    local split = string.split(frame.Text, '/')
    return tonumber(string.split(split[1], '(')[2], 10)
end

local normalHealth = player.Character.BattlerHealth.Value
function HEALTH(args)
    --[[
       Used to set the players health  
    --]]
    if args[2] ~= nil and args[2]:lower() == "set" then
        local value = tonumber(args[3])
        if value == nil then 
           Write({"health set requires a valid number"}, _G.EarwaxSettings.ErrorColor)
           return 
        end
        
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
           Write({
               "Note: Also works with masks",
               "Go buy a helmet and try again",
               "ERROR: You dont own a helmet..."
           }, _G.EarwaxSettings.ErrorColor)
           return 
        end

        while getCurrentMaxHealth(healthFrame) < value do
            if getHealth(healthFrame) <= 0 then 
               break 
            end
            -- Display
            clearLog()
            Write({healthFrame.Text}, "Red")
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
            Write({healthFrame.Text, "Healing"..dots}, "Red")
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
    else 
        Write({"health set [number]", "health commands:"}, "White")
    end
end

function STATS(args)
    --[[
        Function gives someones stats
    --]]
    local playerName = args[2]
    
    if playerName == nil then 
        Write({
            "note: you dont need full name",
            "stats [player]",
            "stats commands:"
        }, "White")
        return    
    end
    
    local player = findPlayer(playerName)
        
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
            
        Write(messages, "Green")
    else 
        Write({"stats require a valid player"}, _G.EarwaxSettings.ErrorColor)
    end
end

function EXPLOITERS(args) 
    --[[
        Function checks if there are any probable exploiters in the game
    --]]
    local list = {}
    for _,v in pairs(game:GetService("Players"):GetPlayers()) do 
        if v ~= player then
            local _,_ = pcall(function()
                local level = v.PlayerData.Stats.Level.Value
                local stamina = v.PlayerData.Stats.Stamina.Value
                local coins = v.PlayerData.Stats.Money5.Value
                
                if stamina < 60 and level == 400 then 
                   table.insert(list, v) 
                end
                if coins > 5000 then 
                   table.insert(list, v) 
                end
            end)
        end
    end
    
    local formattedList = {}
    
    for _,v in pairs(list) do 
        table.insert(formattedList, v.Name)
    end
    
    table.insert(formattedList, "Probable Exploiters:")
    
    Write(formattedList, "White")
end

local farming = false
function FARM(args)
    --[[
        Auto farm function 
    --]]
    if args[2] ~= nil and args[2]:lower() == "stop" then 
       farming = false 
       return
    end
    
    if farming == true then 
       return 
    end
    
    local level = tonumber(args[2])
    if level ~= nil then
        local character = player.Character 
        local hrp = character:WaitForChild("HumanoidRootPart")
        local playerLevel = player.PlayerData.Stats.Level
        
        local _,_ = pcall(function()
            character:WaitForChild("BattlerHealth"):Destroy()
            character:WaitForChild("Head"):WaitForChild("Nametag"):Destroy()
        end)
        
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
        
        farming = true
        while farming do
            clearLog()
            Write({
                tostring("Progress: "..math.floor(playerLevel.Value / level * 100) .. "% / 100%"),
                "This autofarm WONT ban you!",
                "Your nametag and health has been deleted!",
                "run: farm stop to stop it",
                "Autofarming to level " .. tostring(level)
            }, "Green")
            for _, quest in pairs(questData) do 
                if farming == false or playerLevel.Value >= level then 
                    farming = false 
                    return
                end
                hrp.CFrame = quest.Position -- teleport
                wait(2) -- delay
                
                -- Do Quest
                ohTable2.QuestName = quest.Name
                for i=1, quest.Steps do 
                    if farming == false or playerLevel.Value >= level then 
                        farming = false 
                        return
                    end
                    ohTable2.Step = i
                    game:GetService("ReplicatedStorage").NetworkFolder.GameFunction:InvokeServer(ohString1, ohTable2)
                    wait(2)
                end
            end  
        end
        farming = false
    else 
        Write({"farm [level]", "farm stop", "farm commands: "}, "White")
    end
end

function AVATAR(args)
        --[[
            Function used to copy a players avatar
        --]]
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
    
    if args[2] ~= nil and args[2]:lower() == "copy" then
        local playerName = args[3]
        
        if args[3] == nil then 
           Write({"avatar copy requires a player name"}, _G.EarwaxSettings.ErrorColor)
           return 
        end
        
        local player = findPlayer(playerName)
        
        local apperance = player.PlayerData.Appearance 
        
        for _,v in pairs(apperance:GetChildren()) do 
            if v.Name ~= "Element" and v.Name ~= "Scroll" then 
                ohTable2["Selections"][v.Name] = v.Value
            end
        end
        game:GetService("ReplicatedStorage").NetworkFolder.GameFunction:InvokeServer(ohString1, ohTable2)
    elseif args[2] ~= nil and args[2]:lower() == "default" then 
        game:GetService("ReplicatedStorage").NetworkFolder.GameFunction:InvokeServer(ohString1, ohTable2)
    else 
        Write({"avatar copy [player]", "avatar default", "avatar commands:"}, "White")
    end 
end

local function findScroll()
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
            table.insert(Status, "Scroll on shop found["..v.Name.."]")
            scrollExist = true
            break
        end
    end
    return scrollExist, Status
end

function SCROLL(args)
    --[[
        Function used to find and tp to scrolls
    --]]
    if args[2] ~= nil and args[2]:lower() == "status" then
        local _, Status = findScroll()
        Write(Status, "White")
    elseif args[2] ~= nil and args[2]:lower() == "find" then 
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
            Write(Status)
        end
    end
end

local adornee = true
local function extendHitbox(player, size)
    local selectionBox
    local _,_ = pcall(function()
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if hrp == nil then return end 
    hrp.Size = Vector3.new(size, size, size)
    
    selectionBox = Instance.new("SelectionBox")
    selectionBox.Adornee = hrp 
    selectionBox.Name = "xuz"
    selectionBox.Visible = adornee
    selectionBox.Parent = hrp 
    
    local value = Instance.new("BoolValue")
    value.Name = "xuz2"
    value.Parent = hrp
    
    local element = player:WaitForChild("PlayerData"):WaitForChild("Appearance"):WaitForChild("Elements").Value 

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
    end)
    return selectionBox
end

local events = {}
local size = 10
local extendedForAll = false
function HITBOX(args)
    --[[
        Function used to extend hitboxes
    --]]
    if args[2] ~= nil and args[2]:lower() == "extend" then 
        if args[3] ~= nil and args[3]:lower() == "all" then
            if extendedForAll then return end
            extendedForAll = true
            for _,v in pairs(game:GetService("Players"):GetPlayers()) do 
                if v ~= player then
                   local selectionBox = extendHitbox(v, size)

                    events[#events+1] = v.CharacterAdded:Connect(function(character)
                        character:WaitForChild("HumanoidRootPart")
                        local selectionBox = extendHitbox(v, size)
                    end)
                end
            end
            
            events[#events+1] = game:GetService("Players").PlayerAdded:Connect(function(player)
                events[#events+1] = player.CharacterAdded:Connect(function(character)
                    character:WaitForChild("HumanoidRootPart")
                    local selectionBox = extendHitbox(player, size)
                end)
            end)
        elseif args[3] ~= nil and args[3]:lower() == "none" then 
            extendedForAll = false
            for i,v in pairs(events) do
                if v ~= nil then
                   v:Disconnect() 
                   table.remove(events, i)
                end
            end

            for i,v in pairs(game:GetService("Players"):GetPlayers()) do 
                spawn(function()
                    local character = v.Character or v.CharacterAdded:Wait()
                    local hrp = character:WaitForChild("HumanoidRootPart")
                    hrp.Size = Vector3.new(1.9, 2.2, 1)
                    
                    for _,v in pairs(hrp:GetChildren()) do 
                        if v.Name == "xuz" or v.Name == "xuz2" then 
                           v:Destroy()
                        end
                    end
                end) 
            end
        else 
            local playerName = args[3]
            
            if playerName == nil then 
                Write({"hitbox extend all", "hitbox extend none", "hitbox extend [player]", "hitbox extend commands"}, "White")
                return
            end
            
            local player = findPlayer(playerName)
            
            if player then 
                local selectionBox = extendHitbox(player, size)

                events[#events+1] = player.CharacterAdded:Connect(function(character)
                    character:WaitForChild("HumanoidRootPart")
                    local selectionBox = extendHitbox(player, size)
                end)
            else 
                Write({"hitbox extend requires a valid player"}, _G.EarwaxSettings.ErrorColor)
            end
        end
    elseif args[2] ~= nil and args[2]:lower() == "size" then 
        local hitboxSize = tonumber(args[3])
        
        if hitboxSize then 
            size = hitboxSize
            for _,v in pairs(game:GetService("Players"):GetPlayers()) do 
                spawn(function()
                    local character = v.Character or v.CharacterAdded:Wait()
                    local hrp = character:WaitForChild("HumanoidRootPart")
                   
                    if hrp:FindFirstChild("xuz2") then 
                       hrp.Size = Vector3.new(size,size,size)
                    end
                end)
            end
        else 
            Write({"hitbox size requires a number"}, _G.EarwaxSettings.ErrorColor)
        end
    elseif args[2] ~= nil and args[2]:lower() == "adornee" then 
        adornee = not adornee
        for _,v in pairs(game:GetService("Players"):GetPlayers()) do
            spawn(function()
                local character = v.Character or v.CharacterAdded:Wait()
                local hrp = character:WaitForChild("HumanoidRootPart")
                for _,v in pairs(hrp:GetChildren()) do 
                    if v.Name == "xuz" then 
                        v.Visible = adornee
                    end
                end
            end)
        end
    else 
        Write({
            "hitbox extend all",
            "hitbox extend [player]",
            "hitbox extend none",
            "hitbox size [number]",
            "hitbox adornee",
            "hitbox commands:"
        }, "White")
    end
end

function HIDE()
    --[[
        Function used to hide the exploits
    --]]
    
    -- Set the stam to normal 
    player.PlayerData.Stats.Stamina.Value = normalStam 
    
    -- Set health to normal
    player.PlayerGui.MainMenu.HealthFrame.Title.Text = "HEALTH ("..tostring(normalHealth).."/"..tostring(normalHealth)..")"
    
    -- Hide extenders 
    adornee = false 
    for _,v in pairs(game:GetService("Players"):GetPlayers()) do
        spawn(function()
            local character = v.Character or v.CharacterAdded:Wait()
            local hrp = character:WaitForChild("HumanoidRootPart")
            for _,v in pairs(hrp:GetChildren()) do 
                if v.Name == "xuz" then 
                    v.Visible = adornee
                end
            end
        end)
    end
    
    -- Hide GUI 
    MainFrame.Visible = false 
end

local commands = {
    tp = {TP, "tp [player]"}, 
    stam = {STAM, "stam set [amount]", "stam set2 [amount(max=400)]"}, 
    health = {HEALTH, "health set [amount]"}, 
    stats = {STATS, "stats [player]"}, 
    exploiters = {EXPLOITERS, "exploiters"},
    farm = {FARM, "farm [level]", "farm stop"},
    avatar = {AVATAR, "avatar copy [player]", "avatar default"},
    scroll = {SCROLL, "scroll status", "scroll find"}, 
    hitbox = {HITBOX, "hitbox extend all", "hitbox extend none", "hitbox extend [player]", "hitbox size [number]", "hitbox adornee"},
    hide = {HIDE, "hide"}
}

function commandLineHandler(command)
   --[[
        Function used to handle the command line
   --]]
   local cmd = string.split(command, ' ')
   clearLog()
   
    if cmd[1] ~= nil and cmd[1] == "commands" then 
        local listOfCommands = {}
        for _,v in pairs(commands) do 
            for _,v in pairs(v) do 
                if type(v) ~= "function" then 
                   table.insert(listOfCommands, v)
                end
            end
        end
        Write(listOfCommands, "White")
        return
    end
   
    for i,v in pairs(commands) do 
        if cmd[1]:lower() == i then 
           v[1](cmd)
        end
    end
end

CommandLine:GetPropertyChangedSignal("Text"):Connect(function()
    local text = CommandLine.Text 
    if text == "" or text == " " then 
        clearLog() 
        return 
    end 
    
    local board = {}
    
    for _,v in pairs(commands) do 
        for _,v in pairs(v) do
            if type(v) ~= "function" then
                if string.match(v, "^"..text) then
                   table.insert(board, v)
                   clearLog()
                end
            end
        end
    end
    
    
    Write(board, "White")
    
end)

local function onFocusLost(enterPressed, inputThatCausedFocusLost)
    if enterPressed then
        commandLineHandler(CommandLine.Text)
    end
end
CommandLine.FocusLost:Connect(onFocusLost)

-- Hide the GUI when shift + . is pressed
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input,isTyping) -- input is for the key
    if isTyping then return end
	if input.KeyCode == Enum.KeyCode.Period then 
	    MainFrame.Visible = not MainFrame.Visible
	end
end)
