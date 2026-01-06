--[[ 
    RakaHensem Utility V7 - Deep Scan Fixed
    Theme: Cyber Green & Orange
    Layout: Left-Scrollable Tabs
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer

-- // 1. SYSTEM SAFETY CHECK (Deep Scan Remotes)
local function FindRemote(parent, names)
    for _, name in pairs(names) do
        local found = parent:FindFirstChild(name, true) -- True = Recursive search
        if found then return found end
    end
    return nil
end

-- Mencari path 'net' library yang sering pindah-pindah
local Packages = ReplicatedStorage:FindFirstChild("Packages")
local NetLib = Packages and FindRemote(Packages, {"net", "sleitnick_net@0.2.0"}) 
local NetFolder = NetLib and NetLib:FindFirstChild("net")

if not NetFolder then
    -- Fallback manual jika path berubah total
    NetFolder = ReplicatedStorage
    warn("Warning: Net Library path not found standardly. Attempting fallback.")
end

-- Define Remotes dengan Safety Check
local ChargeRod    = NetFolder:FindFirstChild("RF/ChargeFishingRod")
local RequestGame  = NetFolder:FindFirstChild("RF/RequestFishingMinigameStarted")
local CompleteGame = NetFolder:FindFirstChild("RE/FishingCompleted")
local CancelInput  = NetFolder:FindFirstChild("RF/CancelFishingInputs")
local SellItemRemote = NetFolder:FindFirstChild("RF/SellItem") 

-- Auto Find Weather (Mencari segala kemungkinan nama remote cuaca)
local WeatherRemote = FindRemote(NetFolder, {"RF/PurchaseWeather", "RF/WeatherTotem", "RF/WorldEvent", "RF/ChangeWeather"})

-- // 2. CONFIGURATION
getgenv().fishingStart = false
_G.FishSettings = { DelayCharge = 0, DelayReset = 0 }
_G.SellSettings = { Active = false, Interval = 300, NextSellTime = os.time() + 300 }
_G.WeatherSettings = { Active = false, Selected = {}, Interval = 5 }

local fishArgs = { -1.115296483039856, 0, 1763651451.636425 }

-- // 3. NOTIFICATION & UTILS
local function Notify(title, text)
    game:GetService("StarterGui"):SetCore("SendNotification", { Title = title, Text = text, Duration = 3 })
end

-- // 4. TURBO FISHING LOGIC (Optimized Memory)
local function startTurboFishing()
    task.spawn(function() pcall(function() CancelInput:InvokeServer() end) end)
    
    while getgenv().fishingStart do
        if not Player.Character then task.wait(1) end -- Safety check character

        -- 1. Charge & Request (Concurrent)
        task.spawn(function() 
            if ChargeRod then pcall(function() ChargeRod:InvokeServer() end) end
        end)
        
        task.spawn(function() 
            if RequestGame then pcall(function() RequestGame:InvokeServer(unpack(fishArgs)) end) end
        end)
        
        if _G.FishSettings.DelayCharge > 0 then task.wait(_G.FishSettings.DelayCharge) end
        
        -- 2. Instant Catch
        if CompleteGame then pcall(function() CompleteGame:FireServer() end) end
        
        -- 3. Reset
        task.spawn(function() 
            if CancelInput then pcall(function() CancelInput:InvokeServer() end) end
        end)
        
        -- Prevent Crash (Micro Wait)
        if _G.FishSettings.DelayReset > 0 then 
            task.wait(_G.FishSettings.DelayReset) 
        else 
            RunService.Heartbeat:Wait() 
        end
        
        if not getgenv().fishingStart then break end
    end
end

-- // 5. UI SYSTEM (Green & Orange - Left Scroll Tabs)
local UI = {
    Bg = Color3.fromRGB(12, 28, 18),         -- Dark Green Background
    Sidebar = Color3.fromRGB(8, 20, 12),     -- Darker Green Sidebar
    Accent = Color3.fromRGB(255, 120, 0),    -- Orange Accent
    Text = Color3.fromRGB(220, 255, 220),    -- Pale Green Text
    SubText = Color3.fromRGB(100, 160, 100)  -- Dim Green
}

if CoreGui:FindFirstChild("RakaV7") then CoreGui.RakaV7:Destroy() end
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "RakaV7"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main Frame
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 380, 0, 280) -- Lebih lebar untuk sidebar
MainFrame.Position = UDim2.new(0.5, -190, 0.4, 0)
MainFrame.BackgroundColor3 = UI.Bg
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 6)

-- Stroke (Outline Orange)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = UI.Accent
MainStroke.Thickness = 1.5

