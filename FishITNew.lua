-- [1] Notifikasi Awal
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Raka Ganteng",
        Text = "Loading: HYPER FAST FISHING + AUTO SELL!",
        Duration = 2,
    })
end)

task.wait(3.5)

-- [2] Variable & Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage") 
local VirtualInputManager = game:GetService("VirtualInputManager") 
local TweenService = game:GetService("TweenService")

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
-- [NEW] Mencoba mencari remote Sell
local SellAll      = net:FindFirstChild("RF/SellAll") or net:FindFirstChild("RF/SellEverything")

-- // KONFIGURASI GLOBAL
getgenv().fishingStart = false
_G.FishSettings = {
    DelayCharge = 0.85, 
    DelayReset = 0.1,   
}
_G.SellSettings = {
    Interval = 600, -- Default 10 menit
    NextSellTime = os.time() + 600
}

-- Args Lemparan
local fishArgs = { -1.115296483039856, 0, 1763651451.636425 }

-- =====================================================
-- 🛡️ FISHING BLOCKER (ANTI-FAIL SYSTEM)
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
-- 🎣 FUNGSI LOOP FISHING (HYPER FAST UPGRADE)
-- =====================================================
local function startFishingHyperLoop()
    if FishingBlocker.AutoGreat then
        local agRemote = net:FindFirstChild("RF/UpdateAutoFishingState")
        if agRemote then agRemote:InvokeServer(true) end
    end

    pcall(function() CancelInput:InvokeServer() end)
    task.wait(0.05)

    while getgenv().fishingStart do
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

