--[[
    Universal Game Dumper
    Decompiles ALL scripts from any Roblox game into GUI + clipboard + gofile upload
    Works on any game — no game-specific logic
]]

repeat task.wait() until game:IsLoaded()
task.wait(3)

local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- ===================== GUI ===================== --

local oldGui = CoreGui:FindFirstChild("UDump_UI")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UDump_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 1004
pcall(function() if gethui then ScreenGui.Parent = gethui() return end end)
if not ScreenGui.Parent then
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end end)
    ScreenGui.Parent = CoreGui
end

local BG = Instance.new("Frame")
BG.Size = UDim2.new(0, 540, 0, 420)
BG.Position = UDim2.new(0.5, -270, 0.5, -210)
BG.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
BG.BackgroundTransparency = 0.05
BG.BorderSizePixel = 0
BG.Active = true
BG.Draggable = true
BG.Parent = ScreenGui
Instance.new("UICorner", BG).CornerRadius = UDim.new(0, 8)

local TitleBar = Instance.new("TextLabel")
TitleBar.Size = UDim2.new(1, 0, 0, 28)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
TitleBar.Text = "  📦 Universal Dumper — " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
TitleBar.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleBar.TextSize = 13
TitleBar.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
TitleBar.TextXAlignment = Enum.TextXAlignment.Left
TitleBar.TextTruncate = Enum.TextTruncate.AtEnd
TitleBar.BorderSizePixel = 0
TitleBar.Parent = BG
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 50)
StatusLabel.Position = UDim2.fromOffset(10, 32)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Starting..."
StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
StatusLabel.TextSize = 11
StatusLabel.FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json")
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextYAlignment = Enum.TextYAlignment.Top
StatusLabel.TextWrapped = true
StatusLabel.Parent = BG

local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 1, -120)
ScrollFrame.Position = UDim2.fromOffset(10, 85)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.Parent = BG
Instance.new("UICorner", ScrollFrame).CornerRadius = UDim.new(0, 4)

local SourceLabel = Instance.new("TextLabel")
SourceLabel.Size = UDim2.new(1, -10, 0, 0)
SourceLabel.Position = UDim2.fromOffset(5, 0)
SourceLabel.AutomaticSize = Enum.AutomaticSize.Y
SourceLabel.BackgroundTransparency = 1
SourceLabel.Text = ""
SourceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SourceLabel.TextSize = 10
SourceLabel.FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json")
SourceLabel.TextXAlignment = Enum.TextXAlignment.Left
SourceLabel.TextYAlignment = Enum.TextYAlignment.Top
SourceLabel.TextWrapped = true
SourceLabel.RichText = false
SourceLabel.Parent = ScrollFrame

-- Buttons
local BtnRow = Instance.new("Frame")
BtnRow.Size = UDim2.new(1, -20, 0, 28)
BtnRow.Position = UDim2.new(0, 10, 1, -32)
BtnRow.BackgroundTransparency = 1
BtnRow.Parent = BG

local function makeBtn(text, color, xPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 125, 1, 0)
    btn.Position = UDim2.new(0, xPos, 0, 0)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    btn.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
    btn.AutoButtonColor = true
    btn.BorderSizePixel = 0
    btn.Parent = BtnRow
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    return btn
end

local CopyBtn = makeBtn("📋 Copy", Color3.fromRGB(40, 80, 40), 0)
local PrevBtn = makeBtn("⬅️ Prev", Color3.fromRGB(50, 50, 60), 130)
local NextBtn = makeBtn("➡️ Next", Color3.fromRGB(40, 40, 80), 260)
local UploadBtn = makeBtn("☁️ Upload", Color3.fromRGB(80, 50, 20), 390)

local function setStatus(t) StatusLabel.Text = t end
local function notify(text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = "Dumper", Text = text, Duration = 6})
    end)
end

-- ===================== HTTP ===================== --

local _request = nil
if typeof(request) == "function" then _request = request
elseif typeof(http_request) == "function" then _request = http_request
elseif typeof(syn) == "table" and typeof(syn.request) == "function" then _request = syn.request
elseif typeof(http) == "table" and typeof(http.request) == "function" then _request = http.request
elseif typeof(fluxus) == "table" and typeof(fluxus.request) == "function" then _request = fluxus.request
end

-- ===================== ZIP ===================== --

local function numToLE2(n) return string.char(n%256, math.floor(n/256)%256) end
local function numToLE4(n) return string.char(n%256, math.floor(n/256)%256, math.floor(n/65536)%256, math.floor(n/16777216)%256) end
local crc32_table = {}
for i = 0, 255 do
    local c = i
    for _ = 1, 8 do
        if bit32.band(c, 1) == 1 then c = bit32.bxor(bit32.rshift(c, 1), 0xEDB88320) else c = bit32.rshift(c, 1) end
    end
    crc32_table[i] = c