-- Draggable Logic
local dragging, dragInput, dragStart, startPos
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
    end
end)
MainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Sidebar (Left - Scrollable)
local Sidebar = Instance.new("ScrollingFrame", MainFrame)
Sidebar.Size = UDim2.new(0, 100, 1, 0)
Sidebar.BackgroundColor3 = UI.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.ScrollBarThickness = 2
Sidebar.ScrollBarImageColor3 = UI.Accent
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 6)
local SideList = Instance.new("UIListLayout", Sidebar)
SideList.SortOrder = Enum.SortOrder.LayoutOrder
SideList.Padding = UDim.new(0, 5)
local SidePad = Instance.new("UIPadding", Sidebar)
SidePad.PaddingTop = UDim.new(0, 10)
SidePad.PaddingLeft = UDim.new(0, 5)

-- Content Container (Right)
local Content = Instance.new("Frame", MainFrame)
Content.Size = UDim2.new(1, -110, 1, 0)
Content.Position = UDim2.new(0, 110, 0, 0)
Content.BackgroundTransparency = 1

local Pages = {}

-- Helper Functions UI
local function MakePage(name)
    local p = Instance.new("ScrollingFrame", Content)
    p.Name = name
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.Visible = false
    p.ScrollBarThickness = 2
    p.ScrollBarImageColor3 = UI.Accent
    
    local list = Instance.new("UIListLayout", p)
    list.Padding = UDim.new(0, 6)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    
    local pad = Instance.new("UIPadding", p)
    pad.PaddingTop = UDim.new(0, 10); pad.PaddingLeft = UDim.new(0, 5); pad.PaddingRight = UDim.new(0, 5)
    
    Pages[name] = p
    return p
end

local function MakeTab(text, pageName)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Text = text
    btn.BackgroundColor3 = UI.Bg
    btn.TextColor3 = UI.SubText
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    -- Visual selection logic
    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do p.Visible = false end
        Pages[pageName].Visible = true
        
        -- Reset all buttons in Sidebar
        for _, b in pairs(Sidebar:GetChildren()) do
            if b:IsA("TextButton") then
                b.TextColor3 = UI.SubText
                b.BackgroundColor3 = UI.Bg
            end
        end
        -- Active State
        btn.TextColor3 = UI.Accent
        btn.BackgroundColor3 = Color3.fromRGB(20, 40, 30)
    end)
    return btn
end

