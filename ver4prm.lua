local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Holding = false

-- === USTAWIENIA GLOBALNE ===
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

-- KONFIGURACJA CZCIONKI
local CustomFont = Font.new(
    "rbxasset://fonts/families/ComicNeueAngular.json", 
    Enum.FontWeight.Bold, 
    Enum.FontStyle.Normal
)

-- === SYSTEM RADIAL MENU (KLAWISZ Y) ===
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

local MenuButtons = {}

local function CreateMenuOption(name, angle, color, actionName)
    local Container = Instance.new("Frame", RadialFrame)
    Container.Size = UDim2.new(0, 120, 0, 50)
    local rad = math.rad(angle)
    Container.Position = UDim2.new(0.5, math.cos(rad) * 130 - 60, 0.5, math.sin(rad) * 130 - 25)
    Container.BackgroundTransparency = 1

    local Option = Instance.new("TextLabel", Container)
    Option.Size = UDim2.new(1, 0, 1, 0)
    Option.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Option.BackgroundTransparency = 0.2
    Option.Text = name
    Option.TextColor3 = Color3.new(1, 1, 1)
    Option.FontFace = CustomFont
    Option.TextSize = 15
    Option.Name = actionName
    
    Instance.new("UICorner", Option).CornerRadius = UDim.new(0, 12)
    local Stroke = Instance.new("UIStroke", Option)
    Stroke.Thickness = 3
    Stroke.Color = color

    table.insert(MenuButtons, {Gui = Option, Color = color})
    return Option
end

-- Tworzenie przycisków
CreateMenuOption("NOCLIP: OFF", 0, Color3.fromRGB(255, 80, 80), "Noclip")
CreateMenuOption("FLY: OFF", 90, Color3.fromRGB(80, 255, 80), "Fly")
CreateMenuOption("AIM: ON", 180, Color3.fromRGB(80, 80, 255), "Aim")
CreateMenuOption("ESP: ON", 270, Color3.fromRGB(255, 255, 80), "Esp")

local function GetButtonUnderMouse()
    local MousePos = UserInputService:GetMouseLocation()
    for _, data in pairs(MenuButtons) do
        local Gui = data.Gui
        local AbsPos = Gui.AbsolutePosition
        local AbsSize = Gui.AbsoluteSize
        if MousePos.X >= AbsPos.X and MousePos.X <= AbsPos.X + AbsSize.X and
           MousePos.Y >= AbsPos.Y and MousePos.Y <= AbsPos.Y + AbsSize.Y then
            return Gui
        end
    end
    return nil
end

-- Obsługa wejścia (Klawisz Y)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Y then
        RadialFrame.Visible = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Y then
        local Hovered = GetButtonUnderMouse()
        if Hovered then
            if Hovered.Name == "Noclip" then
                _G.Noclip = not _G.Noclip
                Hovered.Text = "NOCLIP: " .. (_G.Noclip and "ON" or "OFF")
            elseif Hovered.Name == "Fly" then
                _G.Fly = not _G.Fly
                Hovered.Text = "FLY: " .. (_G.Fly and "ON" or "OFF")
            elseif Hovered.Name == "Aim" then
                _G.AimbotEnabled = not _G.AimbotEnabled
                Hovered.Text = "AIM: " .. (_G.AimbotEnabled and "ON" or "OFF")
            elseif Hovered.Name == "Esp" then
                _G.ShowESP = not _G.ShowESP
                Hovered.Text = "ESP: " .. (_G.ShowESP and "ON" or "OFF")
            end
            -- Efekt mignięcia
            local oldCol = Hovered.BackgroundColor3
            Hovered.BackgroundColor3 = Color3.new(1, 1, 1)
            task.delay(0.1, function() Hovered.BackgroundColor3 = oldCol end)
        end
        RadialFrame.Visible = false
    end
end)

