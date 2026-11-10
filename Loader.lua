-- ============================================================
--  Anime Adventures — Trait Reroll
--  made by NotGreyAnymore
--  Pixel-matched to real AA Trait Reroll UI.
-- ============================================================

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local LocalPlayer      = Players.LocalPlayer
local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
--  REPLACE WITH YOUR ROBLOX ASSET ID AFTER UPLOADING
-- ============================================================
local TOKEN_ASSET_ID = "rbxassetid://REPLACE_TOKEN_IMAGE"
local UNIT_IMAGES = {
    ["Chuuni"]="rbxassetid://REPLACE",["Phoenix"]="rbxassetid://REPLACE",
    ["Goku"]="rbxassetid://REPLACE",  ["Naruto"]="rbxassetid://REPLACE",
    ["Luffy"]="rbxassetid://REPLACE", ["Tanjiro"]="rbxassetid://REPLACE",
    ["Gojo"]="rbxassetid://REPLACE",  ["Sukuna"]="rbxassetid://REPLACE",
    ["Levi"]="rbxassetid://REPLACE",  ["Deku"]="rbxassetid://REPLACE",
    ["Saitama"]="rbxassetid://REPLACE",["Rimuru"]="rbxassetid://REPLACE",
    ["Ainz"]="rbxassetid://REPLACE",  ["Itachi"]="rbxassetid://REPLACE",
    ["Madara"]="rbxassetid://REPLACE",["Vegeta"]="rbxassetid://REPLACE",
}

-- ============================================================
--  TRAIT DATA
-- ============================================================
local BASE_TRAITS = {
    {name="Superior I",   base=14.98,tier="common",   effect="+10% Damage"},
    {name="Range I",      base=12.48,tier="common",   effect="+10% Range"},
    {name="Nimble I",     base=12.48,tier="common",   effect="-5% Cooldown"},
    {name="Superior II",  base=10.48,tier="uncommon", effect="+12.5% Damage"},
    {name="Adept",        base= 9.99,tier="uncommon", effect="+50% XP"},
    {name="Nimble II",    base= 8.74,tier="uncommon", effect="-7.5% Cooldown"},
    {name="Range II",     base= 8.74,tier="uncommon", effect="+12.5% Range"},
    {name="Culling",      base= 5.00,tier="uncommon", effect="+20% Dmg <30% HP"},
    {name="Superior III", base= 4.50,tier="rare",     effect="+15% Damage"},
    {name="Range III",    base= 3.75,tier="rare",     effect="+15% Range"},
    {name="Nimble III",   base= 3.75,tier="rare",     effect="-12% Cooldown"},
    {name="Sniper",       base= 2.50,tier="rare",     effect="+25% Range"},
    {name="Godspeed",     base= 1.00,tier="epic",     effect="-20% Cooldown"},
    {name="Reaper",       base= 0.80,tier="epic",     effect="+15% Dmg +25% Boss"},
    {name="Celestial",    base= 0.36,tier="epic",     effect="+10% Dmg +10% Range +True Dmg"},
    {name="Divine",       base= 0.20,tier="legendary",effect="+20% Dmg +20% Range -10% CD"},
    {name="Golden",       base= 0.15,tier="legendary",effect="+30% Dmg +10% Kill Money"},
    {name="Unique",       base= 0.10,tier="unique",   effect="+300% Dmg +10% Range -10% CD"},
}
local TIER_COL={
    common=Color3.fromRGB(180,200,255),uncommon=Color3.fromRGB(80,220,120),
    rare=Color3.fromRGB(80,150,255),   epic=Color3.fromRGB(180,80,255),
    legendary=Color3.fromRGB(255,165,0),unique=Color3.fromRGB(255,215,0),
}
local TIER_BG={
    common=Color3.fromRGB(35,45,75),  uncommon=Color3.fromRGB(18,55,30),
    rare=Color3.fromRGB(18,38,78),    epic=Color3.fromRGB(48,18,78),
    legendary=Color3.fromRGB(75,42,0),unique=Color3.fromRGB(75,55,0),
}
local TIER_LBL={common="Common",uncommon="Uncommon",rare="Rare",epic="Epic",legendary="Legendary",unique="UNIQUE"}

local UNIQUE_LUCK=25
local PRESETS={10,20,30,40,50,100,250,500,1000,2500}
local UNIT_TAGS={"chuuni","phoenix","goku","naruto","luffy","ichigo","saitama","rimuru",
    "ainz","giorno","jotaro","vegeta","tanjiro","zenitsu","inosuke","killua","gon",
    "itachi","madara","sasuke","kakashi","sukuna","gojo","yuji","erza","natsu","asta",
    "yuno","deku","bakugo","todoroki","levi","eren","benimaru","albedo","unit","tower"}

-- ============================================================
--  STATE
-- ============================================================
local luckOn=true; local visTok=10; local maxTok=10
local rolling=false; local tcOpen=false; local detUnit=nil

