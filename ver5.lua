local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Holding = false

-- === USTAWIENIA ===
_G.AimbotEnabled = true
_G.TeamCheck = false    
_G.FriendCheck = false   -- Domyślnie wyłączone (strzela do znajomych), można zmienić w GUI
_G.AimPart = "Head" 
_G.AutoShoot = true      
_G.FOVRadius = 150
_G.ShowESP = true
_G.Noclip = false
_G.Fly = false
local FlySpeed = 75 
local SpawnPos = Vector3.new(103.3, -679.5, 1181.8) -- Współrzędne spawna

-- KONFIGURACJA CZCIONKI
local CustomFont = Font.new(
    "rbxasset://fonts/families/ComicNeueAngular.json", 
    Enum.FontWeight.Bold, 
    Enum.FontStyle.Normal
)

-- === HUD POZYCJI (LEWY DOLNY RÓG) ===
local PosGui = Instance.new("ScreenGui")
PosGui.Name = "PositionHUD"
PosGui.ResetOnSpawn = false
PosGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local PosFrame = Instance.new("Frame")
PosFrame.Size = UDim2.new(0, 220, 0, 35)
PosFrame.Position = UDim2.new(0, 10, 1, -45)
PosFrame.BackgroundColor3 = Color3.new(0, 0, 0)
PosFrame.BackgroundTransparency = 0.5
PosFrame.BorderSizePixel = 0
PosFrame.Parent = PosGui

local PosCorner = Instance.new("UICorner", PosFrame)
PosCorner.CornerRadius = UDim.new(0, 8)

local PosLabel = Instance.new("TextLabel")
PosLabel.Size = UDim2.new(1, -10, 1, 0)
PosLabel.Position = UDim2.new(0, 10, 0, 0)
PosLabel.BackgroundTransparency = 1
PosLabel.TextColor3 = Color3.new(1, 1, 1)
PosLabel.FontFace = CustomFont
PosLabel.TextSize = 16
PosLabel.TextXAlignment = Enum.TextXAlignment.Left
PosLabel.Parent = PosFrame

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        local pos = root.Position
        PosLabel.Text = string.format("POS: X: %.1f | Y: %.1f | Z: %.1f", pos.X, pos.Y, pos.Z)
    else
        PosLabel.Text = "POS: N/A"
    end
end)

-- === GUI LISTY GRACZY DO TELEPORTACJI (NOWOŚĆ) ===
local TpGui = Instance.new("ScreenGui")
TpGui.Name = "TeleportGui"
TpGui.ResetOnSpawn = false
TpGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
TpGui.Enabled = false -- Domyślnie ukryte

local TpMainFrame = Instance.new("Frame", TpGui)
TpMainFrame.Size = UDim2.new(0, 250, 0, 350)
TpMainFrame.Position = UDim2.new(0.5, -125, 0.5, -175)
TpMainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TpMainFrame.BorderSizePixel = 2
TpMainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)

local TpTitle = Instance.new("TextLabel", TpMainFrame)
TpTitle.Size = UDim2.new(1, 0, 0, 30)
TpTitle.BackgroundTransparency = 1
TpTitle.Text = "WYBIERZ GRACZA DO TP"
TpTitle.TextColor3 = Color3.new(1, 1, 1)
TpTitle.FontFace = CustomFont
TpTitle.TextSize = 18

-- Przycisk zamykania TP Menu
local CloseTpBtn = Instance.new("TextButton", TpMainFrame)
CloseTpBtn.Size = UDim2.new(0, 20, 0, 20)
CloseTpBtn.Position = UDim2.new(1, -25, 0, 5)
CloseTpBtn.Text = "X"
CloseTpBtn.TextColor3 = Color3.new(1, 0, 0)
CloseTpBtn.BackgroundColor3 = Color3.new(0, 0, 0)
CloseTpBtn.MouseButton1Click:Connect(function()
    TpGui.Enabled = false
end)

-- Przycisk Friend Check (Strzelanie do znajomych)
local FriendCheckBtn = Instance.new("TextButton", TpMainFrame)
FriendCheckBtn.Size = UDim2.new(1, -10, 0, 25)
FriendCheckBtn.Position = UDim2.new(0, 5, 0, 30)
FriendCheckBtn.Text = "FRIEND CHECK: OFF (Strzela)"
FriendCheckBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
FriendCheckBtn.TextColor3 = Color3.new(1, 1, 1)
FriendCheckBtn.FontFace = CustomFont
FriendCheckBtn.MouseButton1Click:Connect(function()
    _G.FriendCheck = not _G.FriendCheck
    if _G.FriendCheck then
        FriendCheckBtn.Text = "FRIEND CHECK: ON (Nie strzela)"
        FriendCheckBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 0)
    else
        FriendCheckBtn.Text = "FRIEND CHECK: OFF (Strzela)"
        FriendCheckBtn.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
    end
