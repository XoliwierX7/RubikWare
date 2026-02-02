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
_G.ShowESP = true
local ForcedTarget = nil

-- CZCIONKA
local CustomFont = Font.new("rbxasset://fonts/families/ComicNeueAngular.json", Enum.FontWeight.Bold)

-- === UI SYSTEM ===
local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.Name = "ModernPlayerList"

local MainFrame = Instance.new("ScrollingFrame")
MainFrame.Size = UDim2.new(0, 350, 0, 500)
MainFrame.Position = UDim2.new(1, -360, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BackgroundTransparency = 0.2
MainFrame.BorderSizePixel = 0
MainFrame.ScrollBarThickness = 2
MainFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
MainFrame.Parent = ScreenGui

local UICornerMain = Instance.new("UICorner", MainFrame)
UICornerMain.CornerRadius = UDim.new(0, 15)

local UIListLayout = Instance.new("UIListLayout", MainFrame)
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Nagłówek Listy
local Header = Instance.new("TextLabel")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundTransparency = 1
Header.Text = "ACTIVE TARGETS"
Header.TextColor3 = Color3.new(1, 1, 1)
Header.FontFace = CustomFont
Header.TextSize = 20
Header.Parent = MainFrame

-- FUNKCJA TWEEN (ANIMACJA)
local function AnimateUI(obj, properties)
    TweenService:Create(obj, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties):Play()
end

local function RefreshList()
    for _, child in pairs(MainFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local Entry = Instance.new("Frame")
        Entry.Size = UDim2.new(0.95, 0, 0, 100)
        Entry.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        Entry.BorderSizePixel = 0
        Entry.Parent = MainFrame
        
        local Corner = Instance.new("UICorner", Entry)
        Corner.CornerRadius = UDim.new(0, 10)

        -- PFP
        local PFP = Instance.new("ImageLabel")
        PFP.Size = UDim2.new(0, 60, 0, 60)
        PFP.Position = UDim2.new(0, 10, 0, 10)
        PFP.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
        PFP.BackgroundTransparency = 1
        PFP.Parent = Entry
        Instance.new("UICorner", PFP).CornerRadius = UDim.new(1, 0)

        -- Name
        local NameLabel = Instance.new("TextLabel")
        NameLabel.Size = UDim2.new(1, -150, 0, 25)
        NameLabel.Position = UDim2.new(0, 80, 0, 10)
        NameLabel.BackgroundTransparency = 1
        NameLabel.Text = player.DisplayName
        NameLabel.TextColor3 = Color3.new(1, 1, 1)
        NameLabel.TextSize = 16
        NameLabel.FontFace = CustomFont
        NameLabel.TextXAlignment = Enum.TextXAlignment.Left
        NameLabel.Parent = Entry

        -- Stats
        local StatsLabel = Instance.new("TextLabel")
        StatsLabel.Size = UDim2.new(1, -150, 0, 40)
        StatsLabel.Position = UDim2.new(0, 80, 0, 30)
        StatsLabel.BackgroundTransparency = 1
        StatsLabel.RichText = true
        StatsLabel.FontFace = CustomFont
        StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
        StatsLabel.Parent = Entry

        -- PRZYCISKI (Prawa strona)
        local btnAim = Instance.new("TextButton")
        btnAim.Size = UDim2.new(0, 60, 0, 30)
        btnAim.Position = UDim2.new(1, -70, 0, 15)
        btnAim.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
        btnAim.Text = "🎯 AIM"
        btnAim.FontFace = CustomFont
        btnAim.TextColor3 = Color3.new(1, 1, 1)
        btnAim.Parent = Entry
        Instance.new("UICorner", btnAim)

        local btnView = Instance.new("TextButton")
        btnView.Size = UDim2.new(0, 60, 0, 30)
        btnView.Position = UDim2.new(1, -70, 0, 55)
        btnView.BackgroundColor3 = Color3.fromRGB(50, 150, 255)
        btnView.Text = "👁️ VIEW"
        btnView.FontFace = CustomFont
        btnView.TextColor3 = Color3.new(1, 1, 1)
        btnView.Parent = Entry
        Instance.new("UICorner", btnView)

        -- LOGIKA PRZYCISKÓW
        btnAim.MouseButton1Click:Connect(function()
            if ForcedTarget == player then ForcedTarget = nil btnAim.Text = "🎯 AIM" else ForcedTarget = player btnAim.Text = "✅ LOCK" end
        end)

        btnView.MouseButton1Click:Connect(function()
            if Camera.CameraSubject == player.Character:FindFirstChild("Humanoid") then
                Camera.CameraSubject = LocalPlayer.Character.Humanoid
                btnView.Text = "👁️ VIEW"
            else
                Camera.CameraSubject = player.Character:FindFirstChild("Humanoid")
                btnView.Text = "🔙 BACK"
            end
        end)

        -- HOVER ANIMATION
        Entry.MouseEnter:Connect(function() AnimateUI(Entry, {BackgroundColor3 = Color3.fromRGB(50, 50, 50)}) end)
        Entry.MouseLeave:Connect(function() AnimateUI(Entry, {BackgroundColor3 = Color3.fromRGB(30, 30, 30)}) end)

        -- LIVE UPDATE
        task.spawn(function()
            while Entry.Parent do
                local hum = player.Character and player.Character:FindFirstChild("Humanoid")
                local hp = hum and math.floor(hum.Health) or 0
                local hpCol = Color3.fromHSV((hp/100)*0.35, 0.9, 1):ToHex()
                local stats = player:FindFirstChild("CustomLeaderstats")
                local ws = stats and stats:FindFirstChild("Win Streak") and stats["Win Streak"].Value or 0
                local lvl = stats and stats:FindFirstChild("Level") and stats.Level.Value or 0
                local elo = stats and stats:FindFirstChild("Current ELO") and stats["Current ELO"].Value or 0

                StatsLabel.Text = string.format("<font color='#%s'>%d❤️</font> <font color='#ffa500'>%s🔥</font>\n<font color='#00bfff'>%s⭐</font> <font color='#9400d3'>%s📊</font>", hpCol, hp, ws, lvl, elo)
                task.wait(0.5)
            end
        end)
    end
    MainFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 50)
end

Players.PlayerAdded:Connect(RefreshList)
Players.PlayerRemoving:Connect(RefreshList)
task.spawn(RefreshList)

-- === AIMBOT LOGIC (Z UWZGLĘDNIENIEM PRZYCISKU LOCK) ===
RunService.RenderStepped:Connect(function()
    if (Holding or ForcedTarget) and _G.AimbotEnabled then
        local Target = ForcedTarget or nil
        
        if not Target then -- Standardowy Aimbot jeśli nie ma Locka
            local MaxDist = _G.FOVRadius
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild(_G.AimPart) then
                    local Hum = v.Character:FindFirstChild("Humanoid")
                    if Hum and Hum.Health > 0 then
                        local Point, OnScreen = Camera:WorldToScreenPoint(v.Character[_G.AimPart].Position)
                        if OnScreen then
                            local Dist = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(Point.X, Point.Y)).Magnitude
                            if Dist < MaxDist then Target = v MaxDist = Dist end
                        end
                    end
                end
            end
        end

        if Target and Target.Character and Target.Character:FindFirstChild(_G.AimPart) then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, Target.Character[_G.AimPart].Position)
        end
    end
end)

-- Obsługa myszki
UserInputService.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then Holding = true end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then Holding = false end end)