-- ============================================================
--  MATH
-- ============================================================
local function getTraits()
    if not luckOn then
        local t={} for _,v in ipairs(BASE_TRAITS) do t[#t+1]={name=v.name,chance=v.base,tier=v.tier,effect=v.effect} end return t
    end
    local diff=UNIQUE_LUCK-0.10; local tot=0
    for _,v in ipairs(BASE_TRAITS) do if v.tier~="unique" then tot=tot+v.base end end
    local r={}
    for _,v in ipairs(BASE_TRAITS) do
        if v.tier=="unique" then r[#r+1]={name=v.name,chance=UNIQUE_LUCK,tier=v.tier,effect=v.effect}
        else r[#r+1]={name=v.name,chance=math.floor((v.base-(v.base/tot)*diff)*10000+0.5)/10000,tier=v.tier,effect=v.effect} end
    end
    return r
end
local function rollOne()
    local t=getTraits(); local r=math.random()*100; local a=0
    for _,v in ipairs(t) do a=a+v.chance; if r<a then return v end end
    return t[#t]
end
local function scanWS()
    for _,root in ipairs({workspace:FindFirstChild("Units"),workspace:FindFirstChild("TowerFolder"),workspace:FindFirstChild("Towers"),workspace}) do
        if root then
            for _,obj in ipairs(root:GetChildren()) do
                if obj:IsA("Model") and obj.Name~="Camera" and obj.Name~="Terrain" then
                    local lo=obj.Name:lower()
                    for _,tag in ipairs(UNIT_TAGS) do if lo:find(tag,1,true) then return obj.Name end end
                end
            end
        end
    end
    return nil
end

-- ============================================================
--  GUI UTILS
-- ============================================================
local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
local function corner(i,r) Instance.new("UICorner",i).CornerRadius=UDim.new(0,r or 8) end
local function stroke(i,c,t) local s=Instance.new("UIStroke",i);s.Color=c;s.Thickness=t or 2;return s end
local function gradient(i,c0,c1,rot)
    local g=Instance.new("UIGradient",i)
    g.Color=ColorSequence.new(c0,c1); g.Rotation=rot or 90
end

local function frame(p,sz,pos,bg,zi,clip)
    local f=Instance.new("Frame",p)
    f.Size=sz; f.Position=pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3=bg or rgb(20,15,40)
    f.BorderSizePixel=0; f.ZIndex=zi or 2
    if clip then f.ClipsDescendants=true end
    return f
end

local function label(p,txt,sz,pos,col,bold,zi,fs,xa)
    local l=Instance.new("TextLabel",p)
    l.Text=txt; l.Size=sz; l.Position=pos or UDim2.new(0,0,0,0)
    l.BackgroundTransparency=1; l.TextColor3=col or rgb(255,255,255)
    l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextSize=fs or 13; l.ZIndex=zi or 3
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.TextTruncate=Enum.TextTruncate.AtEnd
    return l
end

local function btn(p,txt,sz,pos,bg,tc,zi,fs,rad)
    local b=Instance.new("TextButton",p)
    b.Text=txt; b.Size=sz; b.Position=pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3=bg or rgb(100,50,200)
    b.TextColor3=tc or rgb(255,255,255)
    b.Font=Enum.Font.GothamBold; b.TextSize=fs or 14
    b.BorderSizePixel=0; b.AutoButtonColor=false; b.ZIndex=zi or 4
    corner(b,rad or 22)
    b.MouseEnter:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.1),{BackgroundTransparency=0.15}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.1),{BackgroundTransparency=0}):Play()
    end)
    b.MouseButton1Down:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.07),
            {Size=UDim2.new(sz.X.Scale,sz.X.Offset-6,sz.Y.Scale,sz.Y.Offset-4)}):Play()
    end)
    b.MouseButton1Up:Connect(function()
        TweenService:Create(b,TweenInfo.new(0.1),{Size=sz}):Play()
    end)
    return b
end

local function imgLabel(p,id,sz,pos,zi)
    local i=Instance.new("ImageLabel",p)
    i.Image=id; i.Size=sz; i.Position=pos or UDim2.new(0,0,0,0)
    i.BackgroundTransparency=1; i.ScaleType=Enum.ScaleType.Fit; i.ZIndex=zi or 4
    return i
end

local function drag(f)
    local dg,ds,sp
    f.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dg=true;ds=i.Position;sp=f.Position end
    end)
    f.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dg=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dg and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-ds
            f.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end

local function mkPill(p,pos,zi)
    local pill=Instance.new("TextButton",p)
    pill.Size=UDim2.new(0,56,0,28); pill.Position=pos
    pill.BackgroundColor3=rgb(34,197,94); pill.BorderSizePixel=0
    pill.Text=""; pill.AutoButtonColor=false; pill.ZIndex=zi or 5; corner(pill,20)
    local knob=Instance.new("Frame",pill)
    knob.Size=UDim2.new(0,22,0,22); knob.Position=UDim2.new(1,-25,0.5,-11)
    knob.BackgroundColor3=rgb(255,255,255); knob.BorderSizePixel=0; knob.ZIndex=(zi or 5)+1; corner(knob,20)
    local onlbl=label(pill,"ON",UDim2.new(1,0,1,0),nil,rgb(255,255,255),true,(zi or 5)+1,9,Enum.TextXAlignment.Center)
    return pill,knob,onlbl
end

-- ============================================================
--  SCREEN GUI
-- ============================================================
local SGui=Instance.new("ScreenGui",PlayerGui)
SGui.Name="AATraitReroll"; SGui.ResetOnSpawn=false; SGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling

-- Always-visible reopen button (bottom right corner)
local reopenBtn=btn(SGui,"☘  Trait Reroll",UDim2.new(0,150,0,38),UDim2.new(1,-158,1,-48),
    rgb(76,29,149),rgb(216,180,254),60,13,22)
stroke(reopenBtn,rgb(139,92,246),2)

-- ============================================================
--  MAIN WINDOW  — matches exact AA dark navy panel
-- ============================================================
local W=frame(SGui,UDim2.new(0,420,0,680),UDim2.new(0.5,-210,0.5,-340),rgb(18,12,45),2)
corner(W,18); drag(W)

