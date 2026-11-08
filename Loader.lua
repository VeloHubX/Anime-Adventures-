-- â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—
-- â•‘    ANIME ADVENTURES â€” UNIT SPAWNER + DUPE    â•‘
-- â•‘    Universal  Â·  Delta / Synapse / Fluxus    â•‘
-- â•‘    Visual-only. Client-side. Gone on rejoin. â•‘
-- â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  ANTI PRIVATE SERVER
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

local ok, serverType = pcall(function()
    return game:GetService("RobloxReplicatedStorage")
        :WaitForChild("GetServerType")
        :InvokeServer()
end)

if ok and serverType == "VIPServer" then
    game:GetService("Players").LocalPlayer:Kick(
        "VIP / Private Server detected.\n" ..
        "Using this script in this server may result in a ban.\n" ..
        "Please join a PUBLIC server."
    )
    return
end

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  EXECUTOR COMPAT LAYER
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

local execName = (identifyexecutor and identifyexecutor()) or "unknown"

-- UNC mouse globals â€” works on Delta, Synapse X, KRNL, Fluxus, Arceus X, etc.
local function unc_movemouse(x, y)
    if mousemoveabs then
        mousemoveabs(x, y)
    elseif mousemoverel then
        -- fallback: relative from current (less accurate but better than nothing)
        mousemoverel(0, 0)
    end
end

local function unc_click()
    if mouse1click then
        mouse1click()
    elseif mouse1press and mouse1release then
        mouse1press()
        task.wait(0.05)
        mouse1release()
    end
end

-- GUI protection: parent to gethui() if available so the game can't destroy the GUI
local function getGuiParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    return game:GetService("Players").LocalPlayer.PlayerGui
end

-- HTTP request compat (not needed here but kept for future extension)
local httpRequest = (syn and syn.request)
    or (http and http.request)
    or http_request
    or (fluxus and fluxus.request)
    or request

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  SERVICES
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local plr   = Players.LocalPlayer
local pgui  = plr.PlayerGui
local char  = plr.Character or plr.CharacterAdded:Wait()
local hrp   = char:WaitForChild("HumanoidRootPart")

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  PLACEMENT SERVICE HOOK
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

local PlacementService = nil
local Loader = ReplicatedStorage:FindFirstChild("src") and
               ReplicatedStorage.src:FindFirstChild("Loader")

if Loader then
    local ok, svc = pcall(function()
        local L = require(Loader)
        return L.load_client_service(script, "PlacementServiceClient")
    end)
    if ok and svc then PlacementService = svc end
end