end
local function crc32(data)
    local crc = 0xFFFFFFFF
    for i = 1, #data do crc = bit32.bxor(bit32.rshift(crc, 8), crc32_table[bit32.band(bit32.bxor(crc, string.byte(data, i)), 0xFF)]) end
    return bit32.bxor(crc, 0xFFFFFFFF)
end
local function buildZip(files)
    local lh, ce, off = {}, {}, 0
    for _, f in ipairs(files) do
        local n, d, c, s = f.name, f.data, crc32(f.data), #f.data
        local h = "PK\3\4"..numToLE2(20)..numToLE2(0)..numToLE2(0)..numToLE2(0)..numToLE2(0)..numToLE4(c)..numToLE4(s)..numToLE4(s)..numToLE2(#n)..numToLE2(0)..n..d
        lh[#lh+1] = h
        ce[#ce+1] = "PK\1\2"..numToLE2(20)..numToLE2(20)..numToLE2(0)..numToLE2(0)..numToLE2(0)..numToLE2(0)..numToLE4(c)..numToLE4(s)..numToLE4(s)..numToLE2(#n)..numToLE2(0)..numToLE2(0)..numToLE2(0)..numToLE2(0)..numToLE4(0)..numToLE4(off)..n
        off = off + #h
    end
    local cd = table.concat(ce)
    return table.concat(lh)..cd.."PK\5\6"..numToLE2(0)..numToLE2(0)..numToLE2(#files)..numToLE2(#files)..numToLE4(#cd)..numToLE4(off)..numToLE2(0)
end

-- ===================== SANITIZE PATH ===================== --

local function sanitizePath(fullName)
    -- Convert Roblox path to file path, strip trailing spaces (Windows compat)
    local path = fullName
        :gsub("^game%.", "")
        :gsub("%.", "/")
        :gsub("%s+/", "/")
        :gsub("%s+$", "")
    -- Remove invalid filename chars
    path = path:gsub("[<>:\"\\|%?%*]", "_")
    return path
end

-- ===================== MAIN ===================== --

task.spawn(function()
    if typeof(decompile) ~= "function" then
        setStatus("❌ decompile() not available on this executor!")
        return
    end

    setStatus("🔍 Collecting scripts...")

    -- Collect all scripts via getscripts() — most reliable
    local scriptSet = {} -- [instance] = true (dedup)
    local scriptList = {} -- ordered list

    -- Method 1: getscripts() — gets all loaded scripts
    pcall(function()
        for _, s in ipairs(getscripts()) do
            if not scriptSet[s] and (s:IsA("ModuleScript") or s:IsA("LocalScript")) then
                scriptSet[s] = true
                scriptList[#scriptList + 1] = s
            end
        end
    end)

    -- Method 2: scan common containers (catches unloaded modules)
    local containers = {
        game:GetService("ReplicatedStorage"),
        game:GetService("ReplicatedFirst"),
        game:GetService("StarterPlayer"),
        game:GetService("StarterGui"),
        game:GetService("Lighting"),
    }
    -- Also add player's scripts
    pcall(function()
        local lp = Players.LocalPlayer
        if lp then
            table.insert(containers, lp.PlayerGui)
            table.insert(containers, lp.PlayerScripts)
            if lp.Character then table.insert(containers, lp.Character) end
        end
    end)

    for _, container in ipairs(containers) do
        pcall(function()
            for _, desc in ipairs(container:GetDescendants()) do
                if not scriptSet[desc] and (desc:IsA("ModuleScript") or desc:IsA("LocalScript")) then
                    scriptSet[desc] = true
                    scriptList[#scriptList + 1] = desc
                end
            end
        end)
    end

    local total = #scriptList
    if total == 0 then
        setStatus("❌ No scripts found! getscripts() may not be available.")
        return
    end

    setStatus("📦 Found " .. total .. " scripts. Decompiling...")
    task.wait()

    -- Decompile all
    local results = {}
    local failed = 0

    for i, s in ipairs(scriptList) do
        if i % 10 == 0 or i == total then
            setStatus("🔧 Decompiling " .. i .. "/" .. total .. " (" .. math.floor(i/total*100) .. "%)\n" ..
                "✅ " .. #results .. " ok  ❌ " .. failed .. " failed\n" ..
                "📄 " .. s:GetFullName())
            task.wait()
        end

        local source = nil
        local ok = pcall(function() source = decompile(s) end)
        if not ok or not source or #source == 0 then
            pcall(function() source = s.Source end)
        end

        if source and #source > 0 then
            local path = sanitizePath(s:GetFullName())
            local ext = s:IsA("LocalScript") and ".client.lua" or ".module.lua"
            if not path:find("%.lua$") then
                path = path .. ext
            end
            results[#results + 1] = {
                name = path,
                source = source,
                size = #source,
                className = s.ClassName,
                fullName = s:GetFullName()
            }
        else
            failed = failed + 1
        end
    end

    -- Sort by size (biggest first — usually the most interesting)
    table.sort(results, function(a, b) return a.size > b.size end)

    setStatus("✅ Done! " .. #results .. " scripts decompiled (" .. failed .. " failed)\n" ..
        "📦 Total: " .. total .. " scripts found\n" ..
        "💡 Use buttons to browse, copy, or upload all")

    if #results == 0 then
        setStatus("❌ All decompiles failed!")
        return
    end

    -- Display
    local currentIdx = 1
    local function showResult(idx)
        if idx < 1 then idx = #results end
        if idx > #results then idx = 1 end
        currentIdx = idx
        local r = results[idx]
        local sizeStr = r.size >= 1024 and string.format("%.1fKB", r.size/1024) or (r.size .. "B")
        setStatus(
            "📄 [" .. idx .. "/" .. #results .. "] " .. r.name .. "\n" ..
            "📐 " .. sizeStr .. "  |  " .. r.className .. "\n" ..
            "📍 " .. r.fullName
        )
        local display = r.source
        if #display > 50000 then
            display = display:sub(1, 50000) .. "\n\n-- [TRUNCATED — full source via Copy or Upload]"
        end
        SourceLabel.Text = display
    end
    showResult(1)

    CopyBtn.MouseButton1Click:Connect(function()
        pcall(function()
            setclipboard(results[currentIdx].source)
            notify("Copied: " .. results[currentIdx].name)
            CopyBtn.Text = "✅ Copied!"
            task.delay(2, function() CopyBtn.Text = "📋 Copy" end)
        end)
    end)

    PrevBtn.MouseButton1Click:Connect(function() showResult(currentIdx - 1) end)
    NextBtn.MouseButton1Click:Connect(function() showResult(currentIdx + 1) end)

    UploadBtn.MouseButton1Click:Connect(function()
        if not _request then
            notify("request() not available!")
            return
        end
        UploadBtn.Text = "☁️ Uploading..."

        task.spawn(function()
            local zipFiles = {}
            for _, r in ipairs(results) do
                zipFiles[#zipFiles + 1] = {name = r.name, data = r.source}
            end

            local zipData = buildZip(zipFiles)

            local serverName = "store1"
            pcall(function()
                local res = _request({Url = "https://api.gofile.io/servers", Method = "GET"})
                local data = HttpService:JSONDecode(res.Body)
                if data.data and data.data.servers then
                    serverName = data.data.servers[1].name
                end
            end)

            local boundary = "----UD" .. tostring(math.random(100000, 999999))
            local gameName = "Game_" .. tostring(game.PlaceId)
            pcall(function()
                gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name:gsub("[^%w%-_]", "_")
            end)
            local fileName = gameName .. "_Dump_" .. os.date("%Y%m%d_%H%M%S") .. ".zip"

            local body = "--" .. boundary .. "\r\n"
                .. 'Content-Disposition: form-data; name="file"; filename="' .. fileName .. '"\r\n'
                .. "Content-Type: application/zip\r\n\r\n"
                .. zipData .. "\r\n--" .. boundary .. "--\r\n"

            local ok, res = pcall(function()
                return _request({
                    Url = "https://" .. serverName .. ".gofile.io/contents/uploadfile",
                    Method = "POST",
                    Headers = {["Content-Type"] = "multipart/form-data; boundary=" .. boundary},
                    Body = body
                })
            end)

            if ok and res and res.Body then
                pcall(function()
                    local data = HttpService:JSONDecode(res.Body)
                    if data.status == "ok" and data.data then
                        local link = data.data.downloadPage or ("https://gofile.io/d/" .. (data.data.code or "?"))
                        UploadBtn.Text = "✅ Done!"
                        notify("Upload: " .. link)
                        setStatus(
                            "✅ UPLOADED " .. #zipFiles .. " files\n" ..
                            "🔗 " .. link .. " (copied to clipboard)\n" ..
                            "📄 Viewing: [" .. currentIdx .. "/" .. #results .. "] " .. results[currentIdx].name
                        )
                        pcall(function() setclipboard(link) end)
                    else
                        UploadBtn.Text = "❌ Failed"
                        notify("Upload failed")
                    end
                end)
            else
                UploadBtn.Text = "❌ Error"
                notify("Upload error")
            end
            task.delay(3, function() UploadBtn.Text = "☁️ Upload" end)
        end)
    end)

    notify(#results .. " scripts dumped!")
end)
