-- Kronos part 2 — commands, keybinds, ESP render, movement features
local K = _G.Kronos
if not K then
	warn("[Kronos] Part 1 didn't load — aborting part 2")
	return
end

local Players = K.Players
local RunService = K.RunService
local UserInputService = K.UserInputService
local TweenService = K.TweenService
local TeleportService = K.TeleportService
local localPlayer = K.localPlayer
local playerGui = K.playerGui
local CONFIG = K.CONFIG
local KEYBINDS = K.KEYBINDS
local THEME = K.THEME
local create = K.create
local corner = K.corner
local stroke = K.stroke
local gradient = K.gradient
local padding = K.padding
local listLayout = K.listLayout
local tween = K.tween
local themeListeners = K.themeListeners
local notify = K.notify
local screenGui = K.screenGui
local locateGui = K.locateGui
local isPointer = K.isPointer
local makeDraggable = K.makeDraggable
local clampToScreen = K.clampToScreen
local attachRipple = K.attachRipple
local watermark = K.watermark
local fpsLabel = K.fpsLabel
local updateBlur = K.updateBlur
local icon = K.icon
local updateIcon = K.updateIcon
local panel = K.panel
local scroller = K.scroller
local refreshers = K.refreshers
local toggleHandlers = K.toggleHandlers
local makeToggle = K.makeToggle
local makeSlider = K.makeSlider
local makeSection = K.makeSection
local makeResetRow = K.makeResetRow
local locatedPlayers = K.locatedPlayers
local playerRows = K.playerRows
local addLocate = K.addLocate
local startSpectate = K.startSpectate
local stopSpectate = K.stopSpectate
local keybindCallbacks = K.keybindCallbacks
local refreshKeybindChips = K.refreshKeybindChips

local function findPlayer(query)
	if not query or query == "" then return nil end
	query = string.lower(query)
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= localPlayer and (string.lower(p.Name) == query or string.lower(p.DisplayName) == query) then return p end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= localPlayer and (string.find(string.lower(p.Name), query, 1, true)
			or string.find(string.lower(p.DisplayName), query, 1, true)) then return p end
	end
	return nil
end

local function teleportTo(player)
	local myChar = localPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local targetChar = player.Character
	local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
	if not myRoot or not targetRoot then return end
	myRoot.CFrame = CFrame.new(targetRoot.Position + Vector3.new(0, 0, 3))
end

-- Command system
local function setToggle(key, value)
	CONFIG[key] = value
	for _, refresh in ipairs(refreshers) do refresh() end
	local handler = toggleHandlers[key]
	if handler then task.spawn(handler, value) end
end

local function toggleFeature(key, label)
	setToggle(key, not CONFIG[key])
	notify(string.format("%s %s", label, CONFIG[key] and "ON" or "OFF"),
		CONFIG[key] and "success" or "info")
end

local COMMAND_LIST = {
	{ cmd = "/esp", desc = "Toggle ESP outline", key = "Enabled", label = "ESP" },
	{ cmd = "/names", desc = "Toggle name tags", key = "ShowNames", label = "Names" },
	{ cmd = "/dist", desc = "Toggle distance labels", key = "ShowDistance", label = "Distance" },
	{ cmd = "/tracers", desc = "Toggle tracer lines", key = "ShowTracers", label = "Tracers" },
	{ cmd = "/chams", desc = "Toggle chams fill", key = "ShowChams", label = "Chams" },
	{ cmd = "/box", desc = "Toggle box ESP", key = "ShowBox", label = "Box ESP" },
	{ cmd = "/health", desc = "Toggle health bars", key = "ShowHealthBar", label = "Health Bar" },
	{ cmd = "/skeleton", desc = "Toggle skeleton ESP", key = "ShowSkeleton", label = "Skeleton" },
	{ cmd = "/noclip", desc = "Walk through walls", key = "Noclip", label = "Noclip" },
	{ cmd = "/jump", desc = "Toggle super jump", key = "SuperJump", label = "Super Jump" },
	{ cmd = "/ij", desc = "Toggle infinite jump", key = "InfiniteJump", label = "Infinite Jump" },
	{ cmd = "/fly", desc = "Toggle fly", key = "Fly", label = "Fly" },
	{ cmd = "/sfly", desc = "Toggle silent fly", key = "SilentFly", label = "Silent Fly" },
	{ cmd = "/vfly", desc = "Toggle vehicle fly", key = "VehicleFly", label = "Vehicle Fly" },
	{ cmd = "/swim", desc = "Toggle swim", key = "Swim", label = "Swim" },
	{ cmd = "/slowfall", desc = "Toggle slow falling", key = "SlowFalling", label = "Slow Falling" },
	{ cmd = "/float", desc = "Toggle walk-on-air float", key = "Float", label = "Float" },
	{ cmd = "/tptool", desc = "Toggle TP tool", key = "TPTool", label = "TP Tool" },
	{ cmd = "/walltp", desc = "Toggle wall TP", key = "WallTP", label = "Wall TP" },
	{ cmd = "/spam", desc = "Toggle tool spam", key = "Spam", label = "Spam" },
	{ cmd = "/xray", desc = "Toggle X-Ray", key = "XRay", label = "X-Ray" },
	{ cmd = "/spectate", desc = "Toggle spectate mode", key = "Spectate", label = "Spectate" },
	{ cmd = "/antivoid", desc = "Toggle anti-void", key = "AntiVoid", label = "Anti-Void" },
	{ cmd = "/antifling", desc = "Toggle anti-fling", key = "AntiFling", label = "Anti-Fling" },
	{ cmd = "/speed", desc = "Toggle custom speed", key = "UseCustomSpeed", label = "Custom Speed" },
	{ cmd = "/antiafk", desc = "Toggle anti-AFK", key = "AntiAFK", label = "Anti-AFK" },
	{ cmd = "/wm", desc = "Toggle watermark", key = "Watermark", label = "Watermark" },
	{ cmd = "/fps", desc = "Toggle FPS display", key = "ShowFPS", label = "FPS" },
	{ cmd = "/teammates", desc = "Show teammates in ESP", key = "ShowTeammates", label = "Teammate ESP" },
	{ cmd = "/tp <name>", desc = "Teleport to a player" },
	{ cmd = "/locate <name>", desc = "Toggle locate marker on player" },
	{ cmd = "/unspectate", desc = "Stop spectating" },
	{ cmd = "/fspeed <n>", desc = "Set fly / sfly speed" },
	{ cmd = "/jp <n>", desc = "Set super jump power" },
	{ cmd = "/ws <n>", desc = "Set walk speed" },
	{ cmd = "/save", desc = "Save current config" },
	{ cmd = "/load", desc = "Load saved config" },
	{ cmd = "/rejoin", desc = "Rejoin this server" },
	{ cmd = "/hop", desc = "Server hop" },
	{ cmd = "/help", desc = "Open this help panel" },
}