-- Keep can_place true continuously
task.spawn(function()
    while task.wait(0.1) do
        if PlacementService then
            pcall(function() PlacementService.can_place = true end)
        end
    end
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  UNIT DATA  (rarity color lookup)
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

local UnitModuleRoot = ReplicatedStorage:FindFirstChild("src") and
                       ReplicatedStorage.src:FindFirstChild("Data") and
                       ReplicatedStorage.src.Data:FindFirstChild("Units")

local function buildUnitDataLookup()
    local t = {}
    if not UnitModuleRoot then return t end
    for _, v in pairs(UnitModuleRoot:GetDescendants()) do
        if v:IsA("ModuleScript") then
            local ok, data = pcall(require, v)
            if ok and type(data) == "table" then
                for _, ud in pairs(data) do
                    if type(ud) == "table" and ud.name then
                        t[ud.name:lower()] = { rarity = ud.rarity or "Common" }
                    end
                end
            end
        end
    end
    return t
end

local unitDataLookup = buildUnitDataLookup()

local RARITY_COLORS = {
    mythic    = Color3.fromRGB(255, 215, 0),
    secret    = Color3.fromRGB(220,  50, 220),
    legendary = Color3.fromRGB(220, 120,   0),
    epic      = Color3.fromRGB(100,  60, 220),
    rare      = Color3.fromRGB( 60, 120, 220),
}
local DEFAULT_COLOR = Color3.fromRGB(80, 160, 80)

local function getRarityColor(rarity)
    return RARITY_COLORS[(rarity or ""):lower()] or DEFAULT_COLOR
end

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  READ PLAYER UNITS FROM GAME UI
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

local function getOwnedUnits()
    local units = {}
    local spawnUI = pgui:FindFirstChild("spawn_units")
    if not spawnUI then return units end

    -- Recursively find the frame named "Units"
    local function findFrame(root, name)
        for _, v in pairs(root:GetDescendants()) do
            if v.Name == name and (v:IsA("Frame") or v:IsA("ScrollingFrame")) then
                return v
            end
        end
    end

    local unitsFrame = findFrame(spawnUI, "Units")
    if not unitsFrame then return units end

    for _, btn in pairs(unitsFrame:GetChildren()) do
        if btn:IsA("ImageButton") or btn:IsA("Frame") then
            local unitName    = btn.Name
            local unitLevel   = 1
            local unitImage   = btn:IsA("ImageButton") and btn.Image or ""
            local borderColor = DEFAULT_COLOR

            -- Level from any TextLabel
            for _, lbl in pairs(btn:GetDescendants()) do
                if lbl:IsA("TextLabel") then
                    local lv = tonumber(lbl.Text:match("%d+"))
                    if lv and lv > 1 then unitLevel = lv end
                end
            end

            -- Image from any ImageLabel child
            local imgLbl = btn:FindFirstChildWhichIsA("ImageLabel")
            if imgLbl and imgLbl.Image ~= "" then unitImage = imgLbl.Image end

            local entry = unitDataLookup[unitName:lower()]
            if entry then borderColor = getRarityColor(entry.rarity) end

            table.insert(units, {
                name        = unitName,
                level       = unitLevel,
                image       = unitImage,
                borderColor = borderColor,
                button      = btn,
                duped       = false,
            })
        end
    end
    return units
end

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  UNIT LIST STATE
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

local unitList  = {}
local isPlacing = false

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  PLACEMENT  (UNC-safe, no VirtualInputManager)
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

local function placeUnit(unit)
    if isPlacing then return end
    isPlacing = true

    -- Step 1: Fire the game's native spawn button
    local realBtn = unit.button
    if realBtn then
        -- Try direct event fire (works on most executors)
        pcall(function() realBtn.MouseButton1Click:Fire() end)

        -- Fallback: move mouse over button and click via UNC
        task.wait(0.05)
        pcall(function()
            local cx = realBtn.AbsolutePosition.X + realBtn.AbsoluteSize.X * 0.5
            local cy = realBtn.AbsolutePosition.Y + realBtn.AbsoluteSize.Y * 0.5
            unc_movemouse(cx, cy)
            task.wait(0.03)
            unc_click()
        end)
    end

    -- Step 2: Ensure bypass is active
    if PlacementService then
        pcall(function() PlacementService.can_place = true end)
    end

    -- Step 3: Move mouse to world position and confirm placement
    task.wait(0.3)
    pcall(function()
        local placePos = hrp.Position + hrp.CFrame.LookVector * 6
        local cam = workspace.CurrentCamera
        local screenPos, onScreen = cam:WorldToViewportPoint(placePos)
        if onScreen then
            unc_movemouse(screenPos.X, screenPos.Y)
            task.wait(0.05)
            unc_click()
        end
    end)

    task.wait(0.4)
    isPlacing = false
end

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  GUI  â€”  SETUP
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

local guiParent = getGuiParent()

-- Remove old instance
local existing = guiParent:FindFirstChild("AA_UnitSpawner")
    or pgui:FindFirstChild("AA_UnitSpawner")
if existing then existing:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "AA_UnitSpawner"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder   = 999
ScreenGui.Parent         = guiParent

-- Protect from game scripts trying to destroy it
if syn and syn.protect_gui then
    pcall(function() syn.protect_gui(ScreenGui) end)
end

-- Main window
local Window = Instance.new("Frame")
Window.Name              = "Window"
Window.Size              = UDim2.new(0, 460, 0, 610)
Window.Position          = UDim2.new(0.5, -230, 0.5, -305)
Window.BackgroundColor3  = Color3.fromRGB(14, 14, 20)
Window.BorderSizePixel   = 0
Window.ClipsDescendants  = true
Window.Parent            = ScreenGui

local wCorner = Instance.new("UICorner")
wCorner.CornerRadius = UDim.new(0, 10)
wCorner.Parent       = Window

local wStroke = Instance.new("UIStroke")
wStroke.Color     = Color3.fromRGB(55, 55, 80)
wStroke.Thickness = 1.5
wStroke.Parent    = Window

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Name             = "TitleBar"
TitleBar.Size             = UDim2.new(1, 0, 0, 44)
TitleBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
TitleBar.BorderSizePixel  = 0
TitleBar.ZIndex           = 2
TitleBar.Parent           = Window

local tbCorner = Instance.new("UICorner")
tbCorner.CornerRadius = UDim.new(0, 10)
tbCorner.Parent       = TitleBar

local tbMask = Instance.new("Frame")  -- square the bottom corners
tbMask.Size             = UDim2.new(1, 0, 0, 10)
tbMask.Position         = UDim2.new(0, 0, 1, -10)
tbMask.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
tbMask.BorderSizePixel  = 0
tbMask.ZIndex           = 2
tbMask.Parent           = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text            = "â˜€  Unit Spawner  +  Dupe"
TitleLabel.Size            = UDim2.new(1, -50, 1, 0)
TitleLabel.Position        = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font            = Enum.Font.GothamBold
TitleLabel.TextColor3      = Color3.fromRGB(240, 240, 255)
TitleLabel.TextSize        = 14
TitleLabel.TextXAlignment  = Enum.TextXAlignment.Left
TitleLabel.ZIndex          = 3
TitleLabel.Parent          = TitleBar

-- Executor tag (bottom-right of title bar)
local ExecLabel = Instance.new("TextLabel")
ExecLabel.Text            = execName
ExecLabel.Size            = UDim2.new(0, 100, 0, 14)
ExecLabel.Position        = UDim2.new(1, -142, 1, -16)
ExecLabel.BackgroundTransparency = 1
ExecLabel.Font            = Enum.Font.Gotham
ExecLabel.TextColor3      = Color3.fromRGB(90, 90, 120)
ExecLabel.TextSize        = 10
ExecLabel.TextXAlignment  = Enum.TextXAlignment.Right
ExecLabel.ZIndex          = 3
ExecLabel.Parent          = TitleBar

local CountLabel = Instance.new("TextLabel")
CountLabel.Name            = "CountLabel"
CountLabel.Text            = "0 units"
CountLabel.Size            = UDim2.new(0, 100, 0, 14)
CountLabel.Position        = UDim2.new(1, -142, 0, 6)
CountLabel.BackgroundTransparency = 1
CountLabel.Font            = Enum.Font.Gotham
CountLabel.TextColor3      = Color3.fromRGB(140, 140, 170)
CountLabel.TextSize        = 11
CountLabel.TextXAlignment  = Enum.TextXAlignment.Right
CountLabel.ZIndex          = 3
CountLabel.Parent          = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Text              = "âœ•"
CloseBtn.Size              = UDim2.new(0, 32, 0, 32)
CloseBtn.Position          = UDim2.new(1, -38, 0, 6)
CloseBtn.BackgroundColor3  = Color3.fromRGB(180, 50, 50)
CloseBtn.Font              = Enum.Font.GothamBold
CloseBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize          = 13
CloseBtn.BorderSizePixel   = 0
CloseBtn.ZIndex            = 4
CloseBtn.Parent            = TitleBar

local cbCorner = Instance.new("UICorner")
cbCorner.CornerRadius = UDim.new(0, 6)
cbCorner.Parent       = CloseBtn

CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- â”€â”€ Action bar â”€â”€
local ActionBar = Instance.new("Frame")
ActionBar.Size             = UDim2.new(1, -20, 0, 34)
ActionBar.Position         = UDim2.new(0, 10, 0, 50)
ActionBar.BackgroundTransparency = 1
ActionBar.ZIndex           = 2
ActionBar.Parent           = Window

local abLayout = Instance.new("UIListLayout")
abLayout.FillDirection     = Enum.FillDirection.Horizontal
abLayout.Padding           = UDim.new(0, 6)
abLayout.VerticalAlignment = Enum.VerticalAlignment.Center
abLayout.Parent            = ActionBar

local function makeActionBtn(text, bgColor)
    local btn = Instance.new("TextButton")
    btn.Text             = text
    btn.Size             = UDim2.new(0, 0, 1, 0)   -- auto width via padding
    btn.AutomaticSize    = Enum.AutomaticSize.X
    btn.BackgroundColor3 = bgColor
    btn.Font             = Enum.Font.GothamBold
    btn.TextColor3       = Color3.fromRGB(230, 230, 255)
    btn.TextSize         = 12
    btn.BorderSizePixel  = 0
    btn.ZIndex           = 2
    btn.Parent           = ActionBar

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent       = btn

    local p = Instance.new("UIPadding")
    p.PaddingLeft  = UDim.new(0, 10)
    p.PaddingRight = UDim.new(0, 10)
    p.Parent       = btn

    return btn
end

local RefreshBtn   = makeActionBtn("âŸ³  Refresh",       Color3.fromRGB(30, 30, 46))
local DupeAllBtn   = makeActionBtn("â§‰  Dupe All",      Color3.fromRGB(28, 60, 28))
local ClearDupeBtn = makeActionBtn("âœ—  Clear Dupes",    Color3.fromRGB(60, 25, 25))

local rbStroke = Instance.new("UIStroke")
rbStroke.Color = Color3.fromRGB(55, 55, 80); rbStroke.Thickness = 1
rbStroke.Parent = RefreshBtn

-- â”€â”€ Scroll / grid â”€â”€
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name              = "UnitGrid"
ScrollFrame.Size              = UDim2.new(1, -20, 1, -100)
ScrollFrame.Position          = UDim2.new(0, 10, 0, 92)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel   = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 120)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollFrame.CanvasSize        = UDim2.new(0, 0, 0, 0)
ScrollFrame.ZIndex            = 2
ScrollFrame.Parent            = Window

