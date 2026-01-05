-- [1] Notifikasi Awal
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Raka Ganteng",
        Text = "Loading: SERAPHIN (Auto Sell + Weather)",
        Duration = 2,
    })
end)

task.wait(2.5)

-- [2] Variable & Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage") 
local VirtualInputManager = game:GetService("VirtualInputManager") 

local Player = Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local HRP = Char:WaitForChild("HumanoidRootPart", 5)
local Hum = Char:WaitForChild("Humanoid", 5)

Player.CharacterAdded:Connect(function(newChar)
    Char = newChar
    HRP = newChar:WaitForChild("HumanoidRootPart", 10)
    Hum = newChar:WaitForChild("Humanoid", 10)
end)

-- // DEFINE REMOTES
local net = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_net@0.2.0"):WaitForChild("net")
local ChargeRod    = net["RF/ChargeFishingRod"]
local RequestGame  = net["RF/RequestFishingMinigameStarted"]
local CompleteGame = net["RE/FishingCompleted"]
local CancelInput  = net["RF/CancelFishingInputs"]
-- [NEW REMOTE]
local SellAll      = net["RF/SellAllItems"] 
-- Remote Weather biasanya berbeda-beda tiap update, ini placeholder logika monitoring
-- local UseTotem = net["RF/UseTotemItem"] -- (Contoh jika ada)

-- // KONFIGURASI GLOBAL
getgenv().fishingStart = false
_G.FishSettings = {
    DelayCharge = 0.85, 
    DelayReset = 0.1,   
}

_G.SellSettings = {
    AutoSell = false,
    Interval = 600, -- Detik
    IsSelling = false
}

_G.WeatherSettings = {
    Active = false,
    Target = "Rain" -- Default target
}

-- Args Lemparan
local fishArgs = { -1.115296483039856, 0, 1763651451.636425 }

-- =====================================================
-- 🛡️ FISHING BLOCKER
-- =====================================================
local FishingBlocker = { Enabled = false, AutoGreat = true }
local BLOCKED_REMOTES = {
    [ChargeRod] = true,
    [RequestGame] = true,
    [CompleteGame] = true,
    [CancelInput] = true,
}

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if FishingBlocker.Enabled and BLOCKED_REMOTES[self] and not checkcaller() then
        if method == "InvokeServer" then
            return task.wait(9e9) 
        elseif method == "FireServer" then
            return nil
        end
    end
    return oldNamecall(self, ...)
end)

-- =====================================================
-- 🎣 FUNGSI LOOP FISHING (HYPER FAST)
-- =====================================================
local function startFishingHyperLoop()
    if FishingBlocker.AutoGreat then
        local agRemote = net:FindFirstChild("RF/UpdateAutoFishingState")
        if agRemote then agRemote:InvokeServer(true) end
    end

    pcall(function() CancelInput:InvokeServer() end)
    task.wait(0.05)

    while getgenv().fishingStart do
        -- Cek jika sedang Auto Sell, pause loop ini
        if _G.SellSettings.IsSelling then
            task.wait(1)
            continue
        end

        task.spawn(function() 
            pcall(function() ChargeRod:InvokeServer() end) 
        end)
        
        task.spawn(function() 
            pcall(function() RequestGame:InvokeServer(unpack(fishArgs)) end) 
        end)
        
        task.wait(_G.FishSettings.DelayCharge)
        
        if not getgenv().fishingStart then break end

        pcall(function() CompleteGame:FireServer() end)
        
        task.wait(_G.FishSettings.DelayReset)
        pcall(function() CancelInput:InvokeServer() end)
    end
end