local COMMANDS = {
	esp = function() toggleFeature("Enabled", "ESP") end,
	names = function() toggleFeature("ShowNames", "Names") end,
	dist = function() toggleFeature("ShowDistance", "Distance") end,
	distance = function() toggleFeature("ShowDistance", "Distance") end,
	tracers = function() toggleFeature("ShowTracers", "Tracers") end,
	chams = function() toggleFeature("ShowChams", "Chams") end,
	box = function() toggleFeature("ShowBox", "Box ESP") end,
	health = function() toggleFeature("ShowHealthBar", "Health Bar") end,
	skeleton = function() toggleFeature("ShowSkeleton", "Skeleton") end,
	noclip = function() toggleFeature("Noclip", "Noclip") end,
	jump = function() toggleFeature("SuperJump", "Super Jump") end,
	superjump = function() toggleFeature("SuperJump", "Super Jump") end,
	ij = function() toggleFeature("InfiniteJump", "Infinite Jump") end,
	infinitejump = function() toggleFeature("InfiniteJump", "Infinite Jump") end,
	fly = function() toggleFeature("Fly", "Fly") end,
	sfly = function() toggleFeature("SilentFly", "Silent Fly") end,
	silentfly = function() toggleFeature("SilentFly", "Silent Fly") end,
	vfly = function() toggleFeature("VehicleFly", "Vehicle Fly") end,
	vehiclefly = function() toggleFeature("VehicleFly", "Vehicle Fly") end,
	swim = function() toggleFeature("Swim", "Swim") end,
	slowfall = function() toggleFeature("SlowFalling", "Slow Falling") end,
	slowfalling = function() toggleFeature("SlowFalling", "Slow Falling") end,
	float = function() toggleFeature("Float", "Float") end,
	tptool = function() toggleFeature("TPTool", "TP Tool") end,
	walltp = function() toggleFeature("WallTP", "Wall TP") end,
	spam = function() toggleFeature("Spam", "Spam") end,
	xray = function() toggleFeature("XRay", "X-Ray") end,
	spectate = function() toggleFeature("Spectate", "Spectate") end,
	antivoid = function() toggleFeature("AntiVoid", "Anti-Void") end,
	antifling = function() toggleFeature("AntiFling", "Anti-Fling") end,
	speed = function() toggleFeature("UseCustomSpeed", "Custom Speed") end,
	antiafk = function() toggleFeature("AntiAFK", "Anti-AFK") end,
	wm = function() toggleFeature("Watermark", "Watermark") end,
	watermark = function() toggleFeature("Watermark", "Watermark") end,
	fps = function() toggleFeature("ShowFPS", "FPS") end,
	teammates = function() toggleFeature("ShowTeammates", "Teammate ESP") end,
	tp = function(args)
		if not args or args == "" then notify("Usage: /tp <player>", "warn"); return end
		local target = findPlayer(args)
		if target then teleportTo(target); notify("Teleported to " .. target.DisplayName, "success")
		else notify("Player not found: " .. args, "error") end
	end,
	locate = function(args)
		if not args or args == "" then notify("Usage: /locate <player>", "warn"); return end
		local target = findPlayer(args)
		if target then addLocate(target)
		else notify("Player not found: " .. args, "error") end
	end,
	unspectate = function()
		stopSpectate()
		notify("Stopped spectating", "info")
	end,
	fspeed = function(args)
		local n = tonumber(args); if not n then notify("Usage: /fspeed <number>", "warn"); return end
		n = math.clamp(n, 10, 500)
		CONFIG.FlySpeed = n
		CONFIG.SilentFlySpeed = n
		notify("Fly speed set to " .. n, "success")
	end,
	jp = function(args)
		local n = tonumber(args); if not n then notify("Usage: /jp <number>", "warn"); return end
		n = math.clamp(n, 50, 1000)
		CONFIG.SuperJumpPower = n
		if CONFIG.SuperJump then applySuperJump() end
		notify("Jump power set to " .. n, "success")
	end,
	ws = function(args)
		local n = tonumber(args); if not n then notify("Usage: /ws <number>", "warn"); return end
		n = math.clamp(n, 8, 500)
		CONFIG.WalkSpeed = n
		local char = localPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = n end
		if setSpeedValue then setSpeedValue(n) end
		notify("Walk speed set to " .. n, "success")
	end,
	save = function()
		if K.saveConfig() then notify("Config saved", "success")
		else notify("Save failed", "error") end
	end,
	load = function()
		if K.loadConfig() then
			notify("Config loaded", "success")
			for _, refresh in ipairs(refreshers) do refresh() end
			refreshKeybindChips()
		else notify("No saved config", "warn") end
	end,
	rejoin = function()
		notify("Rejoining...", "info")
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, localPlayer)
	end,
	hop = function()
		notify("Hopping...", "info")
		pcall(function() TeleportService:Teleport(game.PlaceId, localPlayer) end)
	end,
	help = function() end,
}

