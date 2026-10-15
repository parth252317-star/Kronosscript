-- Kronos part 1 — core, GUI, ESP, and most features
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

for _, name in ipairs({ "Kronos", "KronosControls", "KronosLabels", "KronosTracers", "KronosToasts", "KronosWatermark", "KronosBlur", "KronosOverlay", "KronosLocate" }) do
	local old = playerGui:FindFirstChild(name)
	if old then old:Destroy() end
end
for _, player in ipairs(Players:GetPlayers()) do
	local character = player.Character
	local oldHighlight = character and character:FindFirstChild("KronosHighlight")
	if oldHighlight then oldHighlight:Destroy() end
end
local oldBlur = Lighting:FindFirstChild("KronosBlur")
if oldBlur then oldBlur:Destroy() end

local CONFIG = {
	Enabled = false,
	ToggleKey = Enum.KeyCode.E,
	MaxDistance = 500,
	ShowTeammates = false,
	ShowNames = false,
	ShowDistance = false,
	ShowTracers = false,
	ShowChams = false,
	ShowBox = false,
	ShowHealthBar = false,
	ShowSkeleton = false,
	TracerThickness = 1,
	TracerOrigin = "Top",
	FillTransparency = 90,
	LabelSize = 14,
	BoxThickness = 1,
	Noclip = false,
	SuperJump = false,
	SuperJumpPower = 150,
	InfiniteJump = false,
	Fly = false,
	FlySpeed = 50,
	SilentFly = false,
	SilentFlySpeed = 50,
	WalkSpeed = 16,
	UseCustomSpeed = false,
	VehicleFly = false,
	VehicleFlySpeed = 10,
	Swim = false,
	SlowFalling = false,
	Float = false,
	TPTool = false,
	WallTP = false,
	Spam = false,
	SpamDelay = 100,
	XRay = false,
	XRayTransparency = 85,
	Spectate = false,
	AntiVoid = false,
	AntiFling = false,
	AccentIndex = 1,
	PanelTransparency = 0,
	IconSize = 40,
	BlurEnabled = true,
	RippleEnabled = true,
	TeammateColor = Color3.fromRGB(255, 255, 255),
	EnemyColor = Color3.fromRGB(255, 255, 255),
	NeutralColor = Color3.fromRGB(255, 255, 255),
	AntiAFK = false,
	Watermark = true,
	ShowFPS = true,
	CommandPrefix = "/",
	CommandBoxKey = Enum.KeyCode.F,
}

local DEFAULTS = {
	AccentIndex = 1,
	PanelTransparency = 0,
	IconSize = 40,
}

local KEYBINDS = {
	Enabled = Enum.KeyCode.E,
	ShowNames = nil,
	ShowTracers = nil,
	ShowBox = nil,
	ShowChams = nil,
	Noclip = nil,
	SuperJump = nil,
	InfiniteJump = nil,
	Fly = Enum.KeyCode.G,
	SilentFly = nil,
	VehicleFly = nil,
	Swim = nil,
	SlowFalling = nil,
	Float = nil,
	TPTool = nil,
	WallTP = nil,
	Spam = nil,
	XRay = nil,
	Spectate = nil,
	AntiVoid = nil,
	AntiFling = nil,
	AntiAFK = nil,
	Watermark = nil,
}

local KEYBIND_DEFAULTS = {
	Enabled = Enum.KeyCode.E,
	Fly = Enum.KeyCode.G,
}

local PANEL_WIDTH = 260
local MAX_SCROLL_HEIGHT = 320
local EDGE = 12

local THEME = {
	Background = Color3.fromRGB(16, 16, 22),
	Section = Color3.fromRGB(22, 22, 31),
	Surface = Color3.fromRGB(32, 32, 45),
	Accent = Color3.fromRGB(124, 92, 255),
	Accent2 = Color3.fromRGB(56, 205, 255),
	Off = Color3.fromRGB(72, 72, 92),
	Text = Color3.fromRGB(240, 240, 248),
	SubText = Color3.fromRGB(150, 150, 172),
	Success = Color3.fromRGB(80, 200, 120),
	Warn = Color3.fromRGB(230, 170, 60),
	Error = Color3.fromRGB(220, 80, 90),
}

local PRESETS = {
	{ Color3.fromRGB(124, 92, 255), Color3.fromRGB(56, 205, 255) },
	{ Color3.fromRGB(45, 125, 255), Color3.fromRGB(40, 220, 190) },
	{ Color3.fromRGB(255, 80, 150), Color3.fromRGB(255, 160, 60) },
	{ Color3.fromRGB(40, 200, 110), Color3.fromRGB(190, 240, 70) },
	{ Color3.fromRGB(235, 60, 70), Color3.fromRGB(255, 140, 60) },
	{ Color3.fromRGB(235, 235, 245), Color3.fromRGB(140, 140, 165) },
}

local FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function create(class, props, parent)
	local inst = Instance.new(class)
	for key, value in pairs(props) do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

local function corner(parent, radius)
	return create("UICorner", { CornerRadius = radius }, parent)
end