-- =====================================================
-- 💰 AUTO SELL LOGIC
-- =====================================================
task.spawn(function()
    while true do
        task.wait(1)
        if _G.SellSettings.AutoSell then
            -- Tunggu Interval
            for i = 1, _G.SellSettings.Interval do
                if not _G.SellSettings.AutoSell then break end
                task.wait(1)
            end
            
            if _G.SellSettings.AutoSell then
                -- Mulai Proses Jual
                _G.SellSettings.IsSelling = true
                
                -- Stop Fishing inputs temporarily
                pcall(function() CancelInput:InvokeServer() end)
                task.wait(0.5)
                
                -- Sell
                pcall(function() SellAll:InvokeServer() end)
                
                -- Notif
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "Auto Sell",
                    Text = "Items Sold!",
                    Duration = 2
                })
                
                task.wait(1)
                _G.SellSettings.IsSelling = false
                
                -- Resume Fishing logic is handled inside the loop check
            end
        end
    end
end)

-- =====================================================
-- ☁️ AUTO WEATHER LOGIC (MONITOR)
-- =====================================================
task.spawn(function()
    while true do
        task.wait(5) -- Cek setiap 5 detik
        if _G.WeatherSettings.Active then
            -- Logika deteksi cuaca (Simpel check via Lighting atau UI game)
            -- Karena kita tidak punya akses remote beli spesifik tanpa item ID,
            -- ini hanya monitor dasar.
            -- Implementasi penuh butuh Remote "EquipTotem" + "UseItem"
            
            -- Placeholder Logic:
            -- local current = Lighting.Sky.Name (Contoh)
            -- if current ~= _G.WeatherSettings.Target then
                -- Code beli weather disini
            -- end
        end
    end
end)

