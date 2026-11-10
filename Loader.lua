-- ============================================================
--  Anime Adventures — Trait Reroll Simulator
--  made by NotGreyAnymore
--  Visual-only simulator. Does not connect to Roblox servers.
-- ============================================================

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local LocalPlayer       = Players.LocalPlayer
local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
--  DATA
-- ============================================================

local BASE_TRAITS = {
    { name = "Superior I",   base = 14.98, tier = "common",    effect = "+10% Damage" },
    { name = "Range I",      base = 12.48, tier = "common",    effect = "+10% Range" },
    { name = "Nimble I",     base = 12.48, tier = "common",    effect = "-5% Cooldown" },
    { name = "Superior II",  base = 10.48, tier = "uncommon",  effect = "+12.5% Damage" },
    { name = "Adept",        base =  9.99, tier = "uncommon",  effect = "+50% XP from matches" },
    { name = "Nimble II",    base =  8.74, tier = "uncommon",  effect = "-7.5% Cooldown" },
    { name = "Range II",     base =  8.74, tier = "uncommon",  effect = "+12.5% Range" },
    { name = "Culling",      base =  5.00, tier = "uncommon",  effect = "+20% Damage to enemies <30% HP" },
    { name = "Superior III", base =  4.50, tier = "rare",      effect = "+15% Damage" },
    { name = "Range III",    base =  3.75, tier = "rare",      effect = "+15% Range" },
    { name = "Nimble III",   base =  3.75, tier = "rare",      effect = "-12% Cooldown" },
    { name = "Sniper",       base =  2.50, tier = "rare",      effect = "+25% Range" },
    { name = "Godspeed",     base =  1.00, tier = "epic",      effect = "-20% Cooldown" },
    { name = "Reaper",       base =  0.80, tier = "epic",      effect = "+15% Damage; +25% Damage to Bosses" },
    { name = "Celestial",    base =  0.36, tier = "epic",      effect = "+10% Dmg +10% Range; True Damage" },
    { name = "Divine",       base =  0.20, tier = "legendary", effect = "+20% Damage, +20% Range, -10% CD" },
    { name = "Golden",       base =  0.15, tier = "legendary", effect = "+30% Damage, +10% Kill Money" },
    { name = "Unique",       base =  0.10, tier = "unique",    effect = "+300% Damage, +10% Range, -10% CD" },
}

local TIER_COLORS = {
    common    = Color3.fromRGB(147, 197, 253),
    uncommon  = Color3.fromRGB(134, 239, 172),
    rare      = Color3.fromRGB(251, 191,  36),
    epic      = Color3.fromRGB(192, 132, 252),
    legendary = Color3.fromRGB(248, 113, 113),
    unique    = Color3.fromRGB(253, 224,  71),
}

local UNIQUE_LUCK_CHANCE = 25
local PRESETS = {10, 20, 30, 40, 50, 100, 250, 500, 1000, 2500}

-- Known AA unit names for detection (expand as needed)
local KNOWN_UNITS = {
    "Phoenix","Goku","Naruto","Luffy","Ichigo","Saitama","Rimuru",
    "Ainz","Giorno","Jotaro","Vegeta","Tanjiro","Zenitsu","Inosuke",
    "Killua","Gon","Meruem","Itachi","Madara","Minato","Sasuke",
    "Kakashi","Sukuna","Gojo","Yuji","Nobara","Megumi","Todo",
    "Erza","Natsu","Gray","Laxus","Mirajane","Wendy","Asta",
    "Yuno","Noelle","Magna","Luck","Zora","Yami","Julius",
    "Deku","Bakugo","Todoroki","Endeavor","Hawks","All Might",
    "Shigaraki","Overhaul","Dabi","Toga","Spinner","Mr. Compress",
    "Light","L","Near","Mello","Ryuk","Rem","Misa",
    "Edward","Alphonse","Roy","Riza","Olivier","Scar","Greed",
    "Monkey","Zoro","Sanji","Nami","Robin","Chopper","Usopp","Brook","Jinbe",
    "Ace","Whitebeard","Shanks","Kaido","Big Mom","Blackbeard",
    "Levi","Eren","Mikasa","Armin","Hange","Erwin","Reiner","Bertholdt",
    "Ryomen","Mahito","Dagon","Hanami","Jogo","Choso","Yuta",
    "Benimaru","Shuna","Shion","Gobuta","Ranga","Souei","Hakurou",
    "Albedo","Shalltear","Demiurge","Cocytus","Aura","Mare",
}

-- ============================================================
--  STATE
-- ============================================================

local luckOn         = true
local tokenBalance   = 10
local traitPanelOpen = false
local detectedUnit   = nil

-- ============================================================
--  HELPERS
-- ============================================================

local function round(n, dec)
    local m = 10 ^ (dec or 2)
    return math.floor(n * m + 0.5) / m
end

