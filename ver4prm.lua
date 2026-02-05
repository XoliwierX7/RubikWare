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
local FlySpeed = 50

-- KONFIGURACJA CZCIONKI
local CustomFont = Font.new(
    "rbxasset://fonts/families/ComicNeueAngular.json", 
    Enum.FontWeight.Bold, 
    Enum.FontStyle.Normal
)

-- === SYSTEM RADIAL MENU (DETEKCJA POZYCJI) ===
local RadialGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
RadialGui.Name = "RadialMenuGui"
RadialGui.IgnoreGuiInset = true

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
    
    local Corner = Instance.new("UICorner", Option)
    Corner.CornerRadius = UDim.new(0, 12)
    
    local Stroke = Instance.new("UIStroke", Option)
    Stroke.Thickness = 3
    Stroke.Color = color

    table.insert(MenuButtons, {Gui = Option, Color = color})
    return Option
end

local NoclipBtn = CreateMenuOption("NOCLIP: OFF", 0, Color3.fromRGB(255, 80, 80), "Noclip")
local FlyBtn = CreateMenuOption("FLY: OFF", 90, Color3.fromRGB(80, 255, 80), "Fly")
local AimBtn = CreateMenuOption("AIM: ON", 180, Color3.fromRGB(80, 80, 255), "Aim")
local EspBtn = CreateMenuOption("ESP: ON", 270, Color3.fromRGB(255, 255, 80), "Esp")

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

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.G then
        RadialFrame.Visible = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.G then
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
        end
        RadialFrame.Visible = false
    end
end)

RunService.RenderStepped:Connect(function()
    if RadialFrame.Visible then
        local Hovered = GetButtonUnderMouse()
        for _, data in pairs(MenuButtons) do
            if data.Gui == Hovered then
                data.Gui.BackgroundColor3 = data.Color
                data.Gui.TextColor3 = Color3.new(0, 0, 0)
            else
                data.Gui.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
                data.Gui.TextColor3 = Color3.new(1, 1, 1)
            end
        end
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

-- === LOGIKA FLY (ZAKTUALIZOWANE STEROWANIE) ===
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
            
            -- Przód / Tył
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
            
            -- Lewo / Prawo
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
            
            -- Góra (Spacja) / Dół (Shift)
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0, 1, 0) end
            
            bv.Velocity = dir.Unit * FlySpeed
            if dir.Magnitude == 0 then bv.Velocity = Vector3.new(0,0,0) end
        else
            bv.Parent = nil
            bg.Parent = nil
        end
    end
end)

-- [Sekcja ESP i PlayerList pozostaje bez zmian jak w poprzednim kodzie]
