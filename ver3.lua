local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Holding = false

-- === USTAWIENIA ===
_G.AimbotEnabled = true
_G.AimPart = "Head" 
_G.FOVRadius = 150
local ForcedTarget = nil

-- CZCIONKA
local CustomFont = Font.new("rbxasset://fonts/families/ComicNeueAngular.json", Enum.FontWeight.Bold)

-- === UI SYSTEM ===
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "ExtremeInteractiveList"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Glówny kontener (przeciągalny)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 360, 0, 500)
MainFrame.Position = UDim2.new(1, -380, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
MainFrame.BackgroundTransparency = 0.15
MainFrame.Active = true
MainFrame.Draggable = true -- Możesz przesuwać menu
MainFrame.Parent = ScreenGui

local UICornerMain = Instance.new("UICorner", MainFrame)
UICornerMain.CornerRadius = UDim.new(0, 20)

local UIStrokeMain = Instance.new("UIStroke", MainFrame)
UIStrokeMain.Thickness = 2
UIStrokeMain.Color = Color3.fromRGB(60, 60, 70)

local Header = Instance.new("TextLabel")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundTransparency = 1
Header.Text = "TARGET SELECTOR"
Header.TextColor3 = Color3.fromRGB(255, 255, 255)
Header.FontFace = CustomFont
Header.TextSize = 22
Header.Parent = MainFrame

local Holder = Instance.new("ScrollingFrame")
Holder.Size = UDim2.new(1, -20, 1, -60)
Holder.Position = UDim2.new(0, 10, 0, 50)
Holder.BackgroundTransparency = 1
Holder.BorderSizePixel = 0
Holder.ScrollBarThickness = 2
Holder.CanvasSize = UDim2.new(0, 0, 0, 0)
Holder.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout", Holder)
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- FUNKCJA ANIMACJI
local function Tween(obj, info, prop)
    TweenService:Create(obj, TweenInfo.new(unpack(info)), prop):Play()
end

local function CreatePlayerEntry(player)
    local Entry = Instance.new("Frame")
    Entry.Size = UDim2.new(1, -10, 0, 110)
    Entry.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    Entry.BorderSizePixel = 0
    Entry.Active = true -- Umożliwia klikanie wewnątrz Scrollingu
    Entry.Parent = Holder
    
    local Corner = Instance.new("UICorner", Entry)
    Corner.CornerRadius = UDim.new(0, 12)
    
    -- Animacja wejścia (slide in)
    Entry.Position = UDim2.new(1, 0, 0, 0)
    Tween(Entry, {0.5, Enum.EasingStyle.Back}, {Position = UDim2.new(0, 0, 0, 0)})

    -- PFP
    local PFP = Instance.new("ImageLabel")
    PFP.Size = UDim2.new(0, 60, 0, 60)
    PFP.Position = UDim2.new(0, 10, 0, 10)
    PFP.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
    PFP.BackgroundTransparency = 1
    PFP.Parent = Entry
    Instance.new("UICorner", PFP).CornerRadius = UDim.new(1, 0)

    -- Name
    local NameL = Instance.new("TextLabel")
    NameL.Size = UDim2.new(1, -160, 0, 25)
    NameL.Position = UDim2.new(0, 80, 0, 10)
    NameL.BackgroundTransparency = 1
    NameL.Text = player.DisplayName
    NameL.TextColor3 = Color3.new(1, 1, 1)
    NameL.TextSize = 18
    NameL.FontFace = CustomFont
    NameL.TextXAlignment = Enum.TextXAlignment.Left
    NameL.Parent = Entry

    -- Staty
    local StatsL = Instance.new("TextLabel")
    StatsL.Size = UDim2.new(1, -160, 0, 60)
    StatsL.Position = UDim2.new(0, 80, 0, 35)
    StatsL.BackgroundTransparency = 1
    StatsL.RichText = true
    StatsL.FontFace = CustomFont
    StatsL.TextXAlignment = Enum.TextXAlignment.Left
    StatsL.Parent = Entry

    -- PRZYCISKI
    local function CreateButton(text, pos, color)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 75, 0, 35)
        b.Position = pos
        b.BackgroundColor3 = color
        b.Text = text
        b.FontFace = CustomFont
        b.TextColor3 = Color3.new(1, 1, 1)
        b.TextSize = 14
        b.AutoButtonColor = true
        b.Parent = Entry
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        
        b.MouseEnter:Connect(function() Tween(b, {0.2}, {Size = UDim2.new(0, 80, 0, 40)}) end)
        b.MouseLeave:Connect(function() Tween(b, {0.2}, {Size = UDim2.new(0, 75, 0, 35)}) end)
        
        return b
    end

    local btnAim = CreateButton("🎯 AIM", UDim2.new(1, -85, 0, 15), Color3.fromRGB(200, 40, 40))
    local btnView = CreateButton("👁️ VIEW", UDim2.new(1, -85, 0, 60), Color3.fromRGB(40, 120, 200))

    -- LOGIKA
    btnAim.MouseButton1Click:Connect(function()
        if ForcedTarget == player then
            ForcedTarget = nil
            btnAim.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
            btnAim.Text = "🎯 AIM"
        else
            ForcedTarget = player
            btnAim.BackgroundColor3 = Color3.fromRGB(40, 200, 40)
            btnAim.Text = "✅ LOCK"
        end
    end)

    btnView.MouseButton1Click:Connect(function()
        if Camera.CameraSubject == player.Character:FindFirstChild("Humanoid") then
            Camera.CameraSubject = LocalPlayer.Character.Humanoid
            btnView.Text = "👁️ VIEW"
        elseif player.Character and player.Character:FindFirstChild("Humanoid") then
            Camera.CameraSubject = player.Character.Humanoid
            btnView.Text = "🔙 BACK"
        end
    end)

    -- Live Update Loop
    task.spawn(function()
        while Entry.Parent do
            local hum = player.Character and player.Character:FindFirstChild("Humanoid")
            local hp = hum and math.floor(hum.Health) or 0
            local hpHex = Color3.fromHSV((hp/100)*0.35, 0.9, 1):ToHex()
            local s = player:FindFirstChild("CustomLeaderstats")
            local ws = s and s:FindFirstChild("Win Streak") and s["Win Streak"].Value or 0
            local lvl = s and s:FindFirstChild("Level") and s.Level.Value or 0
            local elo = s and s:FindFirstChild("Current ELO") and s["Current ELO"].Value or 0

            StatsL.Text = string.format("<font color='#%s'>%d❤️</font> <font color='#ffa500'>%s🔥</font>\n<font color='#00bfff'>%s⭐</font> <font color='#9400d3'>%s📊</font>", hpHex, hp, ws, lvl, elo)
            task.wait(0.5)
        end
    end)
