local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Holding = false

-- === KONFIGURACJA ===
_G.AimbotEnabled = true
_G.TeamCheck = false    
_G.FriendCheck = false   
_G.AimPart = "Head" 
_G.AutoShoot = true     
_G.FOVRadius = 150
_G.ShowESP = true
_G.Noclip = false
_G.Fly = false
local FlySpeed = 60

local CustomFont = Font.new("rbxasset://fonts/families/ComicNeueAngular.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)

-- === SYSTEM RADIAL MENU (MODERN RIVALS STYLE) ===
local RadialGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
RadialGui.Name = "RadialMenuGui"
RadialGui.IgnoreGuiInset = true

local RadialFrame = Instance.new("Frame", RadialGui)
RadialFrame.Size = UDim2.new(0, 400, 0, 400)
RadialFrame.Position = UDim2.new(0.5, -200, 0.5, -200)
RadialFrame.BackgroundTransparency = 1
RadialFrame.Visible = false

-- Środkowy punkt menu
local CenterDot = Instance.new("Frame", RadialFrame)
CenterDot.Size = UDim2.new(0, 10, 0, 10)
CenterDot.Position = UDim2.new(0.5, -5, 0.5, -5)
CenterDot.BackgroundColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", CenterDot).CornerRadius = UDim.new(1, 0)

local function CreateMenuOption(name, angle, color)
    local Container = Instance.new("Frame", RadialFrame)
    Container.Size = UDim2.new(0, 120, 0, 50)
    local rad = math.rad(angle)
    Container.Position = UDim2.new(0.5, math.cos(rad) * 130 - 60, 0.5, math.sin(rad) * 130 - 25)
    Container.BackgroundTransparency = 1

    local Option = Instance.new("TextButton", Container)
    Option.Size = UDim2.new(1, 0, 1, 0)
    Option.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Option.BackgroundTransparency = 0.2
    Option.Text = name
    Option.TextColor3 = Color3.new(1, 1, 1)
    Option.FontFace = CustomFont
    Option.TextSize = 16
    Option.AutoButtonColor = false
    
    local Corner = Instance.new("UICorner", Option)
    Corner.CornerRadius = UDim.new(0, 10)
    
    local Stroke = Instance.new("UIStroke", Option)
    Stroke.Thickness = 2
    Stroke.Color = color
    Stroke.Transparency = 0.3

    -- Animacja hover
    Option.MouseEnter:Connect(function()
        TweenService:Create(Option, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50), BackgroundTransparency = 0}):Play()
        TweenService:Create(Container, TweenInfo.new(0.2), {Size = UDim2.new(0, 130, 0, 55)}):Play()
    end)
    Option.MouseLeave:Connect(function()
        TweenService:Create(Option, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(20, 20, 25), BackgroundTransparency = 0.2}):Play()
        TweenService:Create(Container, TweenInfo.new(0.2), {Size = UDim2.new(0, 120, 0, 50)}):Play()
    end)
    
    return Option
end

local NoclipBtn = CreateMenuOption("NOCLIP: WYŁ", 0, Color3.fromRGB(255, 85, 85))
local FlyBtn = CreateMenuOption("LATANIE: WYŁ", 90, Color3.fromRGB(85, 255, 85))
local AimBtn = CreateMenuOption("AIMBOT: WŁ", 180, Color3.fromRGB(85, 85, 255))
local EspBtn = CreateMenuOption("ESP: WŁ", 270, Color3.fromRGB(255, 255, 85))

-- Funkcje przełączania
local function UpdateButtons()
    NoclipBtn.Text = "NOCLIP: " .. (_G.Noclip and "WŁ" or "WYŁ")
    NoclipBtn.TextColor3 = _G.Noclip and Color3.new(0,1,0) or Color3.new(1,1,1)
    
    FlyBtn.Text = "LATANIE: " .. (_G.Fly and "WŁ" or "WYŁ")
    FlyBtn.TextColor3 = _G.Fly and Color3.new(0,1,0) or Color3.new(1,1,1)
    
    AimBtn.Text = "AIMBOT: " .. (_G.AimbotEnabled and "WŁ" or "WYŁ")
    AimBtn.TextColor3 = _G.AimbotEnabled and Color3.new(0,1,0) or Color3.new(1,1,1)
    
    EspBtn.Text = "ESP: " .. (_G.ShowESP and "WŁ" or "WYŁ")
    EspBtn.TextColor3 = _G.ShowESP and Color3.new(0,1,0) or Color3.new(1,1,1)
end

-- Obsługa G
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.G then
        UpdateButtons()
        RadialFrame.Visible = true
        UserInputService.MouseIconEnabled = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.G then
        local pos = UserInputService:GetMouseLocation()
        local objects = LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(pos.X, pos.Y)
        
        for _, obj in pairs(objects) do
            if obj == NoclipBtn then _G.Noclip = not _G.Noclip
            elseif obj == FlyBtn then _G.Fly = not _G.Fly
            elseif obj == AimBtn then _G.AimbotEnabled = not _G.AimbotEnabled
            elseif obj == EspBtn then _G.ShowESP = not _G.ShowESP
            end
        end
        RadialFrame.Visible = false
    end
