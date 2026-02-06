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
_G.FriendCheck = false   
_G.AimPart = "Head" 
_G.AutoShoot = true     
_G.FOVRadius = 150
_G.ShowESP = true
_G.Noclip = false
_G.Fly = false
local FlySpeed = 75 
local SpawnPos = Vector3.new(103.3, -679.5, 1181.8)

-- KONFIGURACJA CZCIONKI
local CustomFont = Font.new(
    "rbxasset://fonts/families/ComicNeueAngular.json", 
    Enum.FontWeight.Bold, 
    Enum.FontStyle.Normal
)

-- === HUD POZYCJI ===
local PosGui = Instance.new("ScreenGui")
PosGui.Name = "PositionHUD"
PosGui.ResetOnSpawn = false
PosGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local PosFrame = Instance.new("Frame")
PosFrame.Size = UDim2.new(0, 220, 0, 35)
PosFrame.Position = UDim2.new(0, 10, 1, -45)
PosFrame.BackgroundColor3 = Color3.new(0, 0, 0)
PosFrame.BackgroundTransparency = 0.5
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

-- === MENU WYBORU GRACZA DO TP ===
local TPSelectionGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
TPSelectionGui.Enabled = false

local TPFrame = Instance.new("ScrollingFrame", TPSelectionGui)
TPFrame.Size = UDim2.new(0, 200, 0, 300)
TPFrame.Position = UDim2.new(0.5, -100, 0.5, -150)
TPFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TPFrame.BorderSizePixel = 0
TPFrame.ScrollBarThickness = 4

local TPLayout = Instance.new("UIListLayout", TPFrame)
TPLayout.Padding = UDim.new(0, 2)

local function UpdateTPList()
    for _, c in pairs(TPFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local btn = Instance.new("TextButton", TPFrame)
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.Text = p.DisplayName
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.FontFace = CustomFont
        btn.MouseButton1Click:Connect(function()
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
            end
            TPSelectionGui.Enabled = false
        end)
    end
    TPFrame.CanvasSize = UDim2.new(0, 0, 0, TPLayout.AbsoluteContentSize.Y)
end

-- === SYSTEM RADIAL MENU (6 OPCJI) ===
local RadialGui = Instance.new("ScreenGui")
RadialGui.Name = "RadialMenuGui"
RadialGui.IgnoreGuiInset = true
RadialGui.ResetOnSpawn = false 
RadialGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local RadialFrame = Instance.new("Frame", RadialGui)
RadialFrame.Size = UDim2.new(0, 450, 0, 450)
RadialFrame.Position = UDim2.new(0.5, -225, 0.5, -225)
RadialFrame.BackgroundTransparency = 1
RadialFrame.Visible = false

local HoveredButton = nil 

local function CreateMenuOption(name, angle, color, actionName)
    local Container = Instance.new("Frame", RadialFrame)
    Container.Size = UDim2.new(0, 110, 0, 50)
    local rad = math.rad(angle)
    Container.Position = UDim2.new(0.5, math.cos(rad) * 150 - 55, 0.5, math.sin(rad) * 150 - 25)
    Container.BackgroundTransparency = 1

    local Option = Instance.new("TextLabel", Container)
    Option.Size = UDim2.new(1, 0, 1, 0)
    Option.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Option.BackgroundTransparency = 0.2
    Option.Text = name
    Option.TextColor3 = Color3.new(1, 1, 1)
    Option.FontFace = CustomFont
    Option.TextSize = 13
    Option.Name = actionName
    Option.Active = true 

    local Corner = Instance.new("UICorner", Option)
    Corner.CornerRadius = UDim.new(0, 10)
    
    local Stroke = Instance.new("UIStroke", Option)
    Stroke.Thickness = 2
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
CreateMenuOption("NOCLIP: OFF", 0, Color3.fromRGB(255, 80, 80), "Noclip")
CreateMenuOption("FLY: OFF", 60, Color3.fromRGB(80, 255, 80), "Fly")
CreateMenuOption("AIM: ON", 120, Color3.fromRGB(80, 80, 255), "Aim")
CreateMenuOption("ESP: ON", 180, Color3.fromRGB(255, 255, 80), "Esp")
CreateMenuOption("TP: SPAWN", 240, Color3.fromRGB(255, 255, 255), "Spawn")
CreateMenuOption("BRING PLAYER", 300, Color3.fromRGB(255, 100, 255), "Bring")

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
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(SpawnPos)
                end
            elseif name == "Bring" then
                UpdateTPList()
                TPSelectionGui.Enabled = true
            end
        end
        RadialFrame.Visible = false
        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    end
end)

