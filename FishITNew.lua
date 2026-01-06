--[[ 
    RakaHensem Utility V6 - Modular Optimized 
    Tabs: Fishing | Main | Misc
    Feature: Turbo Fishing, Auto Weather Fix, Auto Sell
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer

-- // 1. REMOTE & VARIABLES
local net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
local ChargeRod    = net["RF/ChargeFishingRod"]
local RequestGame  = net["RF/RequestFishingMinigameStarted"]
local CompleteGame = net["RE/FishingCompleted"]
local CancelInput  = net["RF/CancelFishingInputs"]
local SellItemRemote = net:FindFirstChild("RF/SellItem") 

-- Auto Find Weather Remote (Supaya tombol tidak hilang)
local WeatherRemote = net:FindFirstChild("RF/PurchaseWeather") or net:FindFirstChild("RF/WeatherTotem") or net:FindFirstChild("RF/WorldEvent")

-- Konfigurasi Global
getgenv().fishingStart = false
_G.FishSettings = { DelayCharge = 0, DelayReset = 0 }
_G.SellSettings = { Active = false, Interval = 300, NextSellTime = os.time() + 300 }
_G.WeatherSettings = { Active = false, Selected = {}, Interval = 5 }

local fishArgs = { -1.115296483039856, 0, 1763651451.636425 }

-- // 2. NOTIFIKASI
local function Notify(title, text)
    game:GetService("StarterGui"):SetCore("SendNotification", { Title = title, Text = text, Duration = 3 })
end

-- // 3. OPTIMIZED FISHING LOOP (NO DELAY METHOD)
local function startTurboFishing()
    -- Reset input awal
    task.spawn(function() pcall(function() CancelInput:InvokeServer() end) end)
    
    while getgenv().fishingStart do
        -- 1. Charge & Request (Concurrent / Bersamaan tanpa tunggu)
        task.spawn(function() pcall(function() ChargeRod:InvokeServer() end) end)
        task.spawn(function() pcall(function() RequestGame:InvokeServer(unpack(fishArgs)) end) end)
        
        -- Delay Charge (Jika user mau pelan, kalau 0 berarti secepat kilat)
        if _G.FishSettings.DelayCharge > 0 then task.wait(_G.FishSettings.DelayCharge) end
        
        -- 2. Complete Game (Instant Fire)
        pcall(function() CompleteGame:FireServer() end)
        
        -- 3. Reset (Cancel Input untuk siap lempar lagi)
        task.spawn(function() pcall(function() CancelInput:InvokeServer() end) end)
        
        -- Delay Reset & Heartbeat agar tidak crash
        if _G.FishSettings.DelayReset > 0 then 
            task.wait(_G.FishSettings.DelayReset) 
        else 
            RunService.Heartbeat:Wait() -- Minimal wait untuk performa
        end
        
        if not getgenv().fishingStart then break end
    end
end

-- // 4. UI SYSTEM (DARK FIRE THEME)
local UI_THEME = {
    Color = Color3.fromRGB(10, 10, 10), 
    Header = Color3.fromRGB(25, 20, 20),
    Accent = Color3.fromRGB(255, 80, 0), -- Orange Api
    Text = Color3.fromRGB(255, 240, 230),
    Font = Enum.Font.GothamBold
}

if CoreGui:FindFirstChild("SeraphinHelper") then CoreGui.SeraphinHelper:Destroy() end
local ScreenGui = Instance.new("ScreenGui", CoreGui)
ScreenGui.Name = "SeraphinHelper"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 320, 0, 400)
MainFrame.Position = UDim2.new(0.5, -160, 0.4, 0)
MainFrame.BackgroundColor3 = UI_THEME.Color
MainFrame.BorderSizePixel = 0
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MainFrame).Color = UI_THEME.Accent
MainFrame.UIStroke.Thickness = 1.5

-- Header
local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 35)
Header.BackgroundColor3 = UI_THEME.Header
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)
local Title = Instance.new("TextLabel", Header)
Title.Text = "RakaHensem Utility V6"
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = UI_THEME.Accent
Title.Font = UI_THEME.Font
Title.TextSize = 14

-- Tab Container
local TabHolder = Instance.new("Frame", MainFrame)
TabHolder.Size = UDim2.new(1, -10, 0, 30)
TabHolder.Position = UDim2.new(0, 5, 0, 40)
TabHolder.BackgroundTransparency = 1
local TabGrid = Instance.new("UIGridLayout", TabHolder)
TabGrid.CellSize = UDim2.new(0.32, 0, 1, 0)
TabGrid.CellPadding = UDim2.new(0, 4, 0, 0)

-- Pages
local PageContainer = Instance.new("Frame", MainFrame)
PageContainer.Size = UDim2.new(1, -10, 1, -80)
PageContainer.Position = UDim2.new(0, 5, 0, 75)
PageContainer.BackgroundTransparency = 1

local Pages = {
    Fishing = Instance.new("ScrollingFrame", PageContainer),
    Main = Instance.new("ScrollingFrame", PageContainer),
    Misc = Instance.new("ScrollingFrame", PageContainer)
}