end

local function Refresh()
    for _, v in pairs(Holder:GetChildren()) do if v:IsA("Frame") then v:Destroy() end end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then CreatePlayerEntry(p) end
    end
    Holder.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 20)
end

Players.PlayerAdded:Connect(Refresh)
Players.PlayerRemoving:Connect(Refresh)
Refresh()

-- === AIMBOT CORE ===
RunService.RenderStepped:Connect(function()
    if (Holding or ForcedTarget) and _G.AimbotEnabled then
        local T = ForcedTarget
        if not T then
            local Mouse = UserInputService:GetMouseLocation()
            local Min = _G.FOVRadius
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(_G.AimPart) then
                    local H = v.Character:FindFirstChild("Humanoid")
                    if H and H.Health > 0 then
                        local Pos, On = Camera:WorldToScreenPoint(v.Character[_G.AimPart].Position)
                        if On then
                            local D = (Vector2.new(Pos.X, Pos.Y) - Mouse).Magnitude
                            if D < Min then T = v Min = D end
                        end
                    end
                end
            end
        end
        if T and T.Character and T.Character:FindFirstChild(_G.AimPart) then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, T.Character[_G.AimPart].Position)
        end
    end
end)

UserInputService.InputBegan:Connect(function(i, p) if not p and i.UserInputType == Enum.UserInputType.MouseButton2 then Holding = true end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then Holding = false end end)