local function handleCommand(message)
	if message:sub(1, #CONFIG.CommandPrefix) ~= CONFIG.CommandPrefix then return false end
	local body = message:sub(#CONFIG.CommandPrefix + 1)
	local spaceIndex = body:find(" ")
	local cmd, args
	if spaceIndex then cmd = body:sub(1, spaceIndex - 1); args = body:sub(spaceIndex + 1)
	else cmd = body end
	cmd = string.lower(cmd)
	local handler = COMMANDS[cmd]
	if handler then task.spawn(handler, args); return true end
	notify("Unknown command: " .. cmd .. " (try /help)", "warn")
	return true
end

-- Command box
local cmdBox = create("Frame", {
	Name = "CommandBox",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 30),
	Size = UDim2.fromOffset(420, 44),
	BackgroundColor3 = THEME.Background,
	Visible = false,
	ZIndex = 20,
}, screenGui)
corner(cmdBox, UDim.new(0, 10))
local cmdBoxStroke = stroke(cmdBox, THEME.Accent, 1.6, 0.2)
gradient(cmdBox, Color3.fromRGB(24, 22, 36), Color3.fromRGB(14, 14, 20), 90)

local cmdIcon = create("TextLabel", {
	Position = UDim2.fromOffset(14, 0),
	Size = UDim2.fromOffset(20, 44),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.Accent2,
	Text = ">",
}, cmdBox)

local cmdInput = create("TextBox", {
	Name = "Input",
	Position = UDim2.fromOffset(40, 0),
	Size = UDim2.new(1, -54, 1, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.Code,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.Text,
	PlaceholderText = "Type a command, then Enter  ( /help )",
	PlaceholderColor3 = THEME.SubText,
	Text = "",
	ClearTextOnFocus = false,
}, cmdBox)

table.insert(themeListeners, function()
	cmdBoxStroke.Color = THEME.Accent
	cmdIcon.TextColor3 = THEME.Accent2
	cmdInput.TextColor3 = THEME.Text
end)

local function openCommandBox(prefill)
	cmdInput.Text = prefill or ""
	cmdBox.Visible = true
	cmdInput:CaptureFocus()
	updateBlur()
end
local function closeCommandBox()
	cmdBox.Visible = false
	cmdInput:ReleaseFocus()
	cmdInput.Text = ""
	updateBlur()
end

-- Help panel
local HELP_WIDTH = 320
local HELP_HEIGHT = 400

local helpPanel = create("Frame", {
	Name = "HelpPanel",
	Position = UDim2.fromOffset(0, 100),
	Size = UDim2.fromOffset(HELP_WIDTH, HELP_HEIGHT),
	BackgroundColor3 = THEME.Background,
	Visible = false,
	ZIndex = 25,
}, screenGui)
corner(helpPanel, UDim.new(0, 14))
local helpStroke = stroke(helpPanel, THEME.Accent, 1.4, 0.25)
gradient(helpPanel, Color3.fromRGB(24, 22, 36), Color3.fromRGB(14, 14, 20), 90)
table.insert(themeListeners, function() helpStroke.Color = THEME.Accent end)

local helpHeader = create("Frame", {
	Name = "Header",
	Position = UDim2.fromOffset(10, 10),
	Size = UDim2.new(1, -20, 0, 32),
	BackgroundTransparency = 1,
}, helpPanel)

local helpDot = create("Frame", {
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.new(0, 2, 0.5, 0),
	Size = UDim2.fromOffset(8, 8),
	BackgroundColor3 = Color3.new(1, 1, 1),
}, helpHeader)
corner(helpDot, UDim.new(1, 0))
local helpDotGradient = gradient(helpDot, THEME.Accent, THEME.Accent2, 45)

create("TextLabel", {
	Position = UDim2.fromOffset(18, 0),
	Size = UDim2.new(1, -60, 1, 0),
	BackgroundTransparency = 1,
	Font = Enum.Font.GothamBold,
	TextSize = 15,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.Text,
	Text = "Kronos Commands",
}, helpHeader)

local helpClose = create("TextButton", {
	Name = "Close",
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, 0, 0.5, 0),
	Size = UDim2.fromOffset(24, 24),
	BackgroundColor3 = THEME.Surface,
	AutoButtonColor = false,
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextColor3 = THEME.SubText,
	Text = "×",
}, helpHeader)
corner(helpClose, UDim.new(1, 0))
attachRipple(helpClose, THEME.Error)
helpClose.MouseEnter:Connect(function() tween(helpClose, { BackgroundColor3 = Color3.fromRGB(190, 60, 70), TextColor3 = THEME.Text }) end)
helpClose.MouseLeave:Connect(function() tween(helpClose, { BackgroundColor3 = THEME.Surface, TextColor3 = THEME.SubText }) end)

table.insert(themeListeners, function()
	helpDotGradient.Color = ColorSequence.new(THEME.Accent, THEME.Accent2)
end)

create("TextLabel", {
	Position = UDim2.fromOffset(12, 44),
	Size = UDim2.new(1, -24, 0, 18),
	BackgroundTransparency = 1,
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = THEME.SubText,
	Text = "Chat or press " .. CONFIG.CommandBoxKey.Name .. "  •  click a row to run",
}, helpPanel)

local helpScroll = create("ScrollingFrame", {
	Name = "Scroll",
	Position = UDim2.fromOffset(10, 68),
	Size = UDim2.new(1, -20, 1, -80),
	BackgroundColor3 = THEME.Section,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	ScrollBarImageColor3 = THEME.Accent,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, helpPanel)
corner(helpScroll, UDim.new(0, 8))
padding(helpScroll, 6)
listLayout(helpScroll, 4)

table.insert(themeListeners, function() helpScroll.ScrollBarImageColor3 = THEME.Accent end)

for i, entry in ipairs(COMMAND_LIST) do
	local row = create("Frame", {
		Name = "Cmd" .. i,
		Size = UDim2.new(1, 0, 0, 32),
		BackgroundColor3 = THEME.Surface,
		LayoutOrder = i,
	}, helpScroll)
	corner(row, UDim.new(0, 6))

	local cmdLabel = create("TextButton", {
		Position = UDim2.fromOffset(8, 0),
		Size = UDim2.new(0, 130, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Code,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.Accent2,
		Text = entry.cmd,
		AutoButtonColor = false,
	}, row)

	create("TextLabel", {
		Position = UDim2.fromOffset(140, 0),
		Size = UDim2.new(1, -148, 1, 0),
		BackgroundTransparency = 1,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = THEME.SubText,
		Text = entry.desc,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, row)

	cmdLabel.Activated:Connect(function()
		if entry.key then toggleFeature(entry.key, entry.label)
		else openCommandBox(entry.cmd:gsub(" <.*", "") .. " ") end
	end)
end

local function openHelpPanel()
	local screen = screenGui.AbsoluteSize
	local x = math.max(20, screen.X - HELP_WIDTH - 20)
	helpPanel.Position = UDim2.fromOffset(x, 100)
	helpPanel.Visible = true
	updateBlur()
	task.defer(function() clampToScreen(helpPanel) end)
end
local function closeHelpPanel()
	helpPanel.Visible = false
	updateBlur()
end

helpClose.Activated:Connect(closeHelpPanel)
makeDraggable(helpHeader, helpPanel)

COMMANDS.help = function() openHelpPanel() end
COMMANDS.cmds = function() openHelpPanel() end

K.helpButton = nil

cmdInput.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		local text = cmdInput.Text
		if text ~= "" then
			if text:sub(1, #CONFIG.CommandPrefix) ~= CONFIG.CommandPrefix then
				text = CONFIG.CommandPrefix .. text
			end
			handleCommand(text)
		end
	end
	closeCommandBox()
end)

-- Keybind handler
local function isTypingInBox()
	local focused = UserInputService:GetFocusedTextBox()
	if focused then return true end
	if cmdBox and cmdBox.Visible then return true end
	return false
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	local capturing = K.capturingKeyFor()
	if capturing then
		if input.KeyCode == Enum.KeyCode.Escape then
			local cb = keybindCallbacks[capturing]
			if cb then cb(KEYBINDS[capturing]) end
			notify("Keybind canceled", "warn")
			K.setCapturingKeyFor(nil)
			return
		end
		if input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
			KEYBINDS[capturing] = input.KeyCode
			local cb = keybindCallbacks[capturing]
			if cb then cb(input.KeyCode) end
			notify(capturing .. " bound to " .. input.KeyCode.Name, "success")
		end
		K.setCapturingKeyFor(nil)
		return
	end	if gameProcessed then return end

	if input.KeyCode == CONFIG.CommandBoxKey and not isTypingInBox() then
		if cmdBox.Visible then closeCommandBox() else openCommandBox(CONFIG.CommandPrefix) end
		return
	end

	if input.KeyCode == Enum.KeyCode.Escape then
		if helpPanel.Visible then closeHelpPanel()
		elseif cmdBox.Visible then closeCommandBox() end
		return
	end

	if isTypingInBox() then return end

	for key, code in pairs(KEYBINDS) do
		if code and input.KeyCode == code then
			setToggle(key, not CONFIG[key])
			notify(string.format("%s %s", key, CONFIG[key] and "ON" or "OFF"),
				CONFIG[key] and "success" or "info")
			break
		end
	end
end)

-- ESP
local guiFolder = create("Folder", { Name = "KronosLabels" }, playerGui)

local overlayGui = create("ScreenGui", {
	Name = "KronosOverlay",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	DisplayOrder = 1,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local tracked = {}

local function isTeammate(player)
	return player.Team ~= nil and player.Team == localPlayer.Team
end

local function getColor(player)
	if player.Team == nil or localPlayer.Team == nil then return CONFIG.EnemyColor end
	return isTeammate(player) and CONFIG.TeammateColor or CONFIG.EnemyColor
end

local SKELETON_BONES_R15 = {
	{ "Head", "UpperTorso" },
	{ "UpperTorso", "LowerTorso" },
	{ "UpperTorso", "LeftUpperArm" },
	{ "LeftUpperArm", "LeftLowerArm" },
	{ "LeftLowerArm", "LeftHand" },
	{ "UpperTorso", "RightUpperArm" },
	{ "RightUpperArm", "RightLowerArm" },
	{ "RightLowerArm", "RightHand" },
	{ "LowerTorso", "LeftUpperLeg" },
	{ "LeftUpperLeg", "LeftLowerLeg" },
	{ "LeftLowerLeg", "LeftFoot" },
	{ "LowerTorso", "RightUpperLeg" },
	{ "RightUpperLeg", "RightLowerLeg" },
	{ "RightLowerLeg", "RightFoot" },
}
local SKELETON_BONES_R6 = {
	{ "Head", "Torso" },
	{ "Torso", "Left Arm" },
	{ "Left Arm", "Left Leg" },
	{ "Torso", "Right Arm" },
	{ "Right Arm", "Right Leg" },
	{ "Torso", "Left Leg" },
	{ "Torso", "Right Leg" },
}

local function removeESP(player)
	local data = tracked[player]
	if not data then return end
	if data.highlight then data.highlight:Destroy() end
	if data.gui then data.gui:Destroy() end
	if data.tracer then data.tracer:Destroy() end
	if data.box then data.box:Destroy() end
	if data.boxStroke then data.boxStroke:Destroy() end
	if data.healthGui then data.healthGui:Destroy() end
	if data.skeletonLines then
		for _, line in pairs(data.skeletonLines) do
			if line then line:Destroy() end
		end
	end
	tracked[player] = nil
end

local function createESP(player, character)
	removeESP(player)
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if not root then return end
	local humanoid = character:WaitForChild("Humanoid", 5)

	local highlight = create("Highlight", {
		Name = "KronosHighlight",
		Adornee = character,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
		FillTransparency = 0.9,
		OutlineTransparency = 0,
	}, character)

	local gui = create("BillboardGui", {
		Name = "Label_" .. player.Name,
		Adornee = root,
		AlwaysOnTop = true,
		Size = UDim2.fromOffset(160, 40),
		StudsOffset = Vector3.new(0, 3.5, 0),
	}, guiFolder)

	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextStrokeTransparency = 0.5,
	}, gui)

	local box = create("Frame", {
		Name = "Box_" .. player.Name,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 1,
	}, overlayGui)
	local boxStroke = stroke(box, Color3.new(1, 1, 1), 1, 0)

	local healthGui = create("BillboardGui", {
		Name = "Health_" .. player.Name,
		Adornee = root,
		AlwaysOnTop = true,
		Size = UDim2.fromOffset(6, 40),
		StudsOffset = Vector3.new(-1.6, 3.5, 0),
	}, guiFolder)
	local healthBg = create("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(40, 40, 50),
		BorderSizePixel = 0,
	}, healthGui)
	corner(healthBg, UDim.new(0.4, 0))
	local healthFill = create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(80, 220, 120),
		BorderSizePixel = 0,
	}, healthBg)
	corner(healthFill, UDim.new(0.4, 0))

	local skeletonLines = {}

	local tracer = create("Frame", {
		Name = "Tracer_" .. player.Name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 0,
	}, overlayGui)

	tracked[player] = {
		highlight = highlight,
		gui = gui,
		label = label,
		tracer = tracer,
		root = root,
		humanoid = humanoid,
		box = box,
		boxStroke = boxStroke,
		healthGui = healthGui,
		healthFill = healthFill,
		skeletonLines = skeletonLines,
	}
