local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Holding = false
local LockedTarget = nil -- Zmienna do blokowania celu

-- === USTAWIENIA ===
_G.AimbotEnabled = true
_G.TeamCheck = false    
_G.FriendCheck = false   
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

-- === GUI LISTY GRACZY DLA "BRING" ===
local BringGui = Instance.new("ScreenGui")
BringGui.Name = "BringPlayerGui"
BringGui.ResetOnSpawn = false
BringGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
BringGui.Enabled = false -- Domyślnie ukryte

local BringFrame = Instance.new("Frame", BringGui)
BringFrame.Size = UDim2.new(0, 250, 0, 350)
BringFrame.Position = UDim2.new(0.5, -125, 0.5, -175)
BringFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
BringFrame.BorderSizePixel = 0

local BringTitle = Instance.new("TextLabel", BringFrame)
BringTitle.Size = UDim2.new(1, 0, 0, 30)
BringTitle.BackgroundTransparency = 1
BringTitle.Text = "WYBIERZ GRACZA (BRING)"
BringTitle.TextColor3 = Color3.new(1,1,1)
BringTitle.FontFace = CustomFont

local BringScroll = Instance.new("ScrollingFrame", BringFrame)
BringScroll.Size = UDim2.new(1, 0, 1, -30)
BringScroll.Position = UDim2.new(0, 0, 0, 30)
BringScroll.BackgroundTransparency = 1
BringScroll.CanvasSize = UDim2.new(0, 0, 0, 0)

local BringLayout = Instance.new("UIListLayout", BringScroll)
BringLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function RefreshBringList()
    for _, v in pairs(BringScroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton", BringScroll)
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.Text = player.DisplayName .. " (@" .. player.Name .. ")"
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            btn.TextColor3 = Color3.new(1,1,1)
            btn.FontFace = CustomFont
            
            btn.MouseButton1Click:Connect(function()
                -- Logika teleportacji gracza do siebie
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local targetChar = player.Character
                local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                
                if myRoot and targetRoot then
                    targetRoot.CFrame = myRoot.CFrame * CFrame.new(0, 0, -3) -- Teleportuje 3 study przed Ciebie
                end
                BringGui.Enabled = false -- Zamyka menu po wyborze
            end)
        end
    end
    BringScroll.CanvasSize = UDim2.new(0, 0, 0, BringLayout.AbsoluteContentSize.Y)
end

-- === SYSTEM RADIAL MENU (ZMODYFIKOWANY: 6 OPCJI) ===
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
    -- Promień koła
    Container.Position = UDim2.new(0.5, math.cos(rad) * 140 - 62, 0.5, math.sin(rad) * 140 - 25)
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
local BringBtn = CreateMenuOption("BRING PLAYER", 300, Color3.fromRGB(255, 0, 255), "Bring")

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
            elseif name == "Bring" then
                RefreshBringList()
                BringGui.Enabled = true
            end
        end
        RadialFrame.Visible = false
        if not BringGui.Enabled then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
    end
end)

-- === LOGIKA PERSYSTENCJI I FLY (NAPRAWIONE) ===
RunService.Stepped:Connect(function()
    if _G.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

task.spawn(function()
    while true do
        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local root = char:WaitForChild("HumanoidRootPart", 5)
        
        if root then
            -- Tworzymy obiekty fizyki raz, a nie w pętli
            local bv = Instance.new("BodyVelocity")
            local bg = Instance.new("BodyGyro")
            bv.MaxForce = Vector3.new(0,0,0) -- Domyślnie wyłączone
            bg.MaxTorque = Vector3.new(0,0,0)
            bv.Parent = root
            bg.Parent = root
            
            while char.Parent == workspace do
                if _G.Fly then
                    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
                    bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
                    
                    bg.CFrame = Camera.CFrame
                    
                    local dir = Vector3.new(0,0,0)
                    -- Resetujemy wektor ruchu w każdej klatce, żeby postać nie leciała sama
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) end
                    
                    bv.Velocity = (dir.Magnitude > 0) and (dir.Unit * FlySpeed) or Vector3.new(0,0,0)
                else
                    bv.MaxForce = Vector3.new(0,0,0)
                    bg.MaxTorque = Vector3.new(0,0,0)
                end
                task.wait() -- Krótkie opóźnienie dla pętli
            end
        end
        task.wait(1)
    end
end)

-- === LISTA GRACZY (PlayerList) ===
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

-- === ESP LOGIKA ===
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

-- === AIMBOT LOGIKA (NAPRAWIONY TARGET LOCK) ===
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Transparency = 0.6
FOVCircle.Color = Color3.new(1,1,1)

local function GetClosestPlayer()
    local MaximumDistance = _G.FOVRadius
    local Target = nil
    for _, v in next, Players:GetPlayers() do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(_G.AimPart) then
            if _G.TeamCheck and v.Team == LocalPlayer.Team then continue end
            -- USUNIĘTO FRIEND CHECK, ŻEBY MOŻNA BYŁO CELOWAĆ W ZNAJOMYCH
            -- if _G.FriendCheck and IsFriend(v) then continue end 
            
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

UserInputService.InputBegan:Connect(function(Input, Processed)
    if Processed then return end
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then 
        Holding = true
        LockedTarget = GetClosestPlayer() -- Blokujemy cel w momencie kliknięcia
    elseif Input.KeyCode == Enum.KeyCode.P then 
        _G.AutoShoot = not _G.AutoShoot 
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then 
        Holding = false 
        LockedTarget = nil -- Czyścimy cel po puszczeniu
    end
end)

RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = true
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius = _G.FOVRadius
    
    if Holding and _G.AimbotEnabled then
        -- Jeśli zablokowany cel zniknął lub umarł, spróbuj znaleźć nowego
        if LockedTarget and (not LockedTarget.Character or not LockedTarget.Character:FindFirstChild("Humanoid") or LockedTarget.Character.Humanoid.Health <= 0) then
            LockedTarget = GetClosestPlayer()
        end

        -- Jeśli nie mamy zablokowanego celu (bo np. kliknęliśmy w powietrze), spróbuj znaleźć
        if not LockedTarget then
             LockedTarget = GetClosestPlayer()
        end

        if LockedTarget and LockedTarget.Character then
            local Part = LockedTarget.Character[_G.AimPart]
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, Part.Position)
            
            -- USUNIĘTO BLOKADĘ STRZELANIA DO ZNAJOMYCH (not IsFriend(Target))
            if _G.AutoShoot and IsVisible(Part) then
                if mouse1click then mouse1click() end
            end
        end
    end
end)