local function getTraits()
    if not luckOn then
        local t = {}
        for _, v in ipairs(BASE_TRAITS) do
            t[#t+1] = { name=v.name, chance=v.base, tier=v.tier, effect=v.effect }
        end
        return t
    end
    local uniqueNew  = UNIQUE_LUCK_CHANCE
    local diff       = uniqueNew - 0.10
    local totalOther = 0
    for _, v in ipairs(BASE_TRAITS) do
        if v.tier ~= "unique" then totalOther = totalOther + v.base end
    end
    local result = {}
    for _, v in ipairs(BASE_TRAITS) do
        if v.tier == "unique" then
            result[#result+1] = { name=v.name, chance=uniqueNew, tier=v.tier, effect=v.effect }
        else
            local adj = round(v.base - (v.base / totalOther) * diff, 4)
            result[#result+1] = { name=v.name, chance=adj, tier=v.tier, effect=v.effect }
        end
    end
    return result
end

local function rollTrait()
    local traits = getTraits()
    local r      = math.random() * 100
    local acc    = 0
    for _, t in ipairs(traits) do
        acc = acc + t.chance
        if r < acc then return t end
    end
    return traits[#traits]
end

local function detectUnitFromWorkspace()
    -- Scan workspace for known unit names in model/part names
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Part") or obj:IsA("MeshPart") then
            for _, unitName in ipairs(KNOWN_UNITS) do
                if string.find(obj.Name:lower(), unitName:lower()) then
                    return unitName
                end
            end
        end
    end
    return nil
end

-- ============================================================
--  GUI HELPERS
-- ============================================================

local function makeLabel(parent, text, size, pos, color, bold, zIndex)
    local l = Instance.new("TextLabel")
    l.Text               = text
    l.Size               = size or UDim2.new(1,0,0,20)
    l.Position           = pos  or UDim2.new(0,0,0,0)
    l.BackgroundTransparency = 1
    l.TextColor3         = color or Color3.fromRGB(255,255,255)
    l.Font               = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize           = 13
    l.ZIndex             = zIndex or 2
    l.TextXAlignment     = Enum.TextXAlignment.Left
    l.Parent             = parent
    return l
end

local function makeButton(parent, text, size, pos, bgColor, txtColor)
    local b = Instance.new("TextButton")
    b.Text               = text
    b.Size               = size
    b.Position           = pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3   = bgColor  or Color3.fromRGB(100,50,200)
    b.TextColor3         = txtColor or Color3.fromRGB(255,255,255)
    b.Font               = Enum.Font.GothamBold
    b.TextSize           = 13
    b.BorderSizePixel    = 0
    b.AutoButtonColor    = false
    b.ZIndex             = 3
    b.Parent             = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,8)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), {BackgroundTransparency=0.2}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), {BackgroundTransparency=0}):Play()
    end)
    b.MouseButton1Down:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.05),
            {Size=UDim2.new(size.X.Scale, size.X.Offset-4, size.Y.Scale, size.Y.Offset-2)}):Play()
    end)
    b.MouseButton1Up:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.05), {Size=size}):Play()
    end)
    return b
end

local function addStroke(inst, color, thickness)
    local s = Instance.new("UIStroke", inst)
    s.Color     = color     or Color3.fromRGB(168,85,247)
    s.Thickness = thickness or 2
    return s
end

-- ============================================================
--  SCREEN GUI
-- ============================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "AATraitReroll"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = PlayerGui

-- ============================================================
--  MAIN WINDOW
-- ============================================================

local Root = Instance.new("Frame")
Root.Name              = "Root"
Root.Size              = UDim2.new(0,420,0,580)
Root.Position          = UDim2.new(0.5,-210,0.5,-290)
Root.BackgroundColor3  = Color3.fromRGB(15,5,30)
Root.BorderSizePixel   = 0
Root.Parent            = ScreenGui
Instance.new("UICorner", Root).CornerRadius = UDim.new(0,14)
addStroke(Root, Color3.fromRGB(168,85,247), 2)

local BG = Instance.new("UIGradient", Root)
BG.Color    = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(26,10,46)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(26,26,62)),
})
BG.Rotation = 135

-- Drag
local dragging, dragStart, startPos
Root.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or
       inp.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = inp.Position; startPos = Root.Position
    end
end)
Root.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or
       inp.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or
                     inp.UserInputType == Enum.UserInputType.Touch) then
        local d = inp.Position - dragStart
        Root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X,
                                   startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
end)

-- ---- Header ----
local Header = Instance.new("Frame")
Header.Size             = UDim2.new(1,0,0,44)
Header.BackgroundColor3 = Color3.fromRGB(109,40,217)
Header.BorderSizePixel  = 0
Header.ZIndex           = 2
Header.Parent           = Root
Instance.new("UICorner", Header).CornerRadius = UDim.new(0,14)
-- fill bottom corners
local HFill = Instance.new("Frame", Header)
HFill.Size            = UDim2.new(1,0,0.5,0)
HFill.Position        = UDim2.new(0,0,0.5,0)
HFill.BackgroundColor3= Color3.fromRGB(109,40,217)
HFill.BorderSizePixel = 0
HFill.ZIndex          = 2

local TitleLbl = makeLabel(Header, "Trait Reroll", UDim2.new(1,-50,1,0), UDim2.new(0,14,0,0),
    Color3.fromRGB(255,255,255), true, 3)
TitleLbl.TextSize        = 16
TitleLbl.TextXAlignment  = Enum.TextXAlignment.Left

local CloseBtn = makeButton(Header, "X", UDim2.new(0,28,0,28),
    UDim2.new(1,-36,0.5,-14), Color3.fromRGB(220,38,38), Color3.fromRGB(255,255,255))
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- ============================================================
--  UNIQUE LUCK WINDOW  (separate, toggleable)
-- ============================================================

