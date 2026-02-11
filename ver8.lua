local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local LocalPlayer = Players.LocalPlayer
local Holding = false

-- === OPTYMALIZACJA I CZYSZCZENIE ===
local GuisToDelete = {"PositionHUD", "TeleportGui", "RadialMenuGui", "CustomPlayerList", "GlobalMessageGui", "GlobalNotification"}
for _, guiName in pairs(GuisToDelete) do
    if LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild(guiName) then
        LocalPlayer.PlayerGui[guiName]:Destroy()
    end
end

-- === USTAWIENIA ===
_G.AimbotEnabled = true
_G.TeamCheck = false    
_G.FriendCheck = true   
_G.AimPart = "Head" 
_G.AutoShoot = true      
_G.FOVRadius = 150
_G.ShowESP = true
_G.ShowSnaplines = true 
_G.Noclip = false
_G.Fly = false
_G.SpeedEnabled = false 
_G.SpeedValue = 100     
_G.TpMode = "Goto" 
_G.Invisible = false
local FlySpeed = 75 
local SpawnPos = Vector3.new(103.3, -679.5, 1181.8) 

-- === KONFIGURACJA CZCIONKI ===
local CustomFont = Font.new(
    "rbxassetid://12187365977", 
    Enum.FontWeight.Medium, 
    Enum.FontStyle.Normal
)

-- === OPTYMALIZACJA RAYCAST ===
local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude
RayParams.IgnoreWater = true

-- === HEALTH HACK (1000 HP) ===
task.spawn(function()
    while true do
        pcall(function()
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                if hum.MaxHealth ~= 1000 then
                    hum.MaxHealth = 1000
                    hum.Health = 1000
                end
            end
        end)
        task.wait(1)
    end
end)

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

-- === GUI TELEPORTACJI ===
local TpGui = Instance.new("ScreenGui")
TpGui.Name = "TeleportGui"
TpGui.ResetOnSpawn = false
TpGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
TpGui.Enabled = false 

local TpMainFrame = Instance.new("Frame", TpGui)
TpMainFrame.Size = UDim2.new(0, 250, 0, 400)
TpMainFrame.Position = UDim2.new(0.5, -125, 0.5, -200)
TpMainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TpMainFrame.BorderSizePixel = 2
TpMainFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)

local TpTitle = Instance.new("TextLabel", TpMainFrame)
TpTitle.Size = UDim2.new(1, 0, 0, 30)
TpTitle.BackgroundTransparency = 1
TpTitle.Text = "MENU TELEPORTACJI"
TpTitle.TextColor3 = Color3.new(1, 1, 1)
TpTitle.FontFace = CustomFont
TpTitle.TextSize = 18

local CloseTpBtn = Instance.new("TextButton", TpMainFrame)
CloseTpBtn.Size = UDim2.new(0, 20, 0, 20)
CloseTpBtn.Position = UDim2.new(1, -25, 0, 5)
CloseTpBtn.Text = "X"
CloseTpBtn.TextColor3 = Color3.new(1, 0, 0)
CloseTpBtn.BackgroundColor3 = Color3.new(0, 0, 0)
CloseTpBtn.MouseButton1Click:Connect(function()
    TpGui.Enabled = false
end)

local FriendCheckBtn = Instance.new("TextButton", TpMainFrame)
FriendCheckBtn.Size = UDim2.new(1, -10, 0, 25)
FriendCheckBtn.Position = UDim2.new(0, 5, 0, 30)
FriendCheckBtn.Text = "FRIEND CHECK: ON (Nie strzela)"
FriendCheckBtn.BackgroundColor3 = Color3.fromRGB(0, 50, 0)
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

