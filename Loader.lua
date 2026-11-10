-- ============================================================
--  Anime Adventures — Trait Reroll Simulator
--  made by NotGreyAnymore
--  Visual-only simulator. Does not connect to Roblox servers.
-- ============================================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer
local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
--  DATA
-- ============================================================

local BASE_TRAITS = {
    { name="Superior I",   base=14.98, tier="common",    effect="+10% Damage" },
    { name="Range I",      base=12.48, tier="common",    effect="+10% Range" },
    { name="Nimble I",     base=12.48, tier="common",    effect="-5% Cooldown" },
    { name="Superior II",  base=10.48, tier="uncommon",  effect="+12.5% Damage" },
    { name="Adept",        base= 9.99, tier="uncommon",  effect="+50% XP from matches" },
    { name="Nimble II",    base= 8.74, tier="uncommon",  effect="-7.5% Cooldown" },
    { name="Range II",     base= 8.74, tier="uncommon",  effect="+12.5% Range" },
    { name="Culling",      base= 5.00, tier="uncommon",  effect="+20% Dmg <30% HP" },
    { name="Superior III", base= 4.50, tier="rare",      effect="+15% Damage" },
    { name="Range III",    base= 3.75, tier="rare",      effect="+15% Range" },
    { name="Nimble III",   base= 3.75, tier="rare",      effect="-12% Cooldown" },
    { name="Sniper",       base= 2.50, tier="rare",      effect="+25% Range" },
    { name="Godspeed",     base= 1.00, tier="epic",      effect="-20% Cooldown" },
    { name="Reaper",       base= 0.80, tier="epic",      effect="+15% Dmg +25% Boss" },
    { name="Celestial",    base= 0.36, tier="epic",      effect="+10% Dmg +10% Range +True Dmg" },
    { name="Divine",       base= 0.20, tier="legendary", effect="+20% Dmg +20% Range -10% CD" },
    { name="Golden",       base= 0.15, tier="legendary", effect="+30% Dmg +10% Kill Money" },
    { name="Unique",       base= 0.10, tier="unique",    effect="+300% Dmg +10% Range -10% CD" },
}

local TIER_COLORS = {
    common    = Color3.fromRGB(147,197,253),
    uncommon  = Color3.fromRGB(134,239,172),
    rare      = Color3.fromRGB(251,191, 36),
    epic      = Color3.fromRGB(192,132,252),
    legendary = Color3.fromRGB(248,113,113),
    unique    = Color3.fromRGB(253,224, 71),
}

local UNIQUE_LUCK_CHANCE = 25

-- AA unit name fragments — scanner checks model names for these
local UNIT_TAGS = {
    "chuuni","phoenix","goku","naruto","luffy","ichigo","saitama","rimuru",
    "ainz","giorno","jotaro","vegeta","tanjiro","zenitsu","inosuke",
    "killua","gon","meruem","itachi","madara","minato","sasuke","kakashi",
    "sukuna","gojo","yuji","nobara","megumi","todo","erza","natsu","gray",
    "laxus","mirajane","wendy","asta","yuno","noelle","deku","bakugo",
    "todoroki","endeavor","hawks","allmight","all might","shigaraki",
    "overhaul","dabi","toga","light","ryuk","edward","alphonse","roy",
    "monkey","zoro","sanji","ace","whitebeard","shanks","kaido","levi",
    "eren","mikasa","armin","benimaru","shuna","albedo","shalltear",
    "demon","dragon","shadow","flame","storm","void","chaos","divine",
    "celestial","golden","reaper","sniper","godspeed",
}

local PRESETS = {10,20,30,40,50,100,250,500,1000,2500}

-- ============================================================
--  STATE
-- ============================================================

local luckOn         = true
local tokenBalance   = 10
local traitPanelOpen = false
local detectedUnit   = nil
local activePreset   = 10

-- ============================================================
--  HELPERS
-- ============================================================

local function round(n,dec)
    local m = 10^(dec or 2)
    return math.floor(n*m+0.5)/m
end