-- =====================================================
-- 🚫 ANTI-AFK FUNCTION
-- =====================================================
local function StartAntiAFK()
    local vu = game:GetService("VirtualUser")
    Player.Idled:Connect(function()
        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

-- // Konfigurasi Visual (DARK FIRE THEME)
local UI_THEME = {
    MinWidth = 320, 
    MinHeight = 350, 
    Color = Color3.fromRGB(8, 8, 8), 
    Transparency = 0.25, 
    HeaderColor = Color3.fromRGB(20, 15, 15),
    Accent = Color3.fromRGB(255, 69, 0), -- Merah Api
    TabOff = Color3.fromRGB(120, 120, 120),
    TabOn = Color3.fromRGB(255, 165, 0),
    TextColor = Color3.fromRGB(255, 245, 230),
    SubTextColor = Color3.fromRGB(180, 150, 140),
    Font = Enum.Font.GothamBold,
    BtnFont = Enum.Font.GothamMedium 
}

if CoreGui:FindFirstChild("SeraphinHelper") then CoreGui.SeraphinHelper:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SeraphinHelper"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ====================================================
-- [1] MINI FLOATING HUD
-- ====================================================
local FloatHUD = Instance.new("Frame", ScreenGui)
FloatHUD.Name = "FloatingStats"
FloatHUD.Size = UDim2.new(0, 140, 0, 125) 
FloatHUD.Position = UDim2.new(0.85, 0, 0.4, 0)
FloatHUD.BackgroundColor3 = Color3.fromRGB(5, 5, 5) 
FloatHUD.BackgroundTransparency = 0.3
FloatHUD.Visible = true
FloatHUD.Active = true
FloatHUD.Draggable = true 

local HudStroke = Instance.new("UIStroke", FloatHUD)
HudStroke.Color = UI_THEME.Accent 
HudStroke.Thickness = 1.5
HudStroke.Transparency = 0.3
Instance.new("UICorner", FloatHUD).CornerRadius = UDim.new(0, 8)
local ListLayoutHUD = Instance.new("UIListLayout", FloatHUD)
ListLayoutHUD.FillDirection = Enum.FillDirection.Vertical
ListLayoutHUD.Padding = UDim.new(0, 6) 
ListLayoutHUD.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayoutHUD.VerticalAlignment = Enum.VerticalAlignment.Top
ListLayoutHUD.SortOrder = Enum.SortOrder.LayoutOrder 
local PaddingHUD = Instance.new("UIPadding", FloatHUD)
PaddingHUD.PaddingTop = UDim.new(0, 10) 
PaddingHUD.PaddingBottom = UDim.new(0, 8)
PaddingHUD.PaddingLeft = UDim.new(0, 5)
PaddingHUD.PaddingRight = UDim.new(0, 5)

local TitleLabel = Instance.new("TextLabel", FloatHUD)
TitleLabel.LayoutOrder = 1
TitleLabel.Size = UDim2.new(1, 0, 0, 15)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "PANEL SERAPHIN"
TitleLabel.TextColor3 = UI_THEME.Accent 
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 14
TitleLabel.TextStrokeTransparency = 0.8

local Div = Instance.new("Frame", FloatHUD)
Div.LayoutOrder = 2
Div.Size = UDim2.new(0.8, 0, 0, 1)
Div.BackgroundColor3 = Color3.fromRGB(100, 50, 0)
Div.BorderSizePixel = 0

local function CreateStatBlock(titleText, defaultVal, order)
    local Block = Instance.new("Frame", FloatHUD)
    Block.Name = titleText.."Block"
    Block.LayoutOrder = order
    Block.Size = UDim2.new(1, 0, 0, 35) 
    Block.BackgroundTransparency = 1
    
    local LblTitle = Instance.new("TextLabel", Block)
    LblTitle.Name = "Title"
    LblTitle.Size = UDim2.new(1, 0, 0, 12)
    LblTitle.Position = UDim2.new(0, 0, 0, 0)
    LblTitle.BackgroundTransparency = 1
    LblTitle.Text = string.upper(titleText)
    LblTitle.TextColor3 = UI_THEME.SubTextColor
    LblTitle.Font = Enum.Font.GothamBold
    LblTitle.TextSize = 9
    
    local LblValue = Instance.new("TextLabel", Block)
    LblValue.Name = "Value"
    LblValue.Size = UDim2.new(1, 0, 0, 20)
    LblValue.Position = UDim2.new(0, 0, 0, 14)
    LblValue.BackgroundTransparency = 1
    LblValue.Text = defaultVal
    LblValue.TextColor3 = UI_THEME.TextColor
    LblValue.Font = Enum.Font.GothamBold
    LblValue.TextSize = 16 
    return LblValue 
end

local LblFishVal = CreateStatBlock("FISH CAUGHT", "Loading...", 3) 
local LblInvVal  = CreateStatBlock("BACKPACK", "0 / 0", 4)     

-- ====================================================
-- [2] MAIN MENU UI
-- ====================================================
local Main = Instance.new("Frame", ScreenGui)
Main.Name = "Main"
Main.Size = UDim2.new(0, UI_THEME.MinWidth, 0, UI_THEME.MinHeight)
Main.Position = UDim2.new(0.5, -UI_THEME.MinWidth/2, 0.4, 0)
Main.BackgroundColor3 = UI_THEME.Color
Main.BackgroundTransparency = UI_THEME.Transparency
Main.Active = true
Main.ClipsDescendants = true 
Main.Draggable = false 

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = UI_THEME.Accent
MainStroke.Thickness = 1.5
MainStroke.Transparency = 0.2

local Header = Instance.new("Frame", Main)
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 32) 
Header.BackgroundColor3 = UI_THEME.HeaderColor
Header.BackgroundTransparency = 0.5
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 8)

-- Custom Drag Script
local dragToggle, dragInput, dragStart, startPos
local function updateInput(input)
    local delta = input.Position - dragStart
    local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    Main.Position = position
end
Header.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        dragToggle = true
        dragStart = input.Position
        startPos = Main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragToggle = false
            end
        end)
    end
end)
Header.InputChanged:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragToggle then
        updateInput(input)
    end
end)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(1, -60, 1, 0) 
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Text = "SERAPHIN <font color=\"rgb(255,69,0)\">HELPER</font>" 
Title.RichText = true
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = UI_THEME.Font
Title.TextSize = 12
Title.BackgroundTransparency = 1
Title.TextXAlignment = Enum.TextXAlignment.Left 