end)

local TpScroll = Instance.new("ScrollingFrame", TpMainFrame)
TpScroll.Size = UDim2.new(1, -10, 1, -65)
TpScroll.Position = UDim2.new(0, 5, 0, 60)
TpScroll.BackgroundTransparency = 1
TpScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local TpLayout = Instance.new("UIListLayout", TpScroll)
TpLayout.Padding = UDim.new(0, 5)
TpLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function RefreshTpList()
    for _, child in pairs(TpScroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton", TpScroll)
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.Text = player.DisplayName .. " (@" .. player.Name .. ")"
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.FontFace = CustomFont
            
            btn.MouseButton1Click:Connect(function()
                local targetChar = player.Character
                local myChar = LocalPlayer.Character
                if targetChar and targetChar:FindFirstChild("HumanoidRootPart") and myChar and myChar:FindFirstChild("HumanoidRootPart") then
                    myChar.HumanoidRootPart.CFrame = targetChar.HumanoidRootPart.CFrame * CFrame.new(0, 2, 3)
                    TpGui.Enabled = false
                end
            end)
        end
    end
    TpScroll.CanvasSize = UDim2.new(0, 0, 0, TpLayout.AbsoluteContentSize.Y)
end
TpGui:GetPropertyChangedSignal("Enabled"):Connect(function()
    if TpGui.Enabled then RefreshTpList() end
end)


-- === SYSTEM RADIAL MENU (POPRAWIONY I ROZSZERZONY) ===
local RadialGui = Instance.new("ScreenGui")
RadialGui.Name = "RadialMenuGui"
RadialGui.IgnoreGuiInset = true
RadialGui.ResetOnSpawn = false 
RadialGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local RadialFrame = Instance.new("Frame", RadialGui)
RadialFrame.Size = UDim2.new(0, 400, 0, 400)
RadialFrame.Position = UDim2.new(0.5, -200, 0.5, -200)
RadialFrame.BackgroundTransparency = 1
RadialFrame.Visible = false

local HoveredButton = nil 

local function CreateMenuOption(name, angle, color, actionName)
    local Container = Instance.new("Frame", RadialFrame)
    Container.Size = UDim2.new(0, 125, 0, 50)
    local rad = math.rad(angle)
    -- Ustawienie pozycji na okręgu
    Container.Position = UDim2.new(0.5, math.cos(rad) * 150 - 62, 0.5, math.sin(rad) * 150 - 25)
    Container.BackgroundTransparency = 1

    local Option = Instance.new("TextLabel", Container)
    Option.Size = UDim2.new(1, 0, 1, 0)
    Option.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Option.BackgroundTransparency = 0.2
    Option.Text = name
    Option.TextColor3 = Color3.new(1, 1, 1)
    Option.FontFace = CustomFont
    Option.TextSize = 14
    Option.Name = actionName
    Option.Active = true 

    local Corner = Instance.new("UICorner", Option)
    Corner.CornerRadius = UDim.new(0, 12)
    
    local Stroke = Instance.new("UIStroke", Option)
    Stroke.Thickness = 3
    Stroke.Color = color

    Option.MouseEnter:Connect(function()
        HoveredButton = Option
        Option.BackgroundColor3 = color
        Option.TextColor3 = Color3.new(0, 0, 0)
    end)

    Option.MouseLeave:Connect(function()
        if HoveredButton == Option then HoveredButton = nil end
        Option.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        Option.TextColor3 = Color3.new(1, 1, 1)
    end)

    return Option
end

-- Rozmieszczenie 6 przycisków co 60 stopni
local NoclipBtn = CreateMenuOption("NOCLIP: OFF", 0, Color3.fromRGB(255, 80, 80), "Noclip")
local FlyBtn = CreateMenuOption("FLY: OFF", 60, Color3.fromRGB(80, 255, 80), "Fly")
local AimBtn = CreateMenuOption("AIM: ON", 120, Color3.fromRGB(80, 80, 255), "Aim")
local EspBtn = CreateMenuOption("ESP: ON", 180, Color3.fromRGB(255, 255, 80), "Esp")
local SpawnBtn = CreateMenuOption("TP: SPAWN", 240, Color3.fromRGB(255, 255, 255), "Spawn")
local TpMenuBtn = CreateMenuOption("TP MENU", 300, Color3.fromRGB(255, 0, 255), "TpMenu") -- NOWY PRZYCISK

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Y then
        RadialFrame.Visible = true
        UserInputService.MouseBehavior = Enum.MouseBehavior.None
        UserInputService.MouseIconEnabled = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Y then
        if HoveredButton then
            local name = HoveredButton.Name
            if name == "Noclip" then
                _G.Noclip = not _G.Noclip
                HoveredButton.Text = "NOCLIP: " .. (_G.Noclip and "ON" or "OFF")
            elseif name == "Fly" then
                _G.Fly = not _G.Fly
                HoveredButton.Text = "FLY: " .. (_G.Fly and "ON" or "OFF")
                -- Reset velocity when fly is toggled off
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                   local bv = char.HumanoidRootPart:FindFirstChild("FlyVelocity")
                   if bv then bv:Destroy() end
                   local bg = char.HumanoidRootPart:FindFirstChild("FlyGyro")
                   if bg then bg:Destroy() end
                end
            elseif name == "Aim" then
                _G.AimbotEnabled = not _G.AimbotEnabled
                HoveredButton.Text = "AIM: " .. (_G.AimbotEnabled and "ON" or "OFF")
            elseif name == "Esp" then
                _G.ShowESP = not _G.ShowESP
                HoveredButton.Text = "ESP: " .. (_G.ShowESP and "ON" or "OFF")
            elseif name == "Spawn" then
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then
                    root.CFrame = CFrame.new(SpawnPos)
                end
            elseif name == "TpMenu" then -- OBSŁUGA NOWEGO PRZYCISKU
                TpGui.Enabled = not TpGui.Enabled
            end
        end
        RadialFrame.Visible = false
        if not TpGui.Enabled then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
    end
end)