local LuckWin = Instance.new("Frame")
LuckWin.Name             = "LuckWindow"
LuckWin.Size             = UDim2.new(0,220,0,56)
LuckWin.Position         = UDim2.new(0.5,-110,0,70)   -- just below main header
LuckWin.BackgroundColor3 = Color3.fromRGB(13,13,26)
LuckWin.BorderSizePixel  = 0
LuckWin.ZIndex           = 10
LuckWin.Parent           = ScreenGui   -- owns its own layer, separate from Root
Instance.new("UICorner", LuckWin).CornerRadius = UDim.new(0,12)
local LuckStroke = addStroke(LuckWin, Color3.fromRGB(168,85,247), 2)

-- drag LuckWin independently
local ldragging, ldragStart, lstartPos
LuckWin.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or
       inp.UserInputType == Enum.UserInputType.Touch then
        ldragging = true; ldragStart = inp.Position; lstartPos = LuckWin.Position
    end
end)
LuckWin.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or
       inp.UserInputType == Enum.UserInputType.Touch then ldragging = false end
end)
UserInputService.InputChanged:Connect(function(inp)
    if ldragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or
                      inp.UserInputType == Enum.UserInputType.Touch) then
        local d = inp.Position - ldragStart
        LuckWin.Position = UDim2.new(lstartPos.X.Scale, lstartPos.X.Offset+d.X,
                                      lstartPos.Y.Scale, lstartPos.Y.Offset+d.Y)
    end
end)

-- close button on luck window
local LuckClose = makeButton(LuckWin, "X", UDim2.new(0,20,0,20),
    UDim2.new(1,-24,0,4), Color3.fromRGB(220,38,38), Color3.fromRGB(255,255,255))
LuckClose.TextSize = 10
LuckClose.MouseButton1Click:Connect(function()
    LuckWin.Visible = false
end)

-- clover + text
local LuckIcon = makeLabel(LuckWin, "☘", UDim2.new(0,22,0,22), UDim2.new(0,8,0,6),
    Color3.fromRGB(74,222,128), true, 11)
LuckIcon.TextSize       = 18
LuckIcon.TextXAlignment = Enum.TextXAlignment.Center

local LuckTitleLbl = makeLabel(LuckWin, "Unique Luck Active", UDim2.new(1,-60,0,18),
    UDim2.new(0,34,0,8), Color3.fromRGB(167,139,250), true, 11)
LuckTitleLbl.TextSize = 13

local LuckSubLbl = makeLabel(LuckWin, "Unique: 25% chance", UDim2.new(1,-60,0,14),
    UDim2.new(0,34,0,26), Color3.fromRGB(253,224,71), true, 11)
LuckSubLbl.TextSize = 10

-- toggle pill inside luck window
local LuckTogglePill = Instance.new("TextButton")
LuckTogglePill.Size             = UDim2.new(0,38,0,20)
LuckTogglePill.Position         = UDim2.new(1,-42,0.5,-10)
LuckTogglePill.BackgroundColor3 = Color3.fromRGB(34,197,94)
LuckTogglePill.BorderSizePixel  = 0
LuckTogglePill.Text             = ""
LuckTogglePill.ZIndex           = 12
LuckTogglePill.AutoButtonColor  = false
LuckTogglePill.Parent           = LuckWin
Instance.new("UICorner", LuckTogglePill).CornerRadius = UDim.new(1,0)
local LuckKnob = Instance.new("Frame", LuckTogglePill)
LuckKnob.Size             = UDim2.new(0,14,0,14)
LuckKnob.Position         = UDim2.new(1,-17,0.5,-7)
LuckKnob.BackgroundColor3 = Color3.fromRGB(255,255,255)
LuckKnob.BorderSizePixel  = 0
LuckKnob.ZIndex           = 13
Instance.new("UICorner", LuckKnob).CornerRadius = UDim.new(1,0)

-- ============================================================
--  SHOW LUCK WINDOW BUTTON (in main window)
-- ============================================================

local ShowLuckBtn = makeButton(Root, "☘ Unique Luck",
    UDim2.new(0,120,0,24), UDim2.new(0.5,-60,0,52),
    Color3.fromRGB(109,40,217), Color3.fromRGB(167,139,250))
ShowLuckBtn.TextSize = 11
ShowLuckBtn.MouseButton1Click:Connect(function()
    LuckWin.Visible = true
end)

-- ============================================================
--  UNIT DETECT PANEL
-- ============================================================

local UnitDetectFrame = Instance.new("Frame")
UnitDetectFrame.Size             = UDim2.new(1,-20,0,36)
UnitDetectFrame.Position         = UDim2.new(0,10,0,84)
UnitDetectFrame.BackgroundColor3 = Color3.fromRGB(13,13,26)
UnitDetectFrame.BorderSizePixel  = 0
UnitDetectFrame.ZIndex           = 2
UnitDetectFrame.Parent           = Root
Instance.new("UICorner", UnitDetectFrame).CornerRadius = UDim.new(0,8)
addStroke(UnitDetectFrame, Color3.fromRGB(109,40,217), 1)

local DetectIconLbl = makeLabel(UnitDetectFrame, "?", UDim2.new(0,30,1,0),
    UDim2.new(0,6,0,0), Color3.fromRGB(167,139,250), true, 3)
DetectIconLbl.TextSize       = 18
DetectIconLbl.TextXAlignment = Enum.TextXAlignment.Center

local DetectNameLbl = makeLabel(UnitDetectFrame, "No unit detected", UDim2.new(1,-110,0,16),
    UDim2.new(0,38,0,4), Color3.fromRGB(196,181,253), true, 3)
DetectNameLbl.TextSize = 12

local DetectSubLbl = makeLabel(UnitDetectFrame, "Place a unit to detect",
    UDim2.new(1,-110,0,12), UDim2.new(0,38,0,20),
    Color3.fromRGB(109,40,217), false, 3)