-- outer glow
local glow=frame(W,UDim2.new(1,16,1,16),UDim2.new(0,-8,0,-8),rgb(80,30,180),1)
corner(glow,24); glow.BackgroundTransparency=0.88

-- inner dark fill on top of glow
local innerFill=frame(W,UDim2.new(1,0,1,0),nil,rgb(18,12,45),2); corner(innerFill,18)
gradient(innerFill,rgb(28,16,58),rgb(14,9,35),180)

-- ---- TITLE BAR ----
local tBar=frame(W,UDim2.new(1,0,0,52),nil,rgb(55,20,110),4); corner(tBar,18)
-- fill lower corners
frame(tBar,UDim2.new(1,0,0.5,0),UDim2.new(0,0,0.5,0),rgb(55,20,110),4)
gradient(tBar,rgb(75,30,145),rgb(45,15,100),180)
-- shimmer line
local shimLine=frame(W,UDim2.new(1,0,0,2),UDim2.new(0,0,0,51),rgb(160,100,255),5)
shimLine.BackgroundTransparency=0.6

label(tBar,"Trait Reroll",UDim2.new(1,-60,1,0),UDim2.new(0,16,0,0),rgb(255,255,255),true,5,19)

-- Close (hides only)
local xBtn=btn(tBar,"✕",UDim2.new(0,32,0,32),UDim2.new(1,-40,0.5,-16),rgb(185,28,28),rgb(255,255,255),5,16,10)
xBtn.MouseButton1Click:Connect(function() W.Visible=false end)
reopenBtn.MouseButton1Click:Connect(function() W.Visible=true end)

-- ============================================================
--  UNIQUE LUCK BUTTON  (matches the pill button in photo)
-- ============================================================
local luckPillBtn=btn(W,"☘  Unique Luck",UDim2.new(0,160,0,34),UDim2.new(0.5,-80,0,60),
    rgb(80,20,170),rgb(216,180,254),5,13,22)
stroke(luckPillBtn,rgb(139,92,246),2)

-- ============================================================
--  UNIQUE LUCK POPUP CARD  (overlay inside main window, like in photo)
-- ============================================================
local luckCard=frame(W,UDim2.new(1,-24,0,72),UDim2.new(0,12,0,100),rgb(12,8,32),5)
corner(luckCard,14); local luckCardStroke=stroke(luckCard,rgb(139,92,246),2)
gradient(luckCard,rgb(22,10,55),rgb(12,6,30),180)
luckCard.Visible=false

-- clover
local lcClover=label(luckCard,"☘",UDim2.new(0,30,0,30),UDim2.new(0,10,0.5,-15),
    rgb(74,222,128),true,6,22,Enum.TextXAlignment.Center)

-- title
local lcTitle=label(luckCard,"Unique Luck Active",UDim2.new(1,-130,0,24),UDim2.new(0,46,0,10),
    rgb(255,255,255),true,6,16)
-- sub
local lcSub=label(luckCard,"Unique chance: 25.00%",UDim2.new(1,-130,0,20),UDim2.new(0,46,0,36),
    rgb(253,224,71),false,6,12)

-- pill toggle inside card
local lcPill,lcKnob,lcOnLbl=mkPill(luckCard,UDim2.new(1,-68,0.5,-14),6)

-- close X on card
local lcX=btn(luckCard,"✕",UDim2.new(0,22,0,22),UDim2.new(1,-26,0,4),
    rgb(185,28,28),rgb(255,255,255),7,10,8)
lcX.MouseButton1Click:Connect(function() luckCard.Visible=false end)
luckPillBtn.MouseButton1Click:Connect(function() luckCard.Visible=not luckCard.Visible end)

-- ============================================================
--  UNIT DETECT STRIP
-- ============================================================
local udsY=100  -- shifts down when luck card visible
local uds=frame(W,UDim2.new(1,-24,0,46),UDim2.new(0,12,0,104),rgb(10,6,28),4)
corner(uds,12); stroke(uds,rgb(60,30,120),1)
gradient(uds,rgb(16,10,38),rgb(10,6,22),180)

local udiBox=frame(uds,UDim2.new(0,36,0,36),UDim2.new(0,5,0.5,-18),rgb(45,18,95),5); corner(udiBox,10)
local udiLbl=label(udiBox,"?",UDim2.new(1,0,1,0),nil,rgb(180,140,255),true,6,18,Enum.TextXAlignment.Center)
local udiPort=imgLabel(udiBox,"",UDim2.new(1,0,1,0),nil,6); udiPort.Visible=false; corner(udiPort,8)

local udName=label(uds,"No unit detected",UDim2.new(1,-115,0,22),UDim2.new(0,47,0,6),rgb(200,170,255),true,5,13)
local udSub=label(uds,"Place a unit on the map",UDim2.new(1,-115,0,16),UDim2.new(0,47,0,27),rgb(90,65,150),false,5,10)

local scanBtn=btn(uds,"Scan",UDim2.new(0,66,0,30),UDim2.new(1,-74,0.5,-15),
    rgb(76,29,149),rgb(216,180,254),5,13,20)
stroke(scanBtn,rgb(139,92,246),1)

