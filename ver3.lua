local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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

-- KONFIGURACJA CZCIONKI
local CustomFont = Font.new(
    "rbxasset://fonts/families/ComicNeueAngular.json", 
    Enum.FontWeight.Bold, 
    Enum.FontStyle.Normal
)

-- === SYSTEM PLAYER LIST (NAPRAWIONY) ===
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CustomPlayerList"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("ScrollingFrame")
MainFrame.Name = "Container"
MainFrame.Size = UDim2.new(0, 320, 0, 400)
MainFrame.Position = UDim2.new(1, -330, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BackgroundTransparency = 0.3
MainFrame.BorderSizePixel = 0
MainFrame.ScrollBarThickness = 5
MainFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
MainFrame.Parent = ScreenGui

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = MainFrame

-- Funkcja do odświeżania listy
local function RefreshList()
    -- Czyścimy stare wpisy (zostawiając Layout)
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

        -- PFP (Avatar)
        local PFP = Instance.new("ImageLabel")
        PFP.Size = UDim2.new(0, 50, 0, 50)
        PFP.Position = UDim2.new(0, 5, 0.5, -25)
        PFP.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
        PFP.BackgroundTransparency = 1
        PFP.Parent = Entry

        -- Display Name
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

        -- Stats (HP, WS, LVL, ELO)
        local StatsLabel = Instance.new("TextLabel")
        StatsLabel.Size = UDim2.new(1, -65, 0, 40)
        StatsLabel.Position = UDim2.new(0, 60, 0, 25)
        StatsLabel.BackgroundTransparency = 1
        StatsLabel.RichText = true
        StatsLabel.TextSize = 16
        StatsLabel.FontFace = CustomFont
        StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
        StatsLabel.Parent = Entry

        -- Pętla aktualizująca dane konkretnego gracza
        task.spawn(function()
            while Entry.Parent do
                local char = player.Character
                local hum = char and char:FindFirstChild("Humanoid")
                local hp = hum and math.floor(hum.Health) or 0
                local maxHp = hum and hum.MaxHealth or 100
                local hpCol = Color3.fromHSV((hp / maxHp) * 0.35, 0.9, 1):ToHex()
                
                local ws = "0"
                local lvl = "0"
                local elo = "0"
                
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

-- Obsługa zmian w graczach
Players.PlayerAdded:Connect(RefreshList)
Players.PlayerRemoving:Connect(RefreshList)
task.spawn(RefreshList)

-- === RESZTA FUNKCJI (ESP & AIMBOT) ===
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

-- === AIMBOT ===
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
            if _G.FriendCheck and IsFriend(v) then continue end
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
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then Holding = true
    elseif Input.KeyCode == Enum.KeyCode.P then _G.AutoShoot = not _G.AutoShoot end
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
            if _G.AutoShoot and IsVisible(Part) and not IsFriend(Target) then
                if mouse1click then mouse1click() end
            end
        end
    end
end)