end)

-- === LOGIKA NOCLIP & FLY (FIXED) ===
RunService.Stepped:Connect(function()
    if _G.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

task.spawn(function()
    local bv = Instance.new("BodyVelocity")
    local bg = Instance.new("BodyGyro")
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)

    while true do
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if _G.Fly and root then
            bv.Parent = root
            bg.Parent = root
            bg.CFrame = Camera.CFrame
            
            local dir = Vector3.new(0,0,0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
            
            bv.Velocity = dir * FlySpeed
        else
            bv.Parent = nil
            bg.Parent = nil
        end
        task.wait()
    end
end)

-- === SYSTEM PLAYER LIST (POŁĄCZONY) ===
local ListGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
local MainFrame = Instance.new("ScrollingFrame", ListGui)
MainFrame.Size = UDim2.new(0, 320, 0, 400)
MainFrame.Position = UDim2.new(1, -330, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel = 0
MainFrame.ScrollBarThickness = 3
Instance.new("UIListLayout", MainFrame).Padding = UDim.new(0, 5)

local function RefreshList()
    for _, v in pairs(MainFrame:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local Entry = Instance.new("Frame", MainFrame)
        Entry.Size = UDim2.new(1, -10, 0, 60)
        Entry.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        Instance.new("UICorner", Entry)

        local NameL = Instance.new("TextLabel", Entry)
        NameL.Size = UDim2.new(1, -70, 0, 25)
        NameL.Position = UDim2.new(0, 65, 0, 5)
        NameL.Text = p.DisplayName
        NameL.TextColor3 = Color3.new(1,1,1)
        NameL.FontFace = CustomFont
        NameL.BackgroundTransparency = 1
        NameL.TextXAlignment = Enum.TextXAlignment.Left

        local StatsL = Instance.new("TextLabel", Entry)
        StatsL.Size = UDim2.new(1, -70, 0, 25)
        StatsL.Position = UDim2.new(0, 65, 0, 30)
        StatsL.BackgroundTransparency = 1
        StatsL.RichText = true
        StatsL.TextXAlignment = Enum.TextXAlignment.Left
        
        task.spawn(function()
            while Entry.Parent do
                local hp = p.Character and p.Character:FindFirstChild("Humanoid") and math.floor(p.Character.Humanoid.Health) or 0
                StatsL.Text = string.format("<font color='#00ff00'>%d ❤️</font> | <font color='#ffaa00'>Lv: %s</font>", hp, (p:FindFirstChild("CustomLeaderstats") and p.CustomLeaderstats:FindFirstChild("Level") and p.CustomLeaderstats.Level.Value or "0"))
                task.wait(1)
            end
        end)
    end
end

Players.PlayerAdded:Connect(RefreshList)
Players.PlayerRemoving:Connect(RefreshList)
RefreshList()

-- === AIMBOT & ESP (FIXED) ===
local function IsVisible(part)
    local char = LocalPlayer.Character
    if not char then return false end
    local cast = workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, RaycastParams.new())
    return not cast or cast.Instance:IsDescendantOf(part.Parent)
end

local function CreateESP(p)
    p.CharacterAdded:Connect(function(char)
        local bbg = Instance.new("BillboardGui", char:WaitForChild("HumanoidRootPart"))
        bbg.Size = UDim2.new(4,0,5,0); bbg.AlwaysOnTop = true
        local box = Instance.new("Frame", bbg)
        box.Size = UDim2.new(1,0,1,0); box.BackgroundTransparency = 0.8; box.BackgroundColor3 = Color3.new(1,0,0)
        Instance.new("UIStroke", box).Thickness = 2
    end)
end

for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreateESP(p) end end
Players.PlayerAdded:Connect(CreateESP)

local FOV = Drawing.new("Circle")
FOV.Thickness = 1; FOV.Color = Color3.new(1,1,1); FOV.Filled = false; FOV.Transparency = 0.5

RunService.RenderStepped:Connect(function()
    FOV.Visible = true; FOV.Position = UserInputService:GetMouseLocation(); FOV.Radius = _G.FOVRadius
    
    if Holding and _G.AimbotEnabled then
        local target, dist = nil, _G.FOVRadius
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(_G.AimPart) then
                local pos, vis = Camera:WorldToScreenPoint(p.Character[_G.AimPart].Position)
                if vis then
                    local mag = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                    if mag < dist then dist = mag; target = p end
                end
            end
        end
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character[_G.AimPart].Position)
        end
    end
end)

UserInputService.InputBegan:Connect(function(i, g) if not g and i.UserInputType == Enum.UserInputType.MouseButton2 then Holding = true end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then Holding = false end end)