local function stroke(parent, color, thickness, transparency)
	return create("UIStroke", {
		Color = color,
		Thickness = thickness,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function gradient(parent, c0, c1, rotation)
	return create("UIGradient", {
		Color = ColorSequence.new(c0, c1),
		Rotation = rotation or 0,
	}, parent)
end

local function padding(parent, px)
	return create("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
	}, parent)
end

local function listLayout(parent, gap, horizontal)
	return create("UIListLayout", {
		Padding = UDim.new(0, gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
	}, parent)
end

local function tween(inst, props)
	TweenService:Create(inst, FAST, props):Play()
end

local themeListeners = {}

local function applyAccent(index)
	CONFIG.AccentIndex = index
	THEME.Accent = PRESETS[index][1]
	THEME.Accent2 = PRESETS[index][2]
	for _, fn in ipairs(themeListeners) do
		fn()
	end
end

-- Toast system
local toastGui = create("ScreenGui", {
	Name = "KronosToasts",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 100,
}, playerGui)

local toastHolder = create("Frame", {
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -20, 1, -20),
	Size = UDim2.fromOffset(280, 200),
	BackgroundTransparency = 1,
}, toastGui)
listLayout(toastHolder, 6)
local toastLayout = toastHolder:FindFirstChildOfClass("UIListLayout")
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

local TOAST_LIFETIME = 3
local toastQueue = {}
local MAX_TOASTS = 5

local function showToast(text, kind)
	kind = kind or "info"
	local accent = THEME.Accent2
	if kind == "success" then accent = THEME.Success
	elseif kind == "warn" then accent = THEME.Warn
	elseif kind == "error" then accent = THEME.Error end

	local toast = create("Frame", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundColor3 = THEME.Background,
		BackgroundTransparency = 1,
	}, toastHolder)
	corner(toast, UDim.new(0, 10))
	local toastStroke = stroke(toast, accent, 1.4, 1)
	gradient(toast, Color3.fromRGB(24, 22, 36), Color3.fromRGB(14, 14, 20), 90)

	local bar = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 3, 0.6, 0),
		BackgroundColor3 = accent,
	}, toast)
	corner(bar, UDim.new(1, 0))

	local label = create("TextLabel", {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -20, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.Text,
		Text = text,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, toast)

	tween(toast, { BackgroundTransparency = 0.05 })
	tween(toastStroke, { Transparency = 0.4 })

	table.insert(toastQueue, toast)
	while #toastQueue > MAX_TOASTS do
		local old = table.remove(toastQueue, 1)
		if old then old:Destroy() end
	end

	task.delay(TOAST_LIFETIME, function()
		if toast and toast.Parent then
			tween(toast, { BackgroundTransparency = 1 })
			tween(toastStroke, { Transparency = 1 })
			tween(bar, { BackgroundTransparency = 1 })
			label.Visible = false
			for i, t in ipairs(toastQueue) do
				if t == toast then table.remove(toastQueue, i); break end
			end
			task.wait(0.2)
			toast:Destroy()
		end
	end)
end

local function notify(text, kind) showToast(text, kind) end

-- Save / Load
local SAVE_FILE = "KronosConfig.json"

local function serializeColor(c) return { c.R * 255, c.G * 255, c.B * 255 } end
local function deserializeColor(t)
	if type(t) ~= "table" or #t < 3 then return nil end
	return Color3.fromRGB(t[1], t[2], t[3])
end

local function saveConfig()
	local data = {}
	for k, v in pairs(CONFIG) do
		if typeof(v) == "Color3" then
			data[k] = { __color = serializeColor(v) }
		elseif typeof(v) == "EnumItem" then
			data[k] = { __enum = tostring(v) }
		elseif type(v) == "number" or type(v) == "boolean" or type(v) == "string" then
			data[k] = v
		end
	end
	data.__keybinds = {}
	for k, v in pairs(KEYBINDS) do
		data.__keybinds[k] = v and v.Name or nil
	end
	local ok, json = pcall(function() return HttpService:JSONEncode(data) end)
	if not ok then return false end
	local ok2 = pcall(function()
		if writefile then writefile(SAVE_FILE, json) end
	end)
	return ok2
end

local function loadConfig()
	if not (isfile and readfile) then return false end
	if not isfile(SAVE_FILE) then return false end
	local ok, contents = pcall(readfile, SAVE_FILE)
	if not ok or not contents then return false end
	local ok2, data = pcall(function() return HttpService:JSONDecode(contents) end)
	if not ok2 or type(data) ~= "table" then return false end
	for k, v in pairs(data) do
		if k == "__keybinds" then
			for key, name in pairs(v) do
				if name then
					local ok3, enum = pcall(function() return Enum.KeyCode[name] end)
					if ok3 then KEYBINDS[key] = enum end
				else
					KEYBINDS[key] = nil
				end
			end
		elseif type(v) == "table" and v.__color then
			local c = deserializeColor(v.__color)
			if c then CONFIG[k] = c end
		elseif type(v) == "table" and v.__enum then
		elseif CONFIG[k] ~= nil then
			CONFIG[k] = v
		end
	end
	if CONFIG.AccentIndex and PRESETS[CONFIG.AccentIndex] then
		THEME.Accent = PRESETS[CONFIG.AccentIndex][1]
		THEME.Accent2 = PRESETS[CONFIG.AccentIndex][2]
	end
	return true
end

local screenGui = create("ScreenGui", {
	Name = "Kronos",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local locateGui = create("ScreenGui", {
	Name = "KronosLocate",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 2,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local function isPointer(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function makeDraggable(handle, target, onClick)
	local dragging, pressed, moved = false, false, false
	local activeInput, dragStart, startPos

	handle.InputBegan:Connect(function(input)
		if isPointer(input) then
			dragging = true; pressed = true; moved = false
			activeInput = input
			dragStart = input.Position
			startPos = target.Position
		end
	end)

	handle.InputEnded:Connect(function(input)
		if not pressed or not isPointer(input) then return end
		if activeInput.UserInputType == Enum.UserInputType.Touch and input ~= activeInput then return end
		pressed = false
		if not moved and onClick then onClick() end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		local isMove = input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		if not isMove then return end
		if input.UserInputType == Enum.UserInputType.Touch and input ~= activeInput then return end
		local delta = input.Position - dragStart
		if delta.Magnitude > 4 then moved = true end
		if not moved then return end
		local screen = screenGui.AbsoluteSize
		local size = target.AbsoluteSize
		if size.X <= 0 then size = Vector2.new(target.Size.X.Offset, target.Size.Y.Offset) end
		if size.Y <= 0 then size = Vector2.new(target.Size.X.Offset, target.Size.Y.Offset) end
		local anchor = target.AnchorPoint
		local topLeftX = startPos.X.Offset - size.X * anchor.X + delta.X
		local topLeftY = startPos.Y.Offset - size.Y * anchor.Y + delta.Y
		local clampedX = math.clamp(topLeftX, 0, math.max(0, screen.X - size.X))
		local clampedY = math.clamp(topLeftY, 0, math.max(0, screen.Y - size.Y))
		target.Position = UDim2.fromOffset(clampedX + size.X * anchor.X, clampedY + size.Y * anchor.Y)
	end)

	UserInputService.InputEnded:Connect(function(input)
		if not dragging or not isPointer(input) then return end
		if activeInput.UserInputType == Enum.UserInputType.Touch and input ~= activeInput then return end
		dragging = false
		task.defer(function() pressed = false end)
	end)
end

local function clampToScreen(frame)
	local screen = screenGui.AbsoluteSize
	local size = frame.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then return end
	local anchor = frame.AnchorPoint
	local topLeftX = frame.Position.X.Offset - size.X * anchor.X
	local topLeftY = frame.Position.Y.Offset - size.Y * anchor.Y
	local clampedX = math.clamp(topLeftX, 0, math.max(0, screen.X - size.X))
	local clampedY = math.clamp(topLeftY, 0, math.max(0, screen.Y - size.Y))
	frame.Position = UDim2.fromOffset(clampedX + size.X * anchor.X, clampedY + size.Y * anchor.Y)
end

local function attachRipple(button, accentColor)
	button.InputBegan:Connect(function(input)
		if not CONFIG.RippleEnabled then return end
		if not isPointer(input) then return end
		local ripple = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(0, 0),
			BackgroundColor3 = accentColor or THEME.Accent2,
			BackgroundTransparency = 0.6,
			ZIndex = 5,
		}, button)
		corner(ripple, UDim.new(1, 0))
		local targetSize = button.AbsoluteSize.X * 1.4
		TweenService:Create(ripple, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(targetSize, targetSize),
			BackgroundTransparency = 1,
		}):Play()
		task.delay(0.5, function() ripple:Destroy() end)
	end)
end

-- Watermark
local watermark = create("Frame", {
	Name = "Watermark",
	Position = UDim2.fromOffset(20, 20),
	Size = UDim2.fromOffset(190, 30),
	BackgroundColor3 = THEME.Background,
	BackgroundTransparency = 0.15,
	Visible = CONFIG.Watermark,
	ZIndex = 3,
}, screenGui)
corner(watermark, UDim.new(0, 8))
local wmStroke = stroke(watermark, THEME.Accent, 1.2, 0.4)
gradient(watermark, Color3.fromRGB(22, 20, 34), Color3.fromRGB(14, 14, 20), 90)

local wmDot = create("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 10, 0.5, 0),
	Size = UDim2.fromOffset(6, 6),
	BackgroundColor3 = Color3.new(1, 1, 1),
}, watermark)
corner(wmDot, UDim.new(1, 0))
local wmDotGradient = gradient(wmDot, THEME.Accent, THEME.Accent2, 45)

create("TextLabel", {
	Position = UDim2.fromOffset(22, 0),
	Size = UDim2.new(1, -28, 1, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.Text,
	Text = "Kronos  •  " .. localPlayer.Name,
}, watermark)

table.insert(themeListeners, function()
	wmStroke.Color = THEME.Accent
	wmDotGradient.Color = ColorSequence.new(THEME.Accent, THEME.Accent2)
end)

-- FPS
local fpsLabel = create("TextLabel", {
	Name = "FPSLabel",
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -20, 0, 20),
	Size = UDim2.fromOffset(140, 26),
	BackgroundColor3 = THEME.Background,
	BackgroundTransparency = 0.15,
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextColor3 = THEME.Accent2,
	Text = "FPS 60  •  Ping 0ms",
	Visible = CONFIG.ShowFPS,
	ZIndex = 3,
}, screenGui)
corner(fpsLabel, UDim.new(0, 8))
local fpsStroke = stroke(fpsLabel, THEME.Off, 1, 0.5)
padding(fpsLabel, 4)
table.insert(themeListeners, function()
	fpsLabel.TextColor3 = THEME.Accent2
	fpsStroke.Color = THEME.Accent
end)

local frameTimes = {}
RunService.RenderStepped:Connect(function(dt)
	table.insert(frameTimes, dt)
	if #frameTimes > 60 then table.remove(frameTimes, 1) end
end)

task.spawn(function()
	while true do
		task.wait(0.5)
		if CONFIG.ShowFPS and #frameTimes > 0 then
			local sum = 0
			for _, t in ipairs(frameTimes) do sum += t end
			local avg = sum / #frameTimes
			local fps = math.floor(0.5 + 1 / avg)
			local ping = 0
			pcall(function()
				ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
			end)
			fpsLabel.Text = string.format("FPS %d  •  Ping %dms", fps, ping)
		end
	end
end)

local blur = create("BlurEffect", {
	Name = "KronosBlur",
	Size = 0,
}, Lighting)

local function updateBlur()
	if not CONFIG.BlurEnabled then
		TweenService:Create(blur, FAST, { Size = 0 }):Play()
		return
	end
	local anyOpen = false
	if panel and panel.Visible then anyOpen = true end
	if cmdBox and cmdBox.Visible then anyOpen = true end
	if helpPanel and helpPanel.Visible then anyOpen = true end
	TweenService:Create(blur, TweenInfo.new(0.25), { Size = anyOpen and 14 or 0 }):Play()
end

local icon = create("TextButton", {
	Name = "Icon",
	Size = UDim2.fromOffset(CONFIG.IconSize, CONFIG.IconSize),
	Position = UDim2.fromOffset(24, 80),
	BackgroundColor3 = THEME.Background,
	AutoButtonColor = false,
	Text = "K",
	Font = Enum.Font.GothamBlack,
	TextSize = math.floor(CONFIG.IconSize * 0.42),
	TextColor3 = THEME.SubText,
	ZIndex = 4,
}, screenGui)
corner(icon, UDim.new(1, 0))
local iconStroke = stroke(icon, THEME.Off, 2.5, 0)

local function updateIcon()
	local anyOn = CONFIG.Enabled or CONFIG.ShowNames or CONFIG.ShowDistance
		or CONFIG.ShowTracers or CONFIG.ShowChams or CONFIG.ShowBox
	tween(iconStroke, { Color = anyOn and THEME.Accent2 or THEME.Off })
	tween(icon, { TextColor3 = anyOn and THEME.Text or THEME.SubText })
end
table.insert(themeListeners, updateIcon)

local panel = create("Frame", {
	Name = "Panel",
	Position = UDim2.fromOffset(24, 146),
	Size = UDim2.fromOffset(PANEL_WIDTH, 200),
	BackgroundColor3 = THEME.Background,
	ZIndex = 4,
}, screenGui)
corner(panel, UDim.new(0, 18))
gradient(panel, Color3.fromRGB(22, 20, 34), Color3.fromRGB(14, 14, 20), 90)

local panelStroke = stroke(panel, THEME.Accent, 1.6, 0.35)
local panelStrokeGradient = gradient(panelStroke, THEME.Accent, THEME.Accent2, 45)

local HEADER_H = 30
local HINT_H = 14
local TOP_SPACE = EDGE + HEADER_H + 8
local BOTTOM_SPACE = 8 + HINT_H + EDGE

local body = create("Frame", {
	Name = "Body",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
}, panel)

local scroller = create("ScrollingFrame", {
	Name = "Scroller",
	Position = UDim2.fromOffset(EDGE, TOP_SPACE),
	Size = UDim2.new(1, -EDGE * 2, 1, -(TOP_SPACE + BOTTOM_SPACE)),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 4,
	ScrollBarImageColor3 = THEME.Accent,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, body)
create("UIPadding", { PaddingRight = UDim.new(0, 8) }, scroller)
local scrollLayout = listLayout(scroller, 8)

local function resizePanel()
	local maxScroll = math.min(MAX_SCROLL_HEIGHT, math.max(120, screenGui.AbsoluteSize.Y - 220))
	local contentHeight = scrollLayout.AbsoluteContentSize.Y
	panel.Size = UDim2.fromOffset(PANEL_WIDTH, TOP_SPACE + math.min(contentHeight, maxScroll) + BOTTOM_SPACE)
end
scrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resizePanel)
screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(resizePanel)
resizePanel()

table.insert(themeListeners, function() scroller.ScrollBarImageColor3 = THEME.Accent end)

local edges = {
	Top = { AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, EDGE) },
	Bottom = { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, EDGE) },
	Left = { AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(0, EDGE, 1, 0) },
	Right = { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, EDGE, 1, 0) },
}
for name, props in pairs(edges) do
	local strip = create("Frame", {
		Name = "DragEdge" .. name,
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		Size = props.Size,
		BackgroundTransparency = 1,
		ZIndex = 10,
	}, panel)
	makeDraggable(strip, panel)