local HideBtn = Instance.new("TextButton", Header)
HideBtn.Size = UDim2.new(0, 45, 0, 20) 
HideBtn.Position = UDim2.new(1, -50, 0.5, -10)
HideBtn.Text = "Hide" 
HideBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
HideBtn.BackgroundTransparency = 0.5
HideBtn.TextColor3 = UI_THEME.Accent
HideBtn.Font = Enum.Font.GothamBold
HideBtn.TextSize = 10
HideBtn.AutoButtonColor = true
Instance.new("UICorner", HideBtn).CornerRadius = UDim.new(0, 4)
local HideStroke = Instance.new("UIStroke", HideBtn)
HideStroke.Color = UI_THEME.Accent
HideStroke.Transparency = 0.6

-- ====================================================
-- [3] TAB SYSTEM (HORIZONTAL - 4 TABS)
-- ====================================================
local TabHolder = Instance.new("Frame", Main)
TabHolder.Name = "TabHolder"
TabHolder.Size = UDim2.new(1, -10, 0, 25) 
TabHolder.Position = UDim2.new(0, 5, 0, 35) 
TabHolder.BackgroundTransparency = 1

local TabListLayout = Instance.new("UIListLayout", TabHolder)
TabListLayout.FillDirection = Enum.FillDirection.Horizontal
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 4) 
TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function CreateTabBtn(name, text, order)
    local btn = Instance.new("TextButton", TabHolder)
    btn.Name = name
    btn.LayoutOrder = order
    -- 4 Tombol, jadi ukuran sekitar 0.24 (24%)
    btn.Size = UDim2.new(0.24, 0, 1, 0) 
    btn.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    btn.BackgroundTransparency = 0.3
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    btn.TextColor3 = UI_THEME.TabOff
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    return btn
end

local TabFishingBtn = CreateTabBtn("FishingTab", "FISHING", 1)
local TabMainBtn    = CreateTabBtn("MainTab", "MAIN", 2)
local TabSellBtn    = CreateTabBtn("SellTab", "SELL", 3)
local TabMiscBtn    = CreateTabBtn("MiscTab", "MISC", 4)

-- PAGES CONTAINER
local PageContainer = Instance.new("Frame", Main)
PageContainer.Name = "PageContainer"
PageContainer.Size = UDim2.new(1, -16, 1, -70) 
PageContainer.Position = UDim2.new(0, 8, 0, 65)
PageContainer.BackgroundTransparency = 1

-- Helper Grid
local function MakeGrid(page)
    local g = Instance.new("UIGridLayout", page)
    g.CellSize = UDim2.new(0, 140, 0, 28) 
    g.CellPadding = UDim2.new(0, 8, 0, 6) 
    g.HorizontalAlignment = Enum.HorizontalAlignment.Center
    return g
end

-- Page 1: Fishing
local PageFishing = Instance.new("Frame", PageContainer)
PageFishing.Name = "PageFishing"
PageFishing.Size = UDim2.new(1, 0, 1, 0)
PageFishing.BackgroundTransparency = 1
PageFishing.Visible = true
MakeGrid(PageFishing)

-- Page 2: Main
local PageMain = Instance.new("Frame", PageContainer)
PageMain.Name = "PageMain"
PageMain.Size = UDim2.new(1, 0, 1, 0)
PageMain.BackgroundTransparency = 1
PageMain.Visible = false
MakeGrid(PageMain)

-- Page 3: Sell
local PageSell = Instance.new("Frame", PageContainer)
PageSell.Name = "PageSell"
PageSell.Size = UDim2.new(1, 0, 1, 0)
PageSell.BackgroundTransparency = 1
PageSell.Visible = false
MakeGrid(PageSell)

-- Page 4: Misc
local PageMisc = Instance.new("Frame", PageContainer)
PageMisc.Name = "PageMisc"
PageMisc.Size = UDim2.new(1, 0, 1, 0)
PageMisc.BackgroundTransparency = 1
PageMisc.Visible = false
MakeGrid(PageMisc)

