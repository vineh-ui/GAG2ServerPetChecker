-- // GAG2 Wild Pet Scanner → Discord Webhook

local FLAGGED_KEYWORDS = {}
local PING_ALL = true
local SCAN_INTERVAL = 1

-- // Pets that will ping @everyone
local PING_EVERYONE_PETS = {
    "Raccoon",
    "Unicorn",
    "Dragonfly",
}

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local seenPets = {}
local webhookUrl = ""
local scanning = false
local scanThread = nil

local gui = Instance.new("ScreenGui")
gui.Name = "PetScannerGUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 340, 0, 300)
main.Position = UDim2.new(0.5, -170, 0.5, -150)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
titleBar.BorderSizePixel = 0
titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1, -10, 1, 0)
titleLbl.Position = UDim2.new(0, 10, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "GAG2 Pet Scanner V3"
titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLbl.TextSize = 14
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = titleBar

local statusDot = Instance.new("Frame")
statusDot.Size = UDim2.new(0, 10, 0, 10)
statusDot.Position = UDim2.new(1, -28, 0.5, -5)
statusDot.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
statusDot.BorderSizePixel = 0
statusDot.Parent = titleBar
Instance.new("UICorner", statusDot).CornerRadius = UDim.new(1, 0)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 44)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle — enter webhook below"
statusLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = main

local webhookLabel = Instance.new("TextLabel")
webhookLabel.Size = UDim2.new(1, -20, 0, 16)
webhookLabel.Position = UDim2.new(0, 10, 0, 72)
webhookLabel.BackgroundTransparency = 1
webhookLabel.Text = "Discord Webhook URL"
webhookLabel.TextColor3 = Color3.fromRGB(120, 120, 150)
webhookLabel.TextSize = 11
webhookLabel.Font = Enum.Font.Gotham
webhookLabel.TextXAlignment = Enum.TextXAlignment.Left
webhookLabel.Parent = main

local webhookInput = Instance.new("TextBox")
webhookInput.Size = UDim2.new(1, -20, 0, 34)
webhookInput.Position = UDim2.new(0, 10, 0, 90)
webhookInput.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
webhookInput.BorderSizePixel = 0
webhookInput.Text = ""
webhookInput.PlaceholderText = "https://discord.com/api/webhooks/..."
webhookInput.PlaceholderColor3 = Color3.fromRGB(80, 80, 100)
webhookInput.TextColor3 = Color3.fromRGB(220, 220, 255)
webhookInput.TextSize = 11
webhookInput.Font = Enum.Font.Gotham
webhookInput.ClearTextOnFocus = false
webhookInput.Parent = main
Instance.new("UICorner", webhookInput).CornerRadius = UDim.new(0, 6)
Instance.new("UIPadding", webhookInput).PaddingLeft = UDim.new(0, 8)

local testBtn = Instance.new("TextButton")
testBtn.Size = UDim2.new(1, -20, 0, 30)
testBtn.Position = UDim2.new(0, 10, 0, 134)
testBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
testBtn.BorderSizePixel = 0
testBtn.Text = "Test Webhook"
testBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
testBtn.TextSize = 13
testBtn.Font = Enum.Font.GothamBold
testBtn.Parent = main
Instance.new("UICorner", testBtn).CornerRadius = UDim.new(0, 6)

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(1, -20, 0, 34)
startBtn.Position = UDim2.new(0, 10, 0, 174)
startBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
startBtn.BorderSizePixel = 0
startBtn.Text = "Start Scanner"
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.TextSize = 14
startBtn.Font = Enum.Font.GothamBold
startBtn.Parent = main
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 6)

local logLabel = Instance.new("TextLabel")
logLabel.Size = UDim2.new(1, -20, 0, 14)
logLabel.Position = UDim2.new(0, 10, 0, 218)
logLabel.BackgroundTransparency = 1
logLabel.Text = "Log"
logLabel.TextColor3 = Color3.fromRGB(120, 120, 150)
logLabel.TextSize = 11
logLabel.Font = Enum.Font.Gotham
logLabel.TextXAlignment = Enum.TextXAlignment.Left
logLabel.Parent = main

local logBox = Instance.new("TextLabel")
logBox.Size = UDim2.new(1, -20, 0, 60)
logBox.Position = UDim2.new(0, 10, 0, 234)
logBox.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
logBox.BorderSizePixel = 0
logBox.Text = "Waiting to start..."
logBox.TextColor3 = Color3.fromRGB(180, 255, 180)
logBox.TextSize = 11
logBox.Font = Enum.Font.Code
logBox.TextXAlignment = Enum.TextXAlignment.Left
logBox.TextYAlignment = Enum.TextYAlignment.Top
logBox.TextWrapped = true
logBox.Parent = main
Instance.new("UICorner", logBox).CornerRadius = UDim.new(0, 6)
Instance.new("UIPadding", logBox).PaddingLeft = UDim.new(0, 6)

local logLines = {}

local function log(msg)
    print("[Scanner] " .. msg)
    table.insert(logLines, os.date("%H:%M:%S") .. " " .. msg)
    if #logLines > 4 then table.remove(logLines, 1) end
    logBox.Text = table.concat(logLines, "\n")
