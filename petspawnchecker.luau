-- // GAG2 Wild Pet Scanner -> Discord Webhook
-- // Watches WildPetSpawns and sends a webhook whenever a new pet appears

local WEBHOOK_URL = "YOUR_WEBHOOK_URL_HERE"

-- // Keywords in the model name that will trigger a ping
-- // Leave empty {} to ping on ALL new pets
local FLAGGED_KEYWORDS = {}

-- // Set to true to ping on every single new pet regardless of name
local PING_ALL = false

-- // Scan interval in seconds
local SCAN_INTERVAL = 1

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local seenPets = {}

local function containsKeyword(name)
    local lower = name:lower()
    for _, kw in ipairs(FLAGGED_KEYWORDS) do
        if lower:find(kw:lower()) then
            return true, kw
        end
    end
    return false, nil
end

local function sendWebhook(petName, matchedKw)
    local reason = matchedKw and ("Keyword match: **" .. matchedKw .. "**") or "New wild pet spawned"

    local payload = HttpService:JSONEncode({
        username = "GAG2 Pet Scanner",
        avatar_url = "https://www.roblox.com/favicon.ico",
        embeds = {{
            title = "🐾 New Wild Pet Detected!",
            description = "**Pet:** `" .. petName .. "`\n**Reason:** " .. reason ..
                          "\n**Server:** `" .. (game.JobId ~= "" and game.JobId or "Studio") .. "`" ..
                          "\n**Players:** " .. #Players:GetPlayers(),
            color = matchedKw and 0xFFD700 or 0x5865F2,
            footer = { text = "GAG2 Scanner • " .. os.date("%H:%M:%S") }
        }}
    })

    local success, err = pcall(function()
        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = payload
        })
    end)

    if not success then
        warn("[Scanner] Webhook failed: " .. tostring(err))
    else
        print("[Scanner] Sent webhook for: " .. petName)
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
        warn("[Scanner] WildPetSpawns not found yet, retrying...")
        return
    end

    for _, obj in ipairs(container:GetChildren()) do
        local name = obj.Name
        if seenPets[name] then continue end
        seenPets[name] = true

        print("[Scanner] New pet spotted: " .. name)

        local hasKw, kw = containsKeyword(name)

        if PING_ALL then
            sendWebhook(name, kw)
        elseif hasKw then
            sendWebhook(name, kw)
        else
            print("[Scanner] Skipped (no keyword match): " .. name)
        end
    end
end

print("[Scanner] GAG2 Wild Pet Scanner started.")
while task.wait(SCAN_INTERVAL) do
    local ok, err = pcall(scan)
    if not ok then
        warn("[Scanner] Scan error: " .. tostring(err))
    end
end