local GridLayout = Instance.new("UIGridLayout")
GridLayout.CellSize            = UDim2.new(0, 118, 0, 150)
GridLayout.CellPadding         = UDim2.new(0, 8, 0, 8)
GridLayout.FillDirection       = Enum.FillDirection.Horizontal
GridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
GridLayout.SortOrder           = Enum.SortOrder.LayoutOrder
GridLayout.Parent              = ScrollFrame

local GridPad = Instance.new("UIPadding")
GridPad.PaddingTop  = UDim.new(0, 4)
GridPad.PaddingLeft = UDim.new(0, 4)
GridPad.Parent      = ScrollFrame

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  CARD BUILDER
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

local function makeUnitCard(unitData, index)
    local isDuped = unitData.duped

    local card = Instance.new("Frame")
    card.Name             = "Card_" .. index
    card.Size             = UDim2.new(1, 0, 1, 0)
    card.BackgroundColor3 = isDuped and Color3.fromRGB(18, 28, 18) or Color3.fromRGB(22, 22, 32)
    card.BorderSizePixel  = 0
    card.LayoutOrder      = index
    card.ZIndex           = 2

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 8)
    cCorner.Parent       = card

    local cStroke = Instance.new("UIStroke")
    cStroke.Color     = unitData.borderColor
    cStroke.Thickness = isDuped and 2.5 or 2
    cStroke.Parent    = card

    -- DUPE badge (top-right, duped only)
    if isDuped then
        local db = Instance.new("Frame")
        db.Size             = UDim2.new(0, 36, 0, 18)
        db.Position         = UDim2.new(1, -40, 0, 6)
        db.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
        db.BorderSizePixel  = 0
        db.ZIndex           = 5
        db.Parent           = card

        local dbC = Instance.new("UICorner")
        dbC.CornerRadius = UDim.new(0, 4)
        dbC.Parent       = db

        local dbL = Instance.new("TextLabel")
        dbL.Text            = "DUPE"
        dbL.Size            = UDim2.new(1, 0, 1, 0)
        dbL.BackgroundTransparency = 1
        dbL.Font            = Enum.Font.GothamBold
        dbL.TextColor3      = Color3.fromRGB(200, 255, 200)
        dbL.TextSize        = 9
        dbL.ZIndex          = 6
        dbL.Parent          = db
    end

    -- Unit image
    local unitImg = Instance.new("ImageLabel")
    unitImg.Size             = UDim2.new(1, -8, 0, 90)
    unitImg.Position         = UDim2.new(0, 4, 0, 4)
    unitImg.BackgroundColor3 = Color3.fromRGB(14, 14, 24)
    unitImg.Image            = unitData.image
    unitImg.ScaleType        = Enum.ScaleType.Fit
    unitImg.ZIndex           = 3
    unitImg.Parent           = card

    local imgC = Instance.new("UICorner")
    imgC.CornerRadius = UDim.new(0, 6)
    imgC.Parent       = unitImg

    -- Green overlay on duped images
    if isDuped then
        local ov = Instance.new("Frame")
        ov.Size             = UDim2.new(1, 0, 1, 0)
        ov.BackgroundColor3 = Color3.fromRGB(40, 180, 40)
        ov.BackgroundTransparency = 0.85
        ov.BorderSizePixel  = 0
        ov.ZIndex           = 4
        ov.Parent           = unitImg

        local ovC = Instance.new("UICorner")
        ovC.CornerRadius = UDim.new(0, 6)
        ovC.Parent       = ov
    end

    -- Lv. badge (top-left)
    local lvF = Instance.new("Frame")
    lvF.Size             = UDim2.new(0, 46, 0, 20)
    lvF.Position         = UDim2.new(0, 6, 0, 6)
    lvF.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
    lvF.BorderSizePixel  = 0
    lvF.ZIndex           = 5
    lvF.Parent           = card

    local lvC = Instance.new("UICorner")
    lvC.CornerRadius = UDim.new(0, 4)
    lvC.Parent       = lvF

    local lvS = Instance.new("UIStroke")
    lvS.Color = unitData.borderColor; lvS.Thickness = 1
    lvS.Parent = lvF

    local lvL = Instance.new("TextLabel")
    lvL.Text            = "Lv. " .. unitData.level
    lvL.Size            = UDim2.new(1, 0, 1, 0)
    lvL.BackgroundTransparency = 1
    lvL.Font            = Enum.Font.GothamBold
    lvL.TextColor3      = Color3.fromRGB(240, 240, 255)
    lvL.TextSize        = 10
    lvL.ZIndex          = 6
    lvL.Parent          = lvF

    -- Name label
    local nameL = Instance.new("TextLabel")
    nameL.Text           = unitData.name
    nameL.Size           = UDim2.new(1, -8, 0, 24)
    nameL.Position       = UDim2.new(0, 4, 0, 98)
    nameL.BackgroundTransparency = 1
    nameL.Font           = Enum.Font.GothamBold
    nameL.TextColor3     = isDuped and Color3.fromRGB(160, 240, 160) or Color3.fromRGB(230, 230, 255)
    nameL.TextSize       = 10
    nameL.TextWrapped    = true
    nameL.TextXAlignment = Enum.TextXAlignment.Center
    nameL.ZIndex         = 3
    nameL.Parent         = card

    -- Bottom button row: [â–¶ Place]  [+ Dupe / Ã— Remove]
    local btnRow = Instance.new("Frame")
    btnRow.Size             = UDim2.new(1, -8, 0, 24)
    btnRow.Position         = UDim2.new(0, 4, 0, 124)
    btnRow.BackgroundTransparency = 1
    btnRow.ZIndex           = 3
    btnRow.Parent           = card

    local rowL = Instance.new("UIListLayout")
    rowL.FillDirection     = Enum.FillDirection.Horizontal
    rowL.Padding           = UDim.new(0, 4)
    rowL.VerticalAlignment = Enum.VerticalAlignment.Center
    rowL.Parent            = btnRow

    local function miniBtn(text, bg)
        local b = Instance.new("TextButton")
        b.Text             = text
        b.Size             = UDim2.new(0, 65, 1, 0)
        b.BackgroundColor3 = bg
        b.Font             = Enum.Font.GothamBold
        b.TextColor3       = Color3.fromRGB(230, 230, 255)
        b.TextSize         = 10
        b.BorderSizePixel  = 0
        b.ZIndex           = 4
        b.Parent           = btnRow

        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 5)
        bc.Parent       = b
        return b
    end

    local placeBtn = miniBtn("â–¶ Place",   Color3.fromRGB(30, 60, 100))
    local dupeBtn  = miniBtn(
        isDuped and "Ã— Remove" or "+ Dupe",
        isDuped and Color3.fromRGB(80, 25, 25) or Color3.fromRGB(28, 68, 28)
    )

    -- Hover tween
    local bgNorm  = isDuped and Color3.fromRGB(18, 28, 18) or Color3.fromRGB(22, 22, 32)
    local bgHover = isDuped and Color3.fromRGB(26, 42, 26) or Color3.fromRGB(34, 34, 50)
    local tIn  = TweenService:Create(card, TweenInfo.new(0.1), {BackgroundColor3 = bgHover})
    local tOut = TweenService:Create(card, TweenInfo.new(0.1), {BackgroundColor3 = bgNorm})
    card.MouseEnter:Connect(function() tIn:Play() end)
    card.MouseLeave:Connect(function() tOut:Play() end)

    return card, placeBtn, dupeBtn, cStroke