local function getTraits()
    if not luckOn then
        local t={}
        for _,v in ipairs(BASE_TRAITS) do
            t[#t+1]={name=v.name,chance=v.base,tier=v.tier,effect=v.effect}
        end
        return t
    end
    local diff=UNIQUE_LUCK_CHANCE-0.10
    local tot=0
    for _,v in ipairs(BASE_TRAITS) do if v.tier~="unique" then tot=tot+v.base end end
    local r={}
    for _,v in ipairs(BASE_TRAITS) do
        if v.tier=="unique" then
            r[#r+1]={name=v.name,chance=UNIQUE_LUCK_CHANCE,tier=v.tier,effect=v.effect}
        else
            r[#r+1]={name=v.name,chance=round(v.base-(v.base/tot)*diff,4),tier=v.tier,effect=v.effect}
        end
    end
    return r
end

local function rollTrait()
    local traits=getTraits()
    local rng=math.random()*100
    local acc=0
    for _,t in ipairs(traits) do
        acc=acc+t.chance
        if rng<acc then return t end
    end
    return traits[#traits]
end

-- Scanner: walk workspace for any model whose name contains a known tag
local function scanForUnit()
    local found=nil
    -- Priority: look inside LocalPlayer's placed units folder if it exists
    local placedFolder = workspace:FindFirstChild("Units") or
                         workspace:FindFirstChild("PlacedUnits") or
                         workspace:FindFirstChild("TowerFolder") or
                         workspace:FindFirstChild("Towers")
    local searchRoot = placedFolder or workspace

    for _,obj in ipairs(searchRoot:GetDescendants()) do
        if obj:IsA("Model") and obj.Name~="Camera" then
            local lower = obj.Name:lower()
            for _,tag in ipairs(UNIT_TAGS) do
                if lower:find(tag,1,true) then
                    found = obj.Name
                    break
                end
            end
            if found then break end
        end
    end
    -- Fallback: check direct children of workspace (AA often puts towers here)
    if not found then
        for _,obj in ipairs(workspace:GetChildren()) do
            if obj:IsA("Model") then
                local lower=obj.Name:lower()
                for _,tag in ipairs(UNIT_TAGS) do
                    if lower:find(tag,1,true) then
                        found=obj.Name
                        break
                    end
                end
            end
            if found then break end
        end
    end
    return found
end

-- ============================================================
--  GUI HELPERS
-- ============================================================

local function corner(inst,r) Instance.new("UICorner",inst).CornerRadius=UDim.new(0,r or 8) end
local function stroke(inst,col,th)
    local s=Instance.new("UIStroke",inst)
    s.Color=col or Color3.fromRGB(168,85,247)
    s.Thickness=th or 2
    return s
end
local function lbl(parent,text,size,pos,color,bold,z)
    local l=Instance.new("TextLabel")
    l.Text=text; l.Size=size; l.Position=pos or UDim2.new(0,0,0,0)
    l.BackgroundTransparency=1
    l.TextColor3=color or Color3.fromRGB(255,255,255)
    l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize=13; l.ZIndex=z or 2
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.Parent=parent; return l
end
local function btn(parent,text,size,pos,bg,tc)
    local b=Instance.new("TextButton")
    b.Text=text; b.Size=size; b.Position=pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3=bg or Color3.fromRGB(100,50,200)
    b.TextColor3=tc or Color3.fromRGB(255,255,255)
    b.Font=Enum.Font.GothamBold; b.TextSize=13
    b.BorderSizePixel=0; b.AutoButtonColor=false; b.ZIndex=3
    b.Parent=parent; corner(b,8)
    b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.1),{BackgroundTransparency=0.25}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.1),{BackgroundTransparency=0}):Play() end)
    b.MouseButton1Down:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.05),{Size=UDim2.new(size.X.Scale,size.X.Offset-4,size.Y.Scale,size.Y.Offset-2)}):Play()
    end)
    b.MouseButton1Up:Connect(function() TweenService:Create(b,TweenInfo.new(0.05),{Size=size}):Play() end)
    return b
end
local function pill(parent,pos)
    local p=Instance.new("TextButton")
    p.Size=UDim2.new(0,44,0,22); p.Position=pos
    p.BackgroundColor3=Color3.fromRGB(34,197,94)
    p.BorderSizePixel=0; p.Text=""; p.AutoButtonColor=false; p.ZIndex=4
    p.Parent=parent; corner(p,20)
    local k=Instance.new("Frame",p)
    k.Size=UDim2.new(0,16,0,16); k.Position=UDim2.new(1,-19,0.5,-8)
    k.BackgroundColor3=Color3.fromRGB(255,255,255); k.BorderSizePixel=0; k.ZIndex=5
    corner(k,20); return p,k
end
local function drag(frame)
    local dg,ds,sp
    frame.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dg=true; ds=i.Position; sp=frame.Position
        end
    end)
    frame.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dg=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dg and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-ds
            frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end

-- ============================================================
--  SCREEN GUI  — never destroyed, only hidden
-- ============================================================

local ScreenGui=Instance.new("ScreenGui")
ScreenGui.Name="AATraitReroll"; ScreenGui.ResetOnSpawn=false
ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
ScreenGui.Parent=PlayerGui

-- ============================================================
--  REOPEN BUTTON  (always visible, bottom-right)
-- ============================================================

local ReopenBtn=btn(ScreenGui,"☘ Trait Reroll",UDim2.new(0,130,0,32),
    UDim2.new(1,-140,1,-42),Color3.fromRGB(109,40,217),Color3.fromRGB(255,255,255))
ReopenBtn.ZIndex=50

-- ============================================================
--  MAIN WINDOW
-- ============================================================

