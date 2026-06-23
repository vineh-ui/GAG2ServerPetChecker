-- // GAG2 Wild Pet Scanner

local FLAGGED_KEYWORDS = {}

local PING_ALL = false
local SCAN_INTERVAL = 1

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
main.Name = "Main"
main.Size = UDim2.new(0, 340, 0, 300)
main.Position = UDim2.new(0.5, -170, 0.5, -150)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
titleBar.BorderSizePixel = 0
titleBar.Parent = main
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -10, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "GAG2 Pet Scanner"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

-- Status indicator
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

-- Webhook label
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

-- Webhook input
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

-- Test button
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

-- Start/Stop button
local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(1, -20, 0, 34)
startBtn.Position = UDim2.new(0, 10, 0, 174)
startBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
startBtn.BorderSizePixel = 0
startBtn.Text = "▶  Start Scanner"
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.TextSize = 14
startBtn.Font = Enum.Font.GothamBold
startBtn.Parent = main
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 6)

-- Log box
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

-- // ── Helpers ──────────────────────────────

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

local function sendWebhook(petName, matchedKw, isTest)
    local url = webhookUrl
    if url == "" then
        log("No webhook URL set!")
        return
    end

    local description
    if isTest then
        description = "Webhook is working! Scanner is ready."
    else
        local reason = matchedKw and ("Keyword: **" .. matchedKw .. "**") or "New wild pet spawned"
        description = "**Pet:** `" .. petName .. "`\n**Reason:** " .. reason ..
                      "\n**Server:** `" .. (game.JobId ~= "" and game.JobId or "Studio") .. "`" ..
                      "\n**Players:** " .. #Players:GetPlayers()
    end

    local payload = HttpService:JSONEncode({
        username = "GAG2 Pet Scanner",
        avatar_url = "https://www.roblox.com/favicon.ico",
        embeds = {{
            title = isTest and "🔧 Test Message" or "🐾 New Wild Pet Detected!",
            description = description,
            color = isTest and 0x00BFFF or (matchedKw and 0xFFD700 or 0x5865F2),
            footer = { text = "GAG2 Scanner • " .. os.date("%H:%M:%S") }
        }}
    })

    local success, err = pcall(function()
        request({
            Url = url,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = payload
        })
    end)

    if not success then
        log("Webhook failed: " .. tostring(err))
    else
        log(isTest and "Test sent!" or ("Sent: " .. (petName or "")))
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

    for _, obj in ipairs(container:GetChildren()) do
        local name = obj.Name
        if seenPets[name] then continue end
        seenPets[name] = true

        log("New: " .. name)

        local hasKw, kw = containsKeyword(name)
        if PING_ALL or hasKw then
            sendWebhook(name, kw, false)
        end
    end
end

testBtn.MouseButton1Click:Connect(function()
    webhookUrl = webhookInput.Text
    if webhookUrl == "" then
        log("Enter a webhook URL first!")
        return
    end
    log("Sending test...")
    task.spawn(function()
        sendWebhook(nil, nil, true)
    end)
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
        if webhookUrl == "" then
            log("Enter a webhook URL first!")
            return
        end
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
