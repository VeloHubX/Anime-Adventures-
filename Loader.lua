-- ============================================================
--  Anime Adventures — Trait Reroll Simulator
--  made by NotGreyAnymore
--  Visual-only simulator. Does not connect to Roblox servers.
-- ============================================================

--[[
  USAGE:
    Import into a Roblox LocalScript or paste into a Luau executor.
    This creates a ScreenGui that mimics the Trait Reroll UI with:
      - Unique Luck toggle (boosts Unique to 25%)
      - Token balance picker (10, 20, 30, 40, 50, 100, 250, 500, 1000, 2500, custom)
      - Reroll / Reroll Token / Buy 10 buttons
      - Live results panel with rarity color coding
      - Trait Chances panel (updates live with toggle)
      - Draggable window
]]

local Players        = game:GetService("Players")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer    = Players.LocalPlayer
local PlayerGui      = LocalPlayer:WaitForChild("PlayerGui")

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
    rare      = Color3.fromRGB(251, 191, 36),
    epic      = Color3.fromRGB(192, 132, 252),
    legendary = Color3.fromRGB(248, 113, 113),
    unique    = Color3.fromRGB(253, 224, 71),
}

local UNIQUE_LUCK_CHANCE = 25
local PRESETS = {10, 20, 30, 40, 50, 100, 250, 500, 1000, 2500}

-- ============================================================
--  STATE
-- ============================================================

local luckOn       = true
local tokenBalance = 10
local traitPanelOpen = false
local resultPanelOpen = false

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
    local uniqueNew = UNIQUE_LUCK_CHANCE
    local diff = uniqueNew - 0.10
    local totalOther = 0
    for _, v in ipairs(BASE_TRAITS) do
        if v.tier ~= "unique" then totalOther = totalOther + v.base end
    end
    local result = {}
    for _, v in ipairs(BASE_TRAITS) do
        if v.tier == "unique" then
            result[#result+1] = { name=v.name, chance=uniqueNew, tier=v.tier, effect=v.effect }
        else
            local adjusted = round(v.base - (v.base / totalOther) * diff, 4)
            result[#result+1] = { name=v.name, chance=adjusted, tier=v.tier, effect=v.effect }
        end
    end
    return result
end

local function rollTrait()
    local traits = getTraits()
    local r = math.random() * 100
    local acc = 0
    for _, t in ipairs(traits) do
        acc = acc + t.chance
        if r < acc then return t end
    end
    return traits[#traits]
end

-- ============================================================
--  GUI CONSTRUCTION
-- ============================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AATraitReroll"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- Root frame (draggable)
local Root = Instance.new("Frame")
Root.Name = "Root"
Root.Size = UDim2.new(0, 400, 0, 620)
Root.Position = UDim2.new(0.5, -200, 0.5, -310)
Root.BackgroundColor3 = Color3.fromRGB(15, 5, 30)
Root.BorderSizePixel = 0
Root.Parent = ScreenGui
Instance.new("UICorner", Root).CornerRadius = UDim.new(0, 14)

local RootStroke = Instance.new("UIStroke", Root)
RootStroke.Color = Color3.fromRGB(168, 85, 247)
RootStroke.Thickness = 2

-- Gradient background
local BG = Instance.new("UIGradient", Root)
BG.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,  Color3.fromRGB(26, 10, 46)),
    ColorSequenceKeypoint.new(1,  Color3.fromRGB(26, 26, 62)),
})
BG.Rotation = 135

-- ---- Drag logic ----
local dragging, dragStart, startPos
Root.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = input.Position
        startPos  = Root.Position
    end
end)
Root.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                     input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Root.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ---- Utility: make a label ----
local function makeLabel(parent, text, size, pos, color, weight, zIndex)
    local l = Instance.new("TextLabel")
    l.Text = text
    l.Size = size or UDim2.new(1, 0, 0, 20)
    l.Position = pos or UDim2.new(0, 0, 0, 0)
    l.BackgroundTransparency = 1
    l.TextColor3 = color or Color3.fromRGB(255, 255, 255)
    l.Font = weight == "bold" and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize = 13
    l.ZIndex = zIndex or 2
    l.Parent = parent
    return l
end