local TpModeBtn = Instance.new("TextButton", TpMainFrame)
TpModeBtn.Size = UDim2.new(1, -10, 0, 25)
TpModeBtn.Position = UDim2.new(0, 5, 0, 60)
TpModeBtn.Text = "MODE: ME -> THEM (GOTO)"
TpModeBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
TpModeBtn.TextColor3 = Color3.new(1, 1, 1)
TpModeBtn.FontFace = CustomFont
TpModeBtn.MouseButton1Click:Connect(function()
    if _G.TpMode == "Goto" then
        _G.TpMode = "Bring"
        TpModeBtn.Text = "MODE: THEM -> ME (BRING)"
        TpModeBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
    else
        _G.TpMode = "Goto"
        TpModeBtn.Text = "MODE: ME -> THEM (GOTO)"
        TpModeBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
    end
end)

local TpScroll = Instance.new("ScrollingFrame", TpMainFrame)
TpScroll.Size = UDim2.new(1, -10, 1, -95)
TpScroll.Position = UDim2.new(0, 5, 0, 90)
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
                    if _G.TpMode == "Goto" then
                        myChar.HumanoidRootPart.CFrame = targetChar.HumanoidRootPart.CFrame * CFrame.new(0, 2, 3)
                    elseif _G.TpMode == "Bring" then
                        targetChar.HumanoidRootPart.CFrame = myChar.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
                    end
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

-- === SYSTEM WIADOMOŚCI GLOBALNEJ (NOWE) ===
local GlobalMsgGui = Instance.new("ScreenGui")
GlobalMsgGui.Name = "GlobalMessageGui"
GlobalMsgGui.ResetOnSpawn = false
GlobalMsgGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
GlobalMsgGui.Enabled = false

local GlobalFrame = Instance.new("Frame", GlobalMsgGui)
GlobalFrame.Size = UDim2.new(0, 400, 0, 110)
GlobalFrame.Position = UDim2.new(0.5, -200, 0.3, 0)
GlobalFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
GlobalFrame.BorderSizePixel = 2
GlobalFrame.BorderColor3 = Color3.fromRGB(255, 0, 255)

local GlobalTitle = Instance.new("TextLabel", GlobalFrame)
GlobalTitle.Text = "WPISZ WIADOMOŚĆ"
GlobalTitle.Size = UDim2.new(1, 0, 0, 30)
GlobalTitle.TextColor3 = Color3.new(1, 1, 1)
GlobalTitle.BackgroundTransparency = 1
GlobalTitle.FontFace = CustomFont

local GlobalDesc = Instance.new("TextLabel", GlobalFrame)
GlobalDesc.Text = "(Wciśnij Enter aby wysłać na czat i pokazać GUI)"
GlobalDesc.Size = UDim2.new(1, 0, 0, 20)
GlobalDesc.Position = UDim2.new(0, 0, 0, 25)
GlobalDesc.TextColor3 = Color3.fromRGB(150, 150, 150)
GlobalDesc.BackgroundTransparency = 1
GlobalDesc.FontFace = CustomFont
GlobalDesc.TextSize = 12

local GlobalInput = Instance.new("TextBox", GlobalFrame)
GlobalInput.Size = UDim2.new(0.9, 0, 0, 40)
GlobalInput.Position = UDim2.new(0.05, 0, 0.5, 0)
GlobalInput.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
GlobalInput.TextColor3 = Color3.new(1, 1, 1)
GlobalInput.Text = ""
GlobalInput.PlaceholderText = "Tu wpisz tekst..."
GlobalInput.FontFace = CustomFont

-- Funkcja do wysyłania na czat (Obsługuje stary i nowy czat)
local function SendChatMessage(text)
    local Success = false
    -- Próba 1: Nowy TextChatService
    if TextChatService and TextChatService.TextChannels then
        local General = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if General then
            General:SendAsync(text)
            Success = true
        end
    end
    -- Próba 2: Stary ReplicatedStorage
    if not Success then
        local ChatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        local SayMsg = ChatEvents and ChatEvents:FindFirstChild("SayMessageRequest")
        if SayMsg then
            SayMsg:FireServer(text, "All")
            Success = true
        end
    end