end

local header = create("Frame", {
	Name = "Header",
	Position = UDim2.fromOffset(EDGE, EDGE),
	Size = UDim2.new(1, -EDGE * 2, 0, HEADER_H),
	BackgroundTransparency = 1,
}, body)

local dot = create("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 2, 0.5, 0),
	Size = UDim2.fromOffset(10, 10),
	BackgroundColor3 = Color3.new(1, 1, 1),
}, header)
corner(dot, UDim.new(1, 0))
local dotGradient = gradient(dot, THEME.Accent, THEME.Accent2, 45)

create("TextLabel", {
	Position = UDim2.fromOffset(20, 0),
	Size = UDim2.new(1, -100, 1, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBlack,
	TextSize = 18,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.Text,
	Text = "Kronos",
}, header)

local playerCountLabel = create("TextLabel", {
	Name = "PlayerCount",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -72, 0.5, 0),
	Size = UDim2.fromOffset(60, 20),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextXAlignment = Enum.TextXAlignment.Right,
	TextColor3 = THEME.Accent2,
	Text = "0/0",
}, header)

local function updatePlayerCount()
	playerCountLabel.Text = #Players:GetPlayers() .. "/" .. Players.MaxPlayers
end
updatePlayerCount()
Players.PlayerAdded:Connect(updatePlayerCount)
Players.PlayerRemoving:Connect(updatePlayerCount)
table.insert(themeListeners, function() playerCountLabel.TextColor3 = THEME.Accent2 end)