local function makeButton(parent, text, size, pos, bgColor, textColor)
    local b = Instance.new("TextButton")
    b.Text = text
    b.Size = size
    b.Position = pos
    b.BackgroundColor3 = bgColor or Color3.fromRGB(100, 50, 200)
    b.TextColor3 = textColor or Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.ZIndex = 3
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    b.Parent = parent
    -- Hover tween
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), {BackgroundTransparency = 0.2}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
    end)
    b.MouseButton1Down:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.05), {Size = UDim2.new(size.X.Scale, size.X.Offset - 4, size.Y.Scale, size.Y.Offset - 2)}):Play()
    end)
    b.MouseButton1Up:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.05), {Size = size}):Play()
    end)
    return b
end

-- ============================================================
--  HEADER
-- ============================================================

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 44)
Header.BackgroundColor3 = Color3.fromRGB(109, 40, 217)
Header.BorderSizePixel = 0
Header.ZIndex = 2
Header.Parent = Root
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 14)

local HeaderFill = Instance.new("Frame")
HeaderFill.Size = UDim2.new(1, 0, 0.5, 0)
HeaderFill.Position = UDim2.new(0, 0, 0.5, 0)
HeaderFill.BackgroundColor3 = Color3.fromRGB(109, 40, 217)
HeaderFill.BorderSizePixel = 0
HeaderFill.ZIndex = 2
HeaderFill.Parent = Header

local TitleLabel = makeLabel(Header, "🎲  Trait Reroll  ☘", UDim2.new(1, -50, 1, 0), UDim2.new(0, 14, 0, 0), Color3.fromRGB(255,255,255), "bold", 3)
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.TextSize = 16

local CloseBtn = makeButton(Header, "✕", UDim2.new(0, 28, 0, 28), UDim2.new(1, -36, 0.5, -14), Color3.fromRGB(220, 38, 38), Color3.fromRGB(255,255,255))
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Luck Banner
local LuckBanner = Instance.new("Frame")
LuckBanner.Size = UDim2.new(0.85, 0, 0, 30)
LuckBanner.Position = UDim2.new(0.075, 0, 0, 52)
LuckBanner.BackgroundColor3 = Color3.fromRGB(13, 13, 26)
LuckBanner.BorderSizePixel = 0
LuckBanner.ZIndex = 2
LuckBanner.Parent = Root
local LuckStroke = Instance.new("UIStroke", LuckBanner)
LuckStroke.Color = Color3.fromRGB(168, 85, 247)
LuckStroke.Thickness = 2
Instance.new("UICorner", LuckBanner).CornerRadius = UDim.new(0, 15)
local LuckLabel = makeLabel(LuckBanner, "☘  Unique Luck Active  ☘", UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Color3.fromRGB(167, 139, 250), "bold", 3)
LuckLabel.TextXAlignment = Enum.TextXAlignment.Center

-- ============================================================
--  UNIT ROW
-- ============================================================

local UnitRow = Instance.new("Frame")
UnitRow.Size = UDim2.new(1, -20, 0, 90)
UnitRow.Position = UDim2.new(0, 10, 0, 90)
UnitRow.BackgroundTransparency = 1
UnitRow.ZIndex = 2
UnitRow.Parent = Root
local UnitLayout = Instance.new("UIListLayout", UnitRow)
UnitLayout.FillDirection = Enum.FillDirection.Horizontal
UnitLayout.VerticalAlignment = Enum.VerticalAlignment.Center
UnitLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UnitLayout.Padding = UDim.new(0, 8)