end

-- Funkcja wyświetlająca powiadomienie (Symulacja dla Ciebie)
local function DisplayNotification(text)
    -- Wyświetl GUI lokalnie
    local NotifGui = Instance.new("ScreenGui")
    NotifGui.Name = "GlobalNotification"
    NotifGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local Banner = Instance.new("Frame", NotifGui)
    Banner.Size = UDim2.new(0, 400, 0, 80)
    Banner.Position = UDim2.new(0.5, -200, -0.2, 0) 
    Banner.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    Banner.BorderSizePixel = 2
    Banner.BorderColor3 = Color3.new(1, 1, 1)
    
    local PFP = Instance.new("ImageLabel", Banner)
    PFP.Size = UDim2.new(0, 60, 0, 60)
    PFP.Position = UDim2.new(0, 10, 0.5, -30)
    PFP.BackgroundTransparency = 1
    PFP.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
    
    local NameLbl = Instance.new("TextLabel", Banner)
    NameLbl.Text = LocalPlayer.DisplayName
    NameLbl.Size = UDim2.new(1, -80, 0, 20)
    NameLbl.Position = UDim2.new(0, 80, 0, 10)
    NameLbl.TextColor3 = Color3.fromRGB(255, 200, 0)
    NameLbl.BackgroundTransparency = 1
    NameLbl.FontFace = CustomFont
    NameLbl.TextXAlignment = Enum.TextXAlignment.Left
    NameLbl.TextSize = 18
    
    local MsgLbl = Instance.new("TextLabel", Banner)
    MsgLbl.Text = text
    MsgLbl.Size = UDim2.new(1, -80, 0, 40)
    MsgLbl.Position = UDim2.new(0, 80, 0, 30)
    MsgLbl.TextColor3 = Color3.new(1, 1, 1)
    MsgLbl.BackgroundTransparency = 1
    MsgLbl.FontFace = CustomFont
    MsgLbl.TextXAlignment = Enum.TextXAlignment.Left
    MsgLbl.TextScaled = true
    
    -- Animacja
    TweenService:Create(Banner, TweenInfo.new(0.5, Enum.EasingStyle.Bounce), {Position = UDim2.new(0.5, -200, 0.1, 0)}):Play()
    
    -- Wyślij na czat
    SendChatMessage(text)
    
    -- Usuń po czasie
    task.delay(5, function()
        if Banner then
            TweenService:Create(Banner, TweenInfo.new(0.5), {Position = UDim2.new(0.5, -200, -0.2, 0)}):Play()
            task.wait(0.5)
            NotifGui:Destroy()
        end
    end)
end

GlobalInput.FocusLost:Connect(function(enterPressed)
    if enterPressed and GlobalInput.Text ~= "" then
        DisplayNotification(GlobalInput.Text)
        GlobalInput.Text = ""
        GlobalMsgGui.Enabled = false
    end
end)

-- === SYSTEM RADIAL MENU (ZAKTUALIZOWANY) ===
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
    Container.Size = UDim2.new(0, 130, 0, 50)
    local rad = math.rad(angle)
    Container.Position = UDim2.new(0.5, math.cos(rad) * 190 - 65, 0.5, math.sin(rad) * 190 - 25)
    Container.BackgroundTransparency = 1

    local Option = Instance.new("TextLabel", Container)
    Option.Size = UDim2.new(1, 0, 1, 0)
    Option.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Option.BackgroundTransparency = 0.2
    Option.Text = name
    Option.TextColor3 = Color3.new(1, 1, 1)
    Option.FontFace = CustomFont
    Option.TextSize = 12
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