end

local function setupPlayer(player)
	if player == localPlayer then return end
	if player.Character then task.spawn(createESP, player, player.Character) end
	player.CharacterAdded:Connect(function(character) createESP(player, character) end)
	player.CharacterRemoving:Connect(function() removeESP(player) end)
end

for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(removeESP)

local function positionLine(line, a, b, color, thickness)
	local delta = b - a
	line.Size = UDim2.fromOffset(delta.Magnitude, thickness)
	line.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2)
	line.Rotation = math.deg(math.atan2(delta.Y, delta.X))
	line.BackgroundColor3 = color
	line.BackgroundTransparency = 0
	line.Visible = true
end

RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.zero
	local myChar = localPlayer.Character
	local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

	for player, data in pairs(locatedPlayers) do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and data.frame then
			local pos = camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3.5, 0))
			if pos.Z > 0 then
				local cx = math.clamp(pos.X, 60, viewport.X - 60)
				local cy = math.clamp(pos.Y, 20, viewport.Y - 20)
				data.frame.Position = UDim2.fromOffset(cx - 40, cy)
				data.frame.Visible = true
			else
				data.frame.Visible = false
			end
		elseif data.frame then
			data.frame.Visible = false
		end
	end

	for player, data in pairs(tracked) do
		local visible = myRoot ~= nil and data.root and data.root.Parent ~= nil
		local showLabel = false
		local showTracer = false

		if visible then
			local distance = (data.root.Position - myRoot.Position).Magnitude
			local team = isTeammate(player)
			visible = distance <= CONFIG.MaxDistance and (not team or CONFIG.ShowTeammates)

			if visible then
				local color = getColor(player)
				data.highlight.FillColor = color
				data.highlight.OutlineColor = color
				data.label.TextColor3 = color
				data.label.TextSize = CONFIG.LabelSize

				data.highlight.FillTransparency = CONFIG.ShowChams and 0 or (CONFIG.Enabled and CONFIG.FillTransparency / 100 or 1)
				data.highlight.OutlineTransparency = CONFIG.Enabled and 0 or 1

				if CONFIG.ShowBox then
					local head = data.root.Parent and data.root.Parent:FindFirstChild("Head")
					if head then
						local top = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.7, 0))
						local bottom = camera:WorldToViewportPoint(data.root.Position - Vector3.new(0, 3.2, 0))
						if top.Z > 0 and bottom.Z > 0 then
							local h = math.abs(bottom.Y - top.Y)
							local w = h * 0.6
							local cx = (top.X + bottom.X) / 2
							local cy = (top.Y + bottom.Y) / 2
							data.box.Size = UDim2.fromOffset(w, h)
							data.box.Position = UDim2.fromOffset(cx - w / 2, cy - h / 2)
							data.box.Visible = true
							data.boxStroke.Color = color
							data.boxStroke.Thickness = CONFIG.BoxThickness
						else
							data.box.Visible = false
						end
					else
						data.box.Visible = false
					end
				else
					data.box.Visible = false
				end

				if CONFIG.ShowHealthBar and data.humanoid then
					local hp = math.clamp(data.humanoid.Health / math.max(1, data.humanoid.MaxHealth), 0, 1)
					data.healthFill.Size = UDim2.fromScale(1, hp)
					data.healthFill.BackgroundColor3 = Color3.new(1 - hp, hp, 0.2)
					data.healthGui.Enabled = true
				else
					data.healthGui.Enabled = false
				end

				if CONFIG.ShowSkeleton then
					local character = data.root.Parent
					local bones = character:FindFirstChild("UpperTorso") and SKELETON_BONES_R15 or SKELETON_BONES_R6
					local screenPos = {}
					for _, pair in ipairs(bones) do
						for _, boneName in ipairs(pair) do
							if not screenPos[boneName] then
								local part = character:FindFirstChild(boneName)
								if part and part:IsA("BasePart") then
									local vp = camera:WorldToViewportPoint(part.Position)
									if vp.Z > 0 then
										screenPos[boneName] = Vector2.new(vp.X, vp.Y)
									end
								end
							end
						end
					end
					for i, pair in ipairs(bones) do
						local a = screenPos[pair[1]]
						local b = screenPos[pair[2]]
						local line = data.skeletonLines[i]
						if not line then
							line = create("Frame", {
								BackgroundColor3 = color,
								BorderSizePixel = 0,
								Visible = false,
								ZIndex = 2,
							}, overlayGui)
							data.skeletonLines[i] = line
						end
						if a and b then positionLine(line, a, b, color, 1)
						else line.Visible = false end
					end
					for i = #bones + 1, #data.skeletonLines do
						if data.skeletonLines[i] then data.skeletonLines[i].Visible = false end
					end
				else
					for _, line in pairs(data.skeletonLines) do
						if line then line.Visible = false end
					end
				end

				if CONFIG.ShowTracers and camera then
					local pos = camera:WorldToViewportPoint(data.root.Position)
					if pos.Z > 0 then
						local originY = viewport.Y
						if CONFIG.TracerOrigin == "Center" then originY = viewport.Y / 2
						elseif CONFIG.TracerOrigin == "Top" then originY = 0 end
						local from = Vector2.new(viewport.X / 2, originY)
						local to = Vector2.new(pos.X, pos.Y)
						local delta = to - from
						data.tracer.Size = UDim2.fromOffset(delta.Magnitude, CONFIG.TracerThickness)
						data.tracer.Position = UDim2.fromOffset((from.X + to.X) / 2, (from.Y + to.Y) / 2)
						data.tracer.Rotation = math.deg(math.atan2(delta.Y, delta.X))
						data.tracer.BackgroundColor3 = color
						showTracer = true
					end
				end

				local textParts = {}
				if CONFIG.ShowNames then table.insert(textParts, player.DisplayName) end
				if CONFIG.ShowDistance then table.insert(textParts, string.format("[%d]", math.floor(distance))) end
				showLabel = #textParts > 0
				data.label.Text = table.concat(textParts, " ")
			end
		end

		data.highlight.Enabled = visible and (CONFIG.Enabled or CONFIG.ShowChams)
		data.gui.Enabled = visible and showLabel
		data.tracer.Visible = showTracer
		if not visible then
			data.box.Visible = false
			data.healthGui.Enabled = false
			for _, line in pairs(data.skeletonLines) do
				if line then line.Visible = false end
			end
		end
	end