-- Phoenix card
local PhoenixCard = Instance.new("Frame")
PhoenixCard.Size = UDim2.new(0, 80, 0, 80)
PhoenixCard.BackgroundColor3 = Color3.fromRGB(124, 45, 18)
PhoenixCard.BorderSizePixel = 0
PhoenixCard.ZIndex = 2
PhoenixCard.Parent = UnitRow
Instance.new("UICorner", PhoenixCard).CornerRadius = UDim.new(0, 10)
local PStroke = Instance.new("UIStroke", PhoenixCard)
PStroke.Color = Color3.fromRGB(249, 115, 22)
PStroke.Thickness = 2
local PIcon = makeLabel(PhoenixCard, "🦅", UDim2.new(1,0,0.6,0), UDim2.new(0,0,0.1,0), Color3.fromRGB(255,255,255), "bold", 3)
PIcon.TextSize = 28
PIcon.TextXAlignment = Enum.TextXAlignment.Center
local PName = makeLabel(PhoenixCard, "Phoenix", UDim2.new(1,0,0,16), UDim2.new(0,0,1,-18), Color3.fromRGB(255,255,255), "bold", 3)
PName.TextSize = 11
PName.TextXAlignment = Enum.TextXAlignment.Center
local PLv = makeLabel(PhoenixCard, "Lv.1", UDim2.new(0,30,0,14), UDim2.new(0,4,0,4), Color3.fromRGB(255,255,255), "bold", 3)
PLv.TextSize = 9
PLv.BackgroundColor3 = Color3.fromRGB(0,0,0)
PLv.BackgroundTransparency = 0.4
Instance.new("UICorner", PLv).CornerRadius = UDim.new(0,4)

-- Arrows
local ArrowLabel = makeLabel(UnitRow, "<<<", UDim2.new(0, 36, 0, 40), nil, Color3.fromRGB(239,68,68), "bold", 3)
ArrowLabel.TextSize = 20
ArrowLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Token slot
local TokenSlot = Instance.new("Frame")
TokenSlot.Size = UDim2.new(0, 80, 0, 80)
TokenSlot.BackgroundColor3 = Color3.fromRGB(30, 27, 75)
TokenSlot.BorderSizePixel = 0
TokenSlot.ZIndex = 2
TokenSlot.Parent = UnitRow
Instance.new("UICorner", TokenSlot).CornerRadius = UDim.new(0, 10)
local TStroke = Instance.new("UIStroke", TokenSlot)
TStroke.Color = Color3.fromRGB(251, 191, 36)
TStroke.Thickness = 3
local TIcon = makeLabel(TokenSlot, "💎", UDim2.new(1,0,0.55,0), UDim2.new(0,0,0.05,0), Color3.fromRGB(255,255,255), "bold", 3)
TIcon.TextSize = 26
TIcon.TextXAlignment = Enum.TextXAlignment.Center
local TCount = makeLabel(TokenSlot, "10/1", UDim2.new(1,0,0,14), UDim2.new(0,0,0.65,0), Color3.fromRGB(251,191,36), "bold", 3)
TCount.TextSize = 11
TCount.TextXAlignment = Enum.TextXAlignment.Center
local TLabel = makeLabel(TokenSlot, "Reroll Token", UDim2.new(1,0,0,14), UDim2.new(0,0,0.82,0), Color3.fromRGB(196,181,253), "bold", 3)
TLabel.TextSize = 9
TLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Star slot
local StarSlot = Instance.new("Frame")
StarSlot.Size = UDim2.new(0, 72, 0, 72)
StarSlot.BackgroundColor3 = Color3.fromRGB(45, 27, 78)
StarSlot.BorderSizePixel = 0
StarSlot.ZIndex = 2
StarSlot.Parent = UnitRow
Instance.new("UICorner", StarSlot).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", StarSlot).Color = Color3.fromRGB(109, 40, 217)
local SIcon = makeLabel(StarSlot, "🌑", UDim2.new(1,0,0.55,0), UDim2.new(0,0,0.05,0), Color3.fromRGB(255,255,255), "bold", 3)
SIcon.TextSize = 24
SIcon.TextXAlignment = Enum.TextXAlignment.Center
local SLabel = makeLabel(StarSlot, "Star Remnant", UDim2.new(1,0,0,14), UDim2.new(0,0,0.78,0), Color3.fromRGB(167,139,250), "bold", 3)
SLabel.TextSize = 8
SLabel.TextXAlignment = Enum.TextXAlignment.Center

-- ============================================================
--  UNIQUE TOGGLE ROW
-- ============================================================

