local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local gui = Instance.new("ScreenGui")
gui.Name = "PetInfoSender"
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
titleLbl.Text = "Pet Info Sender"
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

local sendBtn = Instance.new("TextButton")
sendBtn.Size = UDim2.new(1, -20, 0, 34)
sendBtn.Position = UDim2.new(0, 10, 0, 90)
sendBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
sendBtn.BorderSizePixel = 0
sendBtn.Text = "Send Pet Info"
sendBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sendBtn.TextSize = 13
sendBtn.Font = Enum.Font.GothamBold
sendBtn.Parent = main
Instance.new("UICorner", sendBtn).CornerRadius = UDim.new(0, 6)

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

local function getBillboardText(model, guiName)
    local billGui = model:FindFirstChild(guiName)
    if not billGui then return "N/A" end
    for _, v in ipairs(billGui:GetDescendants()) do
        if (v:IsA("TextLabel") or v:IsA("TextButton")) and v.Text ~= "" then
            return v.Text
        end
    end
    return "Empty"
end

sendBtn.MouseButton1Click:Connect(function()
    local url = webhookInput.Text
    if url == "" then
        logLbl.Text = "Enter a webhook URL first!"
        return
    end

    local spawns = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("WildPetSpawns")
    if not spawns then
        logLbl.Text = "WildPetSpawns not found!"
        return
    end

    local pets = spawns:GetChildren()
    if #pets == 0 then
        logLbl.Text = "No pets currently spawned!"
        return
    end

    local sent = 0
    for _, pet in ipairs(pets) do
        local name = pet.Name
        local cost = getBillboardText(pet, "PetCostTimer")
        local leave = getBillboardText(pet, "PetLeaveTimer")

        local payload = HttpService:JSONEncode({
            username = "GAG2 Pet Scanner",
            embeds = {{
                title = "Pet Info",
                description = "**Pet:** `" .. name .. "`\n**Cost:** " .. cost .. "\n**Leaves in:** " .. leave,
                color = 0xFFD700,
                footer = { text = os.date("%H:%M:%S") }
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

        if ok then
            sent += 1
        else
            logLbl.Text = "Error: " .. tostring(err)
            return
        end

        task.wait(0.5)
    end

    logLbl.Text = "✅ Sent " .. sent .. " pet(s) to webhook!"
end)