local Root=Instance.new("Frame")
Root.Name="Root"; Root.Size=UDim2.new(0,420,0,590)
Root.Position=UDim2.new(0.5,-210,0.5,-295)
Root.BackgroundColor3=Color3.fromRGB(15,5,30); Root.BorderSizePixel=0
Root.Parent=ScreenGui; corner(Root,14); stroke(Root,Color3.fromRGB(168,85,247),2)
Instance.new("UIGradient",Root).Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(26,10,46)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(26,26,62)),
})
drag(Root)

-- Header
local Hdr=Instance.new("Frame",Root)
Hdr.Size=UDim2.new(1,0,0,44); Hdr.BackgroundColor3=Color3.fromRGB(109,40,217)
Hdr.BorderSizePixel=0; Hdr.ZIndex=2; corner(Hdr,14)
local HFill=Instance.new("Frame",Hdr)
HFill.Size=UDim2.new(1,0,0.5,0); HFill.Position=UDim2.new(0,0,0.5,0)
HFill.BackgroundColor3=Color3.fromRGB(109,40,217); HFill.BorderSizePixel=0; HFill.ZIndex=2
local TitleL=lbl(Hdr,"Trait Reroll",UDim2.new(1,-50,1,0),UDim2.new(0,14,0,0),
    Color3.fromRGB(255,255,255),true,3)
TitleL.TextSize=16; TitleL.TextXAlignment=Enum.TextXAlignment.Left

-- X hides, never destroys
local XBtn=btn(Hdr,"X",UDim2.new(0,28,0,28),UDim2.new(1,-36,0.5,-14),
    Color3.fromRGB(220,38,38),Color3.fromRGB(255,255,255))
XBtn.MouseButton1Click:Connect(function() Root.Visible=false end)
ReopenBtn.MouseButton1Click:Connect(function() Root.Visible=true end)

-- ============================================================
--  UNIQUE LUCK WINDOW  (separate, independent, hide not destroy)
-- ============================================================

local LuckWin=Instance.new("Frame",ScreenGui)
LuckWin.Name="LuckWindow"; LuckWin.Size=UDim2.new(0,230,0,58)
LuckWin.Position=UDim2.new(0.5,-115,0,80)
LuckWin.BackgroundColor3=Color3.fromRGB(13,13,26); LuckWin.BorderSizePixel=0; LuckWin.ZIndex=10
corner(LuckWin,12); local LuckStroke=stroke(LuckWin,Color3.fromRGB(168,85,247),2)
drag(LuckWin)

local LuckXBtn=btn(LuckWin,"X",UDim2.new(0,20,0,20),UDim2.new(1,-24,0,4),
    Color3.fromRGB(220,38,38),Color3.fromRGB(255,255,255))
LuckXBtn.TextSize=10
LuckXBtn.MouseButton1Click:Connect(function() LuckWin.Visible=false end)

local LuckIcon=lbl(LuckWin,"☘",UDim2.new(0,24,0,24),UDim2.new(0,8,0,8),
    Color3.fromRGB(74,222,128),true,11); LuckIcon.TextSize=18; LuckIcon.TextXAlignment=Enum.TextXAlignment.Center
local LuckTitleL=lbl(LuckWin,"Unique Luck Active",UDim2.new(1,-80,0,18),UDim2.new(0,36,0,8),
    Color3.fromRGB(167,139,250),true,11); LuckTitleL.TextSize=13
local LuckSubL=lbl(LuckWin,"Unique: 25.00% chance",UDim2.new(1,-80,0,13),UDim2.new(0,36,0,28),
    Color3.fromRGB(253,224,71),false,11); LuckSubL.TextSize=10

local LuckPill,LuckKnob=pill(LuckWin,UDim2.new(1,-50,0.5,-11))

-- Show luck window button (in main window header area)
local ShowLuckBtn=btn(Root,"☘ Unique Luck",UDim2.new(0,120,0,24),UDim2.new(0.5,-60,0,52),
    Color3.fromRGB(109,40,217),Color3.fromRGB(167,139,250))
ShowLuckBtn.TextSize=11
ShowLuckBtn.MouseButton1Click:Connect(function() LuckWin.Visible=true end)

-- ============================================================
--  UNIT DETECT PANEL
-- ============================================================

local UDF=Instance.new("Frame",Root)
UDF.Size=UDim2.new(1,-20,0,38); UDF.Position=UDim2.new(0,10,0,84)
UDF.BackgroundColor3=Color3.fromRGB(13,13,26); UDF.BorderSizePixel=0; UDF.ZIndex=2
corner(UDF,8); stroke(UDF,Color3.fromRGB(109,40,217),1)

local DetectIcon=lbl(UDF,"?",UDim2.new(0,30,1,0),UDim2.new(0,6,0,0),
    Color3.fromRGB(167,139,250),true,3); DetectIcon.TextSize=20; DetectIcon.TextXAlignment=Enum.TextXAlignment.Center
