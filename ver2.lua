local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Holding = false

-- === USTAWIENIA ===
_G.AimbotEnabled = true
_G.TeamCheck = false    
_G.FriendCheck = true   
_G.AimPart = "Head" 
_G.AutoShoot = true     
_G.FOVRadius = 150
_G.ShowESP = true

-- KONFIGURACJA CZCIONKI COMIC NEUE ANGULAR BOLD
local CustomFont = Font.new(
    "rbxasset://fonts/families/ComicNeueAngular.json", 
    Enum.FontWeight.Bold, 
    Enum.FontStyle.Normal
)

-- Funkcja sprawdzająca znajomych
local function IsFriend(Player)
    if _G.FriendCheck then return LocalPlayer:IsFriendsWith(Player.UserId) end
    return false
end

-- Raycast (ściany)
local function IsVisible(TargetPart)
    local Character = LocalPlayer.Character
    if not Character then return false end
    local Params = RaycastParams.new()
    Params.FilterDescendantsInstances = {Character, Camera}
    Params.FilterType = Enum.RaycastFilterType.Exclude
    local Result = workspace:Raycast(Camera.CFrame.Position, TargetPart.Position - Camera.CFrame.Position, Params)
    return not Result or Result.Instance:IsDescendantOf(TargetPart.Parent)
end

-- Pomocnicza funkcja do tworzenia napisów statystyk
local function CreateStatLabel(name, position, color, parent)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = UDim2.new(1, 0, 0.12, 0)
    label.Position = position
    label.BackgroundTransparency = 1
    
    -- Ustawienie czcionki przez FontFace (wymagane dla Comic Neue Angular Bold)
    label.FontFace = CustomFont
    
    label.TextColor3 = color
    label.TextScaled = true
    label.Parent = parent

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.5
    stroke.Color = Color3.new(0, 0, 0) -- Czarny obrys dla lepszej widoczności
    stroke.Parent = label
    
    return label
end

-- === SYSTEM ESP ===
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
        Billboard.ResetOnSpawn = false
        Billboard.Parent = root

        local Box = Instance.new("Frame")
        Box.Name = "HitboxFrame"
        Box.Size = UDim2.new(0.9, 0, 0.5, 0)
        Box.Position = UDim2.new(0.05, 0, 0.25, 0)
        Box.BackgroundTransparency = 1
        Box.Parent = Billboard

        local BoxStroke = Instance.new("UIStroke")
        BoxStroke.Thickness = 2
        BoxStroke.Color = IsFriend(Player) and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(255, 0, 0)
        BoxStroke.Parent = Box

        -- ETYKIETY (Comic Neue Angular Bold)
        local NameLabel = CreateStatLabel("NameLabel", UDim2.new(0, 0, 0.05, 0), Color3.new(1, 1, 1), Billboard)
        NameLabel.Text = Player.DisplayName

        local HPLabel = CreateStatLabel("HPLabel", UDim2.new(0, 0, 0.15, 0), Color3.new(0, 255, 0), Billboard)

        local WSLabel = CreateStatLabel("WSLabel", UDim2.new(0, 0, 0.75, 0), Color3.fromRGB(255, 165, 0), Billboard)
        local LevelLabel = CreateStatLabel("LevelLabel", UDim2.new(0, 0, 0.85, 0), Color3.fromRGB(0, 191, 255), Billboard)
        local EloLabel = CreateStatLabel("EloLabel", UDim2.new(0, 0, 0.95, 0), Color3.fromRGB(148, 0, 211), Billboard)

        local update
        update = RunService.Heartbeat:Connect(function()
            if not Character.Parent or not root.Parent or not hum.Parent then
                update:Disconnect()
                Billboard:Destroy()
                return
            end

            if hum.Health > 0 and _G.ShowESP then
                Billboard.Enabled = true
                
                HPLabel.Text = "HP: " .. math.floor(hum.Health)
                HPLabel.TextColor3 = Color3.fromHSV((hum.Health / hum.MaxHealth) * 0.35, 0.9, 1)

                local stats = Player:FindFirstChild("CustomLeaderstats")
                if stats then
                    local ws = stats:FindFirstChild("Win Streak")
                    local lvl = stats:FindFirstChild("Level")
                    local elo = stats:FindFirstChild("Current ELO")
                    
                    WSLabel.Text = "Win Streak: " .. (ws and tostring(ws.Value) or "0")
                    LevelLabel.Text = "Level: " .. (lvl and tostring(lvl.Value) or "0")
                    EloLabel.Text = "ELO: " .. (elo and tostring(elo.Value) or "0")
                end
                
                if IsVisible(Character:FindFirstChild("Head") or root) then
                    BoxStroke.Color = Color3.fromRGB(0, 255, 0)
                else
                    BoxStroke.Color = IsFriend(Player) and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(255, 0, 0)
                end
            else
                Billboard.Enabled = false
            end
        end)
    end

    Player.CharacterAdded:Connect(Setup)
    if Player.Character then task.spawn(Setup, Player.Character) end
end

-- Inicjalizacja
for _, v in pairs(Players:GetPlayers()) do
    if v ~= LocalPlayer then CreateESP(v) end
end
Players.PlayerAdded:Connect(CreateESP)

-- === AIMBOT LOGIC ===
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.new(1, 1, 1)
FOVCircle.Transparency = 0.6

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
    elseif Input.KeyCode == Enum.KeyCode.P then
        _G.AutoShoot = not _G.AutoShoot
    end
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
        if Target and Target.Character and Target.Character:FindFirstChild(_G.AimPart) then
            local Part = Target.Character[_G.AimPart]
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, Part.Position)
            
            if _G.AutoShoot and not IsFriend(Target) and IsVisible(Part) then
                if mouse1click then mouse1click()
                elseif mouse1press then 
                    mouse1press() task.wait() mouse1release() 
                end
            end
        end
    end
end)