local function UpdateTabVisuals(activeTabName)
    -- Reset
    local offColor = Color3.fromRGB(15, 15, 15)
    local onColor  = Color3.fromRGB(40, 20, 10)
    
    TabFishingBtn.TextColor3 = UI_THEME.TabOff
    TabFishingBtn.BackgroundColor3 = offColor
    TabMainBtn.TextColor3 = UI_THEME.TabOff
    TabMainBtn.BackgroundColor3 = offColor
    TabSellBtn.TextColor3 = UI_THEME.TabOff
    TabSellBtn.BackgroundColor3 = offColor
    TabMiscBtn.TextColor3 = UI_THEME.TabOff
    TabMiscBtn.BackgroundColor3 = offColor
    
    -- Set Active
    if activeTabName == "Fishing" then
        TabFishingBtn.TextColor3 = UI_THEME.TabOn
        TabFishingBtn.BackgroundColor3 = onColor
    elseif activeTabName == "Main" then
        TabMainBtn.TextColor3 = UI_THEME.TabOn
        TabMainBtn.BackgroundColor3 = onColor
    elseif activeTabName == "Sell" then
        TabSellBtn.TextColor3 = UI_THEME.TabOn
        TabSellBtn.BackgroundColor3 = onColor
    elseif activeTabName == "Misc" then
        TabMiscBtn.TextColor3 = UI_THEME.TabOn
        TabMiscBtn.BackgroundColor3 = onColor
    end
end

local function SwitchTab(tabName)
    PageFishing.Visible = false
    PageMain.Visible = false
    PageSell.Visible = false
    PageMisc.Visible = false
    
    if tabName == "Fishing" then PageFishing.Visible = true end
    if tabName == "Main"    then PageMain.Visible = true end
    if tabName == "Sell"    then PageSell.Visible = true end
    if tabName == "Misc"    then PageMisc.Visible = true end
    
    UpdateTabVisuals(tabName)
end

TabFishingBtn.MouseButton1Click:Connect(function() SwitchTab("Fishing") end)
TabMainBtn.MouseButton1Click:Connect(function() SwitchTab("Main") end)
TabSellBtn.MouseButton1Click:Connect(function() SwitchTab("Sell") end)
TabMiscBtn.MouseButton1Click:Connect(function() SwitchTab("Misc") end)

UpdateTabVisuals("Fishing")

-- ====================================================
-- [4] LOGIC UI CREATION
-- ====================================================
local function MakeBtn(parent, text)
    local b = Instance.new("TextButton", parent)
    b.Text = text
    b.BackgroundColor3 = Color3.fromRGB(5, 5, 5) 
    b.BackgroundTransparency = 0.4
    b.TextColor3 = Color3.fromRGB(200, 200, 200)
    b.Font = UI_THEME.BtnFont 
    b.TextSize = 10 
    b.AutoButtonColor = true
    b.ClipsDescendants = true
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4) 
    local s = Instance.new("UIStroke", b)
    s.Color = Color3.fromRGB(60, 40, 40) 
    s.Thickness = 1
    s.Transparency = 0.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    return b
end

local function MakeInput(parent, placeholder, default)
    local b = Instance.new("TextBox", parent)
    b.PlaceholderText = placeholder
    b.Text = default
    b.BackgroundColor3 = Color3.fromRGB(15, 10, 10) 
    b.BackgroundTransparency = 0.4
    b.TextColor3 = UI_THEME.Accent
    b.PlaceholderColor3 = Color3.fromRGB(100, 80, 80)
    b.Font = UI_THEME.BtnFont 
    b.TextSize = 10 
    b.ClipsDescendants = true
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4) 
    local s = Instance.new("UIStroke", b)
    s.Color = Color3.fromRGB(60, 40, 40) 
    s.Thickness = 1
    s.Transparency = 0.5
    return b
end

local function ToggleVisual(btn, on)
    if on then
        btn.BackgroundColor3 = UI_THEME.Accent 
        btn.BackgroundTransparency = 0.2
        btn.TextColor3 = Color3.fromRGB(10, 5, 5) 
        btn.UIStroke.Transparency = 1
        btn.Font = Enum.Font.GothamBold
    else
        btn.BackgroundColor3 = Color3.fromRGB(5, 5, 5) 
        btn.BackgroundTransparency = 0.4
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.UIStroke.Transparency = 0.5
        btn.Font = UI_THEME.BtnFont
    end