local helpButton = create("TextButton", {
	Name = "HelpButton",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -36, 0.5, 0),
	Size = UDim2.fromOffset(26, 26),
	BackgroundColor3 = THEME.Surface,
	AutoButtonColor = false,
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = THEME.SubText,
	Text = "?",
}, header)
corner(helpButton, UDim.new(1, 0))
attachRipple(helpButton)
helpButton.MouseEnter:Connect(function() tween(helpButton, { BackgroundColor3 = THEME.Accent, TextColor3 = THEME.Text }) end)
helpButton.MouseLeave:Connect(function() tween(helpButton, { BackgroundColor3 = THEME.Surface, TextColor3 = THEME.SubText }) end)

local closeButton = create("TextButton", {
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, 0, 0.5, 0),
	Size = UDim2.fromOffset(26, 26),
	BackgroundColor3 = THEME.Surface,
	AutoButtonColor = false,
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = THEME.SubText,
	Text = "×",
}, header)
corner(closeButton, UDim.new(1, 0))
attachRipple(closeButton, THEME.Error)
closeButton.MouseEnter:Connect(function() tween(closeButton, { BackgroundColor3 = Color3.fromRGB(190, 60, 70), TextColor3 = THEME.Text }) end)
closeButton.MouseLeave:Connect(function() tween(closeButton, { BackgroundColor3 = THEME.Surface, TextColor3 = THEME.SubText }) end)
closeButton.Activated:Connect(function()
	panel.Visible = false
	updateBlur()
end)

table.insert(themeListeners, function()
	panelStrokeGradient.Color = ColorSequence.new(THEME.Accent, THEME.Accent2)
	dotGradient.Color = ColorSequence.new(THEME.Accent, THEME.Accent2)
end)

makeDraggable(header, panel)
makeDraggable(icon, icon, function()
	panel.Visible = not panel.Visible
	updateBlur()
end)

-- Keybind state
local capturingKeyFor = nil
local keybindCallbacks = {}

local function refreshKeybindChips()
	for key, code in pairs(KEYBINDS) do
		local cb = keybindCallbacks[key]
		if cb then cb(code) end
	end
end

-- Toggle / slider / section / color helpers
local refreshers = {}
local toggleHandlers = {}

local function makeToggle(order, label, key, parent, buildOptions, keybindable)
	local holder = parent
	local wrapper

	if buildOptions then
		wrapper = create("Frame", {
			Name = label,
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = order,
		}, parent)
		listLayout(wrapper, 4)
		holder = wrapper
	end

	local row = create(buildOptions and "TextButton" or "Frame", {
		Name = buildOptions and "Row" or label,
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = THEME.Surface,
		LayoutOrder = buildOptions and 0 or order,
	}, holder)
	corner(row, UDim.new(0, 10))
	if buildOptions then
		row.AutoButtonColor = false
		row.Text = ""
	end

	create("TextLabel", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -140, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.Text,
		Text = label,
	}, row)

	local keybindButton
	if keybindable then
		keybindButton = create("TextButton", {
			Name = "Keybind",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -58, 0.5, 0),
			Size = UDim2.fromOffset(38, 20),
			BackgroundColor3 = THEME.Off,
			AutoButtonColor = false,
			Font = Enum.Font.GothamBold,
			TextSize = 10,
				TextColor3 = THEME.SubText,
			Text = KEYBINDS[key] and KEYBINDS[key].Name or "—",
		}, row)
		corner(keybindButton, UDim.new(0, 6))
		attachRipple(keybindButton)

		keybindCallbacks[key] = function(code)
			if keybindButton and keybindButton.Parent then
				keybindButton.Text = code and code.Name or "—"
			end
		end

		keybindButton.Activated:Connect(function()
			capturingKeyFor = key
			keybindButton.Text = "..."
			notify("Press a key for " .. label .. "  (Esc cancels)", "info")
			task.delay(5, function()
				if capturingKeyFor == key then
					capturingKeyFor = nil
					keybindButton.Text = KEYBINDS[key] and KEYBINDS[key].Name or "—"
					notify("Keybind canceled", "warn")
				end
			end)
		end)

		keybindButton.MouseButton2Click:Connect(function()
			KEYBINDS[key] = nil
			keybindButton.Text = "—"
		end)
	end

	local indicator
	if buildOptions then
		indicator = create("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -100, 0.5, 0),
			Size = UDim2.fromOffset(18, 18),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			TextColor3 = THEME.SubText,
			Text = "+",
		}, row)
	end

	local track = create("TextButton", {
		Name = "Switch",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(40, 22),
		BackgroundColor3 = THEME.Off,
		AutoButtonColor = false,
		Text = "",
	}, row)
	corner(track, UDim.new(1, 0))
	attachRipple(track)

	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = Color3.new(1, 1, 1),
	}, track)
	corner(knob, UDim.new(1, 0))

	local function refresh()
		local on = CONFIG[key]
		tween(track, { BackgroundColor3 = on and THEME.Accent or THEME.Off })
		tween(knob, { Position = on and UDim2.new(0, 21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
		updateIcon()
	end

	track.Activated:Connect(function()
		CONFIG[key] = not CONFIG[key]
		refresh()
		local handler = toggleHandlers[key]
		if handler then task.spawn(handler, CONFIG[key]) end
	end)

	if buildOptions then
		local options = create("Frame", {
			Name = "Options",
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundColor3 = THEME.Background,
			LayoutOrder = 1,
			Visible = false,
		}, wrapper)
		corner(options, UDim.new(0, 10))
		stroke(options, THEME.Off, 1, 0.6)
		padding(options, 6)
		listLayout(options, 6)

		buildOptions(options)

		row.Activated:Connect(function()
			options.Visible = not options.Visible
			indicator.Text = options.Visible and "-" or "+"
		end)
	end

	refresh()
	table.insert(refreshers, refresh)
	table.insert(themeListeners, refresh)
	return wrapper or row
end

local function makeSlider(order, label, min, max, step, key, unit, parent, onChange)
	local holder = create("Frame", {
		Name = label,
		Size = UDim2.new(1, 0, 0, 60),
		BackgroundColor3 = THEME.Surface,
		LayoutOrder = order,
	}, parent)
	corner(holder, UDim.new(0, 10))

	create("TextLabel", {
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(0.6, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.Text,
		Text = label,
	}, holder)

	local valueLabel = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 6),
		Size = UDim2.new(0.4, 0, 0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextColor3 = THEME.Accent2,
		Text = "",
	}, holder)

	local hit = create("Frame", {
		Position = UDim2.fromOffset(14, 28),
		Size = UDim2.new(1, -28, 0, 26),
		BackgroundTransparency = 1,
	}, holder)

	local bar = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundColor3 = THEME.Off,
		BorderSizePixel = 0,
	}, hit)
	corner(bar, UDim.new(1, 0))

	local fill = create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, bar)
	corner(fill, UDim.new(1, 0))
	local fillGradient = gradient(fill, THEME.Accent, THEME.Accent2, 0)

	local knob = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
	}, bar)
	corner(knob, UDim.new(1, 0))
	local knobStroke = stroke(knob, THEME.Accent, 2, 0)

	local function update()
		local alpha = math.clamp((CONFIG[key] - min) / (max - min), 0, 1)
		fill.Size = UDim2.fromScale(alpha, 1)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		valueLabel.Text = string.format("%d%s", CONFIG[key], unit)
	end

	local function setValue(value)
		CONFIG[key] = math.clamp(math.floor(value / step + 0.5) * step, min, max)
		update()
		if onChange then onChange(CONFIG[key]) end
	end

	local sliding = false
	local function setFromX(x)
		local alpha = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		setValue(min + alpha * (max - min))
	end

	hit.InputBegan:Connect(function(input)
		if isPointer(input) then
			sliding = true
			scroller.ScrollingEnabled = false
			setFromX(input.Position.X)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if isPointer(input) then
			sliding = false
			scroller.ScrollingEnabled = true
		end
	end)

	table.insert(themeListeners, function()
		fillGradient.Color = ColorSequence.new(THEME.Accent, THEME.Accent2)
		knobStroke.Color = THEME.Accent
		valueLabel.TextColor3 = THEME.Accent2
	end)

	update()
	return setValue, update