end)

localPlayer.Chatted:Connect(handleCommand)

-- Noclip
RunService.Stepped:Connect(function()
	if not CONFIG.Noclip then return end
	local character = localPlayer.Character
	if not character then return end
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
	end
end)

-- Super Jump
function applySuperJump()
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if CONFIG.SuperJump then
		hum.UseJumpPower = true
		hum.JumpPower = CONFIG.SuperJumpPower
	else
		hum.JumpPower = 50
		hum.UseJumpPower = true
	end
end
toggleHandlers.SuperJump = applySuperJump
localPlayer.CharacterAdded:Connect(function() task.wait(0.2); applySuperJump() end)
if localPlayer.Character then task.spawn(applySuperJump) end

-- Custom Speed
local function applySpeed()
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if CONFIG.UseCustomSpeed then hum.WalkSpeed = CONFIG.WalkSpeed
	else hum.WalkSpeed = 16 end
end
toggleHandlers.UseCustomSpeed = applySpeed
localPlayer.CharacterAdded:Connect(function() task.wait(0.2); applySpeed() end)
if localPlayer.Character then task.spawn(applySpeed) end

-- Anti-AFK
task.spawn(function()
	while true do
		task.wait(60)
		if CONFIG.AntiAFK then
			pcall(function()
				local vu = game:GetService("VirtualUser")
				vu:CaptureController()
				vu:ClickButton2(Vector2.new())
			end)
		end
	end
end)

