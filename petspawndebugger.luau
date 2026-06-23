local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

-- // ── GUI ──────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "PetDumper"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 320, 0, 160)
main.Position = UDim2.new(0.5, -160, 0.5, -80)
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
titleLbl.Text = "🔍 Pet Structure Dumper"
titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLbl.TextSize = 14
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = titleBar

local webhookInput = Instance.new("TextBox")
webhookInput.Size = UDim2.new(1, -20, 0, 34)
webhookInput.Position = UDim2.new(0, 10, 0, 46)
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

local dumpBtn = Instance.new("TextButton")
dumpBtn.Size = UDim2.new(1, -20, 0, 34)
dumpBtn.Position = UDim2.new(0, 10, 0, 90)
dumpBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
dumpBtn.BorderSizePixel = 0
dumpBtn.Text = "Dump First Pet"
dumpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dumpBtn.TextSize = 13
dumpBtn.Font = Enum.Font.GothamBold
dumpBtn.Parent = main
Instance.new("UICorner", dumpBtn).CornerRadius = UDim.new(0, 6)

local logLbl = Instance.new("TextLabel")
logLbl.Size = UDim2.new(1, -20, 0, 20)
logLbl.Position = UDim2.new(0, 10, 0, 132)
logLbl.BackgroundTransparency = 1
logLbl.Text = "Waiting..."
logLbl.TextColor3 = Color3.fromRGB(160, 160, 180)
logLbl.TextSize = 11
logLbl.Font = Enum.Font.Gotham
logLbl.TextXAlignment = Enum.TextXAlignment.Left
logLbl.Parent = main

-- // ── Logic ────────────────────────────────

dumpBtn.MouseButton1Click:Connect(function()
    local url = webhookInput.Text
    if url == "" then
        logLbl.Text = "❌ Enter a webhook URL first!"
        return
    end

    local spawns = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("WildPetSpawns")
    if not spawns then
        logLbl.Text = "❌ WildPetSpawns not found!"
        return
    end

    local first = spawns:GetChildren()[1]
    if not first then
        logLbl.Text = "❌ No pets spawned right now!"
        return
    end

    -- Build dump string
    local lines = {"**Pet:** `" .. first.Name .. "`", ""}
    for _, v in ipairs(first:GetDescendants()) do
        local line = "`[" .. v.ClassName .. "]` **" .. v.Name .. "** — `" .. v:GetFullName() .. "`"
        if v:IsA("TextLabel") or v:IsA("TextButton") then
            line = line .. "\n  📝 Text: `" .. v.Text .. "`"
        end
        if v:IsA("StringValue") or v:IsA("IntValue") or v:IsA("NumberValue") or v:IsA("BoolValue") then
            line = line .. "\n  💾 Value: `" .. tostring(v.Value) .. "`"
        end
        table.insert(lines, line)
    end

    -- Discord has a 4096 char embed description limit so chunk it
    local chunks = {}
    local current = ""
    for _, line in ipairs(lines) do
        if #current + #line + 2 > 3900 then
            table.insert(chunks, current)
            current = line .. "\n"
        else
            current = current .. line .. "\n"
        end
    end
    if current ~= "" then table.insert(chunks, current) end

    logLbl.Text = "Sending " .. #chunks .. " message(s)..."

    for i, chunk in ipairs(chunks) do
        local payload = HttpService:JSONEncode({
            username = "GAG2 Dumper",
            embeds = {{
                title = "🔍 Pet Dump — Part " .. i .. "/" .. #chunks,
                description = chunk,
                color = 0x00BFFF,
                footer = { text = first.Name }
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
            logLbl.Text = "❌ Error: " .. tostring(err)
            return
        end

        task.wait(0.6)
    end

    logLbl.Text = "✅ Dump sent — " .. #chunks .. " message(s)!"
end)