end

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  GRID RENDER
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

local cardRefs = {}

local function renderGrid()
    for _, v in pairs(ScrollFrame:GetChildren()) do
        if v:IsA("Frame") then v:Destroy() end
    end
    cardRefs = {}

    local realN, dupeN = 0, 0
    for _, u in ipairs(unitList) do
        if u.duped then dupeN += 1 else realN += 1 end
    end
    CountLabel.Text = realN .. " units Â· " .. dupeN .. " duped"

    if #unitList == 0 then
        local el = Instance.new("TextLabel")
        el.Text            = "No units found.\nOpen in-match backpack, then Refresh."
        el.Size            = UDim2.new(1, 0, 0, 60)
        el.Position        = UDim2.new(0, 0, 0, 20)
        el.BackgroundTransparency = 1
        el.Font            = Enum.Font.Gotham
        el.TextColor3      = Color3.fromRGB(140, 140, 170)
        el.TextSize        = 13
        el.TextWrapped     = true
        el.ZIndex          = 2
        el.Parent          = ScrollFrame
        return
    end

    for i, unitData in ipairs(unitList) do
        local card, placeBtn, dupeBtn, stroke = makeUnitCard(unitData, i)
        card.Parent = ScrollFrame
        table.insert(cardRefs, {stroke = stroke, unit = unitData})

        placeBtn.MouseButton1Click:Connect(function()
            for _, ref in ipairs(cardRefs) do
                ref.stroke.Color = ref.unit.borderColor
            end
            stroke.Color = Color3.fromRGB(255, 255, 255)
            task.spawn(function() placeUnit(unitData) end)
        end)

        dupeBtn.MouseButton1Click:Connect(function()
            if unitData.duped then
                for idx, u in ipairs(unitList) do
                    if u == unitData then table.remove(unitList, idx) break end
                end
            else
                local copy = {
                    name        = unitData.name,
                    level       = unitData.level,
                    image       = unitData.image,
                    borderColor = unitData.borderColor,
                    button      = unitData.button,
                    duped       = true,
                }
                for idx, u in ipairs(unitList) do
                    if u == unitData then table.insert(unitList, idx + 1, copy) break end
                end
            end
            renderGrid()
        end)
    end
