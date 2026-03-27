--[[
   
               AXIA UI LIBRARY v1.0            
 --                 by never6x
   
    
    Использование:
    local Axia = loadstring(game:HttpGet("..."))()
    local Window = Axia:CreateWindow({ Title = "My Script", Subtitle = "by me" })
    local Tab = Window:AddTab("Combat")
    local Section = Tab:AddSection("Settings")
    Section:AddToggle({ Name = "Aimbot", Flag = "aimbot", Callback = function(v) end })
    Section:AddSlider({ Name = "FOV", Min = 0, Max = 360, Default = 90, Flag = "fov", Callback = function(v) end })
    Section:AddDropdown({ Name = "Bone", Items = {"Head","Torso"}, Default = "Head", Flag = "bone", Callback = function(v) end })
    Section:AddButton({ Name = "Execute", Callback = function() end })
    Section:AddTextbox({ Name = "Player", Default = "", Flag = "player", Callback = function(v) end })
    Section:AddKeybind({ Name = "Toggle Menu", Default = Enum.KeyCode.RightShift, Flag = "menutoggle", Callback = function(v) end })
    Section:AddColorPicker({ Name = "Color", Default = Color3.fromRGB(180, 0, 255), Flag = "clr", Callback = function(v) end })
    Section:AddLabel("Это метка")
]]

-- ───── SERVICES ─────
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui        = game:GetService("CoreGui")

local LocalPlayer   = Players.LocalPlayer
local Mouse         = LocalPlayer:GetMouse()
local Camera        = workspace.CurrentCamera

-- ───── LIBRARY TABLE ─────
local Axia = {}
Axia.__index = Axia
Axia.Flags   = {}
Axia.Connections = {}
Axia.Theme = {
    -- Фоны
    Background      = Color3.fromRGB(10,  8, 18),
    BackgroundLight = Color3.fromRGB(18, 14, 32),
    Surface         = Color3.fromRGB(22, 17, 40),
    SurfaceLight    = Color3.fromRGB(30, 22, 55),
    Border          = Color3.fromRGB(80, 30, 160),
    BorderGlow      = Color3.fromRGB(140, 50, 255),

    -- Акценты (неон)
    Accent          = Color3.fromRGB(160, 50, 255),
    AccentBright    = Color3.fromRGB(200, 90, 255),
    AccentDim       = Color3.fromRGB(100, 30, 180),
    NeonGlow        = Color3.fromRGB(180, 70, 255),
    
    -- Розово-фиолетовый highlight
    Highlight       = Color3.fromRGB(220, 120, 255),
    HighlightDim    = Color3.fromRGB(140, 60, 200),

    -- Текст
    TextBright      = Color3.fromRGB(240, 230, 255),
    TextNormal      = Color3.fromRGB(185, 170, 215),
    TextDim         = Color3.fromRGB(110, 95, 145),
    TextAccent      = Color3.fromRGB(200, 150, 255),

    -- Состояния
    Success         = Color3.fromRGB(100, 255, 160),
    Warning         = Color3.fromRGB(255, 200, 80),
    Danger          = Color3.fromRGB(255, 80, 100),

    -- Слайдер / тогл
    ToggleOff       = Color3.fromRGB(50, 38, 80),
    ToggleOn        = Color3.fromRGB(160, 50, 255),
    SliderFill      = Color3.fromRGB(150, 40, 240),
    SliderBack      = Color3.fromRGB(35, 25, 60),
}

-- ───── УТИЛИТЫ ─────
local function Tween(obj, props, duration, style, dir)
    style = style or Enum.EasingStyle.Quart
    dir   = dir   or Enum.EasingDirection.Out
    local ti = TweenInfo.new(duration or 0.25, style, dir)
    return TweenService:Create(obj, ti, props)
end

local function MakePadding(frame, top, bottom, left, right)
    local p = Instance.new("UIPadding", frame)
    p.PaddingTop    = UDim.new(0, top    or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft   = UDim.new(0, left   or 0)
    p.PaddingRight  = UDim.new(0, right  or 0)
    return p
end

local function MakeCorner(frame, radius)
    local c = Instance.new("UICorner", frame)
    c.CornerRadius = UDim.new(0, radius or 6)
    return c
end

local function MakeStroke(frame, color, thickness, transparency)
    local s = Instance.new("UIStroke", frame)
    s.Color       = color or Color3.fromRGB(100, 40, 200)
    s.Thickness   = thickness or 1
    s.Transparency = transparency or 0
    return s
end

local function MakeGradient(frame, color0, color1, rotation)
    local g = Instance.new("UIGradient", frame)
    g.Color    = ColorSequence.new(color0, color1)
    g.Rotation = rotation or 90
    return g
end

local function MakeListLayout(frame, direction, padding, halign)
    local l = Instance.new("UIListLayout", frame)
    l.FillDirection  = direction or Enum.FillDirection.Vertical
    l.Padding        = UDim.new(0, padding or 4)
    l.HorizontalAlignment = halign or Enum.HorizontalAlignment.Left
    l.SortOrder      = Enum.SortOrder.LayoutOrder
    return l
end

local function AutoSize(frame, list)
    list.Changed:Connect(function()
        frame.Size = UDim2.new(1, 0, 0, list.AbsoluteContentSize.Y + 8)
    end)
end

local function GlowEffect(frame, color, size)
    -- Имитация свечения через ImageLabel
    local glow = Instance.new("ImageLabel")
    glow.Name              = "Glow"
    glow.BackgroundTransparency = 1
    glow.Image             = "rbxassetid://5028857084"
    glow.ImageColor3       = color or Color3.fromRGB(150,40,255)
    glow.ImageTransparency = 0.65
    glow.Size              = UDim2.new(1, size or 30, 1, size or 30)
    glow.Position          = UDim2.new(0, -(size or 30)/2, 0, -(size or 30)/2)
    glow.ZIndex            = frame.ZIndex - 1
    glow.Parent            = frame
    return glow
end

-- ───── SCREEN GUI ─────
local function GetScreenGui()
    local name = "AxiaUI"
    -- Поддержка syn/krnl
    if syn and syn.protect_gui then
        local sg = Instance.new("ScreenGui")
        sg.Name           = name
        sg.ResetOnSpawn   = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        syn.protect_gui(sg)
        sg.Parent = CoreGui
        return sg
    end
    pcall(function()
        if CoreGui:FindFirstChild(name) then
            CoreGui:FindFirstChild(name):Destroy()
        end
    end)
    local sg = Instance.new("ScreenGui")
    sg.Name           = name
    sg.ResetOnSpawn   = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() sg.Parent = CoreGui end)
    if not sg.Parent then sg.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    return sg
end