-- Setup Pages
for name, page in pairs(Pages) do
    page.Name = name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 2
    page.Visible = false
    local list = Instance.new("UIListLayout", page)
    list.Padding = UDim.new(0, 5)
    list.SortOrder = Enum.SortOrder.LayoutOrder
end
Pages.Fishing.Visible = true -- Default Tab

-- // UI BUILDER FUNCTIONS
local function CreateTabBtn(text, pageName)
    local btn = Instance.new("TextButton", TabHolder)
    btn.Text = text
    btn.BackgroundColor3 = UI_THEME.Header
    btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    btn.Font = UI_THEME.Font
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do p.Visible = false end
        Pages[pageName].Visible = true
        
        -- Reset all tab colors
        for _, child in pairs(TabHolder:GetChildren()) do
            if child:IsA("TextButton") then
                child.TextColor3 = Color3.fromRGB(150, 150, 150)
                child.UIStroke.Transparency = 1
            end
        end
        -- Highlight active
        btn.TextColor3 = UI_THEME.Accent
        btn.UIStroke.Transparency = 0
    end)
    local s = Instance.new("UIStroke", btn); s.Color = UI_THEME.Accent; s.Transparency = 1
    return btn
end

local function CreateBtn(parent, text, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.Text = text
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    btn.TextColor3 = UI_THEME.Text
    btn.Font = UI_THEME.Font
    btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    local s = Instance.new("UIStroke", btn); s.Color = Color3.fromRGB(60, 60, 60); s.ApplyStrokeMode = "Border"
    
    btn.MouseButton1Click:Connect(function() callback(btn) end)
    return btn
end

local function CreateInput(parent, placeholder, default, callback)
    local box = Instance.new("TextBox", parent)
    box.Size = UDim2.new(1, 0, 0, 30)
    box.Text = default
    box.PlaceholderText = placeholder
    box.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    box.TextColor3 = UI_THEME.Accent
    box.Font = UI_THEME.Font
    box.TextSize = 11
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    box.FocusLost:Connect(function() callback(box.Text) end)
    return box
end

local function CreateDropdown(parent, title, options, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundTransparency = 1
    frame.ZIndex = 5
    
    local mainBtn = Instance.new("TextButton", frame)
    mainBtn.Size = UDim2.new(1, 0, 1, 0)
    mainBtn.Text = title .. " "
    mainBtn.BackgroundColor3 = Color3.fromRGB(20,20,20)
    mainBtn.TextColor3 = UI_THEME.Text
    mainBtn.Font = UI_THEME.Font; mainBtn.TextSize = 11
    Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0,4)
    
    local list = Instance.new("Frame", frame)
    list.Size = UDim2.new(1, 0, 0, #options * 25)
    list.Position = UDim2.new(0, 0, 1, 2)
    list.BackgroundColor3 = Color3.fromRGB(15,15,15)
    list.Visible = false
    list.ZIndex = 10
    Instance.new("UICorner", list)
    Instance.new("UIListLayout", list)
    
    local open = false
    mainBtn.MouseButton1Click:Connect(function()
        open = not open
        list.Visible = open
        frame.Size = open and UDim2.new(1, 0, 0, 30 + (#options * 25)) or UDim2.new(1, 0, 0, 30)
        mainBtn.Text = title .. (open and " " or " ")
    end)
    
    for _, opt in ipairs(options) do
        local b = Instance.new("TextButton", list)
        b.Size = UDim2.new(1, 0, 0, 25)
        b.Text = opt
        b.BackgroundColor3 = Color3.fromRGB(15,15,15)
        b.TextColor3 = Color3.fromRGB(150,150,150)
        b.Font = UI_THEME.Font; b.TextSize = 10
        b.BorderSizePixel = 0
        b.MouseButton1Click:Connect(function()
            callback(opt, b)
        end)
    end
end

-- // TAB CREATION
local T1 = CreateTabBtn("FISHING", "Fishing")
local T2 = CreateTabBtn("MAIN", "Main")
local T3 = CreateTabBtn("MISC", "Misc")

-- [[ TAB 1: FISHING ]]
local LabelFish = Instance.new("TextLabel", Pages.Fishing); LabelFish.Text = "TURBO FISHING"; LabelFish.Size = UDim2.new(1,0,0,20); LabelFish.TextColor3 = UI_THEME.Accent; LabelFish.BackgroundTransparency=1; LabelFish.Font=UI_THEME.Font

CreateBtn(Pages.Fishing, "Toggle Auto Fish: OFF", function(btn)
    getgenv().fishingStart = not getgenv().fishingStart
    if getgenv().fishingStart then
        btn.Text = "Toggle Auto Fish: ON"
        btn.TextColor3 = UI_THEME.Accent
        task.spawn(startTurboFishing)
    else
        btn.Text = "Toggle Auto Fish: OFF"
        btn.TextColor3 = UI_THEME.Text
        pcall(function() CancelInput:InvokeServer() end)
    end
end)

CreateInput(Pages.Fishing, "Charge Delay (0 for fast)", "0", function(txt)
    _G.FishSettings.DelayCharge = tonumber(txt) or 0
end)

CreateInput(Pages.Fishing, "Reset Delay (0 for fast)", "0", function(txt)
    _G.FishSettings.DelayReset = tonumber(txt) or 0
end)

-- [[ TAB 2: MAIN (Auto Sell & Utils) ]]
local LabelSell = Instance.new("TextLabel", Pages.Main); LabelSell.Text = "ECONOMY & PLAYER"; LabelSell.Size = UDim2.new(1,0,0,20); LabelSell.TextColor3 = UI_THEME.Accent; LabelSell.BackgroundTransparency=1; LabelSell.Font=UI_THEME.Font

CreateBtn(Pages.Main, "Auto Sell: OFF", function(btn)
    _G.SellSettings.Active = not _G.SellSettings.Active
    btn.Text = "Auto Sell: " .. (_G.SellSettings.Active and "ON" or "OFF")
    btn.TextColor3 = _G.SellSettings.Active and UI_THEME.Accent or UI_THEME.Text
end)

CreateInput(Pages.Main, "Sell Interval (seconds)", "300", function(txt)
    _G.SellSettings.Interval = tonumber(txt) or 300
end)

CreateBtn(Pages.Main, "SELL ALL ITEMS NOW", function()
    Notify("System", "Selling items...")
    if SellItemRemote then
        for _, item in pairs(Player.Backpack:GetChildren()) do
            if item:IsA("Tool") and item.Name ~= "Rod" then
                SellItemRemote:InvokeServer(item)
            end
        end
    else
        Notify("Error", "Sell Remote not found!")
    end
end)

-- [[ TAB 3: MISC (Weather) ]]
local LabelWeather = Instance.new("TextLabel", Pages.Misc); LabelWeather.Text = "WEATHER CONTROL"; LabelWeather.Size = UDim2.new(1,0,0,20); LabelWeather.TextColor3 = UI_THEME.Accent; LabelWeather.BackgroundTransparency=1; LabelWeather.Font=UI_THEME.Font

CreateDropdown(Pages.Misc, "Select Weather", {"Wind", "Cloudy", "Snow", "Storm", "Radiant", "Rain"}, function(opt, btn)
    if _G.WeatherSettings.Selected[opt] then
        _G.WeatherSettings.Selected[opt] = nil
        btn.TextColor3 = Color3.fromRGB(150,150,150)
        btn.Text = opt
    else
        _G.WeatherSettings.Selected[opt] = true
        btn.TextColor3 = UI_THEME.Accent
        btn.Text = " " .. opt
    end
end)

-- Tombol Fix untuk membeli cuaca
CreateBtn(Pages.Misc, "BUY SELECTED WEATHER NOW", function()
    local list = {}
    for k,v in pairs(_G.WeatherSettings.Selected) do if v then table.insert(list, k) end end
    
    if #list == 0 then Notify("Weather", "Pilih cuaca dulu di dropdown!"); return end
    
    local target = list[math.random(1, #list)]
    
    if WeatherRemote then
        pcall(function() WeatherRemote:FireServer(target) end)
        Notify("Weather", "Membeli: " .. target)
    else
        Notify("Error", "Remote Weather Tidak Ditemukan!")
    end
end)

CreateBtn(Pages.Misc, "Auto Buy Monitor (5s): OFF", function(btn)
    _G.WeatherSettings.Active = not _G.WeatherSettings.Active
    btn.Text = "Auto Buy Monitor: " .. (_G.WeatherSettings.Active and "ON" or "OFF")
    
    if _G.WeatherSettings.Active then
        task.spawn(function()
            while _G.WeatherSettings.Active do
                local list = {}
                for k,v in pairs(_G.WeatherSettings.Selected) do if v then table.insert(list, k) end end
                
                if #list > 0 and WeatherRemote then
                    local target = list[math.random(1, #list)]
                    pcall(function() WeatherRemote:FireServer(target) end)
                end
                task.wait(_G.WeatherSettings.Interval)
            end
        end)
    end
end)

-- // AUTO SELL LOOP BACKEND
task.spawn(function()
    while true do
        task.wait(1)
        if _G.SellSettings.Active and os.time() >= _G.SellSettings.NextSellTime then
            local wasFish = getgenv().fishingStart
            if wasFish then getgenv().fishingStart = false; task.wait(1) end
            
            if SellItemRemote then
                 for _, item in pairs(Player.Backpack:GetChildren()) do
                    if item:IsA("Tool") and item.Name ~= "Rod" then
                        pcall(function() SellItemRemote:InvokeServer(item) end)
                    end
                end
            end
            
            if wasFish then task.wait(1); getgenv().fishingStart = true; task.spawn(startTurboFishing) end
            _G.SellSettings.NextSellTime = os.time() + _G.SellSettings.Interval
        end
    end
end)

Notify("RakaHensem", "Script V6 Loaded - 3 Tabs Active")