DetectSubLbl.TextSize = 9

local ScanBtn = makeButton(UnitDetectFrame, "Scan",
    UDim2.new(0,56,0,24), UDim2.new(1,-62,0.5,-12),
    Color3.fromRGB(109,40,217), Color3.fromRGB(255,255,255))
ScanBtn.TextSize = 11

-- ============================================================
--  UNIT ROW (Phoenix card area)
-- ============================================================

local UnitRow = Instance.new("Frame")
UnitRow.Size               = UDim2.new(1,-20,0,88)
UnitRow.Position           = UDim2.new(0,10,0,128)
UnitRow.BackgroundTransparency = 1
UnitRow.ZIndex             = 2
UnitRow.Parent             = Root
local URL = Instance.new("UIListLayout", UnitRow)
URL.FillDirection        = Enum.FillDirection.Horizontal
URL.VerticalAlignment    = Enum.VerticalAlignment.Center
URL.HorizontalAlignment  = Enum.HorizontalAlignment.Center
URL.Padding              = UDim.new(0,8)

-- Phoenix card
local PhCard = Instance.new("Frame")
PhCard.Size             = UDim2.new(0,80,0,80)
PhCard.BackgroundColor3 = Color3.fromRGB(124,45,18)
PhCard.BorderSizePixel  = 0
PhCard.ZIndex           = 2
PhCard.Parent           = UnitRow
Instance.new("UICorner", PhCard).CornerRadius = UDim.new(0,10)
addStroke(PhCard, Color3.fromRGB(249,115,22), 2)
local PhIcon = makeLabel(PhCard, "?", UDim2.new(1,0,0.6,0), UDim2.new(0,0,0.08,0),
    Color3.fromRGB(255,255,255), true, 3)
PhIcon.TextSize       = 28
PhIcon.TextXAlignment = Enum.TextXAlignment.Center
local PhName = makeLabel(PhCard, "Unit Slot", UDim2.new(1,0,0,14),
    UDim2.new(0,0,1,-16), Color3.fromRGB(255,255,255), true, 3)
PhName.TextSize       = 10
PhName.TextXAlignment = Enum.TextXAlignment.Center
local PhLv = makeLabel(PhCard, "Lv.1", UDim2.new(0,30,0,14),
    UDim2.new(0,4,0,4), Color3.fromRGB(255,255,255), true, 3)
PhLv.TextSize        = 9
PhLv.BackgroundColor3= Color3.fromRGB(0,0,0)
PhLv.BackgroundTransparency = 0.4
Instance.new("UICorner", PhLv).CornerRadius = UDim.new(0,4)

local ArrowLbl = makeLabel(UnitRow, "<<<", UDim2.new(0,36,0,40),
    nil, Color3.fromRGB(239,68,68), true, 3)
ArrowLbl.TextSize       = 20
ArrowLbl.TextXAlignment = Enum.TextXAlignment.Center

-- Token slot
local TokSlot = Instance.new("Frame")
TokSlot.Size             = UDim2.new(0,80,0,80)
TokSlot.BackgroundColor3 = Color3.fromRGB(30,27,75)
TokSlot.BorderSizePixel  = 0
TokSlot.ZIndex           = 2
TokSlot.Parent           = UnitRow
Instance.new("UICorner", TokSlot).CornerRadius = UDim.new(0,10)
addStroke(TokSlot, Color3.fromRGB(251,191,36), 3)
local TokIcon = makeLabel(TokSlot, "token", UDim2.new(1,0,0.55,0),
    UDim2.new(0,0,0.05,0), Color3.fromRGB(251,191,36), true, 3)
TokIcon.TextSize       = 10
TokIcon.TextXAlignment = Enum.TextXAlignment.Center
local TokCount = makeLabel(TokSlot, "10/1", UDim2.new(1,0,0,14),
    UDim2.new(0,0,0.65,0), Color3.fromRGB(251,191,36), true, 3)
TokCount.TextSize       = 11
TokCount.TextXAlignment = Enum.TextXAlignment.Center
local TokLabel = makeLabel(TokSlot, "Reroll Token", UDim2.new(1,0,0,14),
    UDim2.new(0,0,0.82,0), Color3.fromRGB(196,181,253), false, 3)
TokLabel.TextSize       = 9
TokLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Star slot
local StarSlot = Instance.new("Frame")
StarSlot.Size             = UDim2.new(0,72,0,72)
StarSlot.BackgroundColor3 = Color3.fromRGB(45,27,78)
StarSlot.BorderSizePixel  = 0
StarSlot.ZIndex           = 2
StarSlot.Parent           = UnitRow
Instance.new("UICorner", StarSlot).CornerRadius = UDim.new(0,10)
addStroke(StarSlot, Color3.fromRGB(109,40,217), 2)
local StarIcon = makeLabel(StarSlot, "star", UDim2.new(1,0,0.55,0),
    UDim2.new(0,0,0.05,0), Color3.fromRGB(167,139,250), true, 3)
StarIcon.TextSize       = 10
StarIcon.TextXAlignment = Enum.TextXAlignment.Center
local StarLabel = makeLabel(StarSlot, "Star Remnant", UDim2.new(1,0,0,14),
    UDim2.new(0,0,0.78,0), Color3.fromRGB(167,139,250), false, 3)
StarLabel.TextSize       = 8
StarLabel.TextXAlignment = Enum.TextXAlignment.Center