-- === LOGIKA NOCLIP ===
RunService.Stepped:Connect(function()
    if _G.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- === LOGIKA FLY (W,A,S,D, Space, Shift) ===
task.spawn(function()
    local bv = Instance.new("BodyVelocity")
    local bg = Instance.new("BodyGyro")
    bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    
    while task.wait() do
        if _G.Fly and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            bv.Parent = LocalPlayer.Character.HumanoidRootPart
            bg.Parent = LocalPlayer.Character.HumanoidRootPart
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
            bv.Parent = nil
            bg.Parent = nil
        end
    end
end)

-- === LISTA GRACZY (Player List) ===
local ListGui = Instance.new("ScreenGui")
ListGui.Name = "CustomPlayerList"
ListGui.ResetOnSpawn = false
ListGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("ScrollingFrame")
MainFrame.Size = UDim2.new(0, 320, 0, 400)
MainFrame.Position = UDim2.new(1, -330, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0.3
MainFrame.BorderSizePixel = 0
MainFrame.ScrollBarThickness = 5
MainFrame.Parent = ListGui

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = MainFrame

local function RefreshList()
    for _, child in pairs(MainFrame:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local Entry = Instance.new("Frame")
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

        local StatsLabel = Instance.new("TextLabel")
        StatsLabel.Size = UDim2.new(1, -65, 1, 0)
        StatsLabel.Position = UDim2.new(0, 60, 0, 0)
        StatsLabel.BackgroundTransparency = 1
        StatsLabel.RichText = true
        StatsLabel.TextColor3 = Color3.new(1,1,1)
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
                
                local stats = player:FindFirstChild("CustomLeaderstats")
                local ws = stats and stats:FindFirstChild("Win Streak") and stats["Win Streak"].Value or 0
                local lvl = stats and stats:FindFirstChild("Level") and stats.Level.Value or 0
                local elo = stats and stats:FindFirstChild("Current ELO") and stats["Current ELO"].Value or 0
                
                StatsLabel.Text = string.format("<b>%s</b><br/><font color='#%s'>%d ❤️</font> | <font color='#ffa500'>%s 🔥</font><br/><font color='#00bfff'>Lvl %s</font> | <font color='#9400d3'>Elo %s</font>", player.DisplayName, hpCol, hp, ws, lvl, elo)
                task.wait(1)
            end
        end)
    end
    MainFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y)
end

Players.PlayerAdded:Connect(RefreshList)
Players.PlayerRemoving:Connect(RefreshList)
task.spawn(RefreshList)

-- === LOGIKA ESP ===
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
    Player.CharacterAdded:Connect(function(Character)
        local root = Character:WaitForChild("HumanoidRootPart", 10)
        if not root then return end
        local Billboard = Instance.new("BillboardGui", root)
        Billboard.Name = "ESP_Tag"
        Billboard.Size = UDim2.new(5, 0, 5, 0)
        Billboard.AlwaysOnTop = true
        
        local Box = Instance.new("Frame", Billboard)
        Box.Size = UDim2.new(1,0,1,0)
        Box.BackgroundTransparency = 1
        local Stroke = Instance.new("UIStroke", Box)
        Stroke.Thickness = 2

        RunService.Heartbeat:Connect(function()
            if _G.ShowESP and Character.Parent and root.Parent then
                Billboard.Enabled = true
                Stroke.Color = IsVisible(root) and Color3.new(0,1,0) or Color3.new(1,0,0)
            else
                Billboard.Enabled = false
            end
        end)
    end)
end
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreateESP(p) end end
Players.PlayerAdded:Connect(CreateESP)

-- === LOGIKA AIMBOT ===
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Transparency = 0.6
FOVCircle.Color = Color3.new(1,1,1)

local function GetClosestPlayer()
    local MaximumDistance = _G.FOVRadius
    local Target = nil
    for _, v in next, Players:GetPlayers() do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(_G.AimPart) then
            local Hum = v.Character:FindFirstChildOfClass("Humanoid")
            if Hum and Hum.Health > 0 then
                local ScreenPoint, OnScreen = Camera:WorldToScreenPoint(v.Character[_G.AimPart].Position)
                if OnScreen then
                    local MousePos = UserInputService:GetMouseLocation()
                    local dist = (Vector2.new(MousePos.X, MousePos.Y) - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude
                    if dist < MaximumDistance then
                        Target = v
                        MaximumDistance = dist
                    end
                end
            end
        end
    end
    return Target
end

UserInputService.InputBegan:Connect(function(Input, gpe)
    if gpe then return end
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then Holding = true end
end)
UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then Holding = false end
end)

RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = true
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius = _G.FOVRadius
    
    if Holding and _G.AimbotEnabled then
        local Target = GetClosestPlayer()
        if Target and Target.Character then
            local Part = Target.Character[_G.AimPart]
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, Part.Position)
            if _G.AutoShoot and IsVisible(Part) then
                if mouse1click then mouse1click() end
            end
        end
    end
    
    if RadialFrame.Visible then
        local Hovered = GetButtonUnderMouse()
        for _, data in pairs(MenuButtons) do
            data.Gui.BackgroundColor3 = (data.Gui == Hovered) and data.Color or Color3.fromRGB(25, 25, 25)
            data.Gui.TextColor3 = (data.Gui == Hovered) and Color3.new(0,0,0) or Color3.new(1,1,1)
        end
    end
end)