-- ============================================================
--  CURRENT TRAIT BAR
-- ============================================================
local ctBar=frame(W,UDim2.new(1,-24,0,42),UDim2.new(0,12,0,158),rgb(10,6,28),4)
corner(ctBar,12); stroke(ctBar,rgb(50,28,100),1)
local ctPip=frame(ctBar,UDim2.new(0,5,0.65,0),UDim2.new(0,4,0.175,0),rgb(100,100,210),5); corner(ctPip,3)
local ctName=label(ctBar,"No trait",UDim2.new(1,-170,0,22),UDim2.new(0,14,0,5),rgb(160,140,220),true,5,14)
local ctEff=label(ctBar,"Equip a trait via reroll",UDim2.new(1,-170,0,15),UDim2.new(0,14,0,24),rgb(85,65,135),false,5,10)
local ctPct=label(ctBar,"",UDim2.new(0,80,0,42),UDim2.new(1,-84,0,0),rgb(253,224,71),true,5,12,Enum.TextXAlignment.Right)

-- ============================================================
--  TRAIT CHANCES BUTTON  — orange pill, matches photo exactly
-- ============================================================
local tcBtn=btn(W,"  Trait Chances  ",UDim2.new(0,180,0,36),UDim2.new(0.5,-90,0,208),
    rgb(180,80,0),rgb(255,220,100),5,14,22)
gradient(tcBtn,rgb(210,100,0),rgb(150,60,0),180)
stroke(tcBtn,rgb(255,140,30),1)

-- ============================================================
--  UNIT ROW  — unit card / arrows / token / star
-- ============================================================
local uRow=frame(W,UDim2.new(1,-24,0,110),UDim2.new(0,12,0,252),rgb(0,0,0,0),4)
uRow.BackgroundTransparency=1

-- unit card  — dark red with orange border like AA
local ucF=frame(uRow,UDim2.new(0,96,0,106),UDim2.new(0,0,0,0),rgb(120,40,12),4)
corner(ucF,14); stroke(ucF,rgb(255,140,30),2)
gradient(ucF,rgb(160,55,16),rgb(90,28,8),180)

local ucPort=imgLabel(ucF,"",UDim2.new(1,0,0.78,0),UDim2.new(0,0,0.11,0),5); ucPort.Visible=false; corner(ucPort,10)
local ucIcon=label(ucF,"?",UDim2.new(1,0,0,52),UDim2.new(0,0,0.14,0),rgb(255,255,255),true,5,34,Enum.TextXAlignment.Center)

local ucLvBg=frame(ucF,UDim2.new(0,42,0,20),UDim2.new(0,4,0,4),rgb(0,0,0),5); corner(ucLvBg,8); ucLvBg.BackgroundTransparency=0.35
label(ucLvBg,"Lv. 1",UDim2.new(1,0,1,0),nil,rgb(255,255,255),true,6,10,Enum.TextXAlignment.Center)

local ucCostBg=frame(ucF,UDim2.new(1,-8,0,18),UDim2.new(0,4,1,-22),rgb(0,0,0),5); corner(ucCostBg,8); ucCostBg.BackgroundTransparency=0.4
local ucCost=label(ucCostBg,"1300 ¥",UDim2.new(1,0,1,0),nil,rgb(255,210,80),true,6,10,Enum.TextXAlignment.Center)
local ucName=label(ucF,"Unit",UDim2.new(1,-4,0,16),UDim2.new(0,2,1,-18),rgb(255,255,255),true,5,10,Enum.TextXAlignment.Center)

-- animated << arrows (green, matches photo)
local arrF=frame(uRow,UDim2.new(0,38,0,110),UDim2.new(0,100,0,0),rgb(0,0,0,0),4); arrF.BackgroundTransparency=1
local arrLbl=label(arrF,"<<",UDim2.new(1,0,0,32),UDim2.new(0,0,0.5,-16),rgb(50,220,80),true,5,26,Enum.TextXAlignment.Center)
local aDir=1; local aAlpha=1
RunService.Heartbeat:Connect(function(dt)
    aAlpha=aAlpha+dt*aDir*2.2
    if aAlpha>=1 then aAlpha=1;aDir=-1 elseif aAlpha<=0.3 then aAlpha=0.3;aDir=1 end
    arrLbl.TextTransparency=1-aAlpha
end)

-- token slot  — dark blue with thick gold border like photo
local tokF=frame(uRow,UDim2.new(0,96,0,106),UDim2.new(0,142,0,0),rgb(16,24,80),4)
corner(tokF,14); local tokStroke=stroke(tokF,rgb(255,200,30),3)
gradient(tokF,rgb(22,32,100),rgb(12,18,65),180)

-- rainbow crystal image
local tokImg=imgLabel(tokF,TOKEN_ASSET_ID,UDim2.new(0,60,0,60),UDim2.new(0.5,-30,0,4),5)
-- glow behind crystal
local tokGlow=frame(tokF,UDim2.new(0,64,0,64),UDim2.new(0.5,-32,0,2),rgb(100,220,255),4); corner(tokGlow,32)
tokGlow.BackgroundTransparency=0.78

local tokCount=label(tokF,"10/1",UDim2.new(1,0,0,18),UDim2.new(0,0,0,66),rgb(255,210,50),true,5,14,Enum.TextXAlignment.Center)
label(tokF,"Trait Reroll Token",UDim2.new(1,-4,0,13),UDim2.new(0,2,0,84),rgb(180,150,255),false,5,8,Enum.TextXAlignment.Center)

-- star remnant slot  — matches photo's dark blue slot
local starF=frame(uRow,UDim2.new(0,86,0,96),UDim2.new(0,244,0,6),rgb(16,16,72),4)
corner(starF,14); stroke(starF,rgb(100,60,220),2)
gradient(starF,rgb(22,20,100),rgb(12,10,55),180)