end

local function makeSection(parent, order, title, size)
	local section = create("Frame", {
		Name = title .. "Section",
		Size = size,
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = THEME.Section,
		LayoutOrder = order,
	}, parent)
	corner(section, UDim.new(0, 12))
	stroke(section, THEME.Off, 1, 0.5)
	padding(section, 8)
	listLayout(section, 6)

	local headerButton = create("TextButton", {
		Name = "SectionHeader",
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = 0,
	}, section)

	create("TextLabel", {
		Size = UDim2.new(1, -26, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.SubText,
		Text = string.upper(title),
	}, headerButton)

	local indicator = create("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(22, 22),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
		TextColor3 = THEME.SubText,
		Text = "+",
	}, headerButton)

	local content = create("Frame", {
		Name = "Content",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
		LayoutOrder = 1,
	}, section)
	listLayout(content, 6)

	headerButton.Activated:Connect(function()
		content.Visible = not content.Visible
		indicator.Text = content.Visible and "-" or "+"
	end)

	return content
end

local espResetters = {}
local setTracerWidth, setFillTint, setLabelSize, setBoxThickness, setSpeedValue
local setSuperJumpPower, setFlySpeed, setSilentFlySpeed, setVehicleFlySpeed

local COLOR_PALETTE = {
	Color3.fromRGB(255, 70, 70),
	Color3.fromRGB(255, 150, 50),
	Color3.fromRGB(255, 220, 60),
	Color3.fromRGB(80, 255, 120),
	Color3.fromRGB(60, 210, 255),
	Color3.fromRGB(160, 110, 255),
	Color3.fromRGB(255, 255, 255),
}

local function makeColorRow(order, label, key, parent, customSet, customGet)
	local row = create("Frame", {
		Name = label,
		Size = UDim2.new(1, 0, 0, 58),
		BackgroundColor3 = THEME.Surface,
		LayoutOrder = order,
	}, parent)
	corner(row, UDim.new(0, 10))

	create("TextLabel", {
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -24, 0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.Text,
		Text = label,
	}, row)

	local swatches = create("Frame", {
		Position = UDim2.fromOffset(0, 30),
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundTransparency = 1,
	}, row)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, swatches)

	local rings = {}
	local function getCurrent()
		if customGet then return customGet() end
		return CONFIG[key]
	end
	local function mark()
		local current = getCurrent()
		for _, entry in ipairs(rings) do
			entry.ring.Transparency = (current == entry.color) and 0 or 1
		end
	end

	for index, color in ipairs(COLOR_PALETTE) do
		local swatch = create("TextButton", {
			Size = UDim2.fromOffset(20, 20),
			BackgroundColor3 = color,
			AutoButtonColor = false,
			Text = "",
			LayoutOrder = index,
		}, swatches)
		corner(swatch, UDim.new(1, 0))
		local ring = stroke(swatch, Color3.new(1, 1, 1), 2, 1)
		table.insert(rings, { ring = ring, color = color })

		swatch.Activated:Connect(function()
			if customSet then customSet(color) else CONFIG[key] = color end
			mark()
		end)
	end

	mark()
	table.insert(espResetters, mark)
end

local function makeOriginRow(order, parent)
	local row = create("Frame", {
		Name = "Tracer Origin",
		Size = UDim2.new(1, 0, 0, 58),
		BackgroundColor3 = THEME.Surface,
		LayoutOrder = order,
	}, parent)
	corner(row, UDim.new(0, 10))

	create("TextLabel", {
		Position = UDim2.fromOffset(12, 6),
		Size = UDim2.new(1, -24, 0, 20),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.Text,
		Text = "Tracer Origin",
	}, row)

	local buttons = create("Frame", {
		Position = UDim2.fromOffset(10, 30),
		Size = UDim2.new(1, -20, 0, 22),
		BackgroundTransparency = 1,
	}, row)
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, buttons)

	local buttonList = {}
	local function refreshOrigin()
		for name, button in pairs(buttonList) do
			local selected = CONFIG.TracerOrigin == name
			tween(button, { BackgroundColor3 = selected and THEME.Accent or THEME.Off })
			button.TextColor3 = selected and Color3.new(1, 1, 1) or THEME.SubText
		end
	end

	for index, name in ipairs({ "Bottom", "Center", "Top" }) do
		local button = create("TextButton", {
			Name = name,
			Size = UDim2.new(1 / 3, -4, 1, 0),
			BackgroundColor3 = THEME.Off,
			AutoButtonColor = false,
			Font = Enum.Font.GothamBold,
			TextSize = 12,
			TextColor3 = THEME.SubText,
			Text = name,
			LayoutOrder = index,
		}, buttons)
		corner(button, UDim.new(0, 8))
		attachRipple(button)
		buttonList[name] = button
		button.Activated:Connect(function()
			CONFIG.TracerOrigin = name
			refreshOrigin()
		end)
	end

	refreshOrigin()
	table.insert(themeListeners, refreshOrigin)
	table.insert(espResetters, refreshOrigin)
end

local function makeResetRow(order, text, onClick, parent)
	local button = create("TextButton", {
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Surface,
		AutoButtonColor = false,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = THEME.SubText,
		Text = text,
		LayoutOrder = order,
	}, parent)
	corner(button, UDim.new(0, 10))
	attachRipple(button)
	button.MouseEnter:Connect(function() tween(button, { TextColor3 = THEME.Text }) end)
	button.MouseLeave:Connect(function() tween(button, { TextColor3 = THEME.SubText }) end)
	button.Activated:Connect(onClick)
end

local mainContent = makeSection(scroller, 1, "Main", UDim2.new(1, 0, 0, 0))