-- === LOGIKA PERSYSTENCJI I NOCLIP ===
RunService.Stepped:Connect(function()
    if _G.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- === NAPRAWIONY SYSTEM LATANIA (BEZ ZACINANIA) ===
RunService.Heartbeat:Connect(function()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    
    local root = LocalPlayer.Character.HumanoidRootPart
    local bv = root:FindFirstChild("FlyVelocity") or Instance.new("BodyVelocity")
    local bg = root:FindFirstChild("FlyGyro") or Instance.new("BodyGyro")
    
    if _G.Fly then
        bv.Name = "FlyVelocity"
        bv.Parent = root
        bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        
        bg.Name = "FlyGyro"
        bg.Parent = root
        bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        bg.CFrame = Camera.CFrame
        
        local dir = Vector3.new(0,0,0)
        -- Sprawdzanie klawiszy bezpośrednio (naprawia zacinanie)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
        
        if dir.Magnitude > 0 then
            bv.Velocity = dir.Unit * FlySpeed
        else
            bv.Velocity = Vector3.new(0, 0, 0) -- Natychmiastowe zatrzymanie
        end
    else
        if root:FindFirstChild("FlyVelocity") then root.FlyVelocity:Destroy() end
        if root:FindFirstChild("FlyGyro") then root.FlyGyro:Destroy() end
    end
end)

-- === LISTA GRACZY (PlayerList) - BEZ ZMIAN ===
local PlayerListGui = Instance.new("ScreenGui")
PlayerListGui.Name = "CustomPlayerList"
PlayerListGui.ResetOnSpawn = false
PlayerListGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("ScrollingFrame")
MainFrame.Name = "Container"
MainFrame.Size = UDim2.new(0, 320, 0, 400)
MainFrame.Position = UDim2.new(1, -330, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0.3
MainFrame.BorderSizePixel = 0
MainFrame.ScrollBarThickness = 5
MainFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
MainFrame.Parent = PlayerListGui

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = MainFrame

local function RefreshList()
    for _, child in pairs(MainFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local Entry = Instance.new("Frame")
        Entry.Name = player.Name
        Entry.Size = UDim2.new(1, -10, 0, 70)
        Entry.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        Entry.BackgroundTransparency = 0.2
        Entry.Parent = MainFrame

        local PFP = Instance.new("ImageLabel")
        PFP.Size = UDim2.new(0, 50, 0, 50)
        PFP.Position = UDim2.new(0, 5, 0.5, -25)
        PFP.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
        PFP.BackgroundTransparency = 1
        PFP.Parent = Entry

        local NameLabel = Instance.new("TextLabel")
        NameLabel.Size = UDim2.new(1, -65, 0, 20)
        NameLabel.Position = UDim2.new(0, 60, 0, 5)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = player.DisplayName
        NameLabel.TextColor3 = Color3.new(1, 1, 1)
        NameLabel.TextSize = 16
        NameLabel.FontFace = CustomFont
        NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        NameLabel.Parent = Entry

        local StatsLabel = Instance.new("TextLabel")
        StatsLabel.Size = UDim2.new(1, -65, 0, 40)
        StatsLabel.Position = UDim2.new(0, 60, 0, 25)
        StatsLabel.BackgroundTransparency = 1
        StatsLabel.RichText = true
        StatsLabel.TextSize = 16
        StatsLabel.FontFace = CustomFont
        StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
        StatsLabel.Parent = Entry

        task.spawn(function()
            while Entry.Parent do
                local char = player.Character
                local hum = char and char:FindFirstChild("Humanoid")
                local hp = hum and math.floor(hum.Health) or 0
                local maxHp = hum and hum.MaxHealth or 100
                local hpCol = Color3.fromHSV((hp / maxHp) * 0.35, 0.9, 1):ToHex()
                
                local ws, lvl, elo = "0", "0", "0"
                local stats = player:FindFirstChild("CustomLeaderstats")
                if stats then
                    ws = tostring(stats:FindFirstChild("Win Streak") and stats["Win Streak"].Value or 0)
                    lvl = tostring(stats:FindFirstChild("Level") and stats.Level.Value or 0)
                    elo = tostring(stats:FindFirstChild("Current ELO") and stats["Current ELO"].Value or 0)
                end
                
                StatsLabel.Text = string.format(
                    "<font size='20' color='#%s'>%d ❤️</font> | <font color='#ffa500'>%s 🔥</font><br/>" ..
                    "<font color='#00bfff'>%s ⭐</font> | <font color='#9400d3'>%s 📊</font>",
                    hpCol, hp, ws, lvl, elo
                )
                task.wait(1)
            end
        end)
    end
    MainFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
end

Players.PlayerAdded:Connect(RefreshList)
Players.PlayerRemoving:Connect(RefreshList)
task.spawn(RefreshList)

-- === ESP LOGIKA (Działa jak wcześniej) ===
local function IsFriend(Player)
    if _G.FriendCheck then return LocalPlayer:IsFriendsWith(Player.UserId) end
    return false
end

local function IsVisible(TargetPart)
    local Character = LocalPlayer.Character
    if not Character then return false end
    local Params = RaycastParams.new()
    Params.FilterDescendantsInstances = {Character, Camera}
    Params.FilterType = Enum.RaycastFilterType.Exclude
    local Result = workspace:Raycast(Camera.CFrame.Position, TargetPart.Position - Camera.CFrame.Position, Params)
    return not Result or Result.Instance:IsDescendantOf(TargetPart.Parent)
end

local function CreateStatLabel(name, position, color, parent)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = UDim2.new(1, 0, 0.12, 0)
    label.Position = position
    label.BackgroundTransparency = 1
    label.FontFace = CustomFont
    label.TextColor3 = color
    label.TextScaled = true
    label.Parent = parent
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Parent = label
    return label
end

local function CreateESP(Player)
    local function Setup(Character)
        local root = Character:WaitForChild("HumanoidRootPart", 10)
        local hum = Character:WaitForChild("Humanoid", 10)
        if not root or not hum then return end
        if root:FindFirstChild("ESP_Tag") then root.ESP_Tag:Destroy() end

        local Billboard = Instance.new("BillboardGui")
        Billboard.Name = "ESP_Tag"
        Billboard.Adornee = root
        Billboard.Size = UDim2.new(5, 0, 9, 0)
        Billboard.AlwaysOnTop = true
        Billboard.Parent = root

        local Box = Instance.new("Frame")
        Box.Size = UDim2.new(0.9, 0, 0.5, 0)
        Box.Position = UDim2.new(0.05, 0, 0.25, 0)
        Box.BackgroundTransparency = 1
        Box.Parent = Billboard
        local BoxStroke = Instance.new("UIStroke")
        BoxStroke.Thickness = 2
        BoxStroke.Parent = Box

        local NameLabel = CreateStatLabel("NameLabel", UDim2.new(0, 0, 0.05, 0), Color3.new(1, 1, 1), Billboard)
        NameLabel.Text = Player.DisplayName
        local HPLabel = CreateStatLabel("HPLabel", UDim2.new(0, 0, 0.15, 0), Color3.new(0, 255, 0), Billboard)
        local WSLabel = CreateStatLabel("WSLabel", UDim2.new(0, 0, 0.75, 0), Color3.fromRGB(255, 165, 0), Billboard)
        local LevelLabel = CreateStatLabel("LevelLabel", UDim2.new(0, 0, 0.85, 0), Color3.fromRGB(0, 191, 255), Billboard)
        local EloLabel = CreateStatLabel("EloLabel", UDim2.new(0, 0, 0.95, 0), Color3.fromRGB(148, 0, 211), Billboard)

        RunService.Heartbeat:Connect(function()
            if not Character.Parent or not root.Parent then Billboard:Destroy() return end
            if hum.Health > 0 and _G.ShowESP then
                Billboard.Enabled = true
                HPLabel.Text = "HP: " .. math.floor(hum.Health)
                HPLabel.TextColor3 = Color3.fromHSV((hum.Health / hum.MaxHealth) * 0.35, 0.9, 1)
                
                local stats = Player:FindFirstChild("CustomLeaderstats")
                if stats then
                    WSLabel.Text = "WS: " .. (stats:FindFirstChild("Win Streak") and stats["Win Streak"].Value or 0)
                    LevelLabel.Text = "LVL: " .. (stats:FindFirstChild("Level") and stats.Level.Value or 0)
                    EloLabel.Text = "ELO: " .. (stats:FindFirstChild("Current ELO") and stats["Current ELO"].Value or 0)
                end
                BoxStroke.Color = IsVisible(root) and Color3.new(0,1,0) or (IsFriend(Player) and Color3.new(0,1,1) or Color3.new(1,0,0))
            else
                Billboard.Enabled = false
            end
        end)
    end
    Player.CharacterAdded:Connect(Setup)
    if Player.Character then task.spawn(Setup, Player.Character) end
end

for _, v in pairs(Players:GetPlayers()) do if v ~= LocalPlayer then CreateESP(v) end end
Players.PlayerAdded:Connect(CreateESP)

-- === AIMBOT LOGIKA (POPRAWIONA) ===
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Transparency = 0.6
FOVCircle.Color = Color3.new(1,1,1)

local function GetClosestPlayer()
    local MaximumDistance = _G.FOVRadius
    local Target = nil
    for _, v in next, Players:GetPlayers() do
        -- Poprawiona logika friend check - jeśli _G.FriendCheck jest true, to pomija przyjaciół.
        -- Jeśli jest false (domyślnie), to strzela do nich.
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(_G.AimPart) then
            if _G.TeamCheck and v.Team == LocalPlayer.Team then continue end
            if _G.FriendCheck and IsFriend(v) then continue end -- To pozwala strzelać do znajomych jeśli FriendCheck jest OFF
            local Hum = v.Character:FindFirstChildOfClass("Humanoid")
            if Hum and Hum.Health > 0 then
                local ScreenPoint, OnScreen = Camera:WorldToScreenPoint(v.Character[_G.AimPart].Position)
                if OnScreen then
                    local MousePos = UserInputService:GetMouseLocation()
                    local VectorDistance = (Vector2.new(MousePos.X, MousePos.Y) - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude
                    if VectorDistance < MaximumDistance then
                        Target = v
                        MaximumDistance = VectorDistance
                    end
                end
            end
        end
    end
    return Target
end

RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = true
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius = _G.FOVRadius
    
    -- Naprawa blokowania aimbota: Sprawdzamy stan przycisku na żywo zamiast polegać na zmiennej
    local isAiming = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    
    if isAiming and _G.AimbotEnabled then
        local Target = GetClosestPlayer()
        if Target and Target.Character then
            local Part = Target.Character[_G.AimPart]
            -- Ustawianie kamery
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, Part.Position)
            
            if _G.AutoShoot and IsVisible(Part) then
                -- Opcjonalne: sprawdzanie znajomych jeszcze raz przy strzale
                if not (_G.FriendCheck and IsFriend(Target)) then
                     if mouse1click then mouse1click() end
                end
            end
        end
    end
end)