local DetectName=lbl(UDF,"No unit detected",UDim2.new(1,-110,0,18),UDim2.new(0,40,0,4),
    Color3.fromRGB(196,181,253),true,3); DetectName.TextSize=12
local DetectSub=lbl(UDF,"Place a unit on the map then scan",UDim2.new(1,-110,0,12),UDim2.new(0,40,0,22),
    Color3.fromRGB(109,40,217),false,3); DetectSub.TextSize=9

local ScanBtn=btn(UDF,"Scan",UDim2.new(0,56,0,26),UDim2.new(1,-62,0.5,-13),
    Color3.fromRGB(109,40,217),Color3.fromRGB(255,255,255))
ScanBtn.TextSize=11

-- ============================================================
--  UNIT ROW
-- ============================================================

local UnitRow=Instance.new("Frame",Root)
UnitRow.Size=UDim2.new(1,-20,0,88); UnitRow.Position=UDim2.new(0,10,0,130)
UnitRow.BackgroundTransparency=1; UnitRow.ZIndex=2
local URL=Instance.new("UIListLayout",UnitRow)
URL.FillDirection=Enum.FillDirection.Horizontal
URL.VerticalAlignment=Enum.VerticalAlignment.Center
URL.HorizontalAlignment=Enum.HorizontalAlignment.Center
URL.Padding=UDim.new(0,8)

-- Unit card
local PhCard=Instance.new("Frame",UnitRow)
PhCard.Size=UDim2.new(0,80,0,80); PhCard.BackgroundColor3=Color3.fromRGB(124,45,18)
PhCard.BorderSizePixel=0; PhCard.ZIndex=2; corner(PhCard,10)
stroke(PhCard,Color3.fromRGB(249,115,22),2)
local PhIcon=lbl(PhCard,"?",UDim2.new(1,0,0.6,0),UDim2.new(0,0,0.08,0),
    Color3.fromRGB(255,255,255),true,3); PhIcon.TextSize=28; PhIcon.TextXAlignment=Enum.TextXAlignment.Center
local PhName=lbl(PhCard,"Unit Slot",UDim2.new(1,0,0,14),UDim2.new(0,0,1,-16),
    Color3.fromRGB(255,255,255),true,3); PhName.TextSize=10; PhName.TextXAlignment=Enum.TextXAlignment.Center
local PhLv=lbl(PhCard,"Lv.1",UDim2.new(0,30,0,14),UDim2.new(0,4,0,4),
    Color3.fromRGB(255,255,255),true,3); PhLv.TextSize=9
PhLv.BackgroundColor3=Color3.fromRGB(0,0,0); PhLv.BackgroundTransparency=0.4; corner(PhLv,4)

lbl(UnitRow,"<<<",UDim2.new(0,36,0,40),nil,Color3.fromRGB(239,68,68),true,3).TextSize=20

-- Token slot
local TokSlot=Instance.new("Frame",UnitRow)
TokSlot.Size=UDim2.new(0,80,0,80); TokSlot.BackgroundColor3=Color3.fromRGB(30,27,75)
TokSlot.BorderSizePixel=0; TokSlot.ZIndex=2; corner(TokSlot,10)
stroke(TokSlot,Color3.fromRGB(251,191,36),3)

-- Token image placeholder frame (mimics the diamond icon in-game)
local TokImg=Instance.new("Frame",TokSlot)
TokImg.Size=UDim2.new(0,38,0,38); TokImg.Position=UDim2.new(0.5,-19,0,8)
TokImg.BackgroundColor3=Color3.fromRGB(96,165,250); TokImg.BorderSizePixel=0; TokImg.ZIndex=3
corner(TokImg,6)
local TokImgInner=Instance.new("Frame",TokImg)
TokImgInner.Size=UDim2.new(0,22,0,22); TokImgInner.Position=UDim2.new(0.5,-11,0.5,-11)
TokImgInner.BackgroundColor3=Color3.fromRGB(219,234,254); TokImgInner.BorderSizePixel=0; TokImgInner.ZIndex=4
corner(TokImgInner,4)

-- Token count — this is what updates when user picks a preset
local TokCount=lbl(TokSlot,"10/1",UDim2.new(1,0,0,16),UDim2.new(0,0,0,50),
    Color3.fromRGB(251,191,36),true,4); TokCount.TextSize=13; TokCount.TextXAlignment=Enum.TextXAlignment.Center
local TokLabel=lbl(TokSlot,"Trait Reroll Token",UDim2.new(1,0,0,13),UDim2.new(0,0,0,65),
    Color3.fromRGB(196,181,253),false,3); TokLabel.TextSize=8; TokLabel.TextXAlignment=Enum.TextXAlignment.Center