toggleHandlers.Watermark = function(on) watermark.Visible = on end
toggleHandlers.ShowFPS = function(on) fpsLabel.Visible = on end
watermark.Visible = CONFIG.Watermark
fpsLabel.Visible = CONFIG.ShowFPS

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
	if not CONFIG.InfiniteJump then return end
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

local flyKeybinds = {
	Forward = { Enum.KeyCode.W },
	Backward = { Enum.KeyCode.S },
	Left = { Enum.KeyCode.A },
	Right = { Enum.KeyCode.D },
	Up = { Enum.KeyCode.Space },
	Down = { Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl },
}

local function isFlyKeyDown(list)
	for _, k in ipairs(list) do if UserInputService:IsKeyDown(k) then return true end end
	return false
end

-- Fly
local flyBodyVelocity, flyBodyGyro, flyHeartbeat

local function stopFly()
	if flyHeartbeat then flyHeartbeat:Disconnect(); flyHeartbeat = nil end
	if flyBodyVelocity then flyBodyVelocity:Destroy(); flyBodyVelocity = nil end
	if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = false end
end

local function startFly()
	stopFly()
	local char = localPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end

	flyBodyVelocity = Instance.new("BodyVelocity")
	flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	flyBodyVelocity.Velocity = Vector3.zero
	flyBodyVelocity.Parent = root

	flyBodyGyro = Instance.new("BodyGyro")
	flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	flyBodyGyro.P = 1000
	flyBodyGyro.D = 50
	flyBodyGyro.CFrame = root.CFrame
	flyBodyGyro.Parent = root

	hum.PlatformStand = true

	flyHeartbeat = RunService.Heartbeat:Connect(function()
		if not CONFIG.Fly or not flyBodyVelocity then return end
		local cam = workspace.CurrentCamera
		if not cam then return end
		local move = Vector3.zero
		if isFlyKeyDown(flyKeybinds.Forward) then move += cam.CFrame.LookVector end
		if isFlyKeyDown(flyKeybinds.Backward) then move -= cam.CFrame.LookVector end
		if isFlyKeyDown(flyKeybinds.Right) then move += cam.CFrame.RightVector end
		if isFlyKeyDown(flyKeybinds.Left) then move -= cam.CFrame.RightVector end
		if isFlyKeyDown(flyKeybinds.Up) then move += Vector3.yAxis end
		if isFlyKeyDown(flyKeybinds.Down) then move -= Vector3.yAxis end
		if move.Magnitude > 0 then move = move.Unit * CONFIG.FlySpeed end
		flyBodyVelocity.Velocity = move
		flyBodyGyro.CFrame = CFrame.new(root.Position) * (cam.CFrame - cam.CFrame.Position)
	end)
end

toggleHandlers.Fly = function(on)
	if on then startFly() else stopFly() end
end
localPlayer.CharacterAdded:Connect(function()
	if CONFIG.Fly then task.wait(0.35); startFly() end
end)

-- Silent Fly
local silentFlyConn, silentFlyCamType, silentFlyRootLockConn, silentFlyControls

local function restoreControls()
	if silentFlyControls then
		pcall(function() silentFlyControls:Enable() end)
		silentFlyControls = nil
	end
end

local function stopSilentFly()
	if silentFlyConn then silentFlyConn:Disconnect(); silentFlyConn = nil end
	if silentFlyRootLockConn then silentFlyRootLockConn:Disconnect(); silentFlyRootLockConn = nil end
	restoreControls()
	local cam = workspace.CurrentCamera
	if cam and silentFlyCamType then cam.CameraType = silentFlyCamType; silentFlyCamType = nil end
end

local function startSilentFly()
	stopSilentFly()
	local cam = workspace.CurrentCamera
	if not cam then return end
	silentFlyCamType = cam.CameraType
	cam.CameraType = Enum.CameraType.Scriptable

	local playerScripts = localPlayer:FindFirstChild("PlayerScripts")
	if playerScripts then
		local mod = playerScripts:FindFirstChild("PlayerModule")
		if mod then
			local ok, controls = pcall(function() return require(mod):GetControls() end)
			if ok and controls then
				silentFlyControls = controls
				pcall(function() controls:Disable() end)
			end
		end
	end

	local char = localPlayer.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = 0; hum.JumpPower = 0; hum.UseJumpPower = true end
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			local lockedCF = root.CFrame
			silentFlyRootLockConn = RunService.Stepped:Connect(function()
				if root and root.Parent then
					root.CFrame = lockedCF
					root.AssemblyLinearVelocity = Vector3.zero
					root.AssemblyAngularVelocity = Vector3.zero
				end
			end)
		end
	end

	silentFlyConn = RunService.RenderStepped:Connect(function(dt)
		if not CONFIG.SilentFly then return end
		local camera = workspace.CurrentCamera
		if not camera then return end
		local cf = camera.CFrame
		local move = Vector3.zero
		if isFlyKeyDown(flyKeybinds.Forward) then move += cf.LookVector end
		if isFlyKeyDown(flyKeybinds.Backward) then move -= cf.LookVector end
		if isFlyKeyDown(flyKeybinds.Right) then move += cf.RightVector end
		if isFlyKeyDown(flyKeybinds.Left) then move -= cf.RightVector end
		if isFlyKeyDown(flyKeybinds.Up) then move += Vector3.yAxis end
		if isFlyKeyDown(flyKeybinds.Down) then move -= Vector3.yAxis end
		if move.Magnitude > 0 then
			camera.CFrame = cf + move.Unit * CONFIG.SilentFlySpeed * dt
		end
	end)
end