-- ══════════════════════════════════════════════
--   АНИМАЦИЯ ЗАГРУЗКИ (Loading Screen)
-- ══════════════════════════════════════════════
local function ShowLoadingScreen(screenGui, options)
    local T = Axia.Theme
    options = options or {}
    local title    = options.Title    or "Axia"
    local subtitle = options.Subtitle or "Loading..."

    -- Фон
    local overlay = Instance.new("Frame", screenGui)
    overlay.Name              = "LoadingOverlay"
    overlay.Size              = UDim2.new(1,0,1,0)
    overlay.BackgroundColor3  = T.Background
    overlay.BorderSizePixel   = 0
    overlay.ZIndex            = 100

    -- Центральный контейнер
    local card = Instance.new("Frame", overlay)
    card.Name             = "LoadCard"
    card.AnchorPoint      = Vector2.new(0.5, 0.5)
    card.Position         = UDim2.new(0.5,0,0.5,0)
    card.Size             = UDim2.new(0,320,0,180)
    card.BackgroundColor3 = T.Surface
    card.ZIndex           = 101
    MakeCorner(card, 14)
    MakeStroke(card, T.Accent, 1.5)

    -- Glow за карточкой
    local glowFrame = Instance.new("Frame", overlay)
    glowFrame.AnchorPoint     = Vector2.new(0.5,0.5)
    glowFrame.Position        = UDim2.new(0.5,0,0.5,0)
    glowFrame.Size            = UDim2.new(0,320,0,180)
    glowFrame.BackgroundTransparency = 1
    glowFrame.ZIndex          = 100
    GlowEffect(glowFrame, T.NeonGlow, 60)

    -- Лого / заголовок
    local titleLabel = Instance.new("TextLabel", card)
    titleLabel.Size              = UDim2.new(1,0,0,52)
    titleLabel.Position          = UDim2.new(0,0,0,18)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text              = title
    titleLabel.TextColor3        = T.AccentBright
    titleLabel.TextSize          = 38
    titleLabel.Font              = Enum.Font.GothamBold
    titleLabel.ZIndex            = 102
    titleLabel.TextTransparency  = 1

    -- Декоративные точки в заголовке (неон под текстом)
    local titleUnderline = Instance.new("Frame", card)
    titleUnderline.Size             = UDim2.new(0,0,0,2)
    titleUnderline.Position         = UDim2.new(0.5,0,0,72)
    titleUnderline.AnchorPoint      = Vector2.new(0.5,0)
    titleUnderline.BackgroundColor3 = T.Accent
    titleUnderline.BorderSizePixel  = 0
    titleUnderline.ZIndex           = 102
    MakeCorner(titleUnderline, 2)

    -- Подзаголовок
    local subLabel = Instance.new("TextLabel", card)
    subLabel.Size              = UDim2.new(1,-40,0,20)
    subLabel.Position          = UDim2.new(0,20,0,80)
    subLabel.BackgroundTransparency = 1
    subLabel.Text              = subtitle
    subLabel.TextColor3        = T.TextDim
    subLabel.TextSize          = 14
    subLabel.Font              = Enum.Font.Gotham
    subLabel.ZIndex            = 102
    subLabel.TextTransparency  = 1

    -- Прогресс-бар фон
    local barBg = Instance.new("Frame", card)
    barBg.Size             = UDim2.new(1,-48,0,6)
    barBg.Position         = UDim2.new(0,24,1,-36)
    barBg.BackgroundColor3 = T.SliderBack
    barBg.BorderSizePixel  = 0
    barBg.ZIndex           = 102
    MakeCorner(barBg, 4)

    -- Прогресс-бар заполнение
    local barFill = Instance.new("Frame", barBg)
    barFill.Size             = UDim2.new(0,0,1,0)
    barFill.BackgroundColor3 = T.Accent
    barFill.BorderSizePixel  = 0
    barFill.ZIndex           = 103
    MakeCorner(barFill, 4)
    MakeGradient(barFill,
        Color3.fromRGB(120,30,220),
        Color3.fromRGB(210,100,255),
        0)

    -- Блик на баре
    local barGlow = Instance.new("Frame", barFill)
    barGlow.Size             = UDim2.new(1,0,1,0)
    barGlow.BackgroundColor3 = Color3.fromRGB(255,255,255)
    barGlow.BackgroundTransparency = 0.85
    barGlow.BorderSizePixel  = 0
    barGlow.ZIndex           = 104
    MakeCorner(barGlow, 4)

    -- Статус текст
    local statusLabel = Instance.new("TextLabel", card)
    statusLabel.Size              = UDim2.new(1,-48,0,16)
    statusLabel.Position          = UDim2.new(0,24,1,-56)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text              = "Initializing..."
    statusLabel.TextColor3        = T.TextAccent
    statusLabel.TextSize          = 12
    statusLabel.Font              = Enum.Font.Gotham
    statusLabel.TextXAlignment    = Enum.TextXAlignment.Left
    statusLabel.ZIndex            = 102
    statusLabel.TextTransparency  = 1

    -- Вращающийся спиннер (через ImageLabel с RotationAnim)
    local spinnerFrame = Instance.new("Frame", card)
    spinnerFrame.Size             = UDim2.new(0,28,0,28)
    spinnerFrame.Position         = UDim2.new(1,-46,0,14)
    spinnerFrame.BackgroundTransparency = 1
    spinnerFrame.ZIndex           = 102

    local spinner = Instance.new("ImageLabel", spinnerFrame)
    spinner.Size             = UDim2.new(1,0,1,0)
    spinner.BackgroundTransparency = 1
    spinner.Image            = "rbxassetid://4965945816"
    spinner.ImageColor3      = T.AccentBright
    spinner.ZIndex           = 103

    -- Спиннер анимация
    local spinConn
    spinConn = RunService.RenderStepped:Connect(function(dt)
        if spinner and spinner.Parent then
            spinner.Rotation = spinner.Rotation + dt * 280
        end
    end)

    -- Точки загрузки (три мерцающих)
    local dotsFrame = Instance.new("Frame", card)
    dotsFrame.Size             = UDim2.new(0,60,0,14)
    dotsFrame.Position         = UDim2.new(0.5,-30,0,100)
    dotsFrame.BackgroundTransparency = 1
    dotsFrame.ZIndex           = 102

    local dots = {}
    for i = 1, 3 do
        local dot = Instance.new("Frame", dotsFrame)
        dot.Size             = UDim2.new(0,8,0,8)
        dot.Position         = UDim2.new(0,(i-1)*18,0.5,-4)
        dot.BackgroundColor3 = T.Accent
        dot.BorderSizePixel  = 0
        dot.ZIndex           = 103
        dot.BackgroundTransparency = 0.7
        MakeCorner(dot, 99)
        dots[i] = dot
    end

    -- Анимация точек
    local dotThread = coroutine.wrap(function()
        local idx = 1
        while overlay and overlay.Parent do
            for i,d in pairs(dots) do
                if d and d.Parent then
                    Tween(d,{BackgroundTransparency = i==idx and 0 or 0.75},0.15):Play()
                    Tween(d,{Size = i==idx and UDim2.new(0,10,0,10) or UDim2.new(0,7,0,7)},0.15):Play()
                end
            end
            idx = (idx % 3) + 1
            task.wait(0.22)
        end
    end)
    dotThread()

    -- Анимация появления
    card.Size = UDim2.new(0,280,0,130)
    card.BackgroundTransparency = 1

    -- Fade in
    Tween(card,{BackgroundTransparency = 0, Size = UDim2.new(0,320,0,180)}, 0.5, Enum.EasingStyle.Back):Play()
    Tween(overlay,{BackgroundTransparency = 0},0.3):Play()
    task.wait(0.25)
    Tween(titleLabel, {TextTransparency=0}, 0.4):Play()
    task.wait(0.15)
    Tween(subLabel,   {TextTransparency=0}, 0.35):Play()
    Tween(statusLabel,{TextTransparency=0}, 0.35):Play()

    -- Анимация underline
    Tween(titleUnderline, {Size = UDim2.new(0,180,0,2)}, 0.6, Enum.EasingStyle.Quart):Play()

    -- Статусы загрузки
    local statuses = {
        "Initializing core...",
        "Loading modules...",
        "Applying theme...",
        "Setting up UI...",
        "Finalizing...",
        "Ready!",
    }

    -- Заполняем прогресс-бар
    local function AnimateLoad(callback)
        task.spawn(function()
            for i, status in ipairs(statuses) do
                if statusLabel and statusLabel.Parent then
                    Tween(statusLabel,{TextTransparency=1},0.1):Play()
                    task.wait(0.12)
                    statusLabel.Text = status
                    Tween(statusLabel,{TextTransparency=0},0.15):Play()
                end
                local targetFill = i / #statuses
                Tween(barFill, {Size=UDim2.new(targetFill,0,1,0)}, 0.28):Play()
                task.wait(0.28 + (i < #statuses and 0.12 or 0))
            end

            -- Финальный flash
            if barFill and barFill.Parent then
                Tween(barFill,{BackgroundColor3=T.Highlight},0.2):Play()
                task.wait(0.2)
            end

            task.wait(0.3)

            -- Fade out
            if spinConn then spinConn:Disconnect() end
            Tween(card,  {BackgroundTransparency=1, Size=UDim2.new(0,280,0,140)}, 0.45, Enum.EasingStyle.Quart):Play()
            Tween(overlay,{BackgroundTransparency=1}, 0.5):Play()
            task.wait(0.5)
            overlay:Destroy()
            if callback then callback() end
        end)
    end

    return AnimateLoad
end

-- ══════════════════════════════════════════════
--   DRAGGABLE
-- ══════════════════════════════════════════════
local function MakeDraggable(topbar, frame)
    local dragging, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)
    topbar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ══════════════════════════════════════════════
--   CREATE WINDOW
-- ══════════════════════════════════════════════
function Axia:CreateWindow(options)
    options = options or {}
    local T = self.Theme
    local title      = options.Title      or "Axia"
    local subtitle   = options.Subtitle   or ""
    local toggleKey  = options.ToggleKey  or Enum.KeyCode.RightShift
    local size       = options.Size       or Vector2.new(560, 380)
    local position   = options.Position   or UDim2.new(0.5,-size.X/2,0.5,-size.Y/2)

    -- Экран
    local screenGui = GetScreenGui()

    -- Loading
    local startFunc = ShowLoadingScreen(screenGui, {
        Title    = title,
        Subtitle = subtitle,
    })

    -- ─── Основной фрейм ───
    local mainFrame = Instance.new("Frame", screenGui)
    mainFrame.Name             = "AxiaWindow"
    mainFrame.Size             = UDim2.new(0, size.X, 0, size.Y)
    mainFrame.Position         = position
    mainFrame.BackgroundColor3 = T.Background
    mainFrame.BorderSizePixel  = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Visible          = false
    MakeCorner(mainFrame, 12)
    MakeStroke(mainFrame, T.Border, 1.2)

    -- Фоновый градиент
    MakeGradient(mainFrame,
        T.Background,
        Color3.fromRGB(16, 10, 30),
        135)

    -- Блеск сверху (highlight полоска)
    local topGlow = Instance.new("Frame", mainFrame)
    topGlow.Size             = UDim2.new(1,0,0,2)
    topGlow.BackgroundColor3 = T.AccentDim
    topGlow.BorderSizePixel  = 0
    topGlow.ZIndex           = 3
    MakeGradient(topGlow,
        Color3.fromRGB(60,10,140),
        T.AccentBright,
        0)

    -- ─── Топбар ───
    local topbar = Instance.new("Frame", mainFrame)
    topbar.Name             = "Topbar"
    topbar.Size             = UDim2.new(1,0,0,44)
    topbar.BackgroundColor3 = T.BackgroundLight
    topbar.BorderSizePixel  = 0
    topbar.ZIndex           = 3
    MakeGradient(topbar,
        T.BackgroundLight,
        T.Background,
        90)

    -- Разделитель под топбаром
    local topDivider = Instance.new("Frame", mainFrame)
    topDivider.Size             = UDim2.new(1,0,0,1)
    topDivider.Position         = UDim2.new(0,0,0,44)
    topDivider.BackgroundColor3 = T.Border
    topDivider.BorderSizePixel  = 0
    topDivider.ZIndex           = 3
    MakeGradient(topDivider,
        Color3.fromRGB(40,10,90),
        T.AccentBright,
        0)

    -- Лого-иконка (цветной квадрат с буквой A)
    local logoFrame = Instance.new("Frame", topbar)
    logoFrame.Size             = UDim2.new(0,28,0,28)
    logoFrame.Position         = UDim2.new(0,10,0.5,-14)
    logoFrame.BackgroundColor3 = T.Accent
    logoFrame.ZIndex           = 4
    MakeCorner(logoFrame, 7)

    local logoLabel = Instance.new("TextLabel", logoFrame)
    logoLabel.Size              = UDim2.new(1,0,1,0)
    logoLabel.BackgroundTransparency = 1
    logoLabel.Text              = "⬡"
    logoLabel.TextColor3        = Color3.fromRGB(255,255,255)
    logoLabel.TextSize          = 18
    logoLabel.Font              = Enum.Font.GothamBold
    logoLabel.ZIndex            = 5

    -- Заголовок
    local titleLabel = Instance.new("TextLabel", topbar)
    titleLabel.Size              = UDim2.new(0,200,1,0)
    titleLabel.Position          = UDim2.new(0,46,0,0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text              = title
    titleLabel.TextColor3        = T.TextBright
    titleLabel.TextSize          = 17
    titleLabel.Font              = Enum.Font.GothamBold
    titleLabel.TextXAlignment    = Enum.TextXAlignment.Left
    titleLabel.ZIndex            = 4

    -- Подзаголовок
    local subtitleLabel = Instance.new("TextLabel", topbar)
    subtitleLabel.Size              = UDim2.new(0,300,0,14)
    subtitleLabel.Position          = UDim2.new(0,46,1,-16)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text              = subtitle
    subtitleLabel.TextColor3        = T.TextDim
    subtitleLabel.TextSize          = 12
    subtitleLabel.Font              = Enum.Font.Gotham
    subtitleLabel.TextXAlignment    = Enum.TextXAlignment.Left
    subtitleLabel.ZIndex            = 4

    -- Кнопка закрыть
    local closeBtn = Instance.new("TextButton", topbar)
    closeBtn.Size              = UDim2.new(0,26,0,26)
    closeBtn.Position          = UDim2.new(1,-34,0.5,-13)
    closeBtn.BackgroundColor3  = Color3.fromRGB(255,60,80)
    closeBtn.Text              = "×"
    closeBtn.TextColor3        = Color3.fromRGB(255,255,255)
    closeBtn.TextSize          = 18
    closeBtn.Font              = Enum.Font.GothamBold
    closeBtn.ZIndex            = 5
    closeBtn.BorderSizePixel   = 0
    MakeCorner(closeBtn, 8)

    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn,{BackgroundColor3=Color3.fromRGB(255,100,120)},0.15):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn,{BackgroundColor3=Color3.fromRGB(255,60,80)},0.15):Play()
    end)
    closeBtn.MouseButton1Click:Connect(function()
        Tween(mainFrame,{BackgroundTransparency=1},0.25):Play()
        task.wait(0.25)
        screenGui:Destroy()
    end)

    -- Кнопка свернуть
    local minBtn = Instance.new("TextButton", topbar)
    minBtn.Size              = UDim2.new(0,26,0,26)
    minBtn.Position          = UDim2.new(1,-64,0.5,-13)
    minBtn.BackgroundColor3  = Color3.fromRGB(255,170,0)
    minBtn.Text              = "–"
    minBtn.TextColor3        = Color3.fromRGB(255,255,255)
    minBtn.TextSize          = 18
    minBtn.Font              = Enum.Font.GothamBold
    minBtn.ZIndex            = 5
    minBtn.BorderSizePixel   = 0
    MakeCorner(minBtn, 8)

    local minimized = false
    local normalSize = UDim2.new(0, size.X, 0, size.Y)
    local miniSize   = UDim2.new(0, size.X, 0, 44)

    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        Tween(mainFrame, {Size = minimized and miniSize or normalSize}, 0.3, Enum.EasingStyle.Quart):Play()
    end)

    -- Перетаскивание
    MakeDraggable(topbar, mainFrame)

    -- ─── Табы (боковая панель) ───
    local tabBar = Instance.new("Frame", mainFrame)
    tabBar.Name             = "TabBar"
    tabBar.Size             = UDim2.new(0,110,1,-45)
    tabBar.Position         = UDim2.new(0,0,0,45)
    tabBar.BackgroundColor3 = T.BackgroundLight
    tabBar.BorderSizePixel  = 0
    tabBar.ZIndex           = 3
    MakeGradient(tabBar,
        T.BackgroundLight,
        T.Background,
        90)

    -- Разделитель между табами и контентом
    local tabDivider = Instance.new("Frame", mainFrame)
    tabDivider.Size             = UDim2.new(0,1,1,-45)
    tabDivider.Position         = UDim2.new(0,110,0,45)
    tabDivider.BackgroundColor3 = T.Border
    tabDivider.BorderSizePixel  = 0
    tabDivider.ZIndex           = 3

    -- Прокрутка для табов
    local tabScroll = Instance.new("ScrollingFrame", tabBar)
    tabScroll.Size             = UDim2.new(1,0,1,-10)
    tabScroll.Position         = UDim2.new(0,0,0,8)
    tabScroll.BackgroundTransparency = 1
    tabScroll.ScrollBarThickness = 0
    tabScroll.ZIndex           = 4
    tabScroll.BorderSizePixel  = 0
    tabScroll.CanvasSize       = UDim2.new(0,0,0,0)
    tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

    local tabList = MakeListLayout(tabScroll, Enum.FillDirection.Vertical, 4)
    MakePadding(tabScroll, 0,0,6,6)

    -- ─── Контент ───
    local contentArea = Instance.new("Frame", mainFrame)
    contentArea.Name             = "ContentArea"
    contentArea.Size             = UDim2.new(1,-111,1,-45)
    contentArea.Position         = UDim2.new(0,111,0,45)
    contentArea.BackgroundTransparency = 1
    contentArea.ZIndex           = 3
    contentArea.ClipsDescendants = true

    -- Window object
    local Window = {}
    Window._tabs        = {}
    Window._activeTab   = nil
    Window._frame       = mainFrame
    Window._screenGui   = screenGui

    -- Переключение табов
    local function SwitchTab(tabObj)
        for _, t in pairs(Window._tabs) do
            t._page.Visible = false
            Tween(t._button, {
                BackgroundColor3 = T.Surface,
                TextColor3       = T.TextDim,
            }, 0.2):Play()
            if t._button:FindFirstChildOfClass("UIStroke") then
                Tween(t._button:FindFirstChildOfClass("UIStroke"),{
                    Color = Color3.fromRGB(50,30,90)
                }, 0.2):Play()
            end
            if t._indicator then
                Tween(t._indicator, {BackgroundTransparency=1}, 0.2):Play()
            end
        end
        tabObj._page.Visible = true
        Tween(tabObj._button, {
            BackgroundColor3 = T.SurfaceLight,
            TextColor3       = T.TextBright,
        }, 0.2):Play()
        if tabObj._button:FindFirstChildOfClass("UIStroke") then
            Tween(tabObj._button:FindFirstChildOfClass("UIStroke"),{
                Color = T.Accent
            }, 0.2):Play()
        end
        if tabObj._indicator then
            Tween(tabObj._indicator, {BackgroundTransparency=0}, 0.2):Play()
        end
        Window._activeTab = tabObj
    end

    -- Добавить таб
    function Window:AddTab(name, icon)
        local TabObj = {}

        -- Кнопка таба
        local tabBtn = Instance.new("TextButton", tabScroll)
        tabBtn.Name             = name
        tabBtn.Size             = UDim2.new(1,0,0,34)
        tabBtn.BackgroundColor3 = T.Surface
        tabBtn.Text             = (icon and icon.." " or "") .. name
        tabBtn.TextColor3       = T.TextDim
        tabBtn.TextSize         = 13
        tabBtn.Font             = Enum.Font.Gotham
        tabBtn.TextXAlignment   = Enum.TextXAlignment.Left
        tabBtn.ZIndex           = 5
        tabBtn.BorderSizePixel  = 0
        MakeCorner(tabBtn, 8)
        MakeStroke(tabBtn, Color3.fromRGB(50,30,90), 1)
        MakePadding(tabBtn, 0,0,10,0)

        -- Активный индикатор (фиолетовая полоска слева)
        local indicator = Instance.new("Frame", tabBtn)
        indicator.Size             = UDim2.new(0,3,0.6,0)
        indicator.Position         = UDim2.new(0,0,0.2,0)
        indicator.BackgroundColor3 = T.Accent
        indicator.BorderSizePixel  = 0
        indicator.BackgroundTransparency = 1
        indicator.ZIndex           = 6
        MakeCorner(indicator, 3)

        TabObj._indicator = indicator
        TabObj._button    = tabBtn

        -- Страница таба
        local page = Instance.new("ScrollingFrame", contentArea)
        page.Name              = "Page_"..name
        page.Size              = UDim2.new(1,0,1,0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel   = 0
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = T.AccentDim
        page.ZIndex            = 4
        page.Visible           = false
        page.CanvasSize        = UDim2.new(0,0,0,0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y

        local pageList = MakeListLayout(page, Enum.FillDirection.Vertical, 8)
        MakePadding(page, 8,8,10,10)

        TabObj._page = page

        -- Ховер
        tabBtn.MouseEnter:Connect(function()
            if Window._activeTab ~= TabObj then
                Tween(tabBtn,{BackgroundColor3=T.SurfaceLight},0.15):Play()
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window._activeTab ~= TabObj then
                Tween(tabBtn,{BackgroundColor3=T.Surface},0.15):Play()
            end
        end)
        tabBtn.MouseButton1Click:Connect(function()
            SwitchTab(TabObj)
        end)

        table.insert(Window._tabs, TabObj)

        if #Window._tabs == 1 then
            SwitchTab(TabObj)
        end

        -- ─── СЕКЦИИ ───
        function TabObj:AddSection(sectionName)
            local Section = {}

            local sectionFrame = Instance.new("Frame", page)
            sectionFrame.Name             = sectionName
            sectionFrame.Size             = UDim2.new(1,0,0,30)
            sectionFrame.BackgroundColor3 = T.Surface
            sectionFrame.BorderSizePixel  = 0
            sectionFrame.ZIndex           = 5
            sectionFrame.AutomaticSize    = Enum.AutomaticSize.Y
            MakeCorner(sectionFrame, 10)
            MakeStroke(sectionFrame, T.Border, 1)

            -- Заголовок секции
            local sectionHeader = Instance.new("Frame", sectionFrame)
            sectionHeader.Size             = UDim2.new(1,0,0,28)
            sectionHeader.BackgroundColor3 = T.SurfaceLight
            sectionHeader.BorderSizePixel  = 0
            sectionHeader.ZIndex           = 6
            MakeCorner(sectionHeader, 8)

            local sectionTitle = Instance.new("TextLabel", sectionHeader)
            sectionTitle.Size              = UDim2.new(1,-12,1,0)
            sectionTitle.Position          = UDim2.new(0,12,0,0)
            sectionTitle.BackgroundTransparency = 1
            sectionTitle.Text              = sectionName
            sectionTitle.TextColor3        = T.TextAccent
            sectionTitle.TextSize          = 12
            sectionTitle.Font              = Enum.Font.GothamSemibold
            sectionTitle.TextXAlignment    = Enum.TextXAlignment.Left
            sectionTitle.ZIndex            = 7

            -- Разделитель под заголовком
            local secDivider = Instance.new("Frame", sectionFrame)
            secDivider.Size             = UDim2.new(1,-12,0,1)
            secDivider.Position         = UDim2.new(0,6,0,28)
            secDivider.BackgroundColor3 = T.Border
            secDivider.BorderSizePixel  = 0
            secDivider.ZIndex           = 6
            secDivider.BackgroundTransparency = 0.6

            -- Контейнер элементов
            local itemsContainer = Instance.new("Frame", sectionFrame)
            itemsContainer.Name             = "Items"
            itemsContainer.Size             = UDim2.new(1,0,0,0)
            itemsContainer.Position         = UDim2.new(0,0,0,32)
            itemsContainer.BackgroundTransparency = 1
            itemsContainer.ZIndex           = 6
            itemsContainer.AutomaticSize   = Enum.AutomaticSize.Y

            local itemList = MakeListLayout(itemsContainer, Enum.FillDirection.Vertical, 2)
            MakePadding(itemsContainer, 4,6,8,8)

            local function UpdateSectionSize()
                task.wait()
                sectionFrame.Size = UDim2.new(1,0,0, 28 + 6 + itemsContainer.AbsoluteSize.Y + 2)
            end

            itemList.Changed:Connect(UpdateSectionSize)

            -- ═══════════ TOGGLE ═══════════
            function Section:AddToggle(opts)
                opts = opts or {}
                local name     = opts.Name     or "Toggle"
                local default  = opts.Default  ~= nil and opts.Default or false
                local flag     = opts.Flag     or name
                local callback = opts.Callback or function() end

                Axia.Flags[flag] = default

                local holder = Instance.new("Frame", itemsContainer)
                holder.Size             = UDim2.new(1,0,0,30)
                holder.BackgroundTransparency = 1
                holder.ZIndex           = 7

                local label = Instance.new("TextLabel", holder)
                label.Size              = UDim2.new(1,-46,1,0)
                label.BackgroundTransparency = 1
                label.Text              = name
                label.TextColor3        = T.TextNormal
                label.TextSize          = 13
                label.Font              = Enum.Font.Gotham
                label.TextXAlignment    = Enum.TextXAlignment.Left
                label.ZIndex            = 8

                -- Переключатель
                local toggleBg = Instance.new("Frame", holder)
                toggleBg.Size             = UDim2.new(0,36,0,20)
                toggleBg.Position         = UDim2.new(1,-36,0.5,-10)
                toggleBg.BackgroundColor3 = default and T.ToggleOn or T.ToggleOff
                toggleBg.ZIndex           = 8
                MakeCorner(toggleBg, 99)
                MakeStroke(toggleBg, default and T.AccentBright or T.Border, 1)

                local toggleCircle = Instance.new("Frame", toggleBg)
                toggleCircle.Size             = UDim2.new(0,14,0,14)
                toggleCircle.Position         = default and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)
                toggleCircle.BackgroundColor3 = Color3.fromRGB(255,255,255)
                toggleCircle.ZIndex           = 9
                MakeCorner(toggleCircle, 99)

                local state = default
                local tog = {}

                local function SetToggle(val, silent)
                    state = val
                    Axia.Flags[flag] = val
                    Tween(toggleBg, {
                        BackgroundColor3 = val and T.ToggleOn or T.ToggleOff
                    }, 0.2):Play()
                    if toggleBg:FindFirstChildOfClass("UIStroke") then
                        Tween(toggleBg:FindFirstChildOfClass("UIStroke"),{
                            Color = val and T.AccentBright or T.Border
                        },0.2):Play()
                    end
                    Tween(toggleCircle, {
                        Position = val and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)
                    }, 0.2):Play()
                    Tween(label, {
                        TextColor3 = val and T.TextBright or T.TextNormal
                    }, 0.2):Play()
                    if not silent then callback(val) end
                end

                toggleBg.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        SetToggle(not state)
                    end
                end)
                holder.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        SetToggle(not state)
                    end
                end)

                function tog:Set(val) SetToggle(val, true) end
                function tog:Get() return state end

                UpdateSectionSize()
                return tog
            end

            -- ═══════════ SLIDER ═══════════
            function Section:AddSlider(opts)
                opts = opts or {}
                local name     = opts.Name     or "Slider"
                local min      = opts.Min      or 0
                local max      = opts.Max      or 100
                local default  = opts.Default  or min
                local flag     = opts.Flag     or name
                local suffix   = opts.Suffix   or ""
                local callback = opts.Callback or function() end

                Axia.Flags[flag] = default

                local holder = Instance.new("Frame", itemsContainer)
                holder.Size             = UDim2.new(1,0,0,38)
                holder.BackgroundTransparency = 1
                holder.ZIndex           = 7

                local row = Instance.new("Frame", holder)
                row.Size             = UDim2.new(1,0,0,18)
                row.BackgroundTransparency = 1
                row.ZIndex           = 8

                local label = Instance.new("TextLabel", row)
                label.Size              = UDim2.new(0.7,0,1,0)
                label.BackgroundTransparency = 1
                label.Text              = name
                label.TextColor3        = T.TextNormal
                label.TextSize          = 13
                label.Font              = Enum.Font.Gotham
                label.TextXAlignment    = Enum.TextXAlignment.Left
                label.ZIndex            = 9

                local valLabel = Instance.new("TextLabel", row)
                valLabel.Size              = UDim2.new(0.3,0,1,0)
                valLabel.Position          = UDim2.new(0.7,0,0,0)
                valLabel.BackgroundTransparency = 1
                valLabel.Text              = tostring(default)..suffix
                valLabel.TextColor3        = T.TextAccent
                valLabel.TextSize          = 12
                valLabel.Font              = Enum.Font.GothamSemibold
                valLabel.TextXAlignment    = Enum.TextXAlignment.Right
                valLabel.ZIndex            = 9

                -- Дорожка
                local trackBg = Instance.new("Frame", holder)
                trackBg.Size             = UDim2.new(1,0,0,8)
                trackBg.Position         = UDim2.new(0,0,1,-10)
                trackBg.BackgroundColor3 = T.SliderBack
                trackBg.ZIndex           = 8
                MakeCorner(trackBg, 99)

                local trackFill = Instance.new("Frame", trackBg)
                local fillPct = (default - min) / (max - min)
                trackFill.Size             = UDim2.new(fillPct,0,1,0)
                trackFill.BackgroundColor3 = T.SliderFill
                trackFill.ZIndex           = 9
                trackFill.BorderSizePixel  = 0
                MakeCorner(trackFill, 99)
                MakeGradient(trackFill,
                    Color3.fromRGB(110,20,210),
                    T.Highlight,
                    0)

                -- Рукоятка
                local knob = Instance.new("Frame", trackBg)
                knob.Size             = UDim2.new(0,14,0,14)
                knob.Position         = UDim2.new(fillPct,0,0.5,-7)
                knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
                knob.ZIndex           = 10
                knob.BorderSizePixel  = 0
                MakeCorner(knob, 99)

                local dragging = false
                local sliderObj = {}
                local currentVal = default

                local function UpdateSlider(x)
                    local absPos  = trackBg.AbsolutePosition.X
                    local absSize = trackBg.AbsoluteSize.X
                    local rel = math.clamp((x - absPos) / absSize, 0, 1)
                    local val = math.floor(min + (max - min) * rel)
                    currentVal = val
                    Axia.Flags[flag] = val
                    valLabel.Text = tostring(val)..suffix
                    Tween(trackFill, {Size=UDim2.new(rel,0,1,0)}, 0.05):Play()
                    Tween(knob,      {Position=UDim2.new(rel,0,0.5,-7)}, 0.05):Play()
                    callback(val)
                end

                trackBg.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        UpdateSlider(inp.Position.X)
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        UpdateSlider(inp.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)

                function sliderObj:Set(val)
                    local rel = (val - min) / (max - min)
                    currentVal = math.clamp(val, min, max)
                    Axia.Flags[flag] = currentVal
                    valLabel.Text = tostring(currentVal)..suffix
                    Tween(trackFill, {Size=UDim2.new(rel,0,1,0)}, 0.15):Play()
                    Tween(knob,      {Position=UDim2.new(rel,0,0.5,-7)}, 0.15):Play()
                end
                function sliderObj:Get() return currentVal end

                UpdateSectionSize()
                return sliderObj
            end

            -- ═══════════ BUTTON ═══════════
            function Section:AddButton(opts)
                opts = opts or {}
                local name     = opts.Name     or "Button"
                local callback = opts.Callback or function() end

                local btn = Instance.new("TextButton", itemsContainer)
                btn.Size             = UDim2.new(1,0,0,30)
                btn.BackgroundColor3 = T.AccentDim
                btn.Text             = name
                btn.TextColor3       = T.TextBright
                btn.TextSize         = 13
                btn.Font             = Enum.Font.GothamSemibold
                btn.ZIndex           = 7
                btn.BorderSizePixel  = 0
                MakeCorner(btn, 8)
                MakeStroke(btn, T.AccentBright, 1)

                btn.MouseEnter:Connect(function()
                    Tween(btn,{BackgroundColor3=T.Accent},0.15):Play()
                end)
                btn.MouseLeave:Connect(function()
                    Tween(btn,{BackgroundColor3=T.AccentDim},0.15):Play()
                end)
                btn.MouseButton1Down:Connect(function()
                    Tween(btn,{BackgroundColor3=T.AccentBright, Size=UDim2.new(1,-4,0,28)},0.08):Play()
                end)
                btn.MouseButton1Up:Connect(function()
                    Tween(btn,{BackgroundColor3=T.Accent, Size=UDim2.new(1,0,0,30)},0.12):Play()
                    callback()
                end)

                UpdateSectionSize()

                local btnObj = {}
                function btnObj:SetText(t) btn.Text = t end
                return btnObj
            end

            -- ═══════════ DROPDOWN ═══════════
            function Section:AddDropdown(opts)
                opts = opts or {}
                local name     = opts.Name     or "Dropdown"
                local items    = opts.Items    or {}
                local default  = opts.Default
                local flag     = opts.Flag     or name
                local callback = opts.Callback or function() end

                local selected = default or (items[1] or "None")
                Axia.Flags[flag] = selected

                local holder = Instance.new("Frame", itemsContainer)
                holder.Size             = UDim2.new(1,0,0,30)
                holder.BackgroundTransparency = 1
                holder.ZIndex           = 7
                holder.ClipsDescendants = false

                local label = Instance.new("TextLabel", holder)
                label.Size              = UDim2.new(1,0,0,16)
                label.BackgroundTransparency = 1
                label.Text              = name
                label.TextColor3        = T.TextNormal
                label.TextSize          = 12
                label.Font              = Enum.Font.Gotham
                label.TextXAlignment    = Enum.TextXAlignment.Left
                label.ZIndex            = 8

                local dropBtn = Instance.new("TextButton", holder)
                dropBtn.Size             = UDim2.new(1,0,0,26)
                dropBtn.Position         = UDim2.new(0,0,0,16)
                dropBtn.BackgroundColor3 = T.SurfaceLight
                dropBtn.Text             = selected.." ▾"
                dropBtn.TextColor3       = T.TextBright
                dropBtn.TextSize         = 12
                dropBtn.Font             = Enum.Font.Gotham
                dropBtn.ZIndex           = 8
                dropBtn.BorderSizePixel  = 0
                MakeCorner(dropBtn, 7)
                MakeStroke(dropBtn, T.Border, 1)
                MakePadding(dropBtn, 0,0,8,0)

                holder.Size = UDim2.new(1,0,0,46)

                -- Список
                local listFrame = Instance.new("Frame", holder)
                listFrame.Size             = UDim2.new(1,0,0,0)
                listFrame.Position         = UDim2.new(0,0,0,46)
                listFrame.BackgroundColor3 = T.Surface
                listFrame.ZIndex           = 15
                listFrame.ClipsDescendants = true
                listFrame.Visible          = false
                MakeCorner(listFrame, 7)
                MakeStroke(listFrame, T.Accent, 1)

                local listScroll = Instance.new("ScrollingFrame", listFrame)
                listScroll.Size             = UDim2.new(1,0,1,0)
                listScroll.BackgroundTransparency = 1
                listScroll.ScrollBarThickness = 3
                listScroll.ScrollBarImageColor3 = T.AccentDim
                listScroll.ZIndex           = 16
                listScroll.BorderSizePixel  = 0
                listScroll.CanvasSize       = UDim2.new(0,0,0,0)
                listScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

                local listLayout = MakeListLayout(listScroll, Enum.FillDirection.Vertical, 2)
                MakePadding(listScroll, 4,4,4,4)

                local isOpen = false
                local dropObj = {}

                local function CloseDropdown()
                    isOpen = false
                    Tween(listFrame, {Size=UDim2.new(1,0,0,0)}, 0.2):Play()
                    task.wait(0.2)
                    listFrame.Visible = false
                    holder.Size = UDim2.new(1,0,0,46)
                    UpdateSectionSize()
                end

                local function PopulateList()
                    for _, c in pairs(listScroll:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end
                    for _, item in ipairs(items) do
                        local itm = Instance.new("TextButton", listScroll)
                        itm.Size             = UDim2.new(1,0,0,24)
                        itm.BackgroundColor3 = item == selected and T.SurfaceLight or Color3.fromRGB(0,0,0)
                        itm.BackgroundTransparency = item == selected and 0 or 1
                        itm.Text             = item
                        itm.TextColor3       = item == selected and T.TextBright or T.TextNormal
                        itm.TextSize         = 12
                        itm.Font             = Enum.Font.Gotham
                        itm.ZIndex           = 17
                        itm.BorderSizePixel  = 0
                        MakeCorner(itm, 5)

                        itm.MouseEnter:Connect(function()
                            if item ~= selected then
                                Tween(itm,{BackgroundTransparency=0, BackgroundColor3=T.Surface},0.1):Play()
                            end
                        end)
                        itm.MouseLeave:Connect(function()
                            if item ~= selected then
                                Tween(itm,{BackgroundTransparency=1},0.1):Play()
                            end
                        end)
                        itm.MouseButton1Click:Connect(function()
                            selected = item
                            Axia.Flags[flag] = item
                            dropBtn.Text = item.." ▾"
                            callback(item)
                            CloseDropdown()
                        end)
                    end
                end

                dropBtn.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    if isOpen then
                        PopulateList()
                        listFrame.Visible = true
                        local targetH = math.min(#items * 28 + 8, 150)
                        holder.Size = UDim2.new(1,0,0,46 + targetH + 4)
                        Tween(listFrame, {Size=UDim2.new(1,0,0,targetH)}, 0.2):Play()
                        UpdateSectionSize()
                    else
                        CloseDropdown()
                    end
                end)

                function dropObj:Set(val)
                    selected = val
                    Axia.Flags[flag] = val
                    dropBtn.Text = val.." ▾"
                end
                function dropObj:Get() return selected end
                function dropObj:Refresh(newItems)
                    items = newItems
                    if isOpen then PopulateList() end
                end

                UpdateSectionSize()
                return dropObj
            end

            -- ═══════════ TEXTBOX ═══════════
            function Section:AddTextbox(opts)
                opts = opts or {}
                local name      = opts.Name      or "Input"
                local default   = opts.Default   or ""
                local placeholder = opts.Placeholder or "Type here..."
                local flag      = opts.Flag      or name
                local callback  = opts.Callback  or function() end

                Axia.Flags[flag] = default

                local holder = Instance.new("Frame", itemsContainer)
                holder.Size             = UDim2.new(1,0,0,46)
                holder.BackgroundTransparency = 1
                holder.ZIndex           = 7

                local label = Instance.new("TextLabel", holder)
                label.Size              = UDim2.new(1,0,0,16)
                label.BackgroundTransparency = 1
                label.Text              = name
                label.TextColor3        = T.TextNormal
                label.TextSize          = 12
                label.Font              = Enum.Font.Gotham
                label.TextXAlignment    = Enum.TextXAlignment.Left
                label.ZIndex            = 8

                local inputFrame = Instance.new("Frame", holder)
                inputFrame.Size             = UDim2.new(1,0,0,26)
                inputFrame.Position         = UDim2.new(0,0,0,18)
                inputFrame.BackgroundColor3 = T.BackgroundLight
                inputFrame.ZIndex           = 8
                inputFrame.BorderSizePixel  = 0
                MakeCorner(inputFrame, 7)
                local stroke = MakeStroke(inputFrame, T.Border, 1)

                local textbox = Instance.new("TextBox", inputFrame)
                textbox.Size              = UDim2.new(1,-16,1,0)
                textbox.Position          = UDim2.new(0,8,0,0)
                textbox.BackgroundTransparency = 1
                textbox.Text              = default
                textbox.PlaceholderText   = placeholder
                textbox.PlaceholderColor3 = T.TextDim
                textbox.TextColor3        = T.TextBright
                textbox.TextSize          = 12
                textbox.Font              = Enum.Font.Gotham
                textbox.TextXAlignment    = Enum.TextXAlignment.Left
                textbox.ZIndex            = 9
                textbox.ClearTextOnFocus  = false

                textbox.Focused:Connect(function()
                    Tween(stroke,{Color=T.Accent},0.2):Play()
                end)
                textbox.FocusLost:Connect(function(enter)
                    Tween(stroke,{Color=T.Border},0.2):Play()
                    Axia.Flags[flag] = textbox.Text
                    callback(textbox.Text)
                end)

                local tbObj = {}
                function tbObj:Set(val)
                    textbox.Text = val
                    Axia.Flags[flag] = val
                end
                function tbObj:Get() return textbox.Text end

                UpdateSectionSize()
                return tbObj
            end

            -- ═══════════ KEYBIND ═══════════
            function Section:AddKeybind(opts)
                opts = opts or {}
                local name     = opts.Name     or "Keybind"
                local default  = opts.Default  or Enum.KeyCode.Unknown
                local flag     = opts.Flag     or name
                local callback = opts.Callback or function() end

                local currentKey = default
                Axia.Flags[flag] = currentKey
                local listening  = false

                local holder = Instance.new("Frame", itemsContainer)
                holder.Size             = UDim2.new(1,0,0,30)
                holder.BackgroundTransparency = 1
                holder.ZIndex           = 7

                local label = Instance.new("TextLabel", holder)
                label.Size              = UDim2.new(0.6,0,1,0)
                label.BackgroundTransparency = 1
                label.Text              = name
                label.TextColor3        = T.TextNormal
                label.TextSize          = 13
                label.Font              = Enum.Font.Gotham
                label.TextXAlignment    = Enum.TextXAlignment.Left
                label.ZIndex            = 8

                local keyBtn = Instance.new("TextButton", holder)
                keyBtn.Size             = UDim2.new(0,80,0,22)
                keyBtn.Position         = UDim2.new(1,-80,0.5,-11)
                keyBtn.BackgroundColor3 = T.SurfaceLight
                keyBtn.Text             = currentKey.Name
                keyBtn.TextColor3       = T.TextAccent
                keyBtn.TextSize         = 11
                keyBtn.Font             = Enum.Font.GothamSemibold
                keyBtn.ZIndex           = 8
                keyBtn.BorderSizePixel  = 0
                MakeCorner(keyBtn, 6)
                MakeStroke(keyBtn, T.Border, 1)

                keyBtn.MouseButton1Click:Connect(function()
                    listening = true
                    keyBtn.Text = "..."
                    Tween(keyBtn:FindFirstChildOfClass("UIStroke"),{Color=T.Accent},0.15):Play()
                end)

                UserInputService.InputBegan:Connect(function(inp, gpe)
                    if listening and not gpe then
                        if inp.UserInputType == Enum.UserInputType.Keyboard then
                            currentKey = inp.KeyCode
                            Axia.Flags[flag] = currentKey
                            keyBtn.Text = currentKey.Name
                            Tween(keyBtn:FindFirstChildOfClass("UIStroke"),{Color=T.Border},0.15):Play()
                            listening = false
                        end
                    elseif not listening then
                        if inp.KeyCode == currentKey then
                            callback(currentKey)
                        end
                    end
                end)

                local kbObj = {}
                function kbObj:Set(key)
                    currentKey = key
                    Axia.Flags[flag] = key
                    keyBtn.Text = key.Name
                end
                function kbObj:Get() return currentKey end

                UpdateSectionSize()
                return kbObj
            end

            -- ═══════════ COLORPICKER ═══════════
            function Section:AddColorPicker(opts)
                opts = opts or {}
                local name     = opts.Name     or "Color"
                local default  = opts.Default  or Color3.fromRGB(160,50,255)
                local flag     = opts.Flag     or name
                local callback = opts.Callback or function() end

                local currentColor = default
                Axia.Flags[flag]   = currentColor

                local holder = Instance.new("Frame", itemsContainer)
                holder.Size             = UDim2.new(1,0,0,30)
                holder.BackgroundTransparency = 1
                holder.ZIndex           = 7

                local label = Instance.new("TextLabel", holder)
                label.Size              = UDim2.new(0.7,0,1,0)
                label.BackgroundTransparency = 1
                label.Text              = name
                label.TextColor3        = T.TextNormal
                label.TextSize          = 13
                label.Font              = Enum.Font.Gotham
                label.TextXAlignment    = Enum.TextXAlignment.Left
                label.ZIndex            = 8

                -- Превью цвета
                local previewBtn = Instance.new("TextButton", holder)
                previewBtn.Size             = UDim2.new(0,24,0,24)
                previewBtn.Position         = UDim2.new(1,-24,0.5,-12)
                previewBtn.BackgroundColor3 = default
                previewBtn.Text             = ""
                previewBtn.ZIndex           = 8
                previewBtn.BorderSizePixel  = 0
                MakeCorner(previewBtn, 6)
                MakeStroke(previewBtn, T.Border, 1)

                -- Простой пикер (HSV)
                local pickerOpen = false
                local pickerFrame = Instance.new("Frame", holder)
                pickerFrame.Size             = UDim2.new(0,160,0,130)
                pickerFrame.Position         = UDim2.new(1,-160,0,32)
                pickerFrame.BackgroundColor3 = T.Surface
                pickerFrame.ZIndex           = 20
                pickerFrame.Visible          = false
                pickerFrame.ClipsDescendants = true
                MakeCorner(pickerFrame, 8)
                MakeStroke(pickerFrame, T.Accent, 1)

                -- SV квадрат
                local svFrame = Instance.new("ImageLabel", pickerFrame)
                svFrame.Size             = UDim2.new(1,-12,0,90)
                svFrame.Position         = UDim2.new(0,6,0,6)
                svFrame.BackgroundColor3 = Color3.fromHSV(0,1,1)
                svFrame.Image            = "rbxassetid://4155801252"
                svFrame.ZIndex           = 21
                svFrame.BorderSizePixel  = 0
                MakeCorner(svFrame, 5)

                -- Hue-полоска
                local hueFrame = Instance.new("ImageLabel", pickerFrame)
                hueFrame.Size            = UDim2.new(1,-12,0,12)
                hueFrame.Position        = UDim2.new(0,6,0,102)
                hueFrame.Image           = "rbxassetid://698051250"
                hueFrame.ZIndex          = 21
                hueFrame.BackgroundTransparency = 1
                MakeCorner(hueFrame, 3)

                local h, s, v = Color3.toHSV(default)
                local huePct   = h
                local cpObj    = {}

                local function UpdateColor()
                    currentColor = Color3.fromHSV(h,s,v)
                    Axia.Flags[flag] = currentColor
                    previewBtn.BackgroundColor3 = currentColor
                    svFrame.BackgroundColor3    = Color3.fromHSV(h,1,1)
                    callback(currentColor)
                end

                -- SV drag
                local svDrag = false
                svFrame.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        svDrag = true
                        local rel = inp.Position - svFrame.AbsolutePosition
                        s = math.clamp(rel.X / svFrame.AbsoluteSize.X, 0, 1)
                        v = math.clamp(1 - rel.Y / svFrame.AbsoluteSize.Y, 0, 1)
                        UpdateColor()
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if svDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        local rel = inp.Position - svFrame.AbsolutePosition
                        s = math.clamp(rel.X / svFrame.AbsoluteSize.X, 0, 1)
                        v = math.clamp(1 - rel.Y / svFrame.AbsoluteSize.Y, 0, 1)
                        UpdateColor()
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then svDrag = false end
                end)

                -- Hue drag
                local hueDrag = false
                hueFrame.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        hueDrag = true
                        h = math.clamp((inp.Position.X - hueFrame.AbsolutePosition.X) / hueFrame.AbsoluteSize.X, 0, 1)
                        UpdateColor()
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if hueDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        h = math.clamp((inp.Position.X - hueFrame.AbsolutePosition.X) / hueFrame.AbsoluteSize.X, 0, 1)
                        UpdateColor()
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then hueDrag = false end
                end)

                previewBtn.MouseButton1Click:Connect(function()
                    pickerOpen = not pickerOpen
                    pickerFrame.Visible = pickerOpen
                    if pickerOpen then
                        holder.Size = UDim2.new(1,0,0,165)
                    else
                        holder.Size = UDim2.new(1,0,0,30)
                    end
                    UpdateSectionSize()
                end)

                function cpObj:Set(color)
                    currentColor = color
                    Axia.Flags[flag] = color
                    previewBtn.BackgroundColor3 = color
                    h,s,v = Color3.toHSV(color)
                end
                function cpObj:Get() return currentColor end

                UpdateSectionSize()
                return cpObj
            end

            -- ═══════════ LABEL ═══════════
            function Section:AddLabel(text)
                local lbl = Instance.new("TextLabel", itemsContainer)
                lbl.Size              = UDim2.new(1,0,0,22)
                lbl.BackgroundTransparency = 1
                lbl.Text              = text or ""
                lbl.TextColor3        = T.TextDim
                lbl.TextSize          = 12
                lbl.Font              = Enum.Font.Gotham
                lbl.TextXAlignment    = Enum.TextXAlignment.Left
                lbl.TextWrapped       = true
                lbl.ZIndex            = 7

                UpdateSectionSize()

                return {
                    SetText = function(self, t)
                        lbl.Text = t
                    end
                }
            end

            -- ═══════════ SEPARATOR ═══════════
            function Section:AddSeparator()
                local sep = Instance.new("Frame", itemsContainer)
                sep.Size             = UDim2.new(1,0,0,1)
                sep.BackgroundColor3 = T.Border
                sep.BorderSizePixel  = 0
                sep.ZIndex           = 7
                sep.BackgroundTransparency = 0.5
                UpdateSectionSize()
            end

            return Section
        end

        return TabObj
    end

    -- Toggle visible by key
    UserInputService.InputBegan:Connect(function(inp, gpe)
        if not gpe and inp.KeyCode == toggleKey then
            mainFrame.Visible = not mainFrame.Visible
        end
    end)

    -- Запускаем загрузку, потом показываем окно
    startFunc(function()
        mainFrame.Visible = true
        -- Анимация появления окна
        mainFrame.BackgroundTransparency = 1
        mainFrame.Position = UDim2.new(
            position.X.Scale,
            position.X.Offset,
            position.Y.Scale,
            position.Y.Offset + 20
        )
        Tween(mainFrame, {
            BackgroundTransparency = 0,
            Position = position,
        }, 0.45, Enum.EasingStyle.Back):Play()
    end)

    return Window