-- Star slot
local StarSlot=Instance.new("Frame",UnitRow)
StarSlot.Size=UDim2.new(0,72,0,72); StarSlot.BackgroundColor3=Color3.fromRGB(45,27,78)
StarSlot.BorderSizePixel=0; StarSlot.ZIndex=2; corner(StarSlot,10)
stroke(StarSlot,Color3.fromRGB(109,40,217),2)
local StarImg=Instance.new("Frame",StarSlot)
StarImg.Size=UDim2.new(0,32,0,32); StarImg.Position=UDim2.new(0.5,-16,0,6)
StarImg.BackgroundColor3=Color3.fromRGB(167,139,250); StarImg.BorderSizePixel=0; StarImg.ZIndex=3
corner(StarImg,6)
local StarCount=lbl(StarSlot,"0/5",UDim2.new(1,0,0,14),UDim2.new(0,0,0,42),
    Color3.fromRGB(167,139,250),true,3); StarCount.TextSize=11; StarCount.TextXAlignment=Enum.TextXAlignment.Center
lbl(StarSlot,"Star Remnant",UDim2.new(1,0,0,12),UDim2.new(0,0,0,56),
    Color3.fromRGB(167,139,250),false,3).TextSize=8

-- ============================================================
--  TOGGLE ROW
-- ============================================================

local TogRow=Instance.new("Frame",Root)
TogRow.Size=UDim2.new(1,-20,0,40); TogRow.Position=UDim2.new(0,10,0,226)
TogRow.BackgroundColor3=Color3.fromRGB(13,13,26); TogRow.BorderSizePixel=0; TogRow.ZIndex=2
corner(TogRow,10); local TRStroke=stroke(TogRow,Color3.fromRGB(168,85,247),2)

local UDot=Instance.new("Frame",TogRow)
UDot.Size=UDim2.new(0,10,0,10); UDot.Position=UDim2.new(0,10,0.5,-5)
UDot.BackgroundColor3=Color3.fromRGB(34,197,94); UDot.BorderSizePixel=0; UDot.ZIndex=3; corner(UDot,20)

local ULbl=lbl(TogRow,"UNIQUE",UDim2.new(0,80,0,16),UDim2.new(0,26,0,5),
    Color3.fromRGB(167,139,250),true,3); ULbl.TextSize=13
local USubLbl=lbl(TogRow,"Unique Luck Active ☘",UDim2.new(0,180,0,12),UDim2.new(0,26,0,22),
    Color3.fromRGB(109,40,217),true,3); USubLbl.TextSize=10

local MainPill,MainKnob=pill(TogRow,UDim2.new(0,220,0.5,-11))

local UniqueBig=lbl(TogRow,"Unique",UDim2.new(0,80,0,28),UDim2.new(1,-90,0.5,-14),
    Color3.fromRGB(168,85,247),true,3); UniqueBig.TextSize=18; UniqueBig.TextXAlignment=Enum.TextXAlignment.Center

lbl(Root,"Rerolling your unit will replace their current traits.",
    UDim2.new(1,-20,0,14),UDim2.new(0,10,0,272),
    Color3.fromRGB(196,181,253),false,2).TextSize=10

-- ============================================================
--  PRESET GRID
-- ============================================================

lbl(Root,"Token Amount",UDim2.new(1,-20,0,14),UDim2.new(0,10,0,290),
    Color3.fromRGB(196,181,253),true,2).TextSize=11

local PresGrid=Instance.new("Frame",Root)
PresGrid.Size=UDim2.new(1,-20,0,56); PresGrid.Position=UDim2.new(0,10,0,306)
PresGrid.BackgroundTransparency=1; PresGrid.ZIndex=2
local PGL=Instance.new("UIGridLayout",PresGrid)
PGL.CellSize=UDim2.new(0,66,0,24); PGL.CellPadding=UDim2.new(0,4,0,4)
PGL.HorizontalAlignment=Enum.HorizontalAlignment.Center

local presetBtns={}
local function highlightPreset(val)
    for _,info in ipairs(presetBtns) do
        if info.val==val then
            info.b.BackgroundColor3=Color3.fromRGB(120,53,15)
            info.b.TextColor3=Color3.fromRGB(251,191,36)
        else
            info.b.BackgroundColor3=Color3.fromRGB(49,46,129)
            info.b.TextColor3=Color3.fromRGB(255,255,255)
        end
    end
end

for _,v in ipairs(PRESETS) do
    local labelTxt = v>=1000 and (v/1000).."k" or tostring(v)
    local b=btn(PresGrid,labelTxt,UDim2.new(0,66,0,24),nil,
        Color3.fromRGB(49,46,129),Color3.fromRGB(255,255,255))
    b.TextSize=11
    table.insert(presetBtns,{b=b,val=v})
    b.MouseButton1Click:Connect(function()
        activePreset=v; tokenBalance=v
        -- Update the token slot display to show selected/total
        TokCount.Text=tokenBalance.."/1"
        highlightPreset(v)
    end)
end
highlightPreset(10)

-- ============================================================
--  ROLL BUTTONS
-- ============================================================