-- 10 opcji (36 stopni)
local NoclipBtn = CreateMenuOption("NOCLIP: OFF", 0, Color3.fromRGB(255, 80, 80), "Noclip")
local FlyBtn = CreateMenuOption("FLY: OFF", 36, Color3.fromRGB(80, 255, 80), "Fly")
local AimBtn = CreateMenuOption("AIM: ON", 72, Color3.fromRGB(80, 80, 255), "Aim")
local EspBtn = CreateMenuOption("ESP: ON", 108, Color3.fromRGB(255, 255, 80), "Esp")
local SnapBtn = CreateMenuOption("SNAPLINES: ON", 144, Color3.fromRGB(255, 150, 0), "Snaplines")
local SpeedBtn = CreateMenuOption("SPEED: OFF", 180, Color3.fromRGB(0, 255, 255), "Speed")    
local SpawnBtn = CreateMenuOption("TP: SPAWN", 216, Color3.fromRGB(255, 255, 255), "Spawn")
local TpMenuBtn = CreateMenuOption("TP MENU", 252, Color3.fromRGB(255, 0, 255), "TpMenu")
local InvisBtn = CreateMenuOption("INVISIBLE: OFF", 288, Color3.fromRGB(100, 100, 100), "Invisible")
local MsgBtn = CreateMenuOption("GLOBAL MSG", 324, Color3.fromRGB(255, 0, 150), "GlobalMsg")

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
            elseif name == "Snaplines" then
                _G.ShowSnaplines = not _G.ShowSnaplines
                HoveredButton.Text = "SNAPLINES: " .. (_G.ShowSnaplines and "ON" or "OFF")
            elseif name == "Speed" then
                _G.SpeedEnabled = not _G.SpeedEnabled
                HoveredButton.Text = "SPEED: " .. (_G.SpeedEnabled and "ON" or "OFF")
            elseif name == "Spawn" then
                local char = LocalPlayer.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                if root then root.CFrame = CFrame.new(SpawnPos) end
            elseif name == "TpMenu" then
                TpGui.Enabled = not TpGui.Enabled
            elseif name == "Invisible" then
                _G.Invisible = not _G.Invisible
                HoveredButton.Text = "INVISIBLE: " .. (_G.Invisible and "ON" or "OFF")
            elseif name == "GlobalMsg" then
                GlobalMsgGui.Enabled = true
            end
        end
        RadialFrame.Visible = false
        if not TpGui.Enabled and not GlobalMsgGui.Enabled then
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
    end
end)

-- === LOGIKA PERSYSTENCJI, NOCLIP, SPEEDHACK, INVISIBLE ===
RunService.Stepped:Connect(function()
    if not LocalPlayer.Character then return end

    if _G.Noclip then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
    
    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        if _G.SpeedEnabled then
            hum.WalkSpeed = _G.SpeedValue
        else
            if hum.WalkSpeed == _G.SpeedValue then hum.WalkSpeed = 16 end
        end
    end

    -- Invisible Logic
    if _G.Invisible then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 1
            elseif part:IsA("Decal") or part:IsA("Texture") then
                part.Transparency = 1
            end
        end
        local head = LocalPlayer.Character:FindFirstChild("Head")
        if head and head:FindFirstChild("BillboardGui") then
            head.BillboardGui.Enabled = false
        end
    elseif not _G.Invisible and not _G.Noclip then
        -- Opcjonalne: jednorazowe przywrócenie (działa w loopie poniżej)
    end
end)

local lastInvis = _G.Invisible
RunService.Heartbeat:Connect(function()
    if lastInvis ~= _G.Invisible then
        if not _G.Invisible and LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.Transparency = 0
                elseif part:IsA("Decal") or part:IsA("Texture") then
                    part.Transparency = 0
                end
            end
            local head = LocalPlayer.Character:FindFirstChild("Head")
            if head then
                for _, v in pairs(head:GetChildren()) do
                    if v:IsA("BillboardGui") then v.Enabled = true end
                end
            end
        end
        lastInvis = _G.Invisible
    end
end)