end

local function setStatus(text, active)
    statusLabel.Text = "Status: " .. text
    statusDot.BackgroundColor3 = active
        and Color3.fromRGB(80, 255, 120)
        or Color3.fromRGB(255, 80, 80)
end

local function containsKeyword(name)
    local lower = name:lower()
    for _, kw in ipairs(FLAGGED_KEYWORDS) do
        if lower:find(kw:lower()) then
            return true, kw
        end
    end
    return false, nil
end

local function shouldPingEveryone(petType)
    for _, rarePet in ipairs(PING_EVERYONE_PETS) do
        if petType:lower() == rarePet:lower() then
            return true
        end
    end
    return false
end

local function getPetInfo(pet)
    local cost = "N/A"
    local leave = "N/A"

    local rootPart = pet:FindFirstChild("RootPart")
    if rootPart then
        local costGui = rootPart:FindFirstChild("PetCostTimer")
        if costGui then
            local tl = costGui:FindFirstChild("TextLabel")
            if tl then cost = tl.Text end
        end

        local leaveGui = rootPart:FindFirstChild("PetLeaveTimer")
        if leaveGui then
            local tl = leaveGui:FindFirstChild("TextLabel")
            if tl then leave = tl.Text end
        end
    end

    return cost, leave
end

local function sendWebhook(petName, cost, leave, matchedKw, isTest)
    local url = webhookUrl
    if url == "" then log("No webhook URL set!") return end

    local description
    local pingEveryone = false

    if isTest then
        description = "Webhook is working! Scanner is ready."
    else
        local reason = matchedKw and ("Keyword: **" .. matchedKw .. "**") or "New wild pet spawned"
        local petType = petName:match("WildPet_(.-)_WildPet") or petName
        pingEveryone = shouldPingEveryone(petType)

        description = "**Pet:** " .. petType ..
                      "\n**Cost:** " .. cost ..
                      "\n**Leaves in:** " .. leave ..
                      "\n**Reason:** " .. reason ..
                      "\n**Server:** `" .. (game.JobId ~= "" and game.JobId or "Studio") .. "`" ..
                      "\n**Players:** " .. #Players:GetPlayers()
    end

    local payload = HttpService:JSONEncode({
        content = pingEveryone and "@everyone Rare pet spotted!" or nil,
        username = "GAG2 Pet Scanner",
        avatar_url = "https://www.roblox.com/favicon.ico",
        embeds = {{
            title = isTest and "Test Message" or (pingEveryone and "RARE Wild Pet!" or "New Wild Pet!"),
            description = description,
            color = isTest and 0x00BFFF or (pingEveryone and 0xFF4444 or 0xFFD700),
            footer = { text = "GAG2 Scanner • " .. os.date("%H:%M:%S") }
        }}
    })

    local ok, err = pcall(function()
        request({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = payload
        })
    end)

    if not ok then
        log("Webhook failed: " .. tostring(err))
    else
        log(isTest and "Test sent!" or ("Sent: " .. (petName:match("WildPet_(.-)_WildPet") or petName)))
    end
end

local function getContainer()
    local map = workspace:FindFirstChild("Map")
    if not map then return nil end
    return map:FindFirstChild("WildPetSpawns")
end

local function scan()
    local container = getContainer()
    if not container then
        log("WildPetSpawns not found...")
        return
    end

    for _, pet in ipairs(container:GetChildren()) do
        local name = pet.Name
        if seenPets[name] then continue end
        seenPets[name] = true

        local cost, leave = getPetInfo(pet)
        local hasKw, kw = containsKeyword(name)
        local petType = name:match("WildPet_(.-)_WildPet") or name

        log("New: " .. petType .. " | " .. cost .. " | " .. leave)

        if PING_ALL or hasKw then
            sendWebhook(name, cost, leave, kw, false)
        end
    end
end

testBtn.MouseButton1Click:Connect(function()
    webhookUrl = webhookInput.Text
    if webhookUrl == "" then log("Enter a webhook URL first!") return end
    log("Sending test...")
    task.spawn(function() sendWebhook(nil, nil, nil, nil, true) end)
end)

startBtn.MouseButton1Click:Connect(function()
    if scanning then
        scanning = false
        if scanThread then task.cancel(scanThread) end
        scanThread = nil
        startBtn.Text = "Start Scanner"
        startBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
        setStatus("Stopped", false)
        log("Scanner stopped.")
    else
        webhookUrl = webhookInput.Text
        if webhookUrl == "" then log("Enter a webhook URL first!") return end
        scanning = true
        seenPets = {}
        startBtn.Text = "Stop Scanner"
        startBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
        setStatus("Scanning every " .. SCAN_INTERVAL .. "s", true)
        log("Scanner started!")

        scanThread = task.spawn(function()
            while scanning do
                local ok, err = pcall(scan)
                if not ok then log("Error: " .. tostring(err)) end
                task.wait(SCAN_INTERVAL)
            end
        end)
    end
end)

log("Ready paste webhook and press Start.")