-- ============================================================
--  TOGGLE ROW (inside main window, mirrors luck window)
-- ============================================================

local TogRow = Instance.new("Frame")
TogRow.Size             = UDim2.new(1,-20,0,40)
TogRow.Position         = UDim2.new(0,10,0,224)
TogRow.BackgroundColor3 = Color3.fromRGB(13,13,26)
TogRow.BorderSizePixel  = 0
TogRow.ZIndex           = 2
TogRow.Parent           = Root
Instance.new("UICorner", TogRow).CornerRadius = UDim.new(0,10)
local TRStroke = addStroke(TogRow, Color3.fromRGB(168,85,247), 2)

local UDot = Instance.new("Frame", TogRow)
UDot.Size             = UDim2.new(0,10,0,10)
UDot.Position         = UDim2.new(0,10,0.5,-5)
UDot.BackgroundColor3 = Color3.fromRGB(34,197,94)
UDot.BorderSizePixel  = 0
UDot.ZIndex           = 3
Instance.new("UICorner", UDot).CornerRadius = UDim.new(1,0)

local ULbl = makeLabel(TogRow, "UNIQUE", UDim2.new(0,80,0,16),
    UDim2.new(0,26,0,5), Color3.fromRGB(167,139,250), true, 3)
ULbl.TextSize = 13
local USubLbl = makeLabel(TogRow, "Unique Luck Active ☘", UDim2.new(0,180,0,12),
    UDim2.new(0,26,0,22), Color3.fromRGB(109,40,217), true, 3)
USubLbl.TextSize = 10

local MainPill = Instance.new("TextButton")
MainPill.Size             = UDim2.new(0,44,0,22)
MainPill.Position         = UDim2.new(0,220,0.5,-11)
MainPill.BackgroundColor3 = Color3.fromRGB(34,197,94)
MainPill.BorderSizePixel  = 0
MainPill.Text             = ""
MainPill.ZIndex           = 3
MainPill.AutoButtonColor  = false
MainPill.Parent           = TogRow
Instance.new("UICorner", MainPill).CornerRadius = UDim.new(1,0)
local MainKnob = Instance.new("Frame", MainPill)
MainKnob.Size             = UDim2.new(0,16,0,16)
MainKnob.Position         = UDim2.new(1,-19,0.5,-8)
MainKnob.BackgroundColor3 = Color3.fromRGB(255,255,255)
MainKnob.BorderSizePixel  = 0
MainKnob.ZIndex           = 4
Instance.new("UICorner", MainKnob).CornerRadius = UDim.new(1,0)

local UniqueBig = makeLabel(TogRow, "Unique", UDim2.new(0,80,0,28),
    UDim2.new(1,-90,0.5,-14), Color3.fromRGB(168,85,247), true, 3)
UniqueBig.TextSize       = 18
UniqueBig.TextXAlignment = Enum.TextXAlignment.Center

local HintLbl = makeLabel(Root, "Rerolling your unit will replace their current traits.",
    UDim2.new(1,-20,0,14), UDim2.new(0,10,0,270),
    Color3.fromRGB(196,181,253), false, 2)
HintLbl.TextSize       = 10
HintLbl.TextXAlignment = Enum.TextXAlignment.Center

-- ============================================================
--  PRESET GRID
-- ============================================================

local PresTitle = makeLabel(Root, "Token Amount", UDim2.new(1,-20,0,14),
    UDim2.new(0,10,0,288), Color3.fromRGB(196,181,253), true, 2)
PresTitle.TextSize       = 11
PresTitle.TextXAlignment = Enum.TextXAlignment.Center

local PresGrid = Instance.new("Frame")
PresGrid.Size               = UDim2.new(1,-20,0,56)
PresGrid.Position           = UDim2.new(0,10,0,304)
PresGrid.BackgroundTransparency = 1
PresGrid.ZIndex             = 2
PresGrid.Parent             = Root
local PGL = Instance.new("UIGridLayout", PresGrid)
PGL.CellSize              = UDim2.new(0,66,0,24)
PGL.CellPadding           = UDim2.new(0,4,0,4)
PGL.HorizontalAlignment   = Enum.HorizontalAlignment.Center

local presetBtns = {}
local function refreshPresetHighlight(sel)
    for _, info in ipairs(presetBtns) do
        if info.val == sel then
            info.btn.BackgroundColor3 = Color3.fromRGB(120,53,15)
            info.btn.TextColor3       = Color3.fromRGB(251,191,36)
        else
            info.btn.BackgroundColor3 = Color3.fromRGB(49,46,129)
            info.btn.TextColor3       = Color3.fromRGB(255,255,255)
        end
    end
end
local activePreset = 10
for _, v in ipairs(PRESETS) do
    local lbl = v >= 1000 and (v/1000).."k" or tostring(v)
    local btn = makeButton(PresGrid, lbl, UDim2.new(0,66,0,24), nil,
        Color3.fromRGB(49,46,129), Color3.fromRGB(255,255,255))
    btn.TextSize = 11
    table.insert(presetBtns, {btn=btn, val=v})
    btn.MouseButton1Click:Connect(function()
        activePreset   = v
        tokenBalance   = v
        TokCount.Text  = tokenBalance.."/1"
        refreshPresetHighlight(v)
    end)
end
refreshPresetHighlight(10)

-- ============================================================
--  ROLL BUTTONS
-- ============================================================