local ToggleRow = Instance.new("Frame")
ToggleRow.Size = UDim2.new(1, -20, 0, 42)
ToggleRow.Position = UDim2.new(0, 10, 0, 188)
ToggleRow.BackgroundColor3 = Color3.fromRGB(13, 13, 26)
ToggleRow.BorderSizePixel = 0
ToggleRow.ZIndex = 2
ToggleRow.Parent = Root
Instance.new("UICorner", ToggleRow).CornerRadius = UDim.new(0, 10)
local TRStroke = Instance.new("UIStroke", ToggleRow)
TRStroke.Color = Color3.fromRGB(168, 85, 247)
TRStroke.Thickness = 2

local UniqueDot = Instance.new("Frame")
UniqueDot.Size = UDim2.new(0, 10, 0, 10)
UniqueDot.Position = UDim2.new(0, 10, 0.5, -5)
UniqueDot.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
UniqueDot.BorderSizePixel = 0
UniqueDot.ZIndex = 3
UniqueDot.Parent = ToggleRow
Instance.new("UICorner", UniqueDot).CornerRadius = UDim.new(1, 0)

local UniqueLabel = makeLabel(ToggleRow, "UNIQUE", UDim2.new(0,80,0,18), UDim2.new(0,26,0,5), Color3.fromRGB(167,139,250), "bold", 3)
UniqueLabel.TextSize = 13
UniqueLabel.TextXAlignment = Enum.TextXAlignment.Left

local UniqueSubLabel = makeLabel(ToggleRow, "Unique Luck Active ☘", UDim2.new(0,160,0,14), UDim2.new(0,26,0,22), Color3.fromRGB(109,40,217), "bold", 3)
UniqueSubLabel.TextSize = 10
UniqueSubLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Toggle pill button
local TogglePill = Instance.new("TextButton")
TogglePill.Size = UDim2.new(0, 44, 0, 24)
TogglePill.Position = UDim2.new(0, 200, 0.5, -12)
TogglePill.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
TogglePill.BorderSizePixel = 0
TogglePill.Text = ""
TogglePill.ZIndex = 3
TogglePill.AutoButtonColor = false
TogglePill.Parent = ToggleRow
Instance.new("UICorner", TogglePill).CornerRadius = UDim.new(1, 0)

local PillKnob = Instance.new("Frame")
PillKnob.Size = UDim2.new(0, 18, 0, 18)
PillKnob.Position = UDim2.new(1, -21, 0.5, -9)
PillKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
PillKnob.BorderSizePixel = 0
PillKnob.ZIndex = 4
PillKnob.Parent = TogglePill
Instance.new("UICorner", PillKnob).CornerRadius = UDim.new(1, 0)

local UniqueBigLabel = makeLabel(ToggleRow, "Unique", UDim2.new(0,80,0,30), UDim2.new(1,-90,0.5,-15), Color3.fromRGB(168,85,247), "bold", 3)
UniqueBigLabel.TextSize = 20
UniqueBigLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Hint
local HintLabel = makeLabel(Root, "Rerolling your unit will replace their current traits.", UDim2.new(1,-20,0,16), UDim2.new(0,10,0,236), Color3.fromRGB(196,181,253), "normal", 2)
HintLabel.TextSize = 10
HintLabel.TextXAlignment = Enum.TextXAlignment.Center

-- ============================================================
--  TOKEN PRESET GRID
-- ============================================================

local PresetTitle = makeLabel(Root, "Token Amount", UDim2.new(1,-20,0,16), UDim2.new(0,10,0,258), Color3.fromRGB(196,181,253), "bold", 2)
PresetTitle.TextSize = 11
PresetTitle.TextXAlignment = Enum.TextXAlignment.Center

local PresetGrid = Instance.new("Frame")
PresetGrid.Size = UDim2.new(1,-20,0,56)
PresetGrid.Position = UDim2.new(0,10,0,276)
PresetGrid.BackgroundTransparency = 1
PresetGrid.ZIndex = 2
PresetGrid.Parent = Root
local PGL = Instance.new("UIGridLayout", PresetGrid)
PGL.CellSize = UDim2.new(0, 66, 0, 24)
PGL.CellPadding = UDim2.new(0, 4, 0, 4)
PGL.HorizontalAlignment = Enum.HorizontalAlignment.Center