local sBg=frame(starF,UDim2.new(0,46,0,46),UDim2.new(0.5,-23,0,6),rgb(70,25,150),5); corner(sBg,10)
gradient(sBg,rgb(110,50,210),rgb(60,18,120),135)
local sInner=frame(sBg,UDim2.new(0,24,0,24),UDim2.new(0.5,-12,0.5,-12),rgb(150,90,255),6); corner(sInner,20); sInner.BackgroundTransparency=0.35
label(starF,"0/5",UDim2.new(1,0,0,16),UDim2.new(0,0,0,55),rgb(180,130,255),true,5,13,Enum.TextXAlignment.Center)
label(starF,"Star Remnant",UDim2.new(1,-4,0,13),UDim2.new(0,2,0,72),rgb(130,80,220),false,5,8,Enum.TextXAlignment.Center)

-- Pick Item button  — green pill under token slot, like photo
local pickBtn=btn(W,"Pick Item",UDim2.new(0,120,0,34),UDim2.new(0.5,-60,0,370),
    rgb(22,120,55),rgb(120,255,150),5,14,22)
gradient(pickBtn,rgb(30,160,70),rgb(14,100,38),180)
stroke(pickBtn,rgb(50,210,90),1)

-- ============================================================
--  UNIQUE TOGGLE ROW  — matches photo's dark card with green dot
-- ============================================================
local togF=frame(W,UDim2.new(1,-24,0,52),UDim2.new(0,12,0,412),rgb(10,6,28),4)
corner(togF,14); local togStroke=stroke(togF,rgb(120,50,240),2)
gradient(togF,rgb(18,10,46),rgb(10,6,26),180)

local togDot=frame(togF,UDim2.new(0,14,0,14),UDim2.new(0,12,0.5,-7),rgb(50,230,100),5); corner(togDot,20)
task.spawn(function()
    while true do
        TweenService:Create(togDot,TweenInfo.new(0.9,Enum.EasingStyle.Sine),{BackgroundTransparency=0.5}):Play()
        task.wait(0.9)
        TweenService:Create(togDot,TweenInfo.new(0.9,Enum.EasingStyle.Sine),{BackgroundTransparency=0}):Play()
        task.wait(0.9)
    end
end)

label(togF,"UNIQUE",UDim2.new(0,72,0,20),UDim2.new(0,30,0,6),rgb(200,150,255),true,5,14)
local togSub=label(togF,"Unique Luck Active  ☘",UDim2.new(0,180,0,16),UDim2.new(0,30,0,28),rgb(90,55,170),true,5,10)
local mainPill,mainKnob,mainOnLbl=mkPill(togF,UDim2.new(0,228,0.5,-14),5)
local uniqueBigLbl=label(togF,"Unique",UDim2.new(0,86,0,36),UDim2.new(1,-94,0.5,-18),rgb(170,70,255),true,5,22,Enum.TextXAlignment.Center)

label(W,"Rerolling your unit will replace their current traits.",
    UDim2.new(1,-24,0,16),UDim2.new(0,12,0,470),rgb(110,85,170),false,4,10,Enum.TextXAlignment.Center)

-- ============================================================
--  TOKEN AMOUNT GRID  — matches photo exactly: orange 10, purple rest
-- ============================================================
label(W,"Token Amount",UDim2.new(1,-24,0,18),UDim2.new(0,12,0,490),
    rgb(220,200,255),true,4,13,Enum.TextXAlignment.Center)

local pgF=frame(W,UDim2.new(1,-24,0,66),UDim2.new(0,12,0,510),rgb(0,0,0,0),4)
pgF.BackgroundTransparency=1
local pgl=Instance.new("UIGridLayout",pgF)
pgl.CellSize=UDim2.new(0,72,0,28); pgl.CellPadding=UDim2.new(0,5,0,5)
pgl.HorizontalAlignment=Enum.HorizontalAlignment.Center

local presetBtns={}; local activePreset=10
local function highlightPreset(val)
    for _,info in ipairs(presetBtns) do
        local active=info.val==val
        -- selected = orange like photo, unselected = muted purple
        TweenService:Create(info.b,TweenInfo.new(0.12),{
            BackgroundColor3=active and rgb(180,80,0) or rgb(42,25,90),
            TextColor3=active and rgb(255,220,80) or rgb(180,155,230)
        }):Play()
    end
end

for _,v in ipairs(PRESETS) do
    local ltext=v>=1000 and (v/1000).."k" or tostring(v)
    local b=btn(pgF,ltext,UDim2.new(0,72,0,28),nil,rgb(42,25,90),rgb(180,155,230),4,12,20)
    stroke(b,rgb(80,50,160),1)
    table.insert(presetBtns,{b=b,val=v})
    b.MouseButton1Click:Connect(function()
        activePreset=v; visTok=v; maxTok=v
        tokCount.Text=visTok.."/1"; highlightPreset(v)
    end)
end
highlightPreset(10)

-- ============================================================
--  ROLL BUTTONS  — pill shaped, exact colors from photo
-- ============================================================
local rRow=frame(W,UDim2.new(1,-24,0,46),UDim2.new(0,12,0,584),rgb(0,0,0,0),4)
rRow.BackgroundTransparency=1
local rRL=Instance.new("UIListLayout",rRow)
rRL.FillDirection=Enum.FillDirection.Horizontal
rRL.HorizontalAlignment=Enum.HorizontalAlignment.Center
rRL.Padding=UDim.new(0,8)