-- === SYSTEM LATANIA ===
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
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
        bv.Velocity = dir.Magnitude > 0 and dir.Unit * FlySpeed or Vector3.new(0, 0, 0)
    else
        if root:FindFirstChild("FlyVelocity") then root.FlyVelocity:Destroy() end
        if root:FindFirstChild("FlyGyro") then root.FlyGyro:Destroy() end
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

-- === ESP I SNAPLINES LOGIKA ===
local function IsFriend(Player)
    if _G.FriendCheck then return LocalPlayer:IsFriendsWith(Player.UserId) end
    return false
end

local function IsVisible(TargetPart)
    local Character = LocalPlayer.Character
    if not Character then return false end
    
    RayParams.FilterDescendantsInstances = {Character, Camera}
    
    local Result = workspace:Raycast(Camera.CFrame.Position, TargetPart.Position - Camera.CFrame.Position, RayParams)
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
    -- Snapline dla gracza
    local SnapLine = Drawing.new("Line")
    SnapLine.Thickness = 1
    SnapLine.Transparency = 1
    SnapLine.Color = Color3.new(1, 1, 1)

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
            if not Character.Parent or not root.Parent then 
                Billboard:Destroy() 
                SnapLine.Visible = false
                return 
            end
            
            -- Logika Snaplines
            if _G.ShowSnaplines and hum.Health > 0 then
                local Vector, OnScreen = Camera:WorldToViewportPoint(root.Position)
                if OnScreen then
                    SnapLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y) -- Od środka dołu ekranu
                    SnapLine.To = Vector2.new(Vector.X, Vector.Y)
                    SnapLine.Visible = true
                    SnapLine.Color = IsVisible(root) and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
                else
                    SnapLine.Visible = false
                end
            else
                SnapLine.Visible = false
            end

            -- Logika ESP
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

-- === TARGET HITBOX (SHOOTING RANGE) ===
task.spawn(function()
    local FolderName = "ShootingRangeEntities"
    local TargetName = "Target"
    local TargetImage = "rbxassetid://14580701813"
    local TargetRot = 45

    while true do
        pcall(function()
            local folder = workspace:FindFirstChild(FolderName)
            if folder then
                for _, model in pairs(folder:GetChildren()) do
                    if model.Name == TargetName then
                        local root = model:FindFirstChild("HumanoidRootPart")
                        if root then
                            local bg = root:FindFirstChild("BillboardGui")
                            local img = bg and bg:FindFirstChild("ImageLabel")

                            if img and img.Image == TargetImage and math.abs(img.Rotation - TargetRot) < 1 then
                                if not root:FindFirstChild("TargetHitbox") then
                                    local box = Instance.new("BoxHandleAdornment")
                                    box.Name = "TargetHitbox"
                                    box.Adornee = root
                                    box.Size = root.Size + Vector3.new(0.5, 0.5, 0.5) 
                                    box.Color3 = Color3.fromRGB(255, 0, 0)
                                    box.Transparency = 0.4
                                    box.AlwaysOnTop = true
                                    box.ZIndex = 10
                                    box.Parent = root
                                end
                            else
                                local existing = root:FindFirstChild("TargetHitbox")
                                if existing then existing:Destroy() end
                            end
                        end
                    end
                end
            end
        end)
        task.wait(0.5) 
    end
end)

-- === AIMBOT LOGIKA ===
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

RunService.RenderStepped:Connect(function()
    FOVCircle.Visible = _G.AimbotEnabled
    FOVCircle.Position = UserInputService:GetMouseLocation()
    FOVCircle.Radius = _G.FOVRadius
    
    local isAiming = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    
    if isAiming and _G.AimbotEnabled then
        local Target = GetClosestPlayer()
        if Target and Target.Character then
            local Part = Target.Character[_G.AimPart]
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, Part.Position)
            if _G.AutoShoot and IsVisible(Part) then
                if not (_G.FriendCheck and IsFriend(Target)) then
                      if mouse1click then 
                          mouse1click() 
                      elseif mouse_click then
                          mouse_click()
                      end
                end
            end
        end
    end
end)