end

-- >> ELEMENT DEFINITIONS <<

-- [TAB 1: FISHING]
local BtnAutoFish = MakeBtn(PageFishing, "Auto Fish: OFF")
local InputReel = MakeInput(PageFishing, "Delay Fishing (0.85)", "0.85")
local InputCast = MakeInput(PageFishing, "Delay Reset (0.1)", "0.1")

-- [TAB 2: MAIN]
local BtnEquip  = MakeBtn(PageMain, "Auto Equip: OFF")
local BtnWow    = MakeBtn(PageMain, "Water Walk: OFF")
local BtnFreeze = MakeBtn(PageMain, "Freeze: OFF")
local BtnNoclip = MakeBtn(PageMain, "No Clip: OFF")
local BtnBoost  = MakeBtn(PageMain, "Boost: OFF")
local BtnRender = MakeBtn(PageMain, "3D Render: ON") 
local BtnFps    = MakeBtn(PageMain, "FPS: Max") 

-- [TAB 3: SELL] (NEW)
local BtnAutoSell = MakeBtn(PageSell, "Auto Sell: OFF")
local InputSell   = MakeInput(PageSell, "Interval (s): 600", "600")
local BtnSellNow  = MakeBtn(PageSell, "SELL NOW")

-- [TAB 4: MISC]
local BtnWeather = MakeBtn(PageMisc, "Auto Weather: OFF")
local InputWeather = MakeInput(PageMisc, "Weather (Rain/Wind)", "Rain")
local BtnSave   = MakeBtn(PageMisc, "Save Pos")
local BtnLoad   = MakeBtn(PageMisc, "Load Pos")
local BtnClean  = MakeBtn(PageMisc, "Auto Clean: OFF") 
local BtnRejoin = MakeBtn(PageMisc, "Rejoin Server")
local BtnPanel  = MakeBtn(PageMisc, "Panel Info: ON")

-- ====================================================
-- [5] LOGIC CONNECTIONS
-- ====================================================

-- Input Updates
InputReel.FocusLost:Connect(function() local n=tonumber(InputReel.Text); if n then _G.FishSettings.DelayCharge=n end end)
InputCast.FocusLost:Connect(function() local n=tonumber(InputCast.Text); if n then _G.FishSettings.DelayReset=n end end)

InputSell.FocusLost:Connect(function()
    local n = tonumber(InputSell.Text)
    if n then _G.SellSettings.Interval = n end
end)
InputWeather.FocusLost:Connect(function()
    _G.WeatherSettings.Target = InputWeather.Text
end)