-- // Konfigurasi Visual (DARK FIRE THEME)
local UI_THEME = {
    MinWidth = 280,  
    MinHeight = 300, 
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

-- Bersihkan UI Lama
if CoreGui:FindFirstChild("SeraphinHelper") then CoreGui.SeraphinHelper:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SeraphinHelper"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ====================================================
-- [1] MINI FLOATING HUD (Style Api)
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

local ListLayout = Instance.new("UIListLayout", FloatHUD)
ListLayout.FillDirection = Enum.FillDirection.Vertical
ListLayout.Padding = UDim.new(0, 6) 
ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder 

local Padding = Instance.new("UIPadding", FloatHUD)
Padding.PaddingTop = UDim.new(0, 10) 
Padding.PaddingBottom = UDim.new(0, 8)
Padding.PaddingLeft = UDim.new(0, 5)
Padding.PaddingRight = UDim.new(0, 5)

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
Main.Size = UDim2.new(0, UI_THEME.MinWidth, 0, UI_THEME.MinHeight + 30) -- Sedikit diperbesar
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
-- [3] TAB SYSTEM
-- ====================================================
local TabHolder = Instance.new("Frame", Main)
TabHolder.Name = "TabHolder"
TabHolder.Size = UDim2.new(1, 0, 0, 25)
TabHolder.Position = UDim2.new(0, 0, 0, 32)
TabHolder.BackgroundTransparency = 1

local TabMainBtn = Instance.new("TextButton", TabHolder)
TabMainBtn.Name = "MainTab"
TabMainBtn.Size = UDim2.new(0.5, 0, 1, 0)
TabMainBtn.BackgroundTransparency = 1
TabMainBtn.Text = "MAIN"
TabMainBtn.Font = Enum.Font.GothamBold
TabMainBtn.TextSize = 11
TabMainBtn.TextColor3 = UI_THEME.TabOn

local TabMiscBtn = Instance.new("TextButton", TabHolder)
TabMiscBtn.Name = "MiscTab"
TabMiscBtn.Size = UDim2.new(0.5, 0, 1, 0)
TabMiscBtn.Position = UDim2.new(0.5, 0, 0, 0)
TabMiscBtn.BackgroundTransparency = 1
TabMiscBtn.Text = "MISC / SELL"
TabMiscBtn.Font = Enum.Font.GothamBold
TabMiscBtn.TextSize = 11
TabMiscBtn.TextColor3 = UI_THEME.TabOff

local TabIndicator = Instance.new("Frame", TabHolder)
TabIndicator.Size = UDim2.new(0.5, 0, 0, 2)
TabIndicator.Position = UDim2.new(0, 0, 1, -2)
TabIndicator.BackgroundColor3 = UI_THEME.Accent
TabIndicator.BorderSizePixel = 0

local PageContainer = Instance.new("Frame", Main)
PageContainer.Name = "PageContainer"
PageContainer.Size = UDim2.new(1, -16, 1, -65) 
PageContainer.Position = UDim2.new(0, 8, 0, 60)
PageContainer.BackgroundTransparency = 1

local PageMain = Instance.new("Frame", PageContainer)
PageMain.Name = "PageMain"
PageMain.Size = UDim2.new(1, 0, 1, 0)
PageMain.BackgroundTransparency = 1
PageMain.Visible = true

local GridMain = Instance.new("UIGridLayout", PageMain)
GridMain.CellSize = UDim2.new(0, 128, 0, 28) 
GridMain.CellPadding = UDim2.new(0, 8, 0, 6) 
GridMain.HorizontalAlignment = Enum.HorizontalAlignment.Center

local PageMisc = Instance.new("Frame", PageContainer)
PageMisc.Name = "PageMisc"
PageMisc.Size = UDim2.new(1, 0, 1, 0)
PageMisc.BackgroundTransparency = 1
PageMisc.Visible = false

local GridMisc = Instance.new("UIGridLayout", PageMisc)
GridMisc.CellSize = UDim2.new(0, 128, 0, 28) 
GridMisc.CellPadding = UDim2.new(0, 8, 0, 6) 
GridMisc.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function SwitchTab(tabName)
    if tabName == "Main" then
        PageMain.Visible = true
        PageMisc.Visible = false
        TabMainBtn.TextColor3 = UI_THEME.TabOn
        TabMiscBtn.TextColor3 = UI_THEME.TabOff
        TabIndicator:TweenPosition(UDim2.new(0, 0, 1, -2), "Out", "Quad", 0.2)
    elseif tabName == "Misc" then
        PageMain.Visible = false
        PageMisc.Visible = true
        TabMainBtn.TextColor3 = UI_THEME.TabOff
        TabMiscBtn.TextColor3 = UI_THEME.TabOn
        TabIndicator:TweenPosition(UDim2.new(0.5, 0, 1, -2), "Out", "Quad", 0.2)
    end
end

TabMainBtn.MouseButton1Click:Connect(function() SwitchTab("Main") end)
TabMiscBtn.MouseButton1Click:Connect(function() SwitchTab("Misc") end)

-- ====================================================
-- [4] LOGIC UI & FUNCTIONS
-- ====================================================
local IsMinimized = false

HideBtn.MouseButton1Click:Connect(function() 
    IsMinimized = not IsMinimized 
    if IsMinimized then
        PageContainer.Visible = false
        TabHolder.Visible = false
        Main:TweenSize(UDim2.new(0, UI_THEME.MinWidth, 0, 32), "Out", "Quad", 0.3, true) 
        HideBtn.Text = "Show" 
        HideBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    else
        Main:TweenSize(UDim2.new(0, UI_THEME.MinWidth, 0, UI_THEME.MinHeight + 30), "Out", "Back", 0.3, true) 
        HideBtn.Text = "Hide" 
        HideBtn.TextColor3 = UI_THEME.Accent
        task.delay(0.2, function() 
            if not IsMinimized then 
                PageContainer.Visible = true 
                TabHolder.Visible = true
            end 
        end)
    end
end)

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

local function Notify(title, text)
    game:GetService("StarterGui"):SetCore("SendNotification", { Title = title, Text = text, Duration = 3 })
end

-- States
local States = {
    Freeze=false, WoW=false, Boost=false, NoRender=false, 
    Noclip=false, Panel=true, AutoEquip=false, AutoClean=false,
    AutoFish=false, AutoSell=false, AutoWeather=false
}
local SavedCFrame = nil 
local Connections = {}
local BodyV = nil

-- >> TOMBOL UI <<

-- TAB MAIN - FISHING SECTION
local BtnAutoFish = MakeBtn(PageMain, "Auto Fish: OFF")
local InputReel = MakeInput(PageMain, "Delay Fishing (0.85)", "0.85")
local InputCast = MakeInput(PageMain, "Delay Reset (0.1)", "0.1")

-- TAB MAIN - UTILITY
local BtnEquip  = MakeBtn(PageMain, "Auto Equip: OFF")
local BtnWow    = MakeBtn(PageMain, "Water Walk: OFF")
local BtnFreeze = MakeBtn(PageMain, "Freeze: OFF")
local BtnNoclip = MakeBtn(PageMain, "No Clip: OFF")
local BtnBoost  = MakeBtn(PageMain, "Boost: OFF")
local BtnRender = MakeBtn(PageMain, "3D Render: ON") 
local BtnFps    = MakeBtn(PageMain, "FPS: Max") 

-- TAB MISC
local BtnSave   = MakeBtn(PageMisc, "Save Pos")
local BtnLoad   = MakeBtn(PageMisc, "Load Pos")
local BtnClean  = MakeBtn(PageMisc, "Auto Clean: OFF") 
local BtnRejoin = MakeBtn(PageMisc, "Rejoin Server")
local BtnPanel  = MakeBtn(PageMisc, "Panel Info: ON")

-- TAB MISC - NEW FEATURES (SELL & WEATHER)
local DivMisc   = Instance.new("Frame", PageMisc) -- Spacer
DivMisc.BackgroundTransparency = 1
local BtnAutoSell = MakeBtn(PageMisc, "Auto Sell: OFF")
local InputSell   = MakeInput(PageMisc, "Sell Interval (s)", "600")
local BtnSellNow  = MakeBtn(PageMisc, "Sell NOW")
-- local BtnWeather  = MakeBtn(PageMisc, "Smart Weather: OFF") -- Placeholder

-- Input Logic Update (Update Config Global)
InputReel.FocusLost:Connect(function()
    local num = tonumber(InputReel.Text)
    if num then _G.FishSettings.DelayCharge = num end
end)
InputCast.FocusLost:Connect(function()
    local num = tonumber(InputCast.Text)
    if num then _G.FishSettings.DelayReset = num end
end)
InputSell.FocusLost:Connect(function()
    local num = tonumber(InputSell.Text)
    if num then 
        _G.SellSettings.Interval = num 
        Notify("Config", "Interval Jual: " .. num .. "s")
    end
end)

-- FPS Logic
local fpsT = 0
RunService.RenderStepped:Connect(function(dt)
    fpsT = fpsT + (1/dt - fpsT) * 0.1 
    local currentFps = math.floor(fpsT)
    Title.Text = "SERAPHIN <font color=\"rgb(255,69,0)\">HELPER</font>  |  FPS: <b>" .. currentFps .. "</b>"
end)

-- FPS Selector Logic
BtnFps.MouseButton1Click:Connect(function()
    local caps = {30, 60, 90, 144, 240, 99999}
    _G.fpsIndex = ((_G.fpsIndex or 5) % #caps) + 1
    local v = caps[_G.fpsIndex]
    
    if setfpscap then 
        setfpscap(v) 
    end
    
    local txt = (v > 1000) and "Max" or tostring(v)
    BtnFps.Text = "FPS: " .. txt
    
    ToggleVisual(BtnFps, true)
    wait(0.1)
    ToggleVisual(BtnFps, false)
end)

ToggleVisual(BtnPanel, true)
BtnPanel.MouseButton1Click:Connect(function()
    States.Panel = not States.Panel
    FloatHUD.Visible = States.Panel
    BtnPanel.Text = "Panel Info: " .. (States.Panel and "ON" or "OFF")
    ToggleVisual(BtnPanel, States.Panel)
end)

-- ====================================================
-- [5] BACKGROUND LOOPS & AUTO LOGICS
-- ====================================================

-- AUTO SELL LOOP (INTELLIGENT)
task.spawn(function()
    while true do
        task.wait(1)
        if States.AutoSell then
            if os.time() >= _G.SellSettings.NextSellTime then
                -- Step 1: Notify
                Notify("Auto Sell", "Waktunya menjual item...")
                
                -- Step 2: Pause Fishing (Safe Pause)
                local wasFishing = getgenv().fishingStart
                if wasFishing then
                    getgenv().fishingStart = false
                    FishingBlocker.Enabled = false 
                    -- Wait for any current catch to finish
                    task.wait(2.5) 
                end
                
                -- Step 3: Trigger Sell Remote
                if SellAll then
                    pcall(function() SellAll:InvokeServer() end)
                    Notify("Auto Sell", "Semua item terjual!")
                else
                    Notify("Error", "Remote Sell tidak ditemukan!")
                end
                
                -- Step 4: Resume
                if wasFishing then
                    Notify("Auto Sell", "Melanjutkan memancing...")
                    task.wait(1)
                    getgenv().fishingStart = true
                    FishingBlocker.Enabled = true
                    task.spawn(startFishingHyperLoop)
                end
                
                -- Step 5: Update Next Sell Time
                _G.SellSettings.NextSellTime = os.time() + _G.SellSettings.Interval
            end
        end
    end
end)

-- AUTO CLEAN RAM LOOP (5 Menit)
task.spawn(function()
    while true do
        task.wait(300) 
        if States.AutoClean then
            pcall(function()
                collectgarbage("collect")
                Notify("Auto Clean", "RAM Dibersihkan!")
            end)
        end
    end
end)

-- Button Logic for Auto Clean
BtnClean.MouseButton1Click:Connect(function()
    States.AutoClean = not States.AutoClean
    BtnClean.Text = "Auto Clean: " .. (States.AutoClean and "ON" or "OFF")
    ToggleVisual(BtnClean, States.AutoClean)
end)

-- >> LOGIC AUTO EQUIP (0.5 Detik)
task.spawn(function()
    while true do
        task.wait(0.5)
        if States.AutoEquip then
            pcall(function()
                local char = Player.Character
                if char then
                    if not char:FindFirstChildWhichIsA("Tool") then
                        local args = { [1] = 1 }
                        local remote = game:GetService("ReplicatedStorage").Packages._Index:FindFirstChild("sleitnick_net@0.2.0")
                        if remote then
                            remote.net:FindFirstChild("RE/EquipToolFromHotbar"):FireServer(unpack(args))
                        end
                    end
                end
            end)
        end
    end
end)

-- >> UPDATE STATS LOOP
task.spawn(function()
    while true do
        task.wait(0.5)
        if not States.Panel then 
            continue 
        end
        pcall(function()
            local ls = Player:FindFirstChild("leaderstats")
            local caughtObj = ls and ls:FindFirstChild("Caught")
            local function formatNum(n) return tostring(n):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "") end
            local val = caughtObj and caughtObj.Value or 0
            LblFishVal.Text = formatNum(val)

            local pg = Player:FindFirstChild("PlayerGui")
            local backpackGui = pg and pg:FindFirstChild("Backpack")
            local bagText = "0/?"
            if backpackGui then
                for _, v in pairs(backpackGui:GetDescendants()) do
                    if v:IsA("TextLabel") and string.find(v.Text, "/") then 
                        bagText = v.Text 
                        break 
                    end
                end
            else 
                local current = #Player.Backpack:GetChildren()
                bagText = tostring(current)
            end
            LblInvVal.Text = bagText
        end)
    end
end)

-- ====================================================
-- [6] FUNCTION BUTTONS LOGIC
-- ====================================================

-- Auto Sell Logic Buttons
BtnAutoSell.MouseButton1Click:Connect(function()
    States.AutoSell = not States.AutoSell
    BtnAutoSell.Text = "Auto Sell: " .. (States.AutoSell and "ON" or "OFF")
    ToggleVisual(BtnAutoSell, States.AutoSell)
    
    if States.AutoSell then
        _G.SellSettings.NextSellTime = os.time() + _G.SellSettings.Interval
        Notify("Auto Sell", "Aktif! Menjual setiap " .. _G.SellSettings.Interval .. " detik.")
    end
end)

BtnSellNow.MouseButton1Click:Connect(function()
    Notify("Manual Sell", "Mencoba menjual item...")
    if SellAll then
        pcall(function() SellAll:InvokeServer() end)
    else
        Notify("Error", "Remote Sell tidak ditemukan.")
    end
end)

-- Auto Fish Button (INTEGRATED HYPER FAST LOGIC)
BtnAutoFish.MouseButton1Click:Connect(function()
    States.AutoFish = not States.AutoFish
    BtnAutoFish.Text = "Auto Fish: " .. (States.AutoFish and "ON" or "OFF")
    ToggleVisual(BtnAutoFish, States.AutoFish)
    
    if States.AutoFish then
        -- START FISHING
        getgenv().fishingStart = true
        FishingBlocker.Enabled = true -- Aktifkan Blocker
        Notify("Auto Fish", "Started (HYPER FAST)")
        
        -- Jalan loop
        task.spawn(startFishingHyperLoop)
    else
        -- STOP FISHING
        getgenv().fishingStart = false
        FishingBlocker.Enabled = false -- Matikan Blocker
        
        -- Safety Clean
        pcall(function() CompleteGame:FireServer() end)
        pcall(function() CancelInput:InvokeServer() end)
        
        Notify("Auto Fish", "Stopped")
    end
end)

-- Auto Equip Button
BtnEquip.MouseButton1Click:Connect(function()
    States.AutoEquip = not States.AutoEquip
    BtnEquip.Text = "Auto Equip: " .. (States.AutoEquip and "ON" or "OFF")
    ToggleVisual(BtnEquip, States.AutoEquip)
end)

-- Freeze
BtnFreeze.MouseButton1Click:Connect(function() 
    States.Freeze = not States.Freeze 
    if HRP then HRP.Anchored = States.Freeze end 
    BtnFreeze.Text = "Freeze: " .. (States.Freeze and "ON" or "OFF")
    ToggleVisual(BtnFreeze, States.Freeze) 
end)

-- Water Walk (Manual)
BtnWow.MouseButton1Click:Connect(function() 
    States.WoW = not States.WoW 
    BtnWow.Text = "Water Walk: " .. (States.WoW and "ON" or "OFF")
    ToggleVisual(BtnWow, States.WoW) 
    
    if States.WoW then 
        -- Gunakan Logic BodyVelocity yang Movable (Tetap bisa jalan)
        BodyV = Instance.new("BodyVelocity", HRP) 
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
        if BodyV then BodyV:Destroy() end 
    end 
end)

-- Noclip
BtnNoclip.MouseButton1Click:Connect(function() 
    States.Noclip = not States.Noclip 
    BtnNoclip.Text = "No Clip: "..(States.Noclip and "ON" or "OFF") 
    ToggleVisual(BtnNoclip, States.Noclip) 
    if States.Noclip then 
        Connections["Noclip"] = RunService.Stepped:Connect(function() 
            if Player.Character then 
                for _,v in pairs(Player.Character:GetDescendants()) do 
                    if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end 
                end 
            end 
        end) 
    else 
        if Connections["Noclip"] then Connections["Noclip"]:Disconnect() end 
    end 
end)

-- Boost
BtnBoost.MouseButton1Click:Connect(function() 
    States.Boost = not States.Boost 
    ToggleVisual(BtnBoost, States.Boost) 
    BtnBoost.Text = "Boost: " .. (States.Boost and "ON" or "OFF")
    Lighting.GlobalShadows = not States.Boost 
    if States.Boost then
        local function CleanVisuals(folder)
            if not folder then return end
            for _, v in pairs(folder:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("Explosion") then v.Enabled = false end
            end
        end
        CleanVisuals(workspace:FindFirstChild("Islands"))
        CleanVisuals(ReplicatedStorage:FindFirstChild("Assets"))
    end
end)

-- 3D Render
BtnRender.MouseButton1Click:Connect(function() 
    States.NoRender = not States.NoRender 
    RunService:Set3dRenderingEnabled(not States.NoRender) 
    BtnRender.Text = "3D Render: "..(States.NoRender and "OFF" or "ON") 
    ToggleVisual(BtnRender, States.NoRender) 
end)

-- Rejoin
BtnRejoin.MouseButton1Click:Connect(function() TeleportService:Teleport(game.PlaceId, Player) end)

-- Save Pos
BtnSave.MouseButton1Click:Connect(function() 
    if HRP then 
        SavedCFrame = HRP.CFrame 
        BtnSave.Text="SAVED" 
        BtnSave.TextColor3 = Color3.fromRGB(100, 255, 100)
        Notify("Posisi Disimpan", "Lokasi Anda saat ini telah disimpan ")
        task.delay(1, function()
            BtnSave.Text="Save Pos" 
            BtnSave.TextColor3 = Color3.fromRGB(200, 200, 200)
        end)
    end 
end)

-- Load Pos
BtnLoad.MouseButton1Click:Connect(function() 
    if SavedCFrame and HRP then 
        HRP.CFrame = SavedCFrame 
        ToggleVisual(BtnLoad,true) 
        Notify("Posisi Dimuat", "Teleportasi ke lokasi yang disimpan")
        wait(0.2) 
        ToggleVisual(BtnLoad,false) 
    else
        Notify("Gagal", "Belum ada posisi yang disimpan ")
    end 
end)