local presetBtns = {}
local function updatePresetHighlight(selected)
    for _, info in ipairs(presetBtns) do
        if info.val == selected then
            info.btn.BackgroundColor3 = Color3.fromRGB(120, 53, 15)
            info.btn.TextColor3 = Color3.fromRGB(251, 191, 36)
        else
            info.btn.BackgroundColor3 = Color3.fromRGB(49, 46, 129)
            info.btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
    end
end

for _, v in ipairs(PRESETS) do
    local lbl = v >= 1000 and (v/1000).."k" or tostring(v)
    local btn = makeButton(PresetGrid, lbl, UDim2.new(0,66,0,24), UDim2.new(0,0,0,0), Color3.fromRGB(49,46,129), Color3.fromRGB(255,255,255))
    btn.TextSize = 11
    table.insert(presetBtns, {btn=btn, val=v})
    btn.MouseButton1Click:Connect(function()
        tokenBalance = v
        TCount.Text = tokenBalance.."/1"
        updatePresetHighlight(v)
    end)
end
updatePresetHighlight(10)

-- ============================================================
--  ROLL BUTTONS
-- ============================================================

local BtnRow = Instance.new("Frame")
BtnRow.Size = UDim2.new(1,-20,0,36)
BtnRow.Position = UDim2.new(0,10,0,340)
BtnRow.BackgroundTransparency = 1
BtnRow.ZIndex = 2
BtnRow.Parent = Root
local BRL = Instance.new("UIListLayout", BtnRow)
BRL.FillDirection = Enum.FillDirection.Horizontal
BRL.HorizontalAlignment = Enum.HorizontalAlignment.Center
BRL.Padding = UDim.new(0, 6)

local RobuxBtn  = makeButton(BtnRow, "Robux Reroll", UDim2.new(0,110,0,36), nil, Color3.fromRGB(22,163,74),  Color3.fromRGB(255,255,255))
local RerollBtn = makeButton(BtnRow, "Reroll",        UDim2.new(0,100,0,36), nil, Color3.fromRGB(219,39,119), Color3.fromRGB(255,255,255))
local TokenBtn  = makeButton(BtnRow, "Reroll Token",  UDim2.new(0,110,0,36), nil, Color3.fromRGB(202,138,4),  Color3.fromRGB(26,10,0))

local Buy10Btn = makeButton(Root, "Buy 10", UDim2.new(0,120,0,32), UDim2.new(0.5,-60,0,384), Color3.fromRGB(202,138,4), Color3.fromRGB(26,10,0))

-- ============================================================
--  TRAIT CHANCES BUTTON + PANEL
-- ============================================================

local TCBtn = makeButton(Root, "Trait Chances", UDim2.new(0,120,0,26), UDim2.new(0.5,-60,0,424), Color3.fromRGB(202,138,4), Color3.fromRGB(26,10,0))

local TraitPanel = Instance.new("Frame")
TraitPanel.Size = UDim2.new(1,-20,0,160)
TraitPanel.Position = UDim2.new(0,10,0,456)
TraitPanel.BackgroundColor3 = Color3.fromRGB(13,13,26)
TraitPanel.BorderSizePixel = 0
TraitPanel.Visible = false
TraitPanel.ZIndex = 2
TraitPanel.Parent = Root
Instance.new("UICorner", TraitPanel).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke", TraitPanel).Color = Color3.fromRGB(109,40,217)

local TraitScroll = Instance.new("ScrollingFrame", TraitPanel)
TraitScroll.Size = UDim2.new(1,-4,1,-4)
TraitScroll.Position = UDim2.new(0,2,0,2)
TraitScroll.BackgroundTransparency = 1
TraitScroll.ScrollBarThickness = 3
TraitScroll.ZIndex = 3
TraitScroll.CanvasSize = UDim2.new(0,0,0,0)
local TraitListLayout = Instance.new("UIListLayout", TraitScroll)
TraitListLayout.Padding = UDim.new(0, 2)