-- Green Robux Reroll
local robuxBtn=btn(rRow,"Robux Reroll",UDim2.new(0,120,0,46),nil,rgb(22,120,55),rgb(150,255,150),4,13,24)
gradient(robuxBtn,rgb(30,160,70),rgb(14,95,38),180); stroke(robuxBtn,rgb(50,210,90),1)

-- Red Reroll (brightest button in photo)
local rerollBtn=btn(rRow,"Reroll",UDim2.new(0,110,0,46),nil,rgb(185,20,80),rgb(255,180,210),4,16,24)
gradient(rerollBtn,rgb(220,25,95),rgb(150,12,65),180); stroke(rerollBtn,rgb(255,80,150),1)

-- Blue Reroll Token
local tokenBtn=btn(rRow,"Reroll Token",UDim2.new(0,120,0,46),nil,rgb(30,80,200),rgb(180,220,255),4,13,24)
gradient(tokenBtn,rgb(40,100,230),rgb(20,65,170),180); stroke(tokenBtn,rgb(80,160,255),1)

-- Orange Buy 10 (centered below, matches photo)
local buy10Btn=btn(W,"Buy 10",UDim2.new(0,160,0,40),UDim2.new(0.5,-80,0,638),
    rgb(180,65,0),rgb(255,220,100),4,15,24)
gradient(buy10Btn,rgb(210,80,0),rgb(150,48,0),180); stroke(buy10Btn,rgb(255,130,30),1)

-- ============================================================
--  TRAIT CHANCES PANEL  (dropdown below Trait Chances btn)
-- ============================================================
local tcPanel=frame(W,UDim2.new(1,-24,0,0),UDim2.new(0,12,0,252),rgb(10,6,28),4,true)
corner(tcPanel,14); stroke(tcPanel,rgb(70,35,150),1); tcPanel.Visible=false

local tcScroll=Instance.new("ScrollingFrame",tcPanel)
tcScroll.Size=UDim2.new(1,-2,1,-2); tcScroll.Position=UDim2.new(0,1,0,1)
tcScroll.BackgroundTransparency=1; tcScroll.ScrollBarThickness=4; tcScroll.ZIndex=5
tcScroll.CanvasSize=UDim2.new(0,0,0,0); tcScroll.ScrollBarImageColor3=rgb(100,60,200)
Instance.new("UIListLayout",tcScroll).Padding=UDim.new(0,2)