-- FPS Logic
local fpsT = 0
RunService.RenderStepped:Connect(function(dt)
    fpsT = fpsT + (1/dt - fpsT) * 0.1 
    local currentFps = math.floor(fpsT)
    Title.Text = "SERAPHIN <font color=\"rgb(255,69,0)\">HELPER</font>  |  FPS: <b>" .. currentFps .. "</b>"
end)
BtnFps.MouseButton1Click:Connect(function()
    local caps = {30, 60, 90, 144, 240, 99999}
    _G.fpsIndex = ((_G.fpsIndex or 5) % #caps) + 1
    local v = caps[_G.fpsIndex]
    if setfpscap then setfpscap(v) end
    local txt = (v > 1000) and "Max" or tostring(v)
    BtnFps.Text = "FPS: " .. txt
    ToggleVisual(BtnFps, true)
    wait(0.1)
    ToggleVisual(BtnFps, false)
end)

-- AUTO FISH
BtnAutoFish.MouseButton1Click:Connect(function()
    getgenv().fishingStart = not getgenv().fishingStart
    local state = getgenv().fishingStart
    BtnAutoFish.Text = "Auto Fish: " .. (state and "ON" or "OFF")
    ToggleVisual(BtnAutoFish, state)
    
    if state then
        FishingBlocker.Enabled = true
        task.spawn(startFishingHyperLoop)
    else
        FishingBlocker.Enabled = false
        pcall(function() CompleteGame:FireServer() end)
        pcall(function() CancelInput:InvokeServer() end)
    end
end)

-- AUTO SELL
BtnAutoSell.MouseButton1Click:Connect(function()
    _G.SellSettings.AutoSell = not _G.SellSettings.AutoSell
    local state = _G.SellSettings.AutoSell
    BtnAutoSell.Text = "Auto Sell: " .. (state and "ON" or "OFF")
    ToggleVisual(BtnAutoSell, state)
end)

BtnSellNow.MouseButton1Click:Connect(function()
    ToggleVisual(BtnSellNow, true)
    pcall(function() SellAll:InvokeServer() end)
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Sell Now", Text = "Sold!", Duration = 2})
    wait(0.2)
    ToggleVisual(BtnSellNow, false)
end)

-- AUTO WEATHER
BtnWeather.MouseButton1Click:Connect(function()
    _G.WeatherSettings.Active = not _G.WeatherSettings.Active
    local state = _G.WeatherSettings.Active
    BtnWeather.Text = "Auto Weather: " .. (state and "ON" or "OFF")
    ToggleVisual(BtnWeather, state)
end)

-- UTILITY
BtnEquip.MouseButton1Click:Connect(function() States.AutoEquip = not States.AutoEquip; BtnEquip.Text = "Auto Equip: " .. (States.AutoEquip and "ON" or "OFF"); ToggleVisual(BtnEquip, States.AutoEquip) end)
BtnClean.MouseButton1Click:Connect(function() States.AutoClean = not States.AutoClean; BtnClean.Text = "Auto Clean: " .. (States.AutoClean and "ON" or "OFF"); ToggleVisual(BtnClean, States.AutoClean) end)
BtnFreeze.MouseButton1Click:Connect(function() States.Freeze = not States.Freeze; if HRP then HRP.Anchored = States.Freeze end; BtnFreeze.Text = "Freeze: " .. (States.Freeze and "ON" or "OFF"); ToggleVisual(BtnFreeze, States.Freeze) end)
BtnNoclip.MouseButton1Click:Connect(function() States.Noclip = not States.Noclip; BtnNoclip.Text = "No Clip: "..(States.Noclip and "ON" or "OFF"); ToggleVisual(BtnNoclip, States.Noclip) end)
BtnRender.MouseButton1Click:Connect(function() States.NoRender = not States.NoRender; RunService:Set3dRenderingEnabled(not States.NoRender); BtnRender.Text = "3D Render: "..(States.NoRender and "OFF" or "ON"); ToggleVisual(BtnRender, States.NoRender) end)
BtnRejoin.MouseButton1Click:Connect(function() TeleportService:Teleport(game.PlaceId, Player) end)

-- WATER WALK
BtnWow.MouseButton1Click:Connect(function() 
    States.WoW = not States.WoW 
    BtnWow.Text = "Water Walk: " .. (States.WoW and "ON" or "OFF")
    ToggleVisual(BtnWow, States.WoW) 
    if States.WoW then 
        local BodyV = Instance.new("BodyVelocity", HRP) 
        BodyV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        BodyV.Velocity = Vector3.zero 
        Connections["WoW"] = RunService.RenderStepped:Connect(function() 
            if HRP and Hum then
                local moveDir = Hum.MoveDirection
                local speed = Hum.WalkSpeed
                BodyV.Velocity = Vector3.new(moveDir.X * speed, 0, moveDir.Z * speed)
            end 
        end) 
    else 
        if Connections["WoW"] then Connections["WoW"]:Disconnect() end 
        if HRP:FindFirstChild("BodyVelocity") then HRP.BodyVelocity:Destroy() end 
    end 
end)

-- INIT (Start Anti-AFK)
task.spawn(StartAntiAFK)