local BtnRow = Instance.new("Frame")
BtnRow.Size               = UDim2.new(1,-20,0,36)
BtnRow.Position           = UDim2.new(0,10,0,368)
BtnRow.BackgroundTransparency = 1
BtnRow.ZIndex             = 2
BtnRow.Parent             = Root
local BRL = Instance.new("UIListLayout", BtnRow)
BRL.FillDirection       = Enum.FillDirection.Horizontal
BRL.HorizontalAlignment = Enum.HorizontalAlignment.Center
BRL.Padding             = UDim.new(0,6)

local RobuxBtn  = makeButton(BtnRow, "Robux Reroll", UDim2.new(0,110,0,36), nil,
    Color3.fromRGB(22,163,74),  Color3.fromRGB(255,255,255))
local RerollBtn = makeButton(BtnRow, "Reroll",        UDim2.new(0,100,0,36), nil,
    Color3.fromRGB(219,39,119), Color3.fromRGB(255,255,255))
local TokenBtn  = makeButton(BtnRow, "Reroll Token",  UDim2.new(0,110,0,36), nil,
    Color3.fromRGB(202,138,4),  Color3.fromRGB(26,10,0))

local Buy10Btn = makeButton(Root, "Buy 10", UDim2.new(0,110,0,30),
    UDim2.new(0.5,-55,0,412), Color3.fromRGB(202,138,4), Color3.fromRGB(26,10,0))

-- ============================================================
--  TRAIT CHANCES BUTTON + PANEL
-- ============================================================

local TCBtn = makeButton(Root, "Trait Chances", UDim2.new(0,120,0,24),
    UDim2.new(0.5,-60,0,450), Color3.fromRGB(202,138,4), Color3.fromRGB(26,10,0))
TCBtn.TextSize = 11

local TraitPanel = Instance.new("Frame")
TraitPanel.Size             = UDim2.new(1,-20,0,120)
TraitPanel.Position         = UDim2.new(0,10,0,480)
TraitPanel.BackgroundColor3 = Color3.fromRGB(13,13,26)
TraitPanel.BorderSizePixel  = 0
TraitPanel.Visible          = false
TraitPanel.ZIndex           = 2
TraitPanel.Parent           = Root
Instance.new("UICorner", TraitPanel).CornerRadius = UDim.new(0,10)
addStroke(TraitPanel, Color3.fromRGB(109,40,217), 1)

local TraitScroll = Instance.new("ScrollingFrame", TraitPanel)
TraitScroll.Size                 = UDim2.new(1,-4,1,-4)
TraitScroll.Position             = UDim2.new(0,2,0,2)
TraitScroll.BackgroundTransparency = 1
TraitScroll.ScrollBarThickness   = 3
TraitScroll.ZIndex               = 3
TraitScroll.CanvasSize           = UDim2.new(0,0,0,0)
Instance.new("UIListLayout", TraitScroll).Padding = UDim.new(0,2)