local function buildTC()
    for _,c in ipairs(tcScroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    -- header
    local hdr=frame(tcScroll,UDim2.new(1,-4,0,22),nil,rgb(28,14,60),6); corner(hdr,6)
    label(hdr,"Trait",UDim2.new(0,110,1,0),UDim2.new(0,8,0,0),rgb(140,100,220),true,7,10)
    label(hdr,"Chance",UDim2.new(0,60,1,0),UDim2.new(0,120,0,0),rgb(140,100,220),true,7,10)
    label(hdr,"Effect",UDim2.new(1,-185,1,0),UDim2.new(0,182,0,0),rgb(140,100,220),true,7,10)
    for _,t in ipairs(getTraits()) do
        local row=frame(tcScroll,UDim2.new(1,-4,0,22),nil,TIER_BG[t.tier],6); corner(row,6)
        stroke(row,TIER_COL[t.tier],1)
        frame(row,UDim2.new(0,4,0.65,0),UDim2.new(0,0,0.175,0),TIER_COL[t.tier],7)
        label(row,t.name,UDim2.new(0,106,1,0),UDim2.new(0,8,0,0),TIER_COL[t.tier],true,7,10)
        label(row,string.format("%.2f%%",t.chance),UDim2.new(0,58,1,0),UDim2.new(0,116,0,0),rgb(255,210,50),true,7,10)
        label(row,t.effect,UDim2.new(1,-180,1,0),UDim2.new(0,176,0,0),rgb(175,155,210),false,7,9)
    end
    tcScroll.CanvasSize=UDim2.new(0,0,0,(#BASE_TRAITS+1)*24+4)
end

tcBtn.MouseButton1Click:Connect(function()
    tcOpen=not tcOpen
    if tcOpen then
        buildTC(); tcPanel.Size=UDim2.new(1,-24,0,180); tcPanel.Visible=true
        W.Size=UDim2.new(0,420,0,680+184)
    else
        tcPanel.Visible=false; W.Size=UDim2.new(0,420,0,680)
    end
end)

-- ============================================================
--  RESULT PANEL
-- ============================================================
local resPanel=frame(W,UDim2.new(1,-24,0,0),UDim2.new(0,12,0,680),rgb(10,6,28),4)
corner(resPanel,14); stroke(resPanel,rgb(120,55,240),2); resPanel.Visible=false

-- UNIQUE splash
local usp=frame(resPanel,UDim2.new(1,0,1,0),nil,rgb(5,2,14),20); usp.Visible=false
corner(usp,14); usp.BackgroundTransparency=0.02
gradient(usp,rgb(20,8,4),rgb(5,2,0),180)
local uspStroke=stroke(usp,rgb(255,215,0),3)
frame(usp,UDim2.new(1,0,0,3),nil,rgb(255,215,0),21) -- gold top bar
-- shadow title
label(usp,"UNIQUE",UDim2.new(1,2,0,56),UDim2.new(0,2,0.08,2),rgb(170,90,0),true,20,52,Enum.TextXAlignment.Center)
label(usp,"UNIQUE",UDim2.new(1,0,0,56),UDim2.new(0,0,0.08,0),rgb(255,215,0),true,21,52,Enum.TextXAlignment.Center)
local uspBar=frame(usp,UDim2.new(0.6,0,0,3),UDim2.new(0.2,0,0.08,60),rgb(255,215,0),21); corner(uspBar,20)
label(usp,"Unique Trait",UDim2.new(1,0,0,22),UDim2.new(0,0,0.08,68),rgb(255,175,45),false,21,17,Enum.TextXAlignment.Center)
local uspEff=label(usp,"+300% Damage  •  +10% Range  •  -10% Cooldown",UDim2.new(1,-20,0,22),UDim2.new(0,10,0.08,96),rgb(255,215,0),false,21,11,Enum.TextXAlignment.Center)
uspEff.TextWrapped=true
local uspNote=label(usp,"",UDim2.new(1,-20,0,16),UDim2.new(0,10,0.5,-4),rgb(180,130,255),false,21,10,Enum.TextXAlignment.Center)
label(usp,"Max 1 placed  —  Rarest trait in the game",UDim2.new(1,-20,0,14),UDim2.new(0,10,1,-44),rgb(90,55,170),false,21,9,Enum.TextXAlignment.Center)
local uspCont=btn(usp,"Continue  ▶",UDim2.new(0,130,0,34),UDim2.new(0.5,-65,1,-44),
    rgb(170,120,0),rgb(255,215,0),21,13,22)
gradient(uspCont,rgb(210,150,0),rgb(135,85,0),180); stroke(uspCont,rgb(255,215,0),1)
uspCont.MouseButton1Click:Connect(function() usp.Visible=false end)

local resTitle=label(resPanel,"Roll Results",UDim2.new(1,0,0,22),UDim2.new(0,0,0,4),rgb(180,150,255),true,5,13,Enum.TextXAlignment.Center)
local rSc=Instance.new("ScrollingFrame",resPanel)
rSc.Size=UDim2.new(1,-4,1,-38); rSc.Position=UDim2.new(0,2,0,24)
rSc.BackgroundTransparency=1; rSc.ScrollBarThickness=4; rSc.ZIndex=5; rSc.CanvasSize=UDim2.new(0,0,0,0)
rSc.ScrollBarImageColor3=rgb(100,60,200)
Instance.new("UIListLayout",rSc).Padding=UDim.new(0,3)
local resStat=label(resPanel,"",UDim2.new(1,0,0,14),UDim2.new(0,0,1,-16),rgb(180,150,255),true,5,10,Enum.TextXAlignment.Center)

-- ============================================================
--  LUCK TOGGLE SYNC
-- ============================================================
local function updateLuck()
    local on=luckOn
    local onC=rgb(34,197,94); local offC=rgb(80,80,110)
    local pc=on and onC or offC
    TweenService:Create(mainPill,TweenInfo.new(0.18),{BackgroundColor3=pc}):Play()
    TweenService:Create(mainKnob,TweenInfo.new(0.18),{Position=on and UDim2.new(1,-25,0.5,-11) or UDim2.new(0,3,0.5,-11)}):Play()
    TweenService:Create(lcPill,TweenInfo.new(0.18),{BackgroundColor3=pc}):Play()
    TweenService:Create(lcKnob,TweenInfo.new(0.18),{Position=on and UDim2.new(1,-25,0.5,-11) or UDim2.new(0,3,0.5,-11)}):Play()
    mainOnLbl.Text=on and "ON" or "OFF"; lcOnLbl.Text=on and "ON" or "OFF"
    if on then
        togStroke.Color=rgb(120,50,240); luckCardStroke.Color=rgb(139,92,246)
        lcTitle.Text="Unique Luck Active"; lcSub.Text="Unique chance: 25.00%"; lcSub.TextColor3=rgb(253,224,71)
        togSub.Text="Unique Luck Active  ☘"; uniqueBigLbl.TextColor3=rgb(170,70,255); togDot.BackgroundColor3=rgb(50,230,100)
    else
        togStroke.Color=rgb(70,70,100); luckCardStroke.Color=rgb(80,80,110)
        lcTitle.Text="Unique Luck Off"; lcSub.Text="Unique chance: 0.10%"; lcSub.TextColor3=rgb(180,160,220)
        togSub.Text="Normal Odds"; uniqueBigLbl.TextColor3=rgb(100,80,160); togDot.BackgroundColor3=rgb(130,130,155)
    end
    if tcOpen then buildTC() end
end

local function toggleLuck() luckOn=not luckOn; updateLuck() end
mainPill.MouseButton1Click:Connect(toggleLuck)
lcPill.MouseButton1Click:Connect(toggleLuck)

-- ============================================================
--  CURRENT TRAIT UPDATE
-- ============================================================
local function setCurTrait(t)
    if not t then
        ctPip.BackgroundColor3=rgb(80,80,120); ctName.Text="No trait"; ctName.TextColor3=rgb(150,130,215)
        ctEff.Text="Equip a trait via reroll"; ctEff.TextColor3=rgb(80,60,130); ctPct.Text=""
    else
        ctPip.BackgroundColor3=TIER_COL[t.tier]; ctName.Text=t.name; ctName.TextColor3=TIER_COL[t.tier]
        ctEff.Text=t.effect; ctEff.TextColor3=rgb(155,135,200)
        ctPct.Text=string.format("%.2f%%",t.chance)
    end
end

-- ============================================================
--  UNIT PORTRAIT LOADER
-- ============================================================
local function loadPortrait(unitName)
    local lo=unitName:lower()
    for key,id in pairs(UNIT_IMAGES) do
        if key:lower()==lo or lo:find(key:lower(),1,true) then
            if not id:find("REPLACE") then
                ucPort.Image=id; ucPort.Visible=true; ucIcon.Visible=false
                udiPort.Image=id; udiPort.Visible=true; udiLbl.Visible=false; return
            end
        end
    end
    ucPort.Visible=false; ucIcon.Visible=true; ucIcon.Text=unitName:sub(1,2):upper()
    udiPort.Visible=false; udiLbl.Visible=true; udiLbl.Text=unitName:sub(1,2):upper()
end

-- ============================================================
--  SCAN
-- ============================================================
scanBtn.MouseButton1Click:Connect(function()
    udName.Text="Scanning..."; udSub.Text=""; udName.TextColor3=rgb(180,150,255)
    task.wait(0.65)
    local found=scanWS()
    if found then
        detUnit=found; udName.Text=found; udName.TextColor3=rgb(80,230,120)
        udSub.Text="Unit detected — ready to reroll"; udSub.TextColor3=rgb(60,200,100)
        ucName.Text=found:len()>9 and found:sub(1,9).."…" or found
        loadPortrait(found)
    else
        detUnit=nil; udName.Text="No unit found"; udName.TextColor3=rgb(255,80,80)
        udSub.Text="Place a unit on the map, then scan"; udSub.TextColor3=rgb(200,60,60)
        ucName.Text="Unit"; ucIcon.Text="?"; ucIcon.Visible=true; ucPort.Visible=false
        udiLbl.Text="?"; udiLbl.Visible=true; udiPort.Visible=false
    end
end)

-- ============================================================
--  ROLL  — always fires, visual tokens decrease only
-- ============================================================
local function showUSP()
    uspNote.Text=luckOn and "0.10% base  |  25.00% with Unique Luck" or "0.10% base"
    usp.Visible=true
    for _=1,5 do
        TweenService:Create(uspStroke,TweenInfo.new(0.18),{Thickness=5}):Play(); task.wait(0.18)
        TweenService:Create(uspStroke,TweenInfo.new(0.18),{Thickness=2}):Play(); task.wait(0.18)
    end
end

local function doRoll(count)
    if rolling then return end; rolling=true
    -- token flash
    TweenService:Create(tokStroke,TweenInfo.new(0.08),{Thickness=5,Color=rgb(255,255,200)}):Play()
    task.wait(0.1)
    TweenService:Create(tokStroke,TweenInfo.new(0.14),{Thickness=3,Color=rgb(255,200,30)}):Play()

    if visTok<count then visTok=maxTok end
    local results={}; for i=1,count do results[i]=rollOne() end
    visTok=math.max(0,visTok-count); tokCount.Text=visTok.."/1"
    if visTok<=0 then task.delay(1,function() visTok=maxTok end) end

    setCurTrait(results[#results])

    for _,c in ipairs(rSc:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    resTitle.Text="Roll Results — "..count.." roll"..(count>1 and "s" or "")
    tcPanel.Visible=false; tcOpen=false

    local uCount=0
    for i,t in ipairs(results) do
        local isU=t.tier=="unique"; if isU then uCount=uCount+1 end
        local row=frame(rSc,UDim2.new(1,-4,0,26),nil,isU and rgb(60,28,0) or TIER_BG[t.tier],6)
        corner(row,8); stroke(row,isU and rgb(255,215,0) or TIER_COL[t.tier],1)
        frame(row,UDim2.new(0,4,0.65,0),UDim2.new(0,0,0.175,0),TIER_COL[t.tier],7)
        label(row,"#"..i,UDim2.new(0,24,1,0),UDim2.new(0,8,0,0),rgb(90,65,170),true,7,9)
        label(row,TIER_LBL[t.tier],UDim2.new(0,66,1,0),UDim2.new(0,34,0,0),TIER_COL[t.tier],true,7,9)
        label(row,t.name,UDim2.new(0,100,1,0),UDim2.new(0,102,0,0),TIER_COL[t.tier],true,7,12)
        local pl=label(row,string.format("%.2f%%",t.chance),UDim2.new(0,58,1,0),UDim2.new(1,-62,0,0),rgb(255,210,50),false,7,10)
        pl.TextXAlignment=Enum.TextXAlignment.Right
    end

    local h=math.min(count*29,190)
    resPanel.Size=UDim2.new(1,-24,0,h+46); resPanel.Visible=true
    rSc.CanvasSize=UDim2.new(0,0,0,count*29); rSc.CanvasPosition=Vector2.new(0,999999)

    if uCount>0 then
        resStat.Text="UNIQUE x"..uCount.."  —  Tokens: "..visTok; resStat.TextColor3=rgb(255,215,0)
        task.spawn(showUSP)
    else
        resStat.Text="Tokens remaining: "..visTok; resStat.TextColor3=rgb(180,150,255)
    end
    rolling=false
end

rerollBtn.MouseButton1Click:Connect(function() doRoll(1) end)
tokenBtn.MouseButton1Click:Connect(function()  doRoll(1) end)
buy10Btn.MouseButton1Click:Connect(function()  doRoll(10) end)
robuxBtn.MouseButton1Click:Connect(function()
    resStat.Text="Robux Reroll — visual only."
    resPanel.Size=UDim2.new(1,-24,0,46); resPanel.Visible=true
end)

-- ============================================================
--  INIT
-- ============================================================
updateLuck(); buildTC(); setCurTrait(nil)
print("[AATraitReroll] Loaded.")