local BRow=Instance.new("Frame",Root)
BRow.Size=UDim2.new(1,-20,0,36); BRow.Position=UDim2.new(0,10,0,370)
BRow.BackgroundTransparency=1; BRow.ZIndex=2
local BRL=Instance.new("UIListLayout",BRow)
BRL.FillDirection=Enum.FillDirection.Horizontal
BRL.HorizontalAlignment=Enum.HorizontalAlignment.Center
BRL.Padding=UDim.new(0,6)

local RobuxBtn =btn(BRow,"Robux Reroll",UDim2.new(0,110,0,36),nil,Color3.fromRGB(22,163,74),Color3.fromRGB(255,255,255))
local RerollBtn=btn(BRow,"Reroll",       UDim2.new(0,100,0,36),nil,Color3.fromRGB(219,39,119),Color3.fromRGB(255,255,255))
local TokenBtn =btn(BRow,"Reroll Token", UDim2.new(0,110,0,36),nil,Color3.fromRGB(202,138,4), Color3.fromRGB(26,10,0))
local Buy10Btn =btn(Root,"Buy 10",UDim2.new(0,110,0,30),UDim2.new(0.5,-55,0,414),Color3.fromRGB(202,138,4),Color3.fromRGB(26,10,0))

-- ============================================================
--  TRAIT CHANCES BUTTON + PANEL
-- ============================================================

local TCBtn=btn(Root,"Trait Chances",UDim2.new(0,120,0,24),UDim2.new(0.5,-60,0,452),
    Color3.fromRGB(202,138,4),Color3.fromRGB(26,10,0)); TCBtn.TextSize=11

local TraitPanel=Instance.new("Frame",Root)
TraitPanel.Size=UDim2.new(1,-20,0,120); TraitPanel.Position=UDim2.new(0,10,0,482)
TraitPanel.BackgroundColor3=Color3.fromRGB(13,13,26); TraitPanel.BorderSizePixel=0
TraitPanel.Visible=false; TraitPanel.ZIndex=2; corner(TraitPanel,10)
stroke(TraitPanel,Color3.fromRGB(109,40,217),1)
local TScroll=Instance.new("ScrollingFrame",TraitPanel)
TScroll.Size=UDim2.new(1,-4,1,-4); TScroll.Position=UDim2.new(0,2,0,2)
TScroll.BackgroundTransparency=1; TScroll.ScrollBarThickness=3; TScroll.ZIndex=3
TScroll.CanvasSize=UDim2.new(0,0,0,0)
Instance.new("UIListLayout",TScroll).Padding=UDim.new(0,2)