toggleHandlers.SilentFly = function(on)
	if on then startSilentFly()
	else
		stopSilentFly()
		local char = localPlayer.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
	end
end
localPlayer.CharacterAdded:Connect(function()
	if CONFIG.SilentFly then task.wait(0.3); startSilentFly() end
end)

-- Vehicle Fly
local vehicleFlyConn, vehicleBV, vehicleBG

local function stopVehicleFly()
	if vehicleFlyConn then vehicleFlyConn:Disconnect(); vehicleFlyConn = nil end
	if vehicleBV then vehicleBV:Destroy(); vehicleBV = nil end
	if vehicleBG then vehicleBG:Destroy(); vehicleBG = nil end
end

local function startVehicleFly()
	stopVehicleFly()
	local char = localPlayer.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local seat = hum and hum.SeatPart
	if not seat then
		notify("Not in a vehicle", "warn")
		return
	end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	vehicleBV = Instance.new("BodyVelocity")
	vehicleBV.MaxForce = Vector3.new(1e6, 1e6, 1e6)
	vehicleBV.Velocity = Vector3.zero
	vehicleBV.Parent = root

	vehicleBG = Instance.new("BodyGyro")
	vehicleBG.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
	vehicleBG.P = 3000
	vehicleBG.D = 100
	vehicleBG.CFrame = root.CFrame
	vehicleBG.Parent = root

	vehicleFlyConn = RunService.Heartbeat:Connect(function()
		if not CONFIG.VehicleFly or not vehicleBV then return end
		local cam = workspace.CurrentCamera
		if not cam then return end
		local ch = localPlayer.Character
		local h = ch and ch:FindFirstChildOfClass("Humanoid")
		if not h or not h.SeatPart then stopVehicleFly(); return end
		local move = Vector3.zero
		if isFlyKeyDown(flyKeybinds.Forward) then move += cam.CFrame.LookVector end
		if isFlyKeyDown(flyKeybinds.Backward) then move -= cam.CFrame.LookVector end
		if isFlyKeyDown(flyKeybinds.Right) then move += cam.CFrame.RightVector end
		if isFlyKeyDown(flyKeybinds.Left) then move -= cam.CFrame.RightVector end
		if isFlyKeyDown(flyKeybinds.Up) then move += Vector3.yAxis end
		if isFlyKeyDown(flyKeybinds.Down) then move -= Vector3.yAxis end
		if move.Magnitude > 0 then move = move.Unit * CONFIG.VehicleFlySpeed end
		vehicleBV.Velocity = move
		vehicleBG.CFrame = CFrame.new(root.Position) * (cam.CFrame - cam.CFrame.Position)
	end)
end

toggleHandlers.VehicleFly = function(on)
	if on then startVehicleFly() else stopVehicleFly() end
end

localPlayer.CharacterAdded:Connect(function(ch)
	local hum = ch:WaitForChild("Humanoid", 5)
	if not hum then return end
	hum.Seated:Connect(function(seated)
		if CONFIG.VehicleFly then
			if seated then task.wait(0.25); startVehicleFly()
			else stopVehicleFly() end
		end
	end)
	if CONFIG.VehicleFly and hum.SeatPart then task.wait(0.35); startVehicleFly() end
end)

-- Swim
local function applySwim()
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	if CONFIG.Swim then
		hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
		hum:ChangeState(Enum.HumanoidStateType.Swimming)
	else
		if hum:GetState() == Enum.HumanoidStateType.Swimming then
			hum:ChangeState(Enum.HumanoidStateType.Running)
		end
	end
end

toggleHandlers.Swim = function(on)
	if on then
		applySwim()
		task.spawn(function()
			while CONFIG.Swim and localPlayer.Character do
				local hum = localPlayer.Character:FindFirstChildOfClass("Humanoid")
				if hum then
					hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
					if hum:GetState() ~= Enum.HumanoidStateType.Swimming then
						hum:ChangeState(Enum.HumanoidStateType.Swimming)
					end
				end
				task.wait(0.3)
			end
		end)
	else
		applySwim()
	end
end

localPlayer.CharacterAdded:Connect(function()
	if CONFIG.Swim then task.wait(0.3); applySwim() end
end)

-- Slow Falling
local slowFallHeartbeat

local function stopSlowFalling()
	if slowFallHeartbeat then slowFallHeartbeat:Disconnect(); slowFallHeartbeat = nil end
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = false end
end

local function startSlowFalling()
	stopSlowFalling()
	slowFallHeartbeat = RunService.Heartbeat:Connect(function()
		if not CONFIG.SlowFalling then return end
		local char = localPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			root.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
		end
	end)
end

toggleHandlers.SlowFalling = function(on)
	if on then startSlowFalling() else stopSlowFalling() end
end

localPlayer.CharacterAdded:Connect(function()
	if CONFIG.SlowFalling then task.wait(0.2); startSlowFalling() end
end)

-- Float
local floatHeartbeat
local floatLastY = nil

local function stopFloat()
	if floatHeartbeat then floatHeartbeat:Disconnect(); floatHeartbeat = nil end
	floatLastY = nil
	local char = localPlayer.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
		hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
	end
end

local function startFloat()
	stopFloat()
	local char = localPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end

	floatLastY = root.Position.Y
	hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)

	floatHeartbeat = RunService.Heartbeat:Connect(function()
		if not CONFIG.Float then return end
		local ch = localPlayer.Character
		local r = ch and ch:FindFirstChild("HumanoidRootPart")
		local h = ch and ch:FindFirstChildOfClass("Humanoid")
		if not r or not h then return end
		local onGround = h.FloorMaterial ~= Enum.Material.Air
		if onGround then
			floatLastY = r.Position.Y
		else
			if floatLastY then
				local currentY = r.Position.Y
				local vel = r.AssemblyLinearVelocity
				if vel.Y <= 0.1 then
					local diff = floatLastY - currentY
					if math.abs(diff) > 0.05 then
						r.CFrame = r.CFrame + Vector3.new(0, diff * 0.35, 0)
						r.AssemblyLinearVelocity = Vector3.new(vel.X, 0, vel.Z)
					end
					if h:GetState() == Enum.HumanoidStateType.Freefall
						or h:GetState() == Enum.HumanoidStateType.FallingDown then
						h:ChangeState(Enum.HumanoidStateType.Running)
					end
				end
			end
		end
	end)
end

toggleHandlers.Float = function(on)
	if on then startFloat() else stopFloat() end
end

localPlayer.CharacterAdded:Connect(function()
	if CONFIG.Float then task.wait(0.2); startFloat() end
end)

