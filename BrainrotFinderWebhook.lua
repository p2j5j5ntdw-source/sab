--[[
    BRAINROT BASE FINDER - WEBHOOK EDITION
    Scans in-game for bases and sends them DIRECTLY to Discord webhooks!
    No need for Python monitor - this does everything!
--]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- HTTP Request function (works with multiple executors)
local function httpRequest(options)
    if syn and syn.request then
        return syn.request(options)
    elseif request then
        return request(options)
    elseif http_request then
        return http_request(options)
    elseif game.HttpPostAsync then
        -- Fallback for Roblox Studio (not recommended for production)
        local result = ""
        game.HttpPostAsync(game, options.Url, function(code, body)
            result = {StatusCode = code, Body = body}
        end, false, options.Headers, options.Body)
        return result
    else
        error("No HTTP request function available!")
    end
end

-- ⚙️ CONFIGURATION - EDIT THESE!
local CONFIG = {
    -- Discord Webhooks (PASTE YOUR WEBHOOK URLS HERE!)
    WEBHOOK_1M_10M = "https://discord.com/api/webhooks/1459674069049016513/KGRlgW8lkLgw-ia4ogTpi-NLpNV4zHvSPjnnzWEcEFEiSBiaC_kt4GHAtkmmr-n2Q2tV",
    WEBHOOK_10M_PLUS = "https://discord.com/api/webhooks/1475618010151653406/Y97rmrCRrsglMsiaPHxplPN534BYNeNTRc1mU03ClbNfmuiMFvVwdmrzlKLxVKedX4lW",
    
    -- Roblox Game Settings
    PLACE_ID = "109983668079237",  -- Steal A Brainrot Place ID
    CUSTOM_JOINER_URL = "https://stealabrainrot-rho-two.vercel.app",  -- Your Vercel joiner
    
    -- Filters
    MIN_MONEY = 1.0,           -- Minimum M/s (in millions)
    MAX_MONEY = 1999.0,        -- Maximum M/s (in millions)
    MAX_PLAYERS = 8,           -- Skip servers with more players
    IGNORE_UNKNOWN = true,     -- Skip bases named "Unknown"
    
    -- Scanning
    SCAN_INTERVAL = 10,        -- Seconds between scans
    SEND_DUPLICATES = false,   -- Send same base multiple times?
    
    -- GUI
    SHOW_GUI = true,           -- Show GUI with found bases
}

-- Storage
local sentBases = {}  -- Track sent bases to avoid duplicates
local foundBases = {}

-- Utility Functions
local function formatMoney(value)
    if value >= 1000000000 then
        return string.format("%.2fB", value / 1000000000)
    elseif value >= 1000000 then
        return string.format("%.2fM", value / 1000000)
    elseif value >= 1000 then
        return string.format("%.2fK", value / 1000)
    else
        return string.format("%.2f", value)
    end
end

local function getPlaceId()
    -- Get Place ID (doesn't expire - permanent game ID)
    return tostring(game.PlaceId)
end

local function getUniverseId()
    -- Get Universe ID (game's universe, doesn't expire)
    local success, universeId = pcall(function()
        return tostring(game.GameId)
    end)
    if success and universeId and universeId ~= "0" then
        return universeId
    end
    return nil
end

local function getPlayerCount()
    return #Players:GetPlayers()
end

local function generateJoinLinks()
    -- Generate permanent join links (no job ID - won't expire!)
    local placeId = CONFIG.PLACE_ID
    
    -- Generic game join link (doesn't expire, joins any available server)
    local robloxWebLink = string.format("https://www.roblox.com/games/%s", placeId)
    local robloxDeepLink = string.format("roblox://experiences/start?placeId=%s", placeId)
    
    -- Vercel link (without job ID - will join a random server)
    local vercelLink = nil
    if CONFIG.CUSTOM_JOINER_URL and CONFIG.CUSTOM_JOINER_URL ~= "" then
        vercelLink = string.format("%s/?placeId=%s", CONFIG.CUSTOM_JOINER_URL, placeId)
    end
    
    return robloxWebLink, robloxDeepLink, vercelLink
end

local function getBaseCoordinates(base)
    -- Get exact coordinates for teleporting
    local position = base:GetPivot().Position
    local cf = base:GetPivot()
    
    return {
        X = math.floor(position.X),
        Y = math.floor(position.Y),
        Z = math.floor(position.Z),
        CFrame = cf
    }
end

local function getMoneyPerSecond(base)
    -- Try multiple methods to get money/sec value
    
    -- Method 1: Check for MoneyPerSec value (IntValue, NumberValue, StringValue)
    local moneyPerSec = base:FindFirstChild("MoneyPerSec")
    if moneyPerSec then
        if moneyPerSec:IsA("IntValue") or moneyPerSec:IsA("NumberValue") then
            return moneyPerSec.Value
        elseif moneyPerSec:IsA("StringValue") then
            local num = tonumber(moneyPerSec.Value)
            if num then return num end
        end
    end
    
    -- Method 2: Check for Income value
    local income = base:FindFirstChild("Income")
    if income then
        if income:IsA("IntValue") or income:IsA("NumberValue") then
            return income.Value
        elseif income:IsA("StringValue") then
            local num = tonumber(income.Value)
            if num then return num end
        end
    end
    
    -- Method 3: Check configuration folder
    if base:FindFirstChild("Configuration") then
        local config = base.Configuration
        if config:FindFirstChild("MoneyPerSec") then
            local moneyValue = config.MoneyPerSec
            if moneyValue:IsA("IntValue") or moneyValue:IsA("NumberValue") then
                return moneyValue.Value
            end
        end
        if config:FindFirstChild("Money") then
            local moneyValue = config.Money
            if moneyValue:IsA("IntValue") or moneyValue:IsA("NumberValue") then
                return moneyValue.Value
            end
        end
        if config:FindFirstChild("Income") then
            local moneyValue = config.Income
            if moneyValue:IsA("IntValue") or moneyValue:IsA("NumberValue") then
                return moneyValue.Value
            end
        end
    end
    
    -- Method 4: Check for Stats folder
    if base:FindFirstChild("Stats") then
        local stats = base.Stats
        if stats:FindFirstChild("MoneyPerSec") then
            local moneyValue = stats.MoneyPerSec
            if moneyValue:IsA("IntValue") or moneyValue:IsA("NumberValue") then
                return moneyValue.Value
            end
        end
        if stats:FindFirstChild("Income") then
            local moneyValue = stats.Income
            if moneyValue:IsA("IntValue") or moneyValue:IsA("NumberValue") then
                return moneyValue.Value
            end
        end
    end
    
    -- Method 5: Check attributes (Roblox attributes)
    local moneyAttr = base:GetAttribute("MoneyPerSec") or base:GetAttribute("Income") or base:GetAttribute("Money")
    if moneyAttr and type(moneyAttr) == "number" then
        return moneyAttr
    end
    
    -- Method 6: Check all descendants for money-related values
    for _, descendant in ipairs(base:GetDescendants()) do
        if (descendant.Name == "MoneyPerSec" or descendant.Name == "Income" or descendant.Name == "Money") and 
           (descendant:IsA("IntValue") or descendant:IsA("NumberValue")) then
            return descendant.Value
        end
    end
    
    return nil
end

local function getBaseName(base)
    -- Try to get custom name
    if base:FindFirstChild("BaseName") then
        return base.BaseName.Value
    end
    
    if base:FindFirstChild("Configuration") and base.Configuration:FindFirstChild("Name") then
        return base.Configuration.Name.Value
    end
    
    -- Check attributes
    local nameAttr = base:GetAttribute("BaseName") or base:GetAttribute("Name")
    if nameAttr then
        return nameAttr
    end
    
    -- Fallback to model name
    return base.Name
end

local function getBaseOwner(base)
    if base:FindFirstChild("Owner") then
        return base.Owner.Value
    end
    
    if base:FindFirstChild("Configuration") and base.Configuration:FindFirstChild("Owner") then
        return base.Configuration.Owner.Value
    end
    
    local ownerAttr = base:GetAttribute("Owner")
    if ownerAttr then
        return ownerAttr
    end
    
    return "Unknown"
end

local function sendWebhook(baseInfo)
    local placeId = getPlaceId()
    local universeId = getUniverseId()
    local webLink, deepLink, vercelLink = generateJoinLinks()
    local playerCount = getPlayerCount()
    local coords = baseInfo.coordinates or {}
    
    -- Determine which webhook to use
    local webhookUrl
    local categoryText
    local color
    
    if baseInfo.money >= 10.0 then
        webhookUrl = CONFIG.WEBHOOK_10M_PLUS
        categoryText = "10M+ 💎"
        color = 16711935  -- Purple (0xFF00FF)
    else
        webhookUrl = CONFIG.WEBHOOK_1M_10M
        categoryText = "1M-10M 💰"
        color = 65280  -- Green (0x00FF00)
    end
    
    if not webhookUrl or webhookUrl == "" then
        warn("❌ Webhook URL not configured!")
        return false
    end
    
    -- Build join links (permanent - no expiration!)
    local joinLinksText = string.format("[🔗 Join Game (Web)](%s)", webLink)
    joinLinksText = joinLinksText .. string.format("\n[📱 Join Game (Mobile)](%s)", deepLink)
    if vercelLink then
        joinLinksText = joinLinksText .. string.format("\n[🔗 Join Game (Vercel)](%s)", vercelLink)
    end
    
    -- Build coordinates for teleport
    local coordsText = string.format("**X:** %d | **Y:** %d | **Z:** %d", 
        coords.X or 0, coords.Y or 0, coords.Z or 0)
    
    -- Build teleport code
    local teleportCode = ""
    if coords.CFrame then
        local x = coords.X or 0
        local y = coords.Y or 0
        local z = coords.Z or 0
        teleportCode = string.format("```lua\nlocal char = game.Players.LocalPlayer.Character\nif char then\n    char:MoveTo(Vector3.new(%d, %d, %d))\nend\n```", x, y, z)
    end
    
    -- Build Discord embed
    local embed = {
        title = string.format("🧠 Brainrot Base Found! [%s]", categoryText),
        description = "Found a valuable brainrot base! **✅ Links never expire - join anytime!**",
        color = color,
        fields = {
            {
                name = "🏷️ Base Name",
                value = baseInfo.name,
                inline = true
            },
            {
                name = "💰 Money per sec",
                value = string.format("**%.2fM/s**", baseInfo.money),
                inline = true
            },
            {
                name = "👥 Server Players",
                value = string.format("%d/50", playerCount),
                inline = true
            },
            {
                name = "👤 Owner",
                value = baseInfo.owner,
                inline = true
            },
            {
                name = "🎮 Place ID",
                value = string.format("`%s`", placeId),
                inline = true
            },
            {
                name = universeId and "🌐 Universe ID" or "",
                value = universeId and string.format("`%s`", universeId) or "",
                inline = true
            },
            {
                name = "🔗 Join Game (Permanent Links)",
                value = joinLinksText,
                inline = false
            },
            {
                name = "📍 Exact Coordinates",
                value = coordsText,
                inline = false
            },
            {
                name = "🚀 Teleport Code (Paste in Executor)",
                value = teleportCode ~= "" and teleportCode or "Coordinates not available",
                inline = false
            },
            {
                name = "💡 How to Use",
                value = "1️⃣ Join game using any link above\n2️⃣ Paste the teleport code in your executor\n3️⃣ You'll teleport directly to the base!\n4️⃣ ✅ Base location is permanent!",
                inline = false
            }
        },
        footer = {
            text = "Brainrot Finder - Never Expires!"
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    
    local payload = {
        embeds = {embed}
    }
    
    local success, response = pcall(function()
        return httpRequest({
            Url = webhookUrl,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(payload)
        })
    end)
    
    if success and response and response.StatusCode == 204 then
        print(string.format("✅ Sent to webhook: %s (%.2fM/s)", baseInfo.name, baseInfo.money))
        return true
    else
        local errorMsg = "Unknown error"
        if not success then
            errorMsg = tostring(response)
        elseif response then
            errorMsg = string.format("Status: %s, Body: %s", tostring(response.StatusCode), tostring(response.Body or "No body"))
        end
        warn(string.format("❌ Failed to send webhook: %s", errorMsg))
        return false
    end
end

local function shouldSendBase(baseInfo)
    -- Check if already sent
    local baseKey = string.format("%s_%.2f", baseInfo.name, baseInfo.money)
    
    if not CONFIG.SEND_DUPLICATES and sentBases[baseKey] then
        return false
    end
    
    -- Check filters
    if baseInfo.money < CONFIG.MIN_MONEY or baseInfo.money > CONFIG.MAX_MONEY then
        return false
    end
    
    if CONFIG.IGNORE_UNKNOWN and baseInfo.name == "Unknown" then
        return false
    end
    
    if getPlayerCount() > CONFIG.MAX_PLAYERS then
        print(string.format("⏭️ Skipping - Too many players (%d/%d)", getPlayerCount(), CONFIG.MAX_PLAYERS))
        return false
    end
    
    return true
end

local function isValidBase(base)
    if not base:IsA("Model") then return false end
    
    local money = getMoneyPerSecond(base)
    if not money or money <= 0 then
        -- Debug: Print why base was rejected
        -- print(string.format("    ⚠️ Rejected %s: money=%s", base.Name, tostring(money)))
        return false
    end
    
    return true
end

local function scanForBases()
    local newBases = {}
    local checkedObjects = {}  -- Prevent duplicates
    
    print("🔍 Scanning workspace for bases...")
    
    -- Common paths where bases might be stored
    local searchPaths = {
        Workspace:FindFirstChild("Bases"),
        Workspace:FindFirstChild("BrainrotBases"),
        Workspace:FindFirstChild("PlayerBases"),
        Workspace,
    }
    
    for _, searchPath in ipairs(searchPaths) do
        if searchPath then
            local pathName = searchPath.Name
            print(string.format("  📁 Scanning: %s", pathName))
            
            for _, obj in ipairs(searchPath:GetDescendants()) do
                -- Skip if already checked (same object reference)
                if not checkedObjects[obj] then
                    checkedObjects[obj] = true
                
                    if isValidBase(obj) then
                        local money = getMoneyPerSecond(obj)
                        local moneyInMillions = money / 1000000
                        local baseName = getBaseName(obj)
                        local owner = getBaseOwner(obj)
                        
                        local coords = getBaseCoordinates(obj)
                        
                        local baseInfo = {
                            instance = obj,
                            name = baseName,
                            money = moneyInMillions,
                            owner = owner,
                            position = obj:GetPivot().Position,
                            coordinates = coords,
                        }
                        
                        table.insert(newBases, baseInfo)
                        print(string.format("    ✅ Found base: %s (%.2fM/s) at %s", baseName, moneyInMillions, tostring(obj:GetFullName())))
                    end
                end
            end
        end
    end
    
    -- Also check all Models in workspace directly (in case bases are top-level)
    print("  📁 Scanning top-level Models in Workspace...")
    for _, obj in ipairs(Workspace:GetChildren()) do
        if not checkedObjects[obj] then
            checkedObjects[obj] = true
        
            if obj:IsA("Model") and isValidBase(obj) then
                local money = getMoneyPerSecond(obj)
                local moneyInMillions = money / 1000000
                local baseName = getBaseName(obj)
                local owner = getBaseOwner(obj)
                
                local coords = getBaseCoordinates(obj)
                
                local baseInfo = {
                    instance = obj,
                    name = baseName,
                    money = moneyInMillions,
                    owner = owner,
                    position = obj:GetPivot().Position,
                    coordinates = coords,
                }
                
                table.insert(newBases, baseInfo)
                print(string.format("    ✅ Found base: %s (%.2fM/s) at %s", baseName, moneyInMillions, tostring(obj:GetFullName())))
            end
        end
    end
    
    -- Sort by money (highest first)
    table.sort(newBases, function(a, b)
        return a.money > b.money
    end)
    
    foundBases = newBases
    print(string.format("📊 Total bases found: %d", #newBases))
    return newBases
end

local function processAndSendBases()
    print("🔍 Scanning for bases...")
    
    local bases = scanForBases()
    local sentCount = 0
    local filteredCount = 0
    
    print(string.format("📊 Found %d total bases", #bases))
    
    for _, baseInfo in ipairs(bases) do
        print(string.format("  💰 Found: %s - %.2fM/s (Owner: %s)", baseInfo.name, baseInfo.money, baseInfo.owner))
        
        if shouldSendBase(baseInfo) then
            print(string.format("  ✅ Sending webhook for: %s (%.2fM/s)", baseInfo.name, baseInfo.money))
            local success = sendWebhook(baseInfo)
            
            if success then
                sentCount = sentCount + 1
                -- Mark as sent
                local baseKey = string.format("%s_%.2f", baseInfo.name, baseInfo.money)
                sentBases[baseKey] = true
            else
                print(string.format("  ❌ Failed to send webhook for: %s", baseInfo.name))
            end
            
            -- Rate limit - wait between webhooks
            task.wait(1)
        else
            filteredCount = filteredCount + 1
            print(string.format("  ⏭️ Filtered out: %s (doesn't meet criteria)", baseInfo.name))
        end
    end
    
    print(string.format("📊 Scan complete! Found %d bases, filtered %d, sent %d to webhook", #bases, filteredCount, sentCount))
end

local function createGUI()
    if not CONFIG.SHOW_GUI then return nil end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BrainrotFinderWebhookGUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Position = UDim2.new(0.7, 0, 0.1, 0)
    MainFrame.Size = UDim2.new(0, 350, 0, 200)
    MainFrame.Active = true
    MainFrame.Draggable = true
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 8)
    Corner.Parent = MainFrame
    
    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Parent = MainFrame
    Header.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Header.BorderSizePixel = 0
    Header.Size = UDim2.new(1, 0, 0, 40)
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 8)
    HeaderCorner.Parent = Header
    
    local Title = Instance.new("TextLabel")
    Title.Parent = Header
    Title.BackgroundTransparency = 1
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.Size = UDim2.new(0.7, 0, 1, 0)
    Title.Font = Enum.Font.GothamBold
    Title.Text = "🧠 Webhook Finder"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 18
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Close Button
    local CloseButton = Instance.new("TextButton")
    CloseButton.Parent = Header
    CloseButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    CloseButton.BorderSizePixel = 0
    CloseButton.Position = UDim2.new(1, -35, 0.5, -12)
    CloseButton.Size = UDim2.new(0, 25, 0, 25)
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseButton.TextSize = 14
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 4)
    CloseCorner.Parent = CloseButton
    
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    
    -- Status Container
    local StatusContainer = Instance.new("Frame")
    StatusContainer.Parent = MainFrame
    StatusContainer.BackgroundTransparency = 1
    StatusContainer.Position = UDim2.new(0, 15, 0, 50)
    StatusContainer.Size = UDim2.new(1, -30, 1, -60)
    
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Parent = StatusContainer
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Size = UDim2.new(1, 0, 0, 20)
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.Text = "🟢 Active"
    StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    StatusLabel.TextSize = 14
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local FoundLabel = Instance.new("TextLabel")
    FoundLabel.Name = "FoundLabel"
    FoundLabel.Parent = StatusContainer
    FoundLabel.BackgroundTransparency = 1
    FoundLabel.Position = UDim2.new(0, 0, 0, 30)
    FoundLabel.Size = UDim2.new(1, 0, 0, 18)
    FoundLabel.Font = Enum.Font.Gotham
    FoundLabel.Text = "📊 Bases found: 0"
    FoundLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    FoundLabel.TextSize = 12
    FoundLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local SentLabel = Instance.new("TextLabel")
    SentLabel.Name = "SentLabel"
    SentLabel.Parent = StatusContainer
    SentLabel.BackgroundTransparency = 1
    SentLabel.Position = UDim2.new(0, 0, 0, 50)
    SentLabel.Size = UDim2.new(1, 0, 0, 18)
    SentLabel.Font = Enum.Font.Gotham
    SentLabel.Text = "✅ Sent to webhook: 0"
    SentLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    SentLabel.TextSize = 12
    SentLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local NextScanLabel = Instance.new("TextLabel")
    NextScanLabel.Name = "NextScanLabel"
    NextScanLabel.Parent = StatusContainer
    NextScanLabel.BackgroundTransparency = 1
    NextScanLabel.Position = UDim2.new(0, 0, 0, 70)
    NextScanLabel.Size = UDim2.new(1, 0, 0, 18)
    NextScanLabel.Font = Enum.Font.Gotham
    NextScanLabel.Text = "⏱️ Next scan in: --s"
    NextScanLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    NextScanLabel.TextSize = 12
    NextScanLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local PlaceIdLabel = Instance.new("TextLabel")
    PlaceIdLabel.Name = "PlaceIdLabel"
    PlaceIdLabel.Parent = StatusContainer
    PlaceIdLabel.BackgroundTransparency = 1
    PlaceIdLabel.Position = UDim2.new(0, 0, 0, 95)
    PlaceIdLabel.Size = UDim2.new(1, 0, 0, 40)
    PlaceIdLabel.Font = Enum.Font.Code
    PlaceIdLabel.Text = "🎮 Place ID: " .. getPlaceId() .. "\n🌐 Universe: " .. (getUniverseId() or "N/A")
    PlaceIdLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    PlaceIdLabel.TextSize = 9
    PlaceIdLabel.TextXAlignment = Enum.TextXAlignment.Left
    PlaceIdLabel.TextWrapped = true
    
    ScreenGui.Parent = game:GetService("CoreGui")
    
    return ScreenGui, StatusLabel, FoundLabel, SentLabel, NextScanLabel
end

-- Main Execution
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🧠 BRAINROT FINDER - WEBHOOK EDITION")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("⚙️ Configuration:")
print(string.format("  💰 Money range: %.1fM - %.1fM", CONFIG.MIN_MONEY, CONFIG.MAX_MONEY))
print(string.format("  👥 Max players: %d", CONFIG.MAX_PLAYERS))
print(string.format("  🔄 Scan interval: %ds", CONFIG.SCAN_INTERVAL))
print(string.format("  🎮 Place ID: %s", getPlaceId()))
print(string.format("  🌐 Universe ID: %s", getUniverseId() or "N/A"))
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("✅ Using permanent Place ID (never expires!)")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

local gui, statusLabel, foundLabel, sentLabel, nextScanLabel = createGUI()

-- Initial scan
task.spawn(function()
    task.wait(2)  -- Wait for game to load
    processAndSendBases()
end)

-- Auto scan loop
task.spawn(function()
    local totalSent = 0
    
    while task.wait(1) do
        if not gui or not gui.Parent then
            break
        end
        
        -- Update countdown
        if nextScanLabel then
            local elapsed = tick() % CONFIG.SCAN_INTERVAL
            local remaining = math.ceil(CONFIG.SCAN_INTERVAL - elapsed)
            nextScanLabel.Text = string.format("⏱️ Next scan in: %ds", remaining)
        end
        
        -- Scan at interval
        if tick() % CONFIG.SCAN_INTERVAL < 1 then
            local beforeCount = totalSent
            processAndSendBases()
            
            -- Update GUI
            if foundLabel then
                foundLabel.Text = string.format("📊 Bases found: %d", #foundBases)
            end
            
            local newSent = 0
            for _ in pairs(sentBases) do
                newSent = newSent + 1
            end
            totalSent = newSent
            
            if sentLabel then
                sentLabel.Text = string.format("✅ Sent to webhook: %d", totalSent)
            end
        end
    end
end)

print("✅ Brainrot Finder is now running!")
print(string.format("🔍 Scanning every %d seconds...", CONFIG.SCAN_INTERVAL))
print("💡 Found bases will be sent to your Discord webhook!")