makeToggle(1, "ESP", "Enabled", mainContent, function(box)
	makeColorRow(1, "ESP Color (all)", "EnemyColor", box,
		function(color)
			CONFIG.EnemyColor = color
			CONFIG.TeammateColor = color
		end,
		function()
			if CONFIG.EnemyColor == CONFIG.TeammateColor then return CONFIG.EnemyColor end
			return nil
		end
	)
	setFillTint = makeSlider(2, "Fill Tint", 0, 90, 5, "FillTransparency", "%", box)
	makeResetRow(3, "Reset ESP settings", function()
		CONFIG.EnemyColor = Color3.fromRGB(255, 255, 255)
		CONFIG.TeammateColor = Color3.fromRGB(255, 255, 255)
		CONFIG.TracerOrigin = "Top"
		setTracerWidth(1); setFillTint(90); setLabelSize(14); setBoxThickness(1)
		for _, refresh in ipairs(espResetters) do refresh() end
	end, box)
end, true)

makeToggle(2, "Names", "ShowNames", mainContent, function(box)
	setLabelSize = makeSlider(1, "Label Size", 10, 24, 1, "LabelSize", " px", box)
end, true)

makeToggle(3, "Distance", "ShowDistance", mainContent, function(box)
	makeSlider(1, "Max Distance", 50, 1000, 10, "MaxDistance", " studs", box)
end, true)

makeToggle(4, "Tracers", "ShowTracers", mainContent, function(box)
	setTracerWidth = makeSlider(1, "Tracer Width", 1, 6, 1, "TracerThickness", " px", box)
	makeOriginRow(2, box)
end, true)

makeToggle(5, "Chams", "ShowChams", mainContent, nil, true)
makeToggle(6, "Box ESP", "ShowBox", mainContent, function(box)
	setBoxThickness = makeSlider(1, "Box Thickness", 1, 4, 1, "BoxThickness", " px", box)
end, true)

makeToggle(7, "Health Bar", "ShowHealthBar", mainContent, nil, true)
makeToggle(8, "Skeleton", "ShowSkeleton", mainContent, nil, true)
makeToggle(9, "Noclip", "Noclip", mainContent, nil, true)

makeToggle(10, "Super Jump", "SuperJump", mainContent, function(box)
	setSuperJumpPower = makeSlider(1, "Jump Power", 50, 500, 10, "SuperJumpPower", "", box, function(v)
		if CONFIG.SuperJump then
			local char = localPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then hum.UseJumpPower = true; hum.JumpPower = v end
		end
	end)
end, true)

makeToggle(11, "Infinite Jump", "InfiniteJump", mainContent, nil, true)

makeToggle(12, "Fly", "Fly", mainContent, function(box)
	setFlySpeed = makeSlider(1, "Fly Speed", 10, 300, 5, "FlySpeed", " spd", box)
end, true)

makeToggle(13, "Silent Fly", "SilentFly", mainContent, function(box)
	setSilentFlySpeed = makeSlider(1, "SFly Speed", 10, 300, 5, "SilentFlySpeed", " spd", box)
end, true)

makeToggle(14, "Custom Speed", "UseCustomSpeed", mainContent, function(box)
	setSpeedValue = makeSlider(1, "Walk Speed", 8, 200, 2, "WalkSpeed", " spd", box, function(v)
		if CONFIG.UseCustomSpeed then
			local char = localPlayer.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum then hum.WalkSpeed = v end
		end
	end)
end, true)

local moveContent = makeSection(scroller, 2, "Movement", UDim2.new(1, 0, 0, 0))

makeToggle(1, "Vehicle Fly", "VehicleFly", moveContent, function(box)
	setVehicleFlySpeed = makeSlider(1, "Vehicle Speed", 5, 500, 5, "VehicleFlySpeed", " spd", box)
end, true)

makeToggle(2, "Swim", "Swim", moveContent, nil, true)
makeToggle(3, "Slow Falling", "SlowFalling", moveContent, nil, true)
makeToggle(4, "Float", "Float", moveContent, nil, true)

makeToggle(5, "TP Tool", "TPTool", moveContent, function(box)
	local tip = create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = THEME.Surface,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = THEME.SubText,
		Text = "Click anywhere on screen to teleport",
		TextWrapped = true,
		LayoutOrder = 1,
	}, box)
	corner(tip, UDim.new(0, 8))
	padding(tip, 6)
end, true)

makeToggle(6, "Wall TP", "WallTP", moveContent, function(box)
	local tip = create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = THEME.Surface,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = THEME.SubText,
		Text = "Click on a wall to teleport through it",
		TextWrapped = true,
		LayoutOrder = 1,
	}, box)
	corner(tip, UDim.new(0, 8))
	padding(tip, 6)
end, true)

local combatContent = makeSection(scroller, 3, "Combat", UDim2.new(1, 0, 0, 0))

makeToggle(1, "Spam", "Spam", combatContent, function(box)
	makeSlider(1, "Interval (ms)", 20, 500, 10, "SpamDelay", " ms", box)
end, true)

makeToggle(2, "Spectate", "Spectate", combatContent, function(box)
	local tip = create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = THEME.Surface,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = THEME.SubText,
		Text = "Click 'SPEC' next to a player to spectate",
		TextWrapped = true,
		LayoutOrder = 1,
	}, box)
	corner(tip, UDim.new(0, 8))
	padding(tip, 6)
end, true)

makeToggle(3, "X-Ray", "XRay", combatContent, function(box)
	makeSlider(1, "Transparency", 50, 95, 5, "XRayTransparency", "%", box)
end, true)

local protContent = makeSection(scroller, 4, "Protection", UDim2.new(1, 0, 0, 0))
makeToggle(1, "Anti-Void", "AntiVoid", protContent, nil, true)
makeToggle(2, "Anti-Fling", "AntiFling", protContent, nil, true)

local utilContent = makeSection(scroller, 5, "Utility", UDim2.new(1, 0, 0, 0))

makeToggle(1, "Anti-AFK", "AntiAFK", utilContent, nil, true)
makeToggle(2, "Watermark", "Watermark", utilContent, nil, true)
makeToggle(3, "FPS / Ping", "ShowFPS", utilContent, nil, true)

local rejoinRow = create("Frame", {
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundColor3 = THEME.Surface,
	LayoutOrder = 4,
}, utilContent)
corner(rejoinRow, UDim.new(0, 10))

local rejoinBtn = create("TextButton", {
	Position = UDim2.fromOffset(6, 6),
	Size = UDim2.new(0.5, -9, 0, 24),
	BackgroundColor3 = THEME.Accent,
	AutoButtonColor = false,
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextColor3 = THEME.Text,
	Text = "Rejoin",
}, rejoinRow)
corner(rejoinBtn, UDim.new(0, 8))
attachRipple(rejoinBtn)

local hopBtn = create("TextButton", {
	Position = UDim2.new(0.5, 3, 0, 6),
	Size = UDim2.new(0.5, -9, 0, 24),
	BackgroundColor3 = THEME.Accent,
	AutoButtonColor = false,
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextColor3 = THEME.Text,
	Text = "Server Hop",
}, rejoinRow)
corner(hopBtn, UDim.new(0, 8))
attachRipple(hopBtn)