end

-- ══════════════════════════════════════════════
--   NOTIFY (уведомление)
-- ══════════════════════════════════════════════
function Axia:Notify(opts)
    opts = opts or {}
    local T       = self.Theme
    local title   = opts.Title   or "Axia"
    local text    = opts.Text    or ""
    local duration = opts.Duration or 3.5
    local ntype   = opts.Type    or "info" -- info, success, warning, danger

    local colorMap = {
        info    = T.Accent,
        success = T.Success,
        warning = T.Warning,
        danger  = T.Danger,
    }
    local accentColor = colorMap[ntype] or T.Accent

    -- Ищем или создаём контейнер уведомлений
    local sg = CoreGui:FindFirstChild("AxiaUI") or LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("AxiaUI")
    if not sg then return end

    local notifHolder = sg:FindFirstChild("NotifHolder")
    if not notifHolder then
        notifHolder = Instance.new("Frame", sg)
        notifHolder.Name             = "NotifHolder"
        notifHolder.Size             = UDim2.new(0,280,1,0)
        notifHolder.Position         = UDim2.new(1,-290,0,0)
        notifHolder.BackgroundTransparency = 1
        notifHolder.ZIndex           = 50
        MakeListLayout(notifHolder, Enum.FillDirection.Vertical, 8)
        MakePadding(notifHolder, 16,0,0,0)
    end

    local card = Instance.new("Frame", notifHolder)
    card.Size             = UDim2.new(1,0,0,0)
    card.BackgroundColor3 = T.Surface
    card.ClipsDescendants = true
    card.ZIndex           = 51
    card.BorderSizePixel  = 0
    MakeCorner(card, 10)
    MakeStroke(card, accentColor, 1.5)

    -- Акцент-полоска слева
    local stripe = Instance.new("Frame", card)
    stripe.Size             = UDim2.new(0,3,1,0)
    stripe.BackgroundColor3 = accentColor
    stripe.BorderSizePixel  = 0
    stripe.ZIndex           = 52
    MakeCorner(stripe, 2)

    local notifTitle = Instance.new("TextLabel", card)
    notifTitle.Size              = UDim2.new(1,-16,0,18)
    notifTitle.Position          = UDim2.new(0,12,0,8)
    notifTitle.BackgroundTransparency = 1
    notifTitle.Text              = title
    notifTitle.TextColor3        = accentColor
    notifTitle.TextSize          = 13
    notifTitle.Font              = Enum.Font.GothamBold
    notifTitle.TextXAlignment    = Enum.TextXAlignment.Left
    notifTitle.ZIndex            = 52

    local notifText = Instance.new("TextLabel", card)
    notifText.Size              = UDim2.new(1,-16,0,32)
    notifText.Position          = UDim2.new(0,12,0,28)
    notifText.BackgroundTransparency = 1
    notifText.Text              = text
    notifText.TextColor3        = T.TextNormal
    notifText.TextSize          = 12
    notifText.Font              = Enum.Font.Gotham
    notifText.TextXAlignment    = Enum.TextXAlignment.Left
    notifText.TextWrapped        = true
    notifText.ZIndex            = 52

    -- Прогресс бар таймер
    local timerBg = Instance.new("Frame", card)
    timerBg.Size             = UDim2.new(1,0,0,3)
    timerBg.Position         = UDim2.new(0,0,1,-3)
    timerBg.BackgroundColor3 = T.SurfaceLight
    timerBg.BorderSizePixel  = 0
    timerBg.ZIndex           = 52

    local timerBar = Instance.new("Frame", timerBg)
    timerBar.Size             = UDim2.new(1,0,1,0)
    timerBar.BackgroundColor3 = accentColor
    timerBar.BorderSizePixel  = 0
    timerBar.ZIndex           = 53

    -- Анимация
    Tween(card, {Size=UDim2.new(1,0,0,72)}, 0.3, Enum.EasingStyle.Back):Play()
    task.wait(0.3)

    Tween(timerBar, {Size=UDim2.new(0,0,1,0)}, duration, Enum.EasingStyle.Linear):Play()
    task.wait(duration)

    Tween(card, {BackgroundTransparency=1, Size=UDim2.new(1,0,0,0)}, 0.3):Play()
    task.wait(0.3)
    card:Destroy()
end

return Axia