local function MakeBtn(parent, text, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(20, 50, 30)
    btn.TextColor3 = UI.Text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    local s = Instance.new("UIStroke", btn); s.Color = UI.Accent; s.ApplyStrokeMode = "Border"; s.Transparency = 0.7
    
    btn.MouseButton1Click:Connect(function() callback(btn) end)
    return btn
end

local function MakeInput(parent, placeholder, default, callback)
    local box = Instance.new("TextBox", parent)
    box.Size = UDim2.new(1, 0, 0, 28)
    box.Text = default
    box.PlaceholderText = placeholder
    box.BackgroundColor3 = Color3.fromRGB(15, 35, 20)
    box.TextColor3 = UI.Accent
    box.Font = Enum.Font.Gotham
    box.TextSize = 11
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    box.FocusLost:Connect(function() callback(box.Text) end)
    return box
end

local function MakeLabel(parent, text)
    local lab = Instance.new("TextLabel", parent)
    lab.Size = UDim2.new(1,0,0,20)
    lab.Text = text
    lab.TextColor3 = UI.Accent
    lab.BackgroundTransparency = 1
    lab.Font = Enum.Font.GothamBlack
    lab.TextSize = 12
    return lab
end

-- // CREATE PAGES & CONTENT
local P_Fish = MakePage("Fishing")
local P_Main = MakePage("Main")
local P_Misc = MakePage("Misc")

-- Tab Buttons (Sequential & Scrollable in Sidebar)
MakeTab("🎣 FISH", "Fishing")
MakeTab("💰 MAIN", "Main")
MakeTab("☁️ MISC", "Misc")

-- [PAGE 1: FISHING]
MakeLabel(P_Fish, "TURBO SETTINGS")
MakeBtn(P_Fish, "Status: STOPPED", function(btn)
    getgenv().fishingStart = not getgenv().fishingStart
    if getgenv().fishingStart then
        btn.Text = "Status: RUNNING ⚡"
        btn.TextColor3 = UI.Accent
        task.spawn(startTurboFishing)
    else
        btn.Text = "Status: STOPPED"
        btn.TextColor3 = UI.Text
    end
end)
MakeInput(P_Fish, "Charge Delay (Default 0)", "0", function(v) _G.FishSettings.DelayCharge = tonumber(v) or 0 end)
MakeInput(P_Fish, "Reset Delay (Default 0)", "0", function(v) _G.FishSettings.DelayReset = tonumber(v) or 0 end)

-- [PAGE 2: MAIN]
MakeLabel(P_Main, "AUTO SELL")
MakeBtn(P_Main, "Auto Sell: OFF", function(btn)
    _G.SellSettings.Active = not _G.SellSettings.Active
    btn.Text = "Auto Sell: " .. (_G.SellSettings.Active and "ON" or "OFF")
end)
MakeInput(P_Main, "Interval (Seconds)", "300", function(v) _G.SellSettings.Interval = tonumber(v) or 300 end)
MakeBtn(P_Main, "SELL NOW (Manual)", function()
    Notify("System", "Selling Items...")
    if SellItemRemote then
        for _, item in pairs(Player.Backpack:GetChildren()) do
            if item:IsA("Tool") and item.Name ~= "Rod" then
                pcall(function() SellItemRemote:InvokeServer(item) end)
            end
        end
    else
        Notify("Error", "Remote Sell not found!")
    end
end)

-- [PAGE 3: MISC / WEATHER]
MakeLabel(P_Misc, "WEATHER SELECTOR")

-- Dropdown Logic Sederhana
local DropOpen = false
local DropFrame = Instance.new("Frame", P_Misc)
DropFrame.Size = UDim2.new(1,0,0,150); DropFrame.BackgroundTransparency=1
local DropBtn = MakeBtn(DropFrame, "Select Weather ▼", function(b)
    DropOpen = not DropOpen
    b.Parent.Height.Visible = DropOpen
end)
DropBtn.Parent = P_Misc -- Pindahkan tombol ke layout utama
DropFrame:Destroy() -- Hapus frame dummy

local WeatherOpts = {"Wind", "Cloudy", "Snow", "Storm", "Radiant", "Rain"}
local OptionContainer = Instance.new("Frame", P_Misc)
OptionContainer.Size = UDim2.new(1,0,0, #WeatherOpts * 22)
OptionContainer.BackgroundTransparency = 1
OptionContainer.Visible = false
DropBtn.MouseButton1Click:Connect(function() OptionContainer.Visible = not OptionContainer.Visible end)

local WLayout = Instance.new("UIGridLayout", OptionContainer)
WLayout.CellSize = UDim2.new(0.48, 0, 0, 20)

for _, w in pairs(WeatherOpts) do
    local b = Instance.new("TextButton", OptionContainer)
    b.Text = w
    b.BackgroundColor3 = UI.Sidebar
    b.TextColor3 = UI.SubText
    b.TextSize = 10
    Instance.new("UICorner", b)
    
    b.MouseButton1Click:Connect(function()
        if _G.WeatherSettings.Selected[w] then
            _G.WeatherSettings.Selected[w] = nil
            b.TextColor3 = UI.SubText
            b.UIStroke.Transparency = 1
        else
            _G.WeatherSettings.Selected[w] = true
            b.TextColor3 = UI.Accent
            local s = Instance.new("UIStroke", b); s.Color = UI.Accent; s.ApplyStrokeMode = "Border"
        end
    end)
end

MakeBtn(P_Misc, "BUY SELECTED NOW", function()
    local list = {}
    for k,v in pairs(_G.WeatherSettings.Selected) do if v then table.insert(list, k) end end
    if #list == 0 then Notify("Warning", "Pilih cuaca dulu!"); return end
    
    if WeatherRemote then
        local t = list[math.random(1, #list)]
        pcall(function() WeatherRemote:FireServer(t) end)
        Notify("Bought", t)
    else
        Notify("Error", "Remote Weather Missing")
    end
end)

-- // AUTO RUN LOOPS
task.spawn(function()
    while true do
        task.wait(1)
        if _G.SellSettings.Active and os.time() > _G.SellSettings.NextSellTime then
             if SellItemRemote then
                 local oldFish = getgenv().fishingStart
                 if oldFish then getgenv().fishingStart = false; task.wait(1) end
                 
                 for _, item in pairs(Player.Backpack:GetChildren()) do
                    if item:IsA("Tool") and item.Name ~= "Rod" then
                        pcall(function() SellItemRemote:InvokeServer(item) end)
                    end
                end
                
                if oldFish then task.wait(0.5); getgenv().fishingStart = true; task.spawn(startTurboFishing) end
            end
            _G.SellSettings.NextSellTime = os.time() + _G.SellSettings.Interval
        end
    end
end)

-- Initialize Default Page
Pages["Fishing"].Visible = true
Notify("RakaHensem V7", "Deep Scan Fixed: Green/Orange Loaded")