table.insert(themeListeners, function()
	rejoinBtn.BackgroundColor3 = THEME.Accent
	hopBtn.BackgroundColor3 = THEME.Accent
end)

rejoinBtn.Activated:Connect(function()
	notify("Rejoining...", "info")
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
end)
hopBtn.Activated:Connect(function()
	notify("Hopping servers...", "info")
	pcall(function() TeleportService:Teleport(game.PlaceId, localPlayer) end)
end)

local saveRow = create("Frame", {
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundColor3 = THEME.Surface,
	LayoutOrder = 5,
}, utilContent)
corner(saveRow, UDim.new(0, 10))

local saveBtn = create("TextButton", {
	Position = UDim2.fromOffset(6, 6),
	Size = UDim2.new(0.33, -8, 0, 24),
	BackgroundColor3 = THEME.Success,
	AutoButtonColor = false,
	Font = Enum.Font.GothamBold,
	TextSize = 11,
	TextColor3 = THEME.Text,
	Text = "Save",
}, saveRow)
corner(saveBtn, UDim.new(0, 8))
attachRipple(saveBtn)

local loadBtn = create("TextButton", {
	Position = UDim2.new(0.33, 2, 0, 6),
	Size = UDim2.new(0.34, -8, 0, 24),
	BackgroundColor3 = THEME.Accent2,
	AutoButtonColor = false,
	Font = Enum.Font.GothamBold,
	TextSize = 11,
	TextColor3 = THEME.Text,
	Text = "Load",
}, saveRow)
corner(loadBtn, UDim.new(0, 8))
attachRipple(loadBtn)

local resetKeysBtn = create("TextButton", {
	Position = UDim2.new(0.67, 2, 0, 6),
	Size = UDim2.new(0.33, -8, 0, 24),
	BackgroundColor3 = THEME.Warn,
	AutoButtonColor = false,
	Font = Enum.Font.GothamBold,
	TextSize = 11,
	TextColor3 = THEME.Text,
	Text = "Keys Reset",
}, saveRow)
corner(resetKeysBtn, UDim.new(0, 8))
attachRipple(resetKeysBtn)

saveBtn.Activated:Connect(function()
	if saveConfig() then notify("Config saved", "success")
	else notify("Save failed", "error") end
end)
loadBtn.Activated:Connect(function()
	if loadConfig() then
		notify("Config loaded", "success")
		for _, refresh in ipairs(refreshers) do refresh() end
		refreshKeybindChips()
	else notify("No saved config found", "warn") end
end)
resetKeysBtn.Activated:Connect(function()
	for key, _ in pairs(KEYBINDS) do
		KEYBINDS[key] = KEYBIND_DEFAULTS[key] or nil
	end
	refreshKeybindChips()
	notify("All keybinds reset", "success")
end)

local gameContent = makeSection(scroller, 6, "Game", UDim2.new(1, 0, 0, 0))
makeToggle(1, "Teammates", "ShowTeammates", gameContent, nil, true)

local colorHolder = create("Frame", {
	Name = "Colors",
	Size = UDim2.new(1, 0, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundColor3 = THEME.Section,
	LayoutOrder = 2,
}, gameContent)
corner(colorHolder, UDim.new(0, 10))
stroke(colorHolder, THEME.Off, 1, 0.5)
padding(colorHolder, 6)
listLayout(colorHolder, 6)

makeColorRow(1, "Enemy Color", "EnemyColor", colorHolder)
makeColorRow(2, "Teammate Color", "TeammateColor", colorHolder)

local playersContent = makeSection(scroller, 7, "Players", UDim2.new(1, 0, 0, 0))

local searchBox = create("TextBox", {
	Size = UDim2.new(1, 0, 0, 30),
	BackgroundColor3 = THEME.Surface,
	Font = Enum.Font.GothamMedium,
	TextSize = 13,
	TextColor3 = THEME.Text,
	PlaceholderText = "Search players...",
	PlaceholderColor3 = THEME.SubText,
	Text = "",
	ClearTextOnFocus = false,
	LayoutOrder = 0,
}, playersContent)
corner(searchBox, UDim.new(0, 10))
padding(searchBox, 8)

local playerRows = {}
local currentFilter = ""
local locatedPlayers = {}
local spectateTarget = nil

local function teleportTo(player)
	local myChar = localPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local targetChar = player.Character
	local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
	if not myRoot or not targetRoot then return end
	myRoot.CFrame = CFrame.new(targetRoot.Position + Vector3.new(0, 0, 3))
end

local function removePlayerRow(player)
	local row = playerRows[player]
	if row then row:Destroy(); playerRows[player] = nil end
end

local function matchesFilter(player)
	if currentFilter == "" then return true end
	local q = string.lower(currentFilter)
	return string.find(string.lower(player.Name), q, 1, true)
		or string.find(string.lower(player.DisplayName), q, 1, true)
end

local function removeLocate(player)
	local data = locatedPlayers[player]
	if not data then return end
	if data.frame then data.frame:Destroy() end
	locatedPlayers[player] = nil
end

local function addLocate(player)
	if locatedPlayers[player] then
		removeLocate(player)
		notify("Stopped locating " .. player.DisplayName, "info")
		return
	end
	local frame = create("Frame", {
		Name = "Locate_" .. player.Name,
		Size = UDim2.fromOffset(80, 24),
		BackgroundColor3 = THEME.Background,
		BackgroundTransparency = 0.15,
		Visible = false,
		ZIndex = 5,
	}, locateGui)
	corner(frame, UDim.new(0, 6))
	stroke(frame, THEME.Accent, 1.4, 0.3)
	create("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = THEME.Text,
		Text = player.DisplayName,
	}, frame)
	locatedPlayers[player] = { frame = frame }
	notify("Locating " .. player.DisplayName, "success")
end

local function stopSpectate()
	spectateTarget = nil
	local cam = workspace.CurrentCamera
	local hum = localPlayer.Character and localPlayer.Character:FindFirstChildOfClass("Humanoid")
	if cam and hum then
		cam.CameraSubject = hum
		cam.CameraType = Enum.CameraType.Custom
	end
end

local function startSpectate(player)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local cam = workspace.CurrentCamera
	if hum and cam then
		spectateTarget = player
		cam.CameraSubject = hum
		cam.CameraType = Enum.CameraType.Follow
		notify("Spectating " .. player.DisplayName, "success")
	end
end