local function buildTraitPanel()
    for _, c in ipairs(TraitScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local traits = getTraits()
    for _, t in ipairs(traits) do
        local row = Instance.new("Frame")
        row.Size             = UDim2.new(1,-4,0,18)
        row.BackgroundColor3 = Color3.fromRGB(30,27,75)
        row.BorderSizePixel  = 0
        row.ZIndex           = 4
        row.Parent           = TraitScroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0,4)
        local nL = makeLabel(row, t.name, UDim2.new(0,100,1,0), UDim2.new(0,4,0,0),
            TIER_COLORS[t.tier], true, 5)
        nL.TextSize = 10
        local pL = makeLabel(row, string.format("%.2f%%", t.chance),
            UDim2.new(0,52,1,0), UDim2.new(0,106,0,0), Color3.fromRGB(251,191,36), true, 5)
        pL.TextSize = 10
        local eL = makeLabel(row, t.effect, UDim2.new(0,180,1,0), UDim2.new(0,160,0,0),
            Color3.fromRGB(156,163,175), false, 5)
        eL.TextSize = 9
    end
    TraitScroll.CanvasSize = UDim2.new(0,0,0, #traits * 20)
end

-- ============================================================
--  RESULT PANEL
-- ============================================================

local ResultPanel = Instance.new("Frame")
ResultPanel.Size             = UDim2.new(1,-20,0,0)
ResultPanel.Position         = UDim2.new(0,10,0,480)
ResultPanel.BackgroundColor3 = Color3.fromRGB(13,13,26)
ResultPanel.BorderSizePixel  = 0
ResultPanel.Visible          = false
ResultPanel.ZIndex           = 2
ResultPanel.Parent           = Root
Instance.new("UICorner", ResultPanel).CornerRadius = UDim.new(0,10)
addStroke(ResultPanel, Color3.fromRGB(168,85,247), 2)

-- UNIQUE splash overlay (shown on result panel when unique hits)
local UniqueSplash = Instance.new("Frame")
UniqueSplash.Size             = UDim2.new(1,0,1,0)
UniqueSplash.BackgroundColor3 = Color3.fromRGB(13,13,26)
UniqueSplash.BackgroundTransparency = 0.1
UniqueSplash.BorderSizePixel  = 0
UniqueSplash.ZIndex           = 20
UniqueSplash.Visible          = false
UniqueSplash.Parent           = ResultPanel
Instance.new("UICorner", UniqueSplash).CornerRadius = UDim.new(0,10)
addStroke(UniqueSplash, Color3.fromRGB(253,224,71), 3)

-- "UNIQUE" text in the actual game's style: big bold yellow
local SplashTitle = makeLabel(UniqueSplash, "UNIQUE", UDim2.new(1,0,0,48),
    UDim2.new(0,0,0.15,0), Color3.fromRGB(253,224,71), true, 21)
SplashTitle.TextSize       = 42
SplashTitle.TextXAlignment = Enum.TextXAlignment.Center

-- Effect line
local SplashEffect = makeLabel(UniqueSplash,
    "+300% Damage  +10% Range  -10% CD  |  Max 1 placed",
    UDim2.new(1,-20,0,24), UDim2.new(0,10,0.15,52),
    Color3.fromRGB(253,224,71), false, 21)
SplashEffect.TextSize       = 11
SplashEffect.TextXAlignment = Enum.TextXAlignment.Center
SplashEffect.TextWrapped    = true

-- Gold rarity bar
local SplashBar = Instance.new("Frame", UniqueSplash)
SplashBar.Size             = UDim2.new(0.6,0,0,4)
SplashBar.Position         = UDim2.new(0.2,0,0.15,48)
SplashBar.BackgroundColor3 = Color3.fromRGB(253,224,71)
SplashBar.BorderSizePixel  = 0
SplashBar.ZIndex           = 22
Instance.new("UICorner", SplashBar).CornerRadius = UDim.new(1,0)

local SplashSub = makeLabel(UniqueSplash, "0.10% base  |  25.00% with Unique Luck",
    UDim2.new(1,-20,0,16), UDim2.new(0,10,0.5,0),
    Color3.fromRGB(167,139,250), false, 21)
SplashSub.TextSize       = 10
SplashSub.TextXAlignment = Enum.TextXAlignment.Center

local SplashClose = makeButton(UniqueSplash, "Continue",
    UDim2.new(0,100,0,28), UDim2.new(0.5,-50,1,-38),
    Color3.fromRGB(253,224,71), Color3.fromRGB(26,10,0))
SplashClose.TextSize = 12
SplashClose.MouseButton1Click:Connect(function()
    UniqueSplash.Visible = false
end)

local ResultTitle = makeLabel(ResultPanel, "Roll Results", UDim2.new(1,0,0,18),
    UDim2.new(0,0,0,4), Color3.fromRGB(196,181,253), true, 3)
ResultTitle.TextSize       = 11
ResultTitle.TextXAlignment = Enum.TextXAlignment.Center

local ResultScroll = Instance.new("ScrollingFrame", ResultPanel)
ResultScroll.Size                 = UDim2.new(1,-4,1,-36)
ResultScroll.Position             = UDim2.new(0,2,0,22)
ResultScroll.BackgroundTransparency = 1
ResultScroll.ScrollBarThickness   = 3
ResultScroll.ZIndex               = 3
ResultScroll.CanvasSize           = UDim2.new(0,0,0,0)
Instance.new("UIListLayout", ResultScroll).Padding = UDim.new(0,3)

local ResultStatus = makeLabel(ResultPanel, "", UDim2.new(1,0,0,14),
    UDim2.new(0,0,1,-16), Color3.fromRGB(196,181,253), true, 3)
ResultStatus.TextSize       = 10
ResultStatus.TextXAlignment = Enum.TextXAlignment.Center

-- ============================================================
--  LUCK TOGGLE LOGIC  (syncs both pills)
-- ============================================================

local function updateLuckUI()
    local on = luckOn
    local onColor  = Color3.fromRGB(34,197,94)
    local offColor = Color3.fromRGB(107,114,128)
    local pillColor = on and onColor or offColor
    local knobOnPos  = UDim2.new(1,-19,0.5,-9)
    local knobOffPos = UDim2.new(0,3,0.5,-9)
    -- main pill
    TweenService:Create(MainPill,  TweenInfo.new(0.2), {BackgroundColor3=pillColor}):Play()
    TweenService:Create(MainKnob,  TweenInfo.new(0.2), {Position=on and knobOnPos or knobOffPos}):Play()
    -- luck window pill
    TweenService:Create(LuckTogglePill, TweenInfo.new(0.2), {BackgroundColor3=pillColor}):Play()
    TweenService:Create(LuckKnob,       TweenInfo.new(0.2),
        {Position=on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)}):Play()

    if on then
        LuckStroke.Color    = Color3.fromRGB(168,85,247)
        LuckTitleLbl.Text   = "Unique Luck Active"
        LuckSubLbl.Text     = "Unique: 25.00% chance"
        LuckSubLbl.TextColor3 = Color3.fromRGB(253,224,71)
        TRStroke.Color      = Color3.fromRGB(168,85,247)
        USubLbl.Text        = "Unique Luck Active ☘"
        UniqueBig.TextColor3 = Color3.fromRGB(168,85,247)
    else
        LuckStroke.Color    = Color3.fromRGB(107,114,128)
        LuckTitleLbl.Text   = "Unique Luck Off"
        LuckSubLbl.Text     = "Unique: 0.10% chance"
        LuckSubLbl.TextColor3 = Color3.fromRGB(196,181,253)
        TRStroke.Color      = Color3.fromRGB(107,114,128)
        USubLbl.Text        = "Normal Odds"
        UniqueBig.TextColor3 = Color3.fromRGB(107,114,128)
    end
    if traitPanelOpen then buildTraitPanel() end
end

local function toggleLuck()
    luckOn = not luckOn
    updateLuckUI()
end

MainPill.MouseButton1Click:Connect(toggleLuck)
LuckTogglePill.MouseButton1Click:Connect(toggleLuck)