-- === LOGIKA PERSYSTENCJI, FLY I NOCLIP ===
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
            local bv = Instance.new("BodyVelocity")
            local bg = Instance.new("BodyGyro")
            bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
            while char.Parent == workspace do
                if _G.Fly then
                    bv.Parent, bg.Parent = root, root
                    bg.CFrame = Camera.CFrame
                    local dir = Vector3.new(0,0,0)
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) end
                    bv.Velocity = (dir.Magnitude > 0) and (dir.Unit * FlySpeed) or Vector3.new(0,0,0)
                else
                    bv.Parent, bg.Parent = nil, nil
                end
                task.wait()
            end
        end
        task.wait(1)
    end
end)

-- === LISTA GRACZY (ESP & LEADERSTATS) ===
local PlayerListGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
local MainFrame = Instance.new("ScrollingFrame", PlayerListGui)
MainFrame.Size = UDim2.new(0, 320, 0, 400)
MainFrame.Position = UDim2.new(1, -330, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0.3
MainFrame.BorderSizePixel = 0
MainFrame.ScrollBarThickness = 5

local UIListLayout = Instance.new("UIListLayout", MainFrame)
UIListLayout.Padding = UDim.new(0, 5)

local function RefreshList()
    for _, child in pairs(MainFrame:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local Entry = Instance.new("Frame", MainFrame)
        Entry.Size = UDim2.new(1, -10, 0, 70)
        Entry.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        
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
        StatsLabel.TextColor3 = Color3.new(1, 1, 1)
        StatsLabel.TextSize = 14
        StatsLabel.FontFace = CustomFont
        StatsLabel.TextXAlignment = Enum.TextXAlignment.Left

        task.spawn(function()
            while Entry.Parent do
                local char = player.Character
                local hum = char and char:FindFirstChild("Humanoid")
                local hp = hum and math.floor(hum.Health) or 0
                local hpCol = Color3.fromHSV((hp / 100) * 0.35, 0.9, 1):ToHex()
                StatsLabel.Text = string.format("<b>%s</b><br/><font color='#%s'>%d ❤️</font>", player.DisplayName, hpCol, hp)
                task.wait(1)
            end
        end)
    end
    MainFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
end

Players.PlayerAdded:Connect(RefreshList)
Players.PlayerRemoving:Connect(RefreshList)
RefreshList()

-- === ESP I AIMBOT ===
local function IsVisible(TargetPart)
    local Character = LocalPlayer.Character
    if not Character then return false end
    local Params = RaycastParams.new()
    Params.FilterDescendantsInstances = {Character, Camera}
    Params.FilterType = Enum.RaycastFilterType.Exclude
    local Result = workspace:Raycast(Camera.CFrame.Position, TargetPart.Position - Camera.CFrame.Position, Params)
    return not Result or Result.Instance:IsDescendantOf(TargetPart.Parent)
end

local function CreateESP(Player)
    local function Setup(Character)
        local root = Character:WaitForChild("HumanoidRootPart", 10)
        if not root then return end
        local Billboard = Instance.new("BillboardGui", root)
        Billboard.Name = "ESP_Tag"
        Billboard.Size = UDim2.new(5, 0, 5, 0)
        Billboard.AlwaysOnTop = true
        local Box = Instance.new("Frame", Billboard)
        Box.Size = UDim2.new(1, 0, 1, 0)
        Box.BackgroundTransparency = 1
        local Stroke = Instance.new("UIStroke", Box)
        Stroke.Thickness = 2
        RunService.Heartbeat:Connect(function()
            Billboard.Enabled = _G.ShowESP
            Stroke.Color = IsVisible(root) and Color3.new(0,1,0) or Color3.new(1,0,0)
        end)
    end
    Player.CharacterAdded:Connect(Setup)
    if Player.Character then Setup(Player.Character) end
end

for _, v in pairs(Players:GetPlayers()) do if v ~= LocalPlayer then CreateESP(v) end end
Players.PlayerAdded:Connect(CreateESP)

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Transparency = 0.6
FOVCircle.Color = Color3.new(1,1,1)

local function GetClosestPlayer()
    local MaximumDistance = _G.FOVRadius
    local Target = nil
    for _, v in next, Players:GetPlayers() do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(_G.AimPart) then
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
    return Target
end

UserInputService.InputBegan:Connect(function(i, g) if not g and i.UserInputType == Enum.UserInputType.MouseButton2 then Holding = true end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then Holding = false end end)

RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = true
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius = _G.FOVRadius
    if Holding and _G.AimbotEnabled then
        local Target = GetClosestPlayer()
        if Target then Camera.CFrame = CFrame.new(Camera.CFrame.Position, Target.Character[_G.AimPart].Position) end
    end
end)