local function addPlayerRow(player)
	if playerRows[player] then return end
	local isMe = (player == localPlayer)

	local row = create("Frame", {
		Name = player.Name,
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Surface,
		LayoutOrder = player.UserId,
		Visible = matchesFilter(player),
	}, playersContent)
	corner(row, UDim.new(0, 10))

	local dot = create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = player.TeamColor and player.TeamColor.Color or THEME.SubText,
	}, row)
	corner(dot, UDim.new(1, 0))

	create("TextLabel", {
		Position = UDim2.fromOffset(26, 0),
		Size = UDim2.new(1, -180, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = isMe and THEME.Accent2 or THEME.Text,
		Text = player.DisplayName .. (isMe and " (you)" or ""),
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, row)

	if not isMe then
		local tpButton = create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6, 0.5, 0),
			Size = UDim2.fromOffset(40, 22),
			BackgroundColor3 = THEME.Accent,
			AutoButtonColor = false,
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = THEME.Text,
			Text = "TP",
		}, row)
		corner(tpButton, UDim.new(0, 8))
		attachRipple(tpButton)
		table.insert(themeListeners, function() tpButton.BackgroundColor3 = THEME.Accent end)
		tpButton.Activated:Connect(function() teleportTo(player) end)

		local locButton = create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -50, 0.5, 0),
			Size = UDim2.fromOffset(40, 22),
			BackgroundColor3 = THEME.Accent2,
			AutoButtonColor = false,
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = THEME.Text,
			Text = "LOC",
		}, row)
		corner(locButton, UDim.new(0, 8))
		attachRipple(locButton)
		table.insert(themeListeners, function() locButton.BackgroundColor3 = THEME.Accent2 end)
		locButton.Activated:Connect(function() addLocate(player) end)

		local specButton = create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -94, 0.5, 0),
			Size = UDim2.fromOffset(40, 22),
			BackgroundColor3 = THEME.Warn,
			AutoButtonColor = false,
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = THEME.Text,
			Text = "SPEC",
		}, row)
		corner(specButton, UDim.new(0, 8))
		attachRipple(specButton)
		table.insert(themeListeners, function() specButton.BackgroundColor3 = THEME.Warn end)
		specButton.Activated:Connect(function()
			if spectateTarget == player then
				stopSpectate()
				notify("Stopped spectating", "info")
			else
				startSpectate(player)
			end
		end)
	end

	playerRows[player] = row
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	currentFilter = searchBox.Text
	for player, row in pairs(playerRows) do
		row.Visible = matchesFilter(player)
	end
end)

for _, player in ipairs(Players:GetPlayers()) do addPlayerRow(player) end
Players.PlayerAdded:Connect(addPlayerRow)
Players.PlayerRemoving:Connect(function(player)
	removePlayerRow(player)
	removeLocate(player)
	if spectateTarget == player then stopSpectate() end
end)

local customizer = makeSection(scroller, 8, "Customize", UDim2.new(1, 0, 0, 0))

local swatchRow = create("Frame", {
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundColor3 = THEME.Surface,
	LayoutOrder = 1,
}, customizer)
corner(swatchRow, UDim.new(0, 10))

create("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	Padding = UDim.new(0, 8),
	SortOrder = Enum.SortOrder.LayoutOrder,
}, swatchRow)

for index, preset in ipairs(PRESETS) do
	local swatch = create("TextButton", {
		Name = "Swatch" .. index,
		Size = UDim2.fromOffset(24, 24),
		BackgroundColor3 = Color3.new(1, 1, 1),
		AutoButtonColor = false,
		Text = "",
		LayoutOrder = index,
	}, swatchRow)
	corner(swatch, UDim.new(1, 0))
	gradient(swatch, preset[1], preset[2], 45)
	attachRipple(swatch)
	local ring = stroke(swatch, Color3.new(1, 1, 1), 2, 1)

	local function mark()
		ring.Transparency = (CONFIG.AccentIndex == index) and 0 or 1
	end
	mark()
	table.insert(themeListeners, mark)

	swatch.Activated:Connect(function() applyAccent(index) end)
end

local setPanelTransparency = makeSlider(2, "Transparency", 0, 60, 5, "PanelTransparency", "%", customizer,
	function(value) panel.BackgroundTransparency = value / 100 end)

local setIconSize = makeSlider(3, "Icon Size", 30, 80, 2, "IconSize", " px", customizer,
	function(value)
		icon.Size = UDim2.fromOffset(value, value)
		icon.TextSize = math.floor(value * 0.42)
	end)

local resetButton = create("TextButton", {
	Size = UDim2.new(1, 0, 0, 32),
	BackgroundColor3 = THEME.Surface,
	AutoButtonColor = false,
	Font = Enum.Font.GothamBold,
	TextSize = 13,
	TextColor3 = THEME.SubText,
	Text = "Reset appearance",
	LayoutOrder = 4,
}, customizer)
corner(resetButton, UDim.new(0, 10))
attachRipple(resetButton)
resetButton.MouseEnter:Connect(function() tween(resetButton, { TextColor3 = THEME.Text }) end)
resetButton.MouseLeave:Connect(function() tween(resetButton, { TextColor3 = THEME.SubText }) end)
resetButton.Activated:Connect(function()
	applyAccent(DEFAULTS.AccentIndex)
	setPanelTransparency(DEFAULTS.PanelTransparency)
	setIconSize(DEFAULTS.IconSize)
end)

create("TextLabel", {
	AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, EDGE, 1, -EDGE),
	Size = UDim2.new(1, -EDGE * 2, 0, HINT_H),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextColor3 = THEME.SubText,
	Text = CONFIG.ToggleKey.Name .. " toggles ESP  •  " .. CONFIG.CommandBoxKey.Name .. " commands  •  ? for help",
}, body)

-- Hand off to part 2
_G.Kronos = {
	Players = Players,
	RunService = RunService,
	UserInputService = UserInputService,
	TweenService = TweenService,
	StarterGui = StarterGui,
	Lighting = Lighting,
	TeleportService = TeleportService,
	Stats = Stats,
	HttpService = HttpService,
	localPlayer = localPlayer,
	playerGui = playerGui,
	CONFIG = CONFIG,
	DEFAULTS = DEFAULTS,
	KEYBINDS = KEYBINDS,
	KEYBIND_DEFAULTS = KEYBIND_DEFAULTS,
	THEME = THEME,
	PRESETS = PRESETS,
	FAST = FAST,
	create = create,
	corner = corner,
	stroke = stroke,
	gradient = gradient,
	padding = padding,
	listLayout = listLayout,
	tween = tween,
	themeListeners = themeListeners,
	applyAccent = applyAccent,
	notify = notify,
	saveConfig = saveConfig,
	loadConfig = loadConfig,
	screenGui = screenGui,
	locateGui = locateGui,
	isPointer = isPointer,
	makeDraggable = makeDraggable,
	clampToScreen = clampToScreen,
	attachRipple = attachRipple,
	watermark = watermark,
	fpsLabel = fpsLabel,
	blur = blur,
	updateBlur = updateBlur,
	icon = icon,
	updateIcon = updateIcon,
	panel = panel,
	scroller = scroller,
	refreshers = refreshers,
	toggleHandlers = toggleHandlers,
	makeToggle = makeToggle,
	makeSlider = makeSlider,
	makeSection = makeSection,
	makeColorRow = makeColorRow,
	makeOriginRow = makeOriginRow,
	makeResetRow = makeResetRow,
	espResetters = espResetters,
	COLOR_PALETTE = COLOR_PALETTE,
	capturingKeyFor = function() return capturingKeyFor end,
	setCapturingKeyFor = function(v) capturingKeyFor = v end,
	keybindCallbacks = keybindCallbacks,
	refreshKeybindChips = refreshKeybindChips,
	locatedPlayers = locatedPlayers,
	playerRows = playerRows,
	addLocate = addLocate,
	startSpectate = startSpectate,
	stopSpectate = stopSpectate,
	findPlayer = nil,
}