local function buildTraitPanel()
    for _,c in ipairs(TScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    for _,t in ipairs(getTraits()) do
        local row=Instance.new("Frame",TScroll)
        row.Size=UDim2.new(1,-4,0,18); row.BackgroundColor3=Color3.fromRGB(30,27,75)
        row.BorderSizePixel=0; row.ZIndex=4; corner(row,4)
        local nL=lbl(row,t.name,UDim2.new(0,100,1,0),UDim2.new(0,4,0,0),TIER_COLORS[t.tier],true,5); nL.TextSize=10
        local pL=lbl(row,string.format("%.2f%%",t.chance),UDim2.new(0,52,1,0),UDim2.new(0,106,0,0),Color3.fromRGB(251,191,36),true,5); pL.TextSize=10
        local eL=lbl(row,t.effect,UDim2.new(0,180,1,0),UDim2.new(0,160,0,0),Color3.fromRGB(156,163,175),false,5); eL.TextSize=9
    end
    TScroll.CanvasSize=UDim2.new(0,0,0,#BASE_TRAITS*20)
end

-- ============================================================
--  RESULT PANEL
-- ============================================================

local ResultPanel=Instance.new("Frame",Root)
ResultPanel.Size=UDim2.new(1,-20,0,0); ResultPanel.Position=UDim2.new(0,10,0,482)
ResultPanel.BackgroundColor3=Color3.fromRGB(13,13,26); ResultPanel.BorderSizePixel=0
ResultPanel.Visible=false; ResultPanel.ZIndex=2; corner(ResultPanel,10)
stroke(ResultPanel,Color3.fromRGB(168,85,247),2)

-- Unique splash overlay
local USplash=Instance.new("Frame",ResultPanel)
USplash.Size=UDim2.new(1,0,1,0); USplash.BackgroundColor3=Color3.fromRGB(13,13,26)
USplash.BackgroundTransparency=0.05; USplash.BorderSizePixel=0; USplash.ZIndex=20
USplash.Visible=false; corner(USplash,10)
local USplashStroke=stroke(USplash,Color3.fromRGB(253,224,71),3)
local SplashTitle=lbl(USplash,"UNIQUE",UDim2.new(1,0,0,52),UDim2.new(0,0,0.12,0),
    Color3.fromRGB(253,224,71),true,21); SplashTitle.TextSize=44; SplashTitle.TextXAlignment=Enum.TextXAlignment.Center
local SplashBar=Instance.new("Frame",USplash)
SplashBar.Size=UDim2.new(0.6,0,0,4); SplashBar.Position=UDim2.new(0.2,0,0.12,56)
SplashBar.BackgroundColor3=Color3.fromRGB(253,224,71); SplashBar.BorderSizePixel=0; SplashBar.ZIndex=22; corner(SplashBar,20)
local SplashEffect=lbl(USplash,"+300% Damage  •  +10% Range  •  -10% CD  •  Max 1 placed",
    UDim2.new(1,-20,0,28),UDim2.new(0,10,0.12,64),
    Color3.fromRGB(253,224,71),false,21); SplashEffect.TextSize=11
SplashEffect.TextXAlignment=Enum.TextXAlignment.Center; SplashEffect.TextWrapped=true
local SplashSub=lbl(USplash,"",UDim2.new(1,-20,0,16),UDim2.new(0,10,0.5,0),
    Color3.fromRGB(167,139,250),false,21); SplashSub.TextSize=10; SplashSub.TextXAlignment=Enum.TextXAlignment.Center
local SplashClose=btn(USplash,"Continue",UDim2.new(0,100,0,28),UDim2.new(0.5,-50,1,-38),
    Color3.fromRGB(253,224,71),Color3.fromRGB(26,10,0)); SplashClose.TextSize=12
SplashClose.MouseButton1Click:Connect(function() USplash.Visible=false end)

local ResTitle=lbl(ResultPanel,"Roll Results",UDim2.new(1,0,0,18),UDim2.new(0,0,0,4),
    Color3.fromRGB(196,181,253),true,3); ResTitle.TextSize=11; ResTitle.TextXAlignment=Enum.TextXAlignment.Center
local RScroll=Instance.new("ScrollingFrame",ResultPanel)
RScroll.Size=UDim2.new(1,-4,1,-36); RScroll.Position=UDim2.new(0,2,0,22)
RScroll.BackgroundTransparency=1; RScroll.ScrollBarThickness=3; RScroll.ZIndex=3
RScroll.CanvasSize=UDim2.new(0,0,0,0)
Instance.new("UIListLayout",RScroll).Padding=UDim.new(0,3)
local ResStatus=lbl(ResultPanel,"",UDim2.new(1,0,0,14),UDim2.new(0,0,1,-16),
    Color3.fromRGB(196,181,253),true,3); ResStatus.TextSize=10; ResStatus.TextXAlignment=Enum.TextXAlignment.Center

-- ============================================================
--  LUCK TOGGLE SYNC
-- ============================================================

local function updateLuckUI()
    local on=luckOn
    local onC=Color3.fromRGB(34,197,94); local offC=Color3.fromRGB(107,114,128)
    local c=on and onC or offC
    TweenService:Create(MainPill,TweenInfo.new(0.2),{BackgroundColor3=c}):Play()
    TweenService:Create(MainKnob,TweenInfo.new(0.2),{Position=on and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}):Play()
    TweenService:Create(LuckPill,TweenInfo.new(0.2),{BackgroundColor3=c}):Play()
    TweenService:Create(LuckKnob,TweenInfo.new(0.2),{Position=on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)}):Play()
    if on then
        LuckStroke.Color=Color3.fromRGB(168,85,247); TRStroke.Color=Color3.fromRGB(168,85,247)
        LuckTitleL.Text="Unique Luck Active"; LuckSubL.Text="Unique: 25.00% chance"
        LuckSubL.TextColor3=Color3.fromRGB(253,224,71)
        USubLbl.Text="Unique Luck Active ☘"; UniqueBig.TextColor3=Color3.fromRGB(168,85,247)
    else
        LuckStroke.Color=Color3.fromRGB(107,114,128); TRStroke.Color=Color3.fromRGB(107,114,128)
        LuckTitleL.Text="Unique Luck Off"; LuckSubL.Text="Unique: 0.10% chance"
        LuckSubL.TextColor3=Color3.fromRGB(196,181,253)
        USubLbl.Text="Normal Odds"; UniqueBig.TextColor3=Color3.fromRGB(107,114,128)
    end
    if traitPanelOpen then buildTraitPanel() end
end

local function toggleLuck() luckOn=not luckOn; updateLuckUI() end
MainPill.MouseButton1Click:Connect(toggleLuck)
LuckPill.MouseButton1Click:Connect(toggleLuck)

TCBtn.MouseButton1Click:Connect(function()
    traitPanelOpen=not traitPanelOpen
    if traitPanelOpen then
        buildTraitPanel(); ResultPanel.Visible=false; TraitPanel.Visible=true
    else TraitPanel.Visible=false end
end)

-- ============================================================
--  SCAN BUTTON
-- ============================================================

ScanBtn.MouseButton1Click:Connect(function()
    DetectName.Text="Scanning..."; DetectSub.Text=""
    DetectName.TextColor3=Color3.fromRGB(196,181,253)
    task.wait(0.5)
    local found=scanForUnit()
    if found then
        detectedUnit=found
        DetectIcon.Text=found:sub(1,2):upper()
        DetectName.Text=found
        DetectName.TextColor3=Color3.fromRGB(74,222,128)
        DetectSub.Text="Unit detected — ready to reroll"
        DetectSub.TextColor3=Color3.fromRGB(74,222,128)
        PhName.Text=found:len()>8 and found:sub(1,8).."…" or found
        PhIcon.Text=found:sub(1,2):upper()
    else
        detectedUnit=nil
        DetectIcon.Text="?"
        DetectName.Text="No unit found"
        DetectName.TextColor3=Color3.fromRGB(248,113,113)
        DetectSub.Text="Place a unit on map, then scan"
        DetectSub.TextColor3=Color3.fromRGB(248,113,113)
        PhName.Text="Unit Slot"
        PhIcon.Text="?"
    end
end)

-- ============================================================
--  ROLL LOGIC
-- ============================================================

local function showUniqueSplash()
    SplashSub.Text=luckOn and "0.10% base  |  25.00% with Unique Luck" or "0.10% base chance"
    USplash.Visible=true
    for _=1,4 do
        TweenService:Create(USplashStroke,TweenInfo.new(0.22),{Thickness=5}):Play()
        task.wait(0.22)
        TweenService:Create(USplashStroke,TweenInfo.new(0.22),{Thickness=2}):Play()
        task.wait(0.22)
    end
end

local function doRolls(count)
    local actual=math.min(count,tokenBalance)
    if actual<1 then
        ResStatus.Text="No tokens left!"
        ResultPanel.Size=UDim2.new(1,-20,0,52); ResultPanel.Visible=true; return
    end
    tokenBalance=tokenBalance-actual
    TokCount.Text=tokenBalance.."/1"

    for _,c in ipairs(RScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    local results={}
    for i=1,actual do results[i]=rollTrait() end

    ResTitle.Text="Roll Results ("..actual.." roll"..(actual>1 and "s" or "")..")"
    TraitPanel.Visible=false; traitPanelOpen=false

    local uniqueCount=0
    for i,t in ipairs(results) do
        local isU=t.tier=="unique"
        if isU then uniqueCount=uniqueCount+1 end
        local row=Instance.new("Frame",RScroll)
        row.Size=UDim2.new(1,-4,0,20)
        row.BackgroundColor3=isU and Color3.fromRGB(59,21,0) or Color3.fromRGB(30,27,75)
        row.BorderSizePixel=0; row.ZIndex=4; corner(row,4)
        if isU then stroke(row,Color3.fromRGB(251,191,36),1) end
        local nL=lbl(row,"#"..i,UDim2.new(0,26,1,0),UDim2.new(0,4,0,0),Color3.fromRGB(109,40,217),true,5); nL.TextSize=10
        local tL=lbl(row,t.name,UDim2.new(0,110,1,0),UDim2.new(0,32,0,0),TIER_COLORS[t.tier],true,5); tL.TextSize=11
        local pL=lbl(row,string.format("%.2f%%",t.chance),UDim2.new(0,60,1,0),UDim2.new(1,-68,0,0),TIER_COLORS[t.tier],true,5)
        pL.TextSize=10; pL.TextXAlignment=Enum.TextXAlignment.Right
    end

    local rowH=math.min(#results*23,140)
    ResultPanel.Size=UDim2.new(1,-20,0,rowH+56); ResultPanel.Visible=true
    RScroll.CanvasSize=UDim2.new(0,0,0,#results*23)
    RScroll.CanvasPosition=Vector2.new(0,999999)

    if uniqueCount>0 then
        ResStatus.Text="UNIQUE x"..uniqueCount.."!  Tokens left: "..tokenBalance
        ResStatus.TextColor3=Color3.fromRGB(253,224,71)
        task.spawn(showUniqueSplash)
    else
        ResStatus.Text="Tokens left: "..tokenBalance
        ResStatus.TextColor3=Color3.fromRGB(196,181,253)
    end
end

RerollBtn.MouseButton1Click:Connect(function() doRolls(1) end)
TokenBtn.MouseButton1Click:Connect(function()  doRolls(1) end)
Buy10Btn.MouseButton1Click:Connect(function()  doRolls(10) end)
RobuxBtn.MouseButton1Click:Connect(function()
    ResStatus.Text="Robux Reroll is cosmetic only in this simulator."
    ResultPanel.Size=UDim2.new(1,-20,0,52); ResultPanel.Visible=true
end)

-- ============================================================
--  INIT
-- ============================================================

updateLuckUI(); buildTraitPanel()
print("[AATraitReroll] Loaded. X hides the window — reopen with the bottom-right button.")