-- TP Tool
local tpConn

local function stopTPTool()
	if tpConn then tpConn:Disconnect(); tpConn = nil end
end

local function startTPTool()
	stopTPTool()
	tpConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not CONFIG.TPTool then return end
		if gameProcessed then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local mouse = localPlayer:GetMouse()
		if mouse and mouse.Target then
			local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
			if root and mouse.Hit then
				root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
				notify("Teleported", "success")
			end
		end
	end)
end

toggleHandlers.TPTool = function(on)
	if on then startTPTool() else stopTPTool() end
end

-- Wall TP
local wallTPConn

local function stopWallTP()
	if wallTPConn then wallTPConn:Disconnect(); wallTPConn = nil end
end

local function startWallTP()
	stopWallTP()
	wallTPConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not CONFIG.WallTP then return end
		if gameProcessed then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		local mouse = localPlayer:GetMouse()
		if not mouse or not mouse.Target then return end
		local target = mouse.Target
		if not target:IsA("BasePart") then return end
		if target.Transparency >= 1 or not target.CanCollide then return end

		local char = localPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end

		local cam = workspace.CurrentCamera
		local unitRay = cam:ScreenPointToRay(mouse.X, mouse.Y)
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = { char }
		local hit = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, rayParams)
		if not hit then return end

		local origin2 = hit.Position + unitRay.Direction * 8
		local hit2 = workspace:Raycast(origin2, -unitRay.Direction * 20, rayParams)
		local exitPos
		if hit2 then
			exitPos = hit2.Position + unitRay.Direction * 3
		else
			exitPos = hit.Position + unitRay.Direction * 6
		end

		root.CFrame = CFrame.new(exitPos + Vector3.new(0, 2, 0))
		notify("Wall TP", "success")
	end)
end

toggleHandlers.WallTP = function(on)
	if on then startWallTP() else stopWallTP() end
end

-- Spam
local spamConn

local function stopSpam()
	if spamConn then spamConn:Disconnect(); spamConn = nil end
end

local function startSpam()
	stopSpam()
	spamConn = RunService.Heartbeat:Connect(function()
		if not CONFIG.Spam then return end
		local char = localPlayer.Character
		local tool = char and char:FindFirstChildOfClass("Tool")
		if tool then
			pcall(function() tool:Activate() end)
			task.wait(CONFIG.SpamDelay / 1000)
		end
	end)
end

toggleHandlers.Spam = function(on)
	if on then startSpam() else stopSpam() end
end

-- X-Ray
local xrayOriginals = {}

local function restoreXRay()
	for part, origTrans in pairs(xrayOriginals) do
		if part and part.Parent then
			part.Transparency = origTrans
		end
	end
	xrayOriginals = {}
end

local function applyXRay()
	restoreXRay()
	local targetTrans = CONFIG.XRayTransparency / 100
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("BasePart") then
			local char = localPlayer.Character
			if not (char and d:IsDescendantOf(char)) then
				xrayOriginals[d] = d.Transparency
				d.Transparency = targetTrans
			end
		end
	end
end

toggleHandlers.XRay = function(on)
	if on then
		applyXRay()
		notify("X-Ray applied", "success")
	else
		restoreXRay()
	end
end

-- Spectate
toggleHandlers.Spectate = function(on)
	if not on then stopSpectate() end
end

-- Anti-Void
local antivoidConn
local lastSafeCF = nil

local function startAntiVoid()
	if antivoidConn then antivoidConn:Disconnect() end
	antivoidConn = RunService.Heartbeat:Connect(function()
		if not CONFIG.AntiVoid then return end
		local char = localPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		if root.Position.Y > -100 then
			lastSafeCF = root.CFrame
		end
		if root.Position.Y < -100 then
			if lastSafeCF then
				root.CFrame = lastSafeCF + Vector3.new(0, 5, 0)
				root.AssemblyLinearVelocity = Vector3.zero
				notify("Anti-Void rescued you", "success")
			else
				root.CFrame = CFrame.new(0, 50, 0)
			end
		end
	end)
end

toggleHandlers.AntiVoid = function(on)
	if on then startAntiVoid()
	else
		if antivoidConn then antivoidConn:Disconnect(); antivoidConn = nil end
	end
end

localPlayer.CharacterAdded:Connect(function()
	if CONFIG.AntiVoid then task.wait(0.2); startAntiVoid() end
end)

-- Anti-Fling
local antiflingConn = nil
local antiflingGyro = nil

local function stopAntiFling()
	if antiflingConn then antiflingConn:Disconnect(); antiflingConn = nil end
	if antiflingGyro then antiflingGyro:Destroy(); antiflingGyro = nil end
end

local function startAntiFling()
	stopAntiFling()
	local char = localPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not root or not hum then return end

	antiflingGyro = Instance.new("BodyGyro")
	antiflingGyro.Name = "KronosAntiFlingGyro"
	antiflingGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
	antiflingGyro.P = 10000
	antiflingGyro.D = 200
	antiflingGyro.CFrame = root.CFrame
	antiflingGyro.Parent = root

	local lockedCF = root.CFrame

	antiflingConn = RunService.Heartbeat:Connect(function()
		if not CONFIG.AntiFling then return end
		local ch = localPlayer.Character
		local r = ch and ch:FindFirstChild("HumanoidRootPart")
		local h = ch and ch:FindFirstChildOfClass("Humanoid")
		if not r or not h then return end

		pcall(function()
			h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		end)

		local vel = r.AssemblyLinearVelocity
		local maxSpeed = 200
		if vel.Magnitude > maxSpeed then
			r.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			r.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
			r.CFrame = lockedCF
		end

		r.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

		if vel.Magnitude < maxSpeed then
			lockedCF = CFrame.new(r.Position, r.Position + r.CFrame.LookVector)
		end

		if antiflingGyro then
			antiflingGyro.CFrame = CFrame.new(r.Position, r.Position + r.CFrame.LookVector)
		end
	end)
end

toggleHandlers.AntiFling = function(on)
	if on then startAntiFling() else stopAntiFling() end
end

localPlayer.CharacterAdded:Connect(function()
	if CONFIG.AntiFling then task.wait(0.25); startAntiFling() end
end)

-- Startup config load
task.spawn(function()
	task.wait(0.5)
	if K.loadConfig() then
		for _, refresh in ipairs(refreshers) do refresh() end
		refreshKeybindChips()
		notify("Config loaded", "success")
	end
end)