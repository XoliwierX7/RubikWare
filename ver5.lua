local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Holding = false
local LockedTarget = nil -- Zmienna do blokowania celu aimbota

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

-- === SYSTEM WYBORU GRACZA (DLA BRING) ===
local BringGui = Instance.new("ScreenGui")
BringGui.Name = "BringSelection"
BringGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
BringGui.Enabled = false

local BringMain = Instance.new("Frame", BringGui)
BringMain.Size = UDim2.new(0, 250, 0, 350)
BringMain.Position = UDim2.new(0.5, -125, 0.5, -175)
BringMain.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
BringMain.BorderSizePixel = 0

local BringCorner = Instance.new("UICorner", BringMain)
local BringScroll = Instance.new("ScrollingFrame", BringMain)
BringScroll.Size = UDim2.new(1, -10, 1, -40)
BringScroll.Position = UDim2.new(0, 5, 0, 35)
BringScroll.BackgroundTransparency = 1
BringScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
BringScroll.ScrollBarThickness = 4

local BringList = Instance.new("UIListLayout", BringScroll)
BringList.Padding = UDim.new(0, 5)

local BringTitle = Instance.new("TextLabel", BringMain)
BringTitle.Size = UDim2.new(1, 0, 0, 30)
BringTitle.Text = "WYBIERZ GRACZA (BRING)"
BringTitle.TextColor3 = Color3.new(1, 1, 1)
BringTitle.FontFace = CustomFont
BringTitle.BackgroundTransparency = 1

local function UpdateBringList()
    for _, child in pairs(BringScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local btn = Instance.new("TextButton", BringScroll)
        btn.Size = UDim2.new(1, -10, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.Text = p.DisplayName
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.FontFace = CustomFont
        btn.TextSize = 14
        Instance.new("UICorner", btn)
        
        btn.MouseButton1Click:Connect(function()
            local char = p.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root and myRoot then
                root.CFrame = myRoot.CFrame * CFrame.new(0, 0, -3)
            end
            BringGui.Enabled = false
        end)
    end
    BringScroll.CanvasSize = UDim2.new(0, 0, 0, BringList.AbsoluteContentSize.Y)
end

-- === SYSTEM RADIAL MENU (6 OPCJI) ===
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
    Container.Position = UDim2.new(0.5, math.cos(rad) * 145 - 62, 0.5, math.sin(rad) * 145 - 25)
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
local BringBtn = CreateMenuOption("BRING PLAYER", 300, Color3.fromRGB(200, 80, 255), "Bring")

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
                if root then root.CFrame = CFrame.new(SpawnPos) end
            elseif name == "Bring" then
                UpdateBringList()
                BringGui.Enabled = true
            end
        end
        RadialFrame.Visible = false
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end
end)

-- === LOGIKA PERSYSTENCJI I FLY (FIXED) ===
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
            local bv = root:FindFirstChild("FlyVelocity") or Instance.new("BodyVelocity")
            bv.Name = "FlyVelocity"
            bv.MaxForce = Vector3.new(0, 0, 0)
            bv.Parent = root

            local bg = root:FindFirstChild("FlyGyro") or Instance.new("BodyGyro")
            bg.Name = "FlyGyro"
            bg.MaxTorque = Vector3.new(0, 0, 0)
            bg.Parent = root
            
            while char.Parent == workspace do
                if _G.Fly then
                    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
                    bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
                    bg.CFrame = Camera.CFrame
                    
                    local dir = Vector3.new(0,0,0)
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
                    
                    bv.Velocity = (dir.Magnitude > 0) and (dir.Unit * FlySpeed) or Vector3.new(0,0,0)
                else
                    bv.MaxForce = Vector3.new(0, 0, 0)
                    bg.MaxTorque = Vector3.new(0, 0, 0)
                end
                task.wait()
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
MainFrame.Parent = PlayerListGui

local UIListLayout = Instance.new("UIListLayout", MainFrame)
UIListLayout.Padding = UDim.new(0, 5)

local function RefreshList()
    for _, child in pairs(MainFrame:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local Entry = Instance.new("Frame", MainFrame)
        Entry.Size = UDim2.new(1, -10, 0, 70)
        Entry.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        Entry.BackgroundTransparency = 0.2

        local PFP = Instance.new("ImageLabel", Entry)
        PFP.Size = UDim2.new(0, 50, 0, 50)
        PFP.Position = UDim2.new(0, 5, 0.5, -25)
        PFP.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
        PFP.BackgroundTransparency = 1

        local StatsLabel = Instance.new("TextLabel", Entry)
        StatsLabel.Size = UDim2.new(1, -65, 1, 0)
        StatsLabel.Position = UDim2.new(0, 60, 0, 0)
        StatsLabel.BackgroundTransparency = 1
        StatsLabel.RichText = true
        StatsLabel.TextSize = 15
        StatsLabel.FontFace = CustomFont
        StatsLabel.TextColor3 = Color3.new(1,1,1)
        StatsLabel.TextXAlignment = Enum.TextXAlignment.Left

        task.spawn(function()
            while Entry.Parent do
                local char = player.Character
                local hum = char and char:FindFirstChild("Humanoid")
                local hp = hum and math.floor(hum.Health) or 0
                local maxHp = hum and hum.MaxHealth or 100
                local hpCol = Color3.fromHSV((hp / maxHp) * 0.35, 0.9, 1):ToHex()
                
                local stats = player:FindFirstChild("CustomLeaderstats")
                local ws = stats and stats:FindFirstChild("Win Streak") and stats["Win Streak"].Value or 0
                local lvl = stats and stats:FindFirstChild("Level") and stats.Level.Value or 0
                
                StatsLabel.Text = string.format("<b>%s</b><br/><font color='#%s'>%d HP</font> | WS: %s | LVL: %s", player.DisplayName, hpCol, hp, ws, lvl)
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
    return LocalPlayer:IsFriendsWith(Player.UserId)
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
    local stroke = Instance.new("UIStroke", label)
    stroke.Thickness = 1.5
    return label
end

local function CreateESP(Player)
    local function Setup(Character)
        local root = Character:WaitForChild("HumanoidRootPart", 10)
        local hum = Character:WaitForChild("Humanoid", 10)
        if not root or not hum then return end
        if root:FindFirstChild("ESP_Tag") then root.ESP_Tag:Destroy() end

        local Billboard = Instance.new("BillboardGui", root)
        Billboard.Name = "ESP_Tag"
        Billboard.Size = UDim2.new(5, 0, 9, 0)
        Billboard.AlwaysOnTop = true

        local Box = Instance.new("Frame", Billboard)
        Box.Size = UDim2.new(0.9, 0, 0.5, 0)
        Box.Position = UDim2.new(0.05, 0, 0.25, 0)
        Box.BackgroundTransparency = 1
        local BoxStroke = Instance.new("UIStroke", Box)
        BoxStroke.Thickness = 2

        local NameLabel = CreateStatLabel("NameLabel", UDim2.new(0, 0, 0.05, 0), Color3.new(1, 1, 1), Billboard)
        NameLabel.Text = Player.DisplayName

        RunService.Heartbeat:Connect(function()
            if not Character.Parent or not root.Parent then Billboard:Destroy() return end
            if hum.Health > 0 and _G.ShowESP then
                Billboard.Enabled = true
                BoxStroke.Color = IsVisible(root) and Color3.new(0,1,0) or (IsFriend(Player) and Color3.new(1,1,0) or Color3.new(1,0,0))
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

-- === AIMBOT LOGIKA (FIXED TARGET LOCK) ===
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
        LockedTarget = nil -- Czyścimy cel po puszczeniu przycisku
    end
end)

RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = true
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius = _G.FOVRadius
    
    if Holding and _G.AimbotEnabled then
        -- Jeśli cel zginął lub wyszedł, szukamy nowego
        if not LockedTarget or not LockedTarget.Character or not LockedTarget.Character:FindFirstChild(_G.AimPart) or (LockedTarget.Character:FindFirstChild("Humanoid") and LockedTarget.Character.Humanoid.Health <= 0) then
            LockedTarget = GetClosestPlayer()
        end
        
        if LockedTarget and LockedTarget.Character then
            local Part = LockedTarget.Character[_G.AimPart]
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, Part.Position)
            
            -- Strzelanie (usunięto blokadę IsFriend)
            if _G.AutoShoot and IsVisible(Part) then
                if mouse1click then mouse1click() end
            end
        end
    end
end)