TCBtn.MouseButton1Click:Connect(function()
    traitPanelOpen = not traitPanelOpen
    if traitPanelOpen then
        buildTraitPanel()
        ResultPanel.Visible = false
        TraitPanel.Visible  = true
    else
        TraitPanel.Visible  = false
    end
end)

-- ============================================================
--  SCAN BUTTON LOGIC
-- ============================================================

ScanBtn.MouseButton1Click:Connect(function()
    DetectNameLbl.Text    = "Scanning..."
    DetectSubLbl.Text     = ""
    task.wait(0.4)
    local found = detectUnitFromWorkspace()
    if found then
        detectedUnit          = found
        DetectNameLbl.Text    = found
        DetectNameLbl.TextColor3 = Color3.fromRGB(74,222,128)
        DetectSubLbl.Text     = "Unit detected"
        DetectSubLbl.TextColor3 = Color3.fromRGB(74,222,128)
        PhName.Text           = found
        PhIcon.Text           = found:sub(1,2)
    else
        detectedUnit          = nil
        DetectNameLbl.Text    = "No unit found"
        DetectNameLbl.TextColor3 = Color3.fromRGB(248,113,113)
        DetectSubLbl.Text     = "Place a unit and scan again"
        DetectSubLbl.TextColor3 = Color3.fromRGB(248,113,113)
    end
end)

-- ============================================================
--  ROLL LOGIC
-- ============================================================

local function showUniqueSplash()
    UniqueSplash.BackgroundTransparency = 0.1
    UniqueSplash.Visible = true
    SplashSub.Text = luckOn
        and "0.10% base  |  25.00% with Unique Luck"
        or  "0.10% base chance"
    -- border pulse
    for _ = 1, 4 do
        TweenService:Create(UniqueSplash:FindFirstChildWhichIsA("UIStroke"),
            TweenInfo.new(0.25), {Thickness=4}):Play()
        task.wait(0.25)
        TweenService:Create(UniqueSplash:FindFirstChildWhichIsA("UIStroke"),
            TweenInfo.new(0.25), {Thickness=2}):Play()
        task.wait(0.25)
    end
end

local function doRolls(count)
    local actual = math.min(count, tokenBalance)
    if actual < 1 then
        ResultStatus.Text = "No tokens left!"
        ResultPanel.Size  = UDim2.new(1,-20,0,52)
        ResultPanel.Visible = true
        return
    end
    tokenBalance  = tokenBalance - actual
    TokCount.Text = tokenBalance.."/1"

    for _, c in ipairs(ResultScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local results = {}
    for i = 1, actual do results[i] = rollTrait() end

    ResultTitle.Text = "Roll Results ("..actual.." roll"..(actual>1 and "s" or "")..")"
    TraitPanel.Visible = false
    traitPanelOpen     = false

    local uniqueCount = 0
    for i, t in ipairs(results) do
        local isU = t.tier == "unique"
        if isU then uniqueCount = uniqueCount + 1 end
        local row = Instance.new("Frame")
        row.Size             = UDim2.new(1,-4,0,20)
        row.BackgroundColor3 = isU and Color3.fromRGB(59,21,0) or Color3.fromRGB(30,27,75)
        row.BorderSizePixel  = 0
        row.ZIndex           = 4
        row.Parent           = ResultScroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0,4)
        if isU then addStroke(row, Color3.fromRGB(251,191,36), 1) end
        local nLbl = makeLabel(row, "#"..i, UDim2.new(0,26,1,0),
            UDim2.new(0,4,0,0), Color3.fromRGB(109,40,217), true, 5)
        nLbl.TextSize = 10
        local tLbl = makeLabel(row, t.name, UDim2.new(0,110,1,0),
            UDim2.new(0,32,0,0), TIER_COLORS[t.tier], true, 5)
        tLbl.TextSize = 11
        local pLbl = makeLabel(row, string.format("%.2f%%", t.chance),
            UDim2.new(0,60,1,0), UDim2.new(1,-68,0,0), TIER_COLORS[t.tier], true, 5)
        pLbl.TextSize       = 10
        pLbl.TextXAlignment = Enum.TextXAlignment.Right
    end

    local rowH = math.min(#results * 23, 140)
    ResultPanel.Size    = UDim2.new(1,-20,0, rowH + 56)
    ResultPanel.Visible = true
    ResultScroll.CanvasSize = UDim2.new(0,0,0, #results * 23)
    ResultScroll.CanvasPosition = Vector2.new(0, 999999)

    if uniqueCount > 0 then
        ResultStatus.Text      = "UNIQUE x"..uniqueCount.."!  Tokens left: "..tokenBalance
        ResultStatus.TextColor3 = Color3.fromRGB(253,224,71)
        task.spawn(showUniqueSplash)
    else
        ResultStatus.Text      = "Tokens left: "..tokenBalance
        ResultStatus.TextColor3 = Color3.fromRGB(196,181,253)
    end
end

RerollBtn.MouseButton1Click:Connect(function() doRolls(1)  end)
TokenBtn.MouseButton1Click:Connect(function()  doRolls(1)  end)
Buy10Btn.MouseButton1Click:Connect(function()  doRolls(10) end)
RobuxBtn.MouseButton1Click:Connect(function()
    ResultStatus.Text  = "Robux Reroll is cosmetic only in this simulator."
    ResultPanel.Size   = UDim2.new(1,-20,0,52)
    ResultPanel.Visible = true
end)

-- ============================================================
--  INIT
-- ============================================================

updateLuckUI()
buildTraitPanel()
print("[AATraitReroll] Loaded. Drag either window to move.")