local function buildTraitPanel()
    for _, c in ipairs(TraitScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local traits = getTraits()
    for _, t in ipairs(traits) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1,-4,0,18)
        row.BackgroundColor3 = Color3.fromRGB(30,27,75)
        row.BorderSizePixel = 0
        row.ZIndex = 4
        row.Parent = TraitScroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0,4)
        local nameL = makeLabel(row, t.name, UDim2.new(0,110,1,0), UDim2.new(0,4,0,0), TIER_COLORS[t.tier], "bold", 5)
        nameL.TextSize = 10
        nameL.TextXAlignment = Enum.TextXAlignment.Left
        local pctL = makeLabel(row, string.format("%.2f%%", t.chance), UDim2.new(0,52,1,0), UDim2.new(0,116,0,0), Color3.fromRGB(251,191,36), "bold", 5)
        pctL.TextSize = 10
        local effL = makeLabel(row, t.effect, UDim2.new(0,160,1,0), UDim2.new(0,170,0,0), Color3.fromRGB(156,163,175), "normal", 5)
        effL.TextSize = 9
        effL.TextXAlignment = Enum.TextXAlignment.Left
    end
    TraitScroll.CanvasSize = UDim2.new(0,0,0, #traits * 20)
end

-- ============================================================
--  RESULTS PANEL
-- ============================================================

local ResultPanel = Instance.new("Frame")
ResultPanel.Size = UDim2.new(1,-20,0,0)
ResultPanel.Position = UDim2.new(0,10,0,456)
ResultPanel.BackgroundColor3 = Color3.fromRGB(13,13,26)
ResultPanel.BorderSizePixel = 0
ResultPanel.Visible = false
ResultPanel.ZIndex = 2
ResultPanel.Parent = Root
Instance.new("UICorner", ResultPanel).CornerRadius = UDim.new(0,10)
Instance.new("UIStroke", ResultPanel).Color = Color3.fromRGB(168,85,247)

local ResultTitle = makeLabel(ResultPanel, "Roll Results", UDim2.new(1,0,0,18), UDim2.new(0,0,0,4), Color3.fromRGB(196,181,253), "bold", 3)
ResultTitle.TextSize = 11
ResultTitle.TextXAlignment = Enum.TextXAlignment.Center

local ResultScroll = Instance.new("ScrollingFrame", ResultPanel)
ResultScroll.Size = UDim2.new(1,-4,1,-36)
ResultScroll.Position = UDim2.new(0,2,0,22)
ResultScroll.BackgroundTransparency = 1
ResultScroll.ScrollBarThickness = 3
ResultScroll.ZIndex = 3
ResultScroll.CanvasSize = UDim2.new(0,0,0,0)
local ResultListLayout = Instance.new("UIListLayout", ResultScroll)
ResultListLayout.Padding = UDim.new(0,3)

local ResultStatus = makeLabel(ResultPanel, "", UDim2.new(1,0,0,14), UDim2.new(0,0,1,-16), Color3.fromRGB(196,181,253), "bold", 3)
ResultStatus.TextSize = 10
ResultStatus.TextXAlignment = Enum.TextXAlignment.Center

-- ============================================================
--  TOGGLE LOGIC
-- ============================================================

local function updateLuckUI()
    if luckOn then
        TweenService:Create(TogglePill, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(34,197,94)}):Play()
        TweenService:Create(PillKnob,   TweenInfo.new(0.2), {Position=UDim2.new(1,-21,0.5,-9)}):Play()
        LuckStroke.Color = Color3.fromRGB(168,85,247)
        LuckLabel.Text = "☘  Unique Luck Active  ☘"
        UniqueSubLabel.Text = "Unique Luck Active ☘"
        UniqueBigLabel.TextColor3 = Color3.fromRGB(168,85,247)
    else
        TweenService:Create(TogglePill, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(107,114,128)}):Play()
        TweenService:Create(PillKnob,   TweenInfo.new(0.2), {Position=UDim2.new(0,3,0.5,-9)}):Play()
        LuckStroke.Color = Color3.fromRGB(107,114,128)
        LuckLabel.Text = "Unique Luck Off"
        UniqueSubLabel.Text = "Normal Odds"
        UniqueBigLabel.TextColor3 = Color3.fromRGB(107,114,128)
    end
    if traitPanelOpen then buildTraitPanel() end
end

TogglePill.MouseButton1Click:Connect(function()
    luckOn = not luckOn
    updateLuckUI()
end)

-- ============================================================
--  ROLL LOGIC
-- ============================================================

local function doRolls(count)
    local actual = math.min(count, tokenBalance)
    if actual < 1 then
        ResultStatus.Text = "No tokens left!"
        ResultPanel.Visible = true
        return
    end
    tokenBalance = tokenBalance - actual
    TCount.Text = tokenBalance.."/1"

    -- clear old results
    for _, c in ipairs(ResultScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local results = {}
    for i = 1, actual do results[i] = rollTrait() end

    ResultTitle.Text = "Roll Results ("..actual.." roll"..(actual > 1 and "s" or "")..")"

    local uniqueCount = 0
    for i, t in ipairs(results) do
        local isUnique = t.tier == "unique"
        if isUnique then uniqueCount = uniqueCount + 1 end
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1,-4,0,20)
        row.BackgroundColor3 = isUnique and Color3.fromRGB(59,21,0) or Color3.fromRGB(30,27,75)
        row.BorderSizePixel = 0
        row.ZIndex = 4
        row.Parent = ResultScroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0,4)
        if isUnique then
            local s = Instance.new("UIStroke", row)
            s.Color = Color3.fromRGB(251,191,36)
            s.Thickness = 1
        end
        local numL = makeLabel(row, "#"..i, UDim2.new(0,28,1,0), UDim2.new(0,4,0,0), Color3.fromRGB(109,40,217), "bold", 5)
        numL.TextSize = 10
        local nameL = makeLabel(row, t.name, UDim2.new(0,110,1,0), UDim2.new(0,34,0,0), TIER_COLORS[t.tier], "bold", 5)
        nameL.TextSize = 11
        nameL.TextXAlignment = Enum.TextXAlignment.Left
        local pctL = makeLabel(row, string.format("%.2f%%", t.chance), UDim2.new(0,60,1,0), UDim2.new(1,-68,0,0), TIER_COLORS[t.tier], "bold", 5)
        pctL.TextSize = 10
        pctL.TextXAlignment = Enum.TextXAlignment.Right
    end

    ResultScroll.CanvasSize = UDim2.new(0,0,0, #results * 23)
    ResultScroll.CanvasPosition = Vector2.new(0, math.huge)

    if uniqueCount > 0 then
        ResultStatus.Text = "🌟 UNIQUE x"..uniqueCount.."!  Tokens left: "..tokenBalance
        ResultStatus.TextColor3 = Color3.fromRGB(253,224,71)
        -- flash
        for _ = 1, 3 do
            TweenService:Create(ResultStatus, TweenInfo.new(0.2), {TextTransparency=0.8}):Play()
            task.wait(0.2)
            TweenService:Create(ResultStatus, TweenInfo.new(0.2), {TextTransparency=0}):Play()
            task.wait(0.2)
        end
    else
        ResultStatus.Text = "Tokens left: "..tokenBalance
        ResultStatus.TextColor3 = Color3.fromRGB(196,181,253)
    end

    -- size result panel dynamically
    local rowH = math.min(#results * 23, 140)
    ResultPanel.Size = UDim2.new(1,-20,0, rowH + 56)
    ResultPanel.Visible = true
end

RerollBtn.MouseButton1Click:Connect(function() doRolls(1) end)
TokenBtn.MouseButton1Click:Connect(function()  doRolls(1) end)
Buy10Btn.MouseButton1Click:Connect(function()  doRolls(10) end)
RobuxBtn.MouseButton1Click:Connect(function()
    ResultStatus.Text = "Robux Reroll is cosmetic only in this simulator."
    ResultPanel.Size = UDim2.new(1,-20,0,52)
    ResultPanel.Visible = true
end)

-- ============================================================
--  TRAIT PANEL TOGGLE
-- ============================================================

TCBtn.MouseButton1Click:Connect(function()
    traitPanelOpen = not traitPanelOpen
    if traitPanelOpen then
        buildTraitPanel()
        ResultPanel.Visible = false
        TraitPanel.Position = UDim2.new(0,10,0,456)
        TraitPanel.Visible = true
    else
        TraitPanel.Visible = false
    end
end)

-- ============================================================
--  INIT
-- ============================================================

updateLuckUI()
buildTraitPanel()

print("[AATraitReroll] Loaded. Drag the window to move it.")