end

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  ACTION BUTTONS
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

RefreshBtn.MouseButton1Click:Connect(function()
    local fresh = getOwnedUnits()
    local oldDupes = {}
    for _, u in ipairs(unitList) do
        if u.duped then table.insert(oldDupes, u) end
    end
    unitList = fresh
    for _, d in ipairs(oldDupes) do
        local ok = false
        for _, u in ipairs(fresh) do if u.name == d.name then ok = true break end end
        if ok then table.insert(unitList, d) end
    end
    renderGrid()
end)

DupeAllBtn.MouseButton1Click:Connect(function()
    local reals = {}
    for _, u in ipairs(unitList) do if not u.duped then table.insert(reals, u) end end
    for _, orig in ipairs(reals) do
        local already = false
        for _, u in ipairs(unitList) do if u.duped and u.name == orig.name then already = true break end end
        if not already then
            table.insert(unitList, {
                name = orig.name, level = orig.level, image = orig.image,
                borderColor = orig.borderColor, button = orig.button, duped = true,
            })
        end
    end
    renderGrid()
end)

ClearDupeBtn.MouseButton1Click:Connect(function()
    local cleaned = {}
    for _, u in ipairs(unitList) do if not u.duped then table.insert(cleaned, u) end end
    unitList = cleaned
    renderGrid()
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  DRAG  (Mouse + Touch for mobile)
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

local dragging  = false
local dragStart = nil
local startPos  = nil

local function onDragStart(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = input.Position
        startPos  = Window.Position
    end
end

local function onDragEnd(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end

TitleBar.InputBegan:Connect(onDragStart)
TitleBar.InputEnded:Connect(onDragEnd)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        Window.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
--  LOAD + AUTO-REFRESH
-- â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

unitList = getOwnedUnits()
renderGrid()

-- Auto-populate once spawn UI becomes visible in a match
task.spawn(function()
    while task.wait(2) do
        if #unitList == 0 then
            local spawnUI = pgui:FindFirstChild("spawn_units")
            if spawnUI and spawnUI.Enabled then
                unitList = getOwnedUnits()
                renderGrid()
            end
        end
    end
end)

print(("[AA Unit Spawner] loaded on %s."):format(execName))
