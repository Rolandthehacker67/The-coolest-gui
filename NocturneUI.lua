--[[

	═══════════════════════════════════════════════════════════════════════════════
	 ██████╗  ██████╗ ██████╗ ████████╗██╗  ██╗██╗   ██╗██████╗ ███╗   ██╗███████╗███████╗
	██╔════╝ ██╔═══██╗██╔══██╗╚══██╔══╝██║  ██║██║   ██║██╔══██╗████╗  ██║██╔════╝██╔════╝
	██║  ███╗██║   ██║██║  ██║   ██║   ███████║██║   ██║██████╔╝██╔██╗ ██║█████╗  ███████╗
	██║   ██║██║   ██║██║  ██║   ██║   ██╔══██║██║   ██║██╔═══╝ ██║╚██╗██║██╔══╝  ╚════██║
	╚██████╔╝╚██████╔╝██████╔╝   ██║   ██║  ██║╚██████╔╝██║     ██║ ╚████║███████╗███████║
	 ╚═════╝  ╚═════╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝  ╚═══╝╚══════╝╚══════╝
	                                        L I Q U I D   G L A S S
	═══════════════════════════════════════════════════════════════════════════════

	Nocturne is a dark "liquid glass" UI framework for Roblox, in the spirit of the
	glassmorphism language shipped in recent iOS and macOS releases: translucent
	layers, refractive edge light, specular sheen that tracks the cursor, drifting
	caustics, and soft volumetric shadow.

	It is a single LocalScript. Drop it anywhere that runs (StarterPlayerScripts is
	the usual home) and it builds itself. It contains zero game features by design:
	every button, switch, slider, card and window is a placeholder that demonstrates
	the look. Nothing reads from the game, nothing writes to it, nothing is sent
	network-side. That makes it safe to hand to anyone, and easy to strip into your
	own project when you are ready to wire behaviour in.

	  • ZERO ASSETS. No image IDs, no font packs, no mesh, no external content.
	    Every icon is drawn with Frames. Every gradient is a UIGradient. The kit
	    works with nothing but the Roblox engine, and never needs asset permissions.
	  • REAL GLASS PHYSICS. Springs, not tweens, for everything that moves; the
	    surfaces wobble, overshoot and settle the way physical material does.
	  • SCENE DEPTH. When glass comes forward the world behind it blurs and dims,
	    the same way the camera does in a vibrancy UI.
	  • 60 FPS DISCIPLINE. One scheduler, one RenderStepped pump, pooling, dirty
	    flags, and a reduce-motion mode for people who need it.
	  • OPEN SOURCE. MIT. Do what you like, keep the header, credit is a kindness.

	Quick start
	───────────
		-- Place this script in StarterPlayerScripts. It self-boots.
		-- Or boot it yourself and grab the API:
		local Nocturne = require(path.to.Nocturne)   -- if you convert it to a Module
		Nocturne.open("settings")

		-- Make a glass surface:
		local frame = Nocturne.Glass.panel(parent, {
			size = UDim2.fromScale(0.36, 0.4),
			roundness = 26,
			tint = 0.14,
		})

		-- Make a placeholder button:
		Nocturne.Widgets.button(frame, {
			label = "Continue",
			variant = "primary",
			onClicked = function() print("placeholder") end,
		})

	Hotkeys
	───────
		Ctrl/Cmd + K ......... Command palette
		Ctrl/Cmd + , ......... Settings
		Ctrl/Cmd + J ......... Dock toggle
		Ctrl/Cmd + M ......... Minimise focused window
		Ctrl/Cmd + E ......... Mission control (exposé)
		Ctrl/Cmd + Shift + F . Fullscreen this script's UI
		Ctrl/Cmd + Shift + L . Lock screen
		Tab .................. Cycle focus ring through glass surfaces
		Esc .................. Close topmost surface
		↑ ↑ ↓ ↓ ← → ← → B A . Developer surprise

	Layout of this file
	───────────────────
		§ 1   Header, banner, license text ................. this block
		§ 2   Services and engine capability probes
		§ 3   Configuration (every knob in one table)
		§ 4   Utilities (math, colour, string, table, time)
		§ 5   Signals, connections, pooling
		§ 6   Spring animation engine and scheduler
		§ 7   Themes (dark glass palettes) and the theme manager
		§ 8   Glass core (the refractive surface itself)
		§ 9   Icon kit (procedural frames-only icons)
		§ 10  Windows, window manager, mission control
		§ 11  Widgets: buttons, switches, sliders, inputs, tabs, menus…
		§ 12  Chrome: dock, menu bar, control centre, toasts
		§ 13  Command palette, keybinds, cheat codes, viewing modes
		§ 14  Demo apps (settings, profile, media, stats, tasks, chat)
		§ 15  Lock screen, boot sequence, ambience, wallpaper engine
		§ 16  Public API, persistence, diagnostics, teardown
		§ 17  Bootstrap

	MIT License

	Copyright (c) 2026 Nocturne UI contributors

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all
	copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.

═══════════════════════════════════════════════════════════════════════════════]]

--═══════════════════════════════════════════════════════════════════════════════--
-- § 2  SERVICES, CAPABILITY PROBES, GLOBAL STATE
--═══════════════════════════════════════════════════════════════════════════════--

local Nocturne = {
	VERSION = "1.0.0",
	CODENAME = "Obsidian Refraction",
	BUILD = 20260913,
	AUTHOR = "Nocturne UI contributors",
	LICENSE = "MIT",
}

Nocturne.__index = Nocturne

-- Services, fetched the boring way so this file survives being required, copied,
-- inlined, or pasted into a Studio command bar.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ContextActionService = game:GetService("ContextActionService")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer and LocalPlayer:WaitForChild("PlayerGui") or nil

-- Guard against an engine that somehow refuses the service; the framework degrades
-- to zero inset offsets instead of failing to load.
local GuiServiceSafe = GuiService
pcall(function()
	if not GuiServiceSafe then
		GuiServiceSafe = game:GetService("GuiService")
	end
end)

-- Capability probes. The kit is built from primitives that exist everywhere, but
-- a few of the nicer touches (scene blur, colour correction, canvas groups) are
-- engine features that older clients or restricted places can refuse. We probe
-- once, at load, and every later use is a cheap boolean test instead of a pcall.
local Capabilities = {
	sceneBlur = false,
	sceneColorCorrection = false,
	canvasGroup = false,
	uiskew = false,
	gradientRotation = false,
	cornerSoftness = false,
	viewportCapture = false,
	soundFx = false,
	touch = false,
	tableClear = true,
}

pcall(function()
	local probe = Instance.new("Frame")
	local canvas = Instance.new("CanvasGroup")
	canvas.Name = "nocturne_canvas_probe"
	canvas.Parent = probe
	Capabilities.canvasGroup = canvas:IsA("CanvasGroup")
	canvas:Destroy()

	local skew = Instance.new("UISkew")
	Capabilities.uiskew = skew ~= nil
	skew:Destroy()

	local grad = Instance.new("UIGradient")
	grad.Rotation = 12
	Capabilities.gradientRotation = true
	grad:Destroy()

	local corner = Instance.new("UICorner")
	corner.Parent = probe
	Capabilities.cornerSoftness = corner:FindProperty("Softness") ~= nil
	corner:Destroy()
	probe:Destroy()
end)

pcall(function()
	local blur = Instance.new("BlurEffect")
	Capabilities.sceneBlur = blur ~= nil
	blur:Destroy()
	local cc = Instance.new("ColorCorrectionEffect")
	Capabilities.sceneColorCorrection = cc ~= nil
	cc:Destroy()
end)

pcall(function()
	local snd = Instance.new("Sound")
	snd.Parent = SoundService
	snd:Destroy()
	Capabilities.soundFx = true
end)

Capabilities.touch = UserInputService.TouchEnabled
Capabilities.keyboard = UserInputService.KeyboardEnabled

-- The environment we are running inside changes a few decisions: no scene exists
-- in Studio's UI-only test views, and in-app viewports want cheaper effects.
local IsStudio = RunService:IsStudio()
local IsClient = RunService:IsClient()
local IsAppView = false
pcall(function()
	if typeof(RunService.IsAppViewMode) == "function" then
		IsAppView = RunService:IsAppViewMode()
	end
end)

-- Every instance this file ever creates is registered here, tagged with the
-- subsystem that owns it. Teardown is then O(registry) instead of "hope the
-- collection service catches it", which matters because this kit is designed to
-- be dropped into projects where a stray ScreenGui is a shipped bug.
local InstanceRegistry = {
	_surfaces = 0,
	_widgets = 0,
	_windows = 0,
	_frames = 0,
}

local function register(kind: string, instance: Instance)
	if instance ~= nil then
		local bucket = InstanceRegistry[kind]
		if type(bucket) == "number" then
			InstanceRegistry[kind] = bucket + 1
		else
			InstanceRegistry[kind] = 1
		end
	end
	return instance
end

-- Global mutable state, kept in one table so a reader can find every field that
-- moves at runtime. Nothing in this file writes to the game data model except
-- through the ScreenGui this kit owns.
local State = {
	ready = false,
	booted = false,
	hidden = false,
	locked = false,
	focusedWindow = nil,
	openWindows = {},
	openWindowCount = 0,
	activeSurface = nil,
	overlayStack = {},
	zCounter = 100,
	dockVisible = true,
	menuBarVisible = true,
	paletteVisible = false,
	missionControl = false,
	controlCentreOpen = false,
	notificationCentreOpen = false,
	currentTheme = "obsidian",
	currentAccent = "moonstone",
	viewMode = "standard",
	reduceMotion = false,
	contrastBoost = false,
	blurStrength = 1,
	uiScale = 1,
	captureMode = false,
	screenshotHint = false,
	cheat = { 0 },
	cheatProgress = 0,
	pixelDensity = 1,
	lastInputKind = "mouse",
	mobile = false,
	tablet = false,
	lowSpecMode = false,
	particleBudget = 220,
	particlesAlive = 0,
	fpsSamples = {},
	fps = 60,
	frameTime = 1 / 60,
	jankStreak = 0,
	adaptiveQuality = 1,
	sessionStart = os.clock(),
	warmth = 0,
	depth = 0,
}

-- Debug logging that stays silent unless someone asks for noise. Frameworks that
-- print unconditionally get muted, then deleted.
local DebugFlags = {
	verbose = false,
	traceGlass = false,
	traceSprings = false,
	traceScheduler = false,
	traceInput = false,
}

local function logInfo(...)
	if DebugFlags.verbose then
		print("[Nocturne]", ...)
	end
end

local function logWarn(...)
	warn("[Nocturne]", ...)
end

local function trace(channel: string, ...)
	if DebugFlags["trace" .. channel:sub(1, 1):upper() .. channel:sub(2)] then
		print(("[Nocturne:%s]"):format(channel), ...)
	end
end

-- A hardened instance factory. Everything in the kit is constructed through here
-- so that creation failures degrade to a no-op frame rather than a broken UI, and
-- so that the teardown path can find every object later.
local function create(className: string, props)
	local ok, instance = pcall(Instance.new, className)
	if not ok or instance == nil then
		-- Degraded, not dead: on a client without a class we substitute a plain
		-- visible frame so the UI keeps working minus one decoration.
		local fallback = Instance.new("Frame")
		fallback.BackgroundTransparency = 1
		return fallback
	end
	if props ~= nil then
		for key, value in props do
			-- Property assignment is per-key guarded: a client that does not know a
			-- property should lose that decoration, not lose the whole widget.
			local applied = pcall(function()
				instance[key] = value
			end)
			if not applied then
				if DebugFlags.verbose then
					logWarn(("property %q rejected on %s"):format(tostring(key), className))
				end
			end
		end
	end
	return instance
end

local function destroy(...)
	for _, target in { ... } do
		if typeof(target) == "Instance" then
			pcall(target.Destroy, target)
		elseif typeof(target) == "table" then
			destroy(table.unpack(target))
		end
	end
end

local function clearChildren(node: Instance)
	for _, child in node:GetChildren() do
		if
			child:IsA("UICorner")
			or child:IsA("UIStroke")
			or child:IsA("UIGradient")
			or child:IsA("UISizeConstraint")
		then
			continue
		end
		child:Destroy()
	end
end

local function safeParent(instance: Instance?, parent: Instance?)
	if instance ~= nil and parent ~= nil and parent.Parent ~= nil or parent == workspace then
		instance.Parent = parent
	end
	return instance
end

-- Parenting helper that refuses to orphan things: a SurfaceGui without a PlayerGui
-- parent throws, and during teardown the PlayerGui may already be gone.
local function adopt(child: Instance, parent: Instance): Instance
	if child == nil then
		return child
	end
	if parent == nil or not parent.Parent then
		parent = PlayerGui or LocalPlayer
	end
	if parent ~= nil then
		pcall(function()
			child.Parent = parent
		end)
	end
	return child
end
--═══════════════════════════════════════════════════════════════════════════════--
-- § 3  CONFIGURATION
--
-- Every tunable in the kit lives in this one table. Forks should fork here rather
-- than digging through the file, and the persistence layer in § 16 reads and
-- writes this table directly, so anything you add here automatically becomes
-- save/load-able and editable from the settings app.
--═══════════════════════════════════════════════════════════════════════════════--

local Config = {
	-- Identity -------------------------------------------------------------
	name = "Nocturne",
	tagline = "Liquid glass, dark side of the moon",

	-- Behaviour ------------------------------------------------------------
	boot = {
		auto = true, -- self-boot when the script runs
		showBootSequence = true, -- the typing terminal intro
		showLockScreen = false, -- start behind the clock and swipe-up
		minimumBootSeconds = 1.15, -- never flash the intro for 1 frame
	},
	modules = {
		windows = true,
		dock = true,
		menuBar = true,
		controlCentre = true,
		commandPalette = true,
		notifications = true,
		contextMenus = true,
		toolTips = true,
		missionControl = true,
		wallpaperEngine = true,
		ambience = true,
		keybinds = true,
		cheatCodes = true,
		diagnostics = true,
	},

	-- Glass surface --------------------------------------------------------
	glass = {
		-- Overall thickness of the material, 0..1. Drives tint, blur, refraction.
		body = 0.55,
		-- How much of the world behind stays visible. Lower = more opaque.
		seeThrough = 0.42,
		-- Edge light: the bright rim that makes glass read as glass.
		rimLight = 0.72,
		rimWidth = 1.4,
		rimFalloff = 2.2,
		-- Specular sheen that follows the cursor across the surface.
		specular = 0.42,
		specularSize = 0.65,
		specularDecay = 7.5,
		-- Caustics: slow drifting light streaks inside the material.
		caustics = true,
		causticsCount = 3,
		causticsSpeed = 0.14,
		causticsStrength = 0.22,
		-- Frosted micro-grain so the surface is not perfectly clean.
		grain = 0.055,
		-- Inner top highlight (light coming from above, always).
		topGloss = 0.34,
		-- Volumetric shadow, faked with a layered dark stack behind each surface.
		shadowStrength = 0.5,
		shadowSpread = 22,
		shadowLayers = 3,
		-- Refraction band at the edges, faked with a brightening inset.
		refraction = 0.5,
		refractionBand = 9,
		-- Wobble on interaction: the whole panel flexes like a membrane.
		wobble = 0.018,
		wobbleFrequency = 11.5,
		wobbleDecay = 5.4,
		-- Blur of the scene behind a focused window (engine-level, if available).
		sceneBlurSize = 21,
		sceneBlurWhenIdle = 0,
		dimBehind = 0.34,
		saturateBehind = 1.18,
		contrastBehind = -0.045,
		roundness = 24,
		defaultRoundness = 24,
		borderOpacity = 0.16,
		hairlineOpacity = 0.3,
	},

	-- Motion ---------------------------------------------------------------
	motion = {
		-- Spring defaults used when a caller does not name its own.
		spring = { stiffness = 170, damping = 22, mass = 1, precision = 0.012 },
		-- Snappier for small controls.
		springQuick = { stiffness = 420, damping = 30, mass = 0.72, precision = 0.004 },
		-- Bouncier for windows, dock magnification, popovers.
		springBouncy = { stiffness = 190, damping = 13.5, mass = 1.25, precision = 0.05 },
		-- Slower, more luxurious, for reveals.
		springCinematic = { stiffness = 92, damping = 19, mass = 1.4, precision = 0.02 },
		tweenPresets = {
			hover = { time = 0.16, style = Enum.EasingStyle.Quart, direction = Enum.EasingDirection.Out },
			press = { time = 0.09, style = Enum.EasingStyle.Quint, direction = Enum.EasingDirection.Out },
			release = { time = 0.34, style = Enum.EasingStyle.Elastic, direction = Enum.EasingDirection.Out },
			panel = { time = 0.42, style = Enum.EasingStyle.Quint, direction = Enum.EasingDirection.Out },
			page = { time = 0.3, style = Enum.EasingStyle.Cubic, direction = Enum.EasingDirection.Out },
			menu = { time = 0.19, style = Enum.EasingStyle.Back, direction = Enum.EasingDirection.Out },
			toast = { time = 0.5, style = Enum.EasingStyle.Back, direction = Enum.EasingDirection.Out },
		},
		stagger = 0.028,
		hoverScale = 1.026,
		pressScale = 0.968,
		magneticRange = 0.34,
		magneticStrength = 0.26,
		rippleSpeed = 1.0,
		rippleOpacity = 0.3,
		cursorTrail = true,
		parallaxStrength = 0.012,
		enableSounds = true,
		soundVolume = 0.34,
	},

	-- Layout ---------------------------------------------------------------
	layout = {
		margin = 16,
		gap = 12,
		innerPadding = 16,
		rowHeight = 38,
		buttonHeight = 40,
		smallButtonHeight = 30,
		iconSize = 18,
		dockSize = 56,
		dockMagnify = 1.46,
		dockGap = 8,
		menuBarHeight = 30,
		statusBarHeight = 26,
		toastWidth = 320,
		paletteWidth = 560,
		paletteRowHeight = 40,
		minWindowWidth = 260,
		minWindowHeight = 180,
		maxWindowFill = 0.9,
		snapMargin = 8,
		snapThreshold = 26,
		titleBarHeight = 42,
		trafficLightGap = 8,
		trafficLightSize = 12,
		sidebarWidth = 200,
		contentPadding = UDim.new(0, 16),
	},

	-- Rendering / performance ---------------------------------------------
	performance = {
		maxGlassLayers = 5,
		particleBudget = 220,
		causticsFps = 30,
		blurUpdateHz = 12,
		maxConcurrentSprings = 420,
		dropCausticsWhenManyPanels = 14,
		adaptiveQuality = true,
		jankThreshold = 0.0285, -- frame time above which we shed decoration
		pauseWhenUnfocused = true,
		reduceMotionOnLowSpec = true,
		lowSpecFps = 42,
	},

	-- Input ----------------------------------------------------------------
	input = {
		dragThreshold = 5,
		resizeThreshold = 3,
		longPressMs = 420,
		doubleClickMs = 320,
		scrollSpeed = 1.0,
		snapAssist = true,
		keybinds = {
			palette = { key = Enum.KeyCode.K, modifiers = { "ctrl" } },
			settings = { key = Enum.KeyCode.Comma, modifiers = { "ctrl" } },
			dock = { key = Enum.KeyCode.J, modifiers = { "ctrl" } },
			minimise = { key = Enum.KeyCode.M, modifiers = { "ctrl" } },
			missionControl = { key = Enum.KeyCode.E, modifiers = { "ctrl" } },
			fullscreen = { key = Enum.KeyCode.F, modifiers = { "ctrl", "shift" } },
			lock = { key = Enum.KeyCode.L, modifiers = { "ctrl", "shift" } },
			notifications = { key = Enum.KeyCode.N, modifiers = { "ctrl" } },
			capture = { key = Enum.KeyCode.P, modifiers = { "ctrl", "shift" } },
			hide = { key = Enum.KeyCode.H, modifiers = { "ctrl", "shift" } },
			diagnostics = { key = Enum.KeyCode.Slash, modifiers = { "ctrl", "shift" } },
		},
	},

	-- Content (placeholder, deliberately) ---------------------------------
	content = {
		appName = "Nocturne",
		userName = "Guest",
		userHandle = "@guest",
		userTitle = "Local Player",
		battery = 0.78,
		wifi = "excellent",
		playlistName = "Late Night Refraction",
		trackName = "Glass Coroutine",
		trackArtist = "Nocturne Sound Lab",
		trackDuration = 214,
		currencySymbol = "◈",
		version = Nocturne.VERSION,
	},

	-- Accessibility ---------------------------------------------------------
	accessibility = {
		reduceMotion = false,
		higherContrast = false,
		largerText = 1.0,
		showFocusRing = true,
		flashOnNotify = true,
		dyslexicSpacing = false,
	},

	-- Diagnostics ----------------------------------------------------------
	diagnostics = {
		showFps = false,
		showFrameGraph = false,
		showSurfaceCounts = false,
		warnOnLeaks = true,
		captureToClipboardHint = true,
	},
}

-- Deep read-only guard for the few tables that must not be reassigned at runtime.
local function shallowSeal(t)
	local proxy = setmetatable({}, {
		__index = t,
		__newindex = function(_, key, _)
			if DebugFlags.verbose then
				logWarn(("Config.%s is sealed"):format(tostring(key)))
			end
		end,
		__metatable = "sealed",
	})
	return proxy
end

-- Deep read-only guard for the motion presets: they are captured as upvalues in
-- hot paths, and a fork reassigning them mid-frame would produce motion that
-- changes character between frames. Sealing makes that a silent no-op.
do
	local m = Config.motion
	m.spring = shallowSeal(m.spring)
	m.springQuick = shallowSeal(m.springQuick)
	m.springBouncy = shallowSeal(m.springBouncy)
	m.springCinematic = shallowSeal(m.springCinematic)
end
Nocturne.Config = Config

--═══════════════════════════════════════════════════════════════════════════════--
-- § 4  UTILITIES — MATH, COLOUR, STRING, TABLE, TIME
--═══════════════════════════════════════════════════════════════════════════════--

local Math = {}
Nocturne.Math = Math

function Math.clamp(value, low, high)
	if value < low then
		return low
	elseif value > high then
		return high
	end
	return value
end

function Math.clamp01(value)
	return Math.clamp(value, 0, 1)
end

function Math.lerp(a, b, alpha)
	return a + (b - a) * alpha
end

function Math.invLerp(a, b, value)
	if b - a == 0 then
		return 0
	end
	return (value - a) / (b - a)
end

function Math.remap(value, inMin, inMax, outMin, outMax, clampResult)
	local alpha = Math.invLerp(inMin, inMax, value)
	if clampResult ~= false then
		alpha = Math.clamp01(alpha)
	end
	return Math.lerp(outMin, outMax, alpha)
end

function Math.approach(current, target, delta)
	if current < target then
		return math.min(current + delta, target)
	elseif current > target then
		return math.max(current - delta, target)
	end
	return target
end

function Math.smoothDamp(current, target, velocityRef, smoothTime, deltaTime, maxSpeed)
	smoothTime = math.max(1e-4, smoothTime or 0.2)
	maxSpeed = maxSpeed or math.huge
	local omega = 2 / smoothTime
	local exponent = math.exp(-omega * deltaTime)
	local delta = current - target
	local maxDelta = maxSpeed / omega
	if math.abs(delta) > maxDelta then
		delta = maxDelta * (delta > 0 and 1 or -1)
	end
	local speed = -omega * delta
	local result = target + (delta + (speed + omega * delta) * deltaTime) * exponent
	return result, (speed - omega * (result - target)) / deltaTime
end

function Math.round(value, places)
	local mult = 10 ^ (places or 0)
	return math.floor(value * mult + 0.5) / mult
end

function Math.roundTo(value, step)
	if step == 0 then
		return value
	end
	return math.floor(value / step + 0.5) * step
end

function Math.sign(value)
	if value > 0 then
		return 1
	elseif value < 0 then
		return -1
	end
	return 0
end

-- Deterministic cheap noise. Used for grain, caustic drift, visualizer bars.
function Math.hash1D(x)
	local s = math.sin(x * 12.9898) * 43758.5453
	return s - math.floor(s)
end

function Math.hash2D(x, y)
	local s = math.sin(x * 127.1 + y * 311.7) * 43758.5453
	return s - math.floor(s)
end

function Math.valueNoise(x)
	local i = math.floor(x)
	local f = x - i
	local u = f * f * (3 - 2 * f)
	return Math.lerp(Math.hash1D(i), Math.hash1D(i + 1), u) * 2 - 1
end

function Math.valueNoise2(x, y)
	local ix, iy = math.floor(x), math.floor(y)
	local fx, fy = x - ix, y - iy
	local ux, uy = fx * fx * (3 - 2 * fx), fy * fy * (3 - 2 * fy)
	local a = Math.hash2D(ix, iy)
	local b = Math.hash2D(ix + 1, iy)
	local c = Math.hash2D(ix, iy + 1)
	local d = Math.hash2D(ix + 1, iy + 1)
	return Math.lerp(Math.lerp(a, b, ux), Math.lerp(c, d, ux), uy)
end

function Math.fbm(x, y, octaves)
	local sum, amp, freq, norm = 0, 0.5, 1, 0
	for _ = 1, octaves or 3 do
		sum += Math.valueNoise2(x * freq, y * freq) * amp
		norm += amp
		amp *= 0.5
		freq *= 2.03
	end
	return sum / norm
end

function Math.pingPong(t, length)
	local l = length or 1
	local m = t % (2 * l)
	if m > l then
		return 2 * l - m
	end
	return m
end

function Math.distance2D(x1, y1, x2, y2)
	local dx, dy = x2 - x1, y2 - y1
	return math.sqrt(dx * dx + dy * dy)
end

function Math.angleBetween(x1, y1, x2, y2)
	return math.atan2(y2 - y1, x2 - x1)
end

function Math.pointInRect(px, py, rx, ry, rw, rh)
	return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end

function Math.rectsOverlap(ax, ay, aw, ah, bx, by, bw, bh)
	return ax < bx + bw and bx < ax + aw and ay < by + bh and by < ay + ah
end

-- A slow LCG so ambience never repeats the same sequence in two sessions and so
-- the framework never depends on the engine's randomiser behaviour.
local rngState = 0x2F6E2B1
local function rngNext()
	rngState = (rngState * 1103515245 + 12345) % 2147483648
	return rngState / 2147483648
end

function Math.randomSeed(seedValue)
	rngState = (tonumber(seedValue) or os.time()) % 2147483648
end

function Math.randomRange(low, high)
	if high == nil then
		low, high = 0, low
	end
	return low + rngNext() * (high - low)
end

function Math.randomInt(low, high)
	return math.floor(Math.randomRange(low, high + 1))
end

function Math.randomChoice(list)
	if #list == 0 then
		return nil
	end
	return list[Math.randomInt(1, #list)]
end

function Math.randomGauss()
	-- Box-Muller, for particle spread that looks natural instead of clumpy.
	local u = math.max(1e-6, rngNext())
	local v = rngNext()
	return math.sqrt(-2 * math.log(u)) * math.cos(2 * math.pi * v)
end

function Math.bezier(p0, p1, p2, p3, t)
	local u = 1 - t
	return u * u * u * p0 + 3 * u * u * t * p1 + 3 * u * t * t * p2 + t * t * t * p3
end

function Math.circlePoint(angle, radius, offsetX, offsetY)
	return (offsetX or 0) + math.cos(angle) * radius, (offsetY or 0) + math.sin(angle) * radius
end

function Math.degToRad(d)
	return d * math.pi / 180
end

function Math.radToDeg(r)
	return r * 180 / math.pi
end

function Math.approximately(a, b, epsilon)
	return math.abs(a - b) < (epsilon or 1e-5)
end

function Math.modulo(a, b)
	return (a % b + b) % b
end

function Math.wrap(a, low, high)
	local span = high - low
	if span == 0 then
		return low
	end
	return low + Math.modulo(a - low, span)
end

function Math.decayRate(halfLife)
	if halfLife <= 0 then
		return math.huge
	end
	return math.log(2) / halfLife
end

function Math.damp(current, target, lambda, deltaTime)
	return Math.lerp(current, target, 1 - math.exp(-lambda * deltaTime))
end

-- Easing functions. Names follow the usual vocabulary so a caller can say
-- easing.outExpo and mean it. Used by tween presets and by the reveal system.
local Easing = {}
Nocturne.Easing = Easing

Easing.linear = function(t)
	return t
end

function Easing.inQuad(t)
	return t * t
end
function Easing.outQuad(t)
	return 1 - (1 - t) * (1 - t)
end
function Easing.inOutQuad(t)
	if t < 0.5 then
		return 2 * t * t
	end
	return 1 - (-2 * t + 2) ^ 2 / 2
end

function Easing.inCubic(t)
	return t * t * t
end
function Easing.outCubic(t)
	return 1 - (1 - t) ^ 3
end
function Easing.inOutCubic(t)
	if t < 0.5 then
		return 4 * t * t * t
	end
	return 1 - (-2 * t + 2) ^ 3 / 2
end

function Easing.inQuart(t)
	return t ^ 4
end
function Easing.outQuart(t)
	return 1 - (1 - t) ^ 4
end
function Easing.inOutQuart(t)
	if t < 0.5 then
		return 8 * t ^ 4
	end
	return 1 - (-2 * t + 2) ^ 4 / 2
end

function Easing.inQuint(t)
	return t ^ 5
end
function Easing.outQuint(t)
	return 1 - (1 - t) ^ 5
end

function Easing.inExpo(t)
	if t == 0 then
		return 0
	end
	return 2 ^ (10 * t - 10)
end
function Easing.outExpo(t)
	if t == 1 then
		return 1
	end
	return 1 - 2 ^ (-10 * t)
end
function Easing.inOutExpo(t)
	if t == 0 then
		return 0
	end
	if t == 1 then
		return 1
	end
	if t < 0.5 then
		return 2 ^ (20 * t - 10) / 2
	end
	return (2 - 2 ^ (-20 * t + 10)) / 2
end

function Easing.inCirc(t)
	return 1 - math.sqrt(1 - t ^ 2)
end
function Easing.outCirc(t)
	return math.sqrt(1 - (t - 1) ^ 2)
end

function Easing.outBack(t)
	local c1 = 1.70158
	local c3 = c1 + 1
	return 1 + c3 * (t - 1) ^ 3 + c1 * (t - 1) ^ 2
end
function Easing.inBack(t)
	local c1 = 1.70158
	local c3 = c1 + 1
	return c3 * t * t * t - c1 * t * t
end
function Easing.inOutBack(t)
	local c1 = 1.70158 * 1.525
	return if t < 0.5
		then (2 * t) ^ 2 * ((c1 + 1) * 2 * t - c1) / 2
		else ((2 * t - 2) ^ 2 * ((c1 + 1) * (t * 2 - 2) + c1) + 2) / 2
end

function Easing.outElastic(t)
	local c4 = (2 * math.pi) / 3
	if t == 0 then
		return 0
	end
	if t == 1 then
		return 1
	end
	return 2 ^ (-10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
end
function Easing.inElastic(t)
	local c4 = (2 * math.pi) / 3
	if t == 0 then
		return 0
	end
	if t == 1 then
		return 1
	end
	return -(2 ^ (10 * t - 10)) * math.sin((t * 10 - 10.75) * c4)
end

function Easing.outBounce(t)
	local n1, d1 = 7.5625, 2.75
	if t < 1 / d1 then
		return n1 * t * t
	elseif t < 2 / d1 then
		t -= 1.5 / d1
		return n1 * t * t + 0.75
	elseif t < 2.5 / d1 then
		t -= 2.25 / d1
		return n1 * t * t + 0.9375
	else
		t -= 2.625 / d1
		return n1 * t * t + 0.984375
	end
end
function Easing.inBounce(t)
	return 1 - Easing.outBounce(1 - t)
end

Easing.smoothstep = function(t)
	return t * t * (3 - 2 * t)
end
Easing.smootherstep = function(t)
	return t * t * t * (t * (t * 6 - 15) + 10)
end

-- An easing curve for the "liquid" settle used by glass wobble: fast out, tiny
-- overshoot, long tail, no bounce that would read as cartoon.
function Easing.liquid(t)
	return 1 - (1 - t) ^ 2.6 * math.cos(t * math.pi * 0.5) * (1 - 0.18 * t)
end

function Easing.attenuate(t, strength)
	return Easing.outCubic(Math.clamp01(t * (strength or 1)))
end

function Easing.byName(name)
	return Easing[name] or Easing.outQuart
end
-- Colour: everything in the kit passes colours as Color3, but authors think in
-- hex, so the config and theme tables are allowed to speak hex and get converted
-- once, at load.
local Color = {}
Nocturne.Color = Color

local colorFromRGB = Color3.fromRGB
local colorFromHSV = Color3.fromHSV
local colorToHSV = Color3.toHSV

local hexCache = setmetatable({}, { __mode = "k" })

function Color.fromHex(hex, alpha)
	local cached = hexCache[hex]
	if cached then
		if alpha == nil then
			return cached
		end
		return cached, alpha
	end
	local s = hex:gsub("^#", ""):gsub("^0x", "")
	if #s == 3 then
		s = s:gsub("(.)", "%1%1")
	end
	local r = tonumber(s:sub(1, 2), 16) or 0
	local g = tonumber(s:sub(3, 4), 16) or 0
	local b = tonumber(s:sub(5, 6), 16) or 0
	local out = colorFromRGB(r, g, b)
	if type(hex) == "string" then
		hexCache[hex] = out
	end
	return out, alpha
end

function Color.toHex(c)
	local r = math.floor(c.R * 255 + 0.5)
	local g = math.floor(c.G * 255 + 0.5)
	local b = math.floor(c.B * 255 + 0.5)
	return string.format("%02x%02x%02x", r, g, b)
end

function Color.mix(a, b, alpha)
	return colorFromRGB(
		Math.lerp(a.R * 255, b.R * 255, alpha),
		Math.lerp(a.G * 255, b.G * 255, alpha),
		Math.lerp(a.B * 255, b.B * 255, alpha)
	)
end

-- Additive white blend is how glass reads light: not a hue mix but a lift.
function Color.addWhite(c, amount)
	return Color.mix(c, colorFromRGB(255, 255, 255), Math.clamp01(amount))
end

function Color.addBlack(c, amount)
	return Color.mix(c, colorFromRGB(0, 0, 0), Math.clamp01(amount))
end

function Color.tint(c, amount)
	return Color.mix(c, colorFromRGB(255, 252, 245), Math.clamp01(amount))
end

function Color.shade(c, amount)
	return Color.mix(c, colorFromRGB(6, 8, 12), Math.clamp01(amount))
end

function Color.multiply(c, scalar)
	return colorFromRGB(c.R * 255 * scalar, c.G * 255 * scalar, c.B * 255 * scalar)
end

function Color.shiftHue(c, degrees)
	local h, s, v = colorToHSV(c)
	return colorFromHSV(Math.wrap(h + degrees / 360, 0, 1), s, v)
end

function Color.setSaturation(c, s)
	local h, _, v = colorToHSV(c)
	return colorFromHSV(h, Math.clamp01(s), v)
end

function Color.setValue(c, v)
	local h, s, _ = colorToHSV(c)
	return colorFromHSV(h, s, Math.clamp01(v))
end

function Color.desaturate(c, amount)
	local h, s, v = colorToHSV(c)
	return colorFromHSV(h, s * (1 - Math.clamp01(amount)), v)
end

function Color.luminance(c)
	return 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B
end

function Color.contrastRatio(a, b)
	local la, lb = Color.luminance(a), Color.luminance(b)
	if la < lb then
		la, lb = lb, la
	end
	return (la + 0.05) / (lb + 0.05)
end

-- Glass needs "same colour but see-through" constantly; keeping the maths here
-- means every widget tints itself from one source of truth.
function Color.alphaLift(c, overColor, alpha)
	return Color.mix(overColor, c, alpha)
end

function Color.isDark(c)
	return Color.luminance(c) < 0.42
end

function Color.readableOn(c)
	return Color.isDark(c) and colorFromRGB(244, 246, 250) or colorFromRGB(10, 12, 16)
end

function Color.fromHSL(h, s, l)
	-- CSS-style HSL, because the palettes below are easier to reason about that way.
	local function channel(n)
		local k = Math.modulo(n + h * 12, 12)
		local a = s * math.min(l, 1 - l)
		return l - a * math.max(-1, math.min(k - 3, math.min(9 - k, 1)))
	end
	return colorFromRGB(channel(0) * 255, channel(8) * 255, channel(4) * 255)
end

-- UDim2 / UDim / Vector2 helpers -------------------------------------------------
local U = {}
Nocturne.U = U

function U.pad(px)
	return UDim.new(0, px)
end

function U.fill(scale)
	return UDim.new(scale or 1, 0)
end

function U.size(xScale, xOffset, yScale, yOffset)
	return UDim2.new(xScale, xOffset, yScale, yOffset)
end

function U.full()
	return UDim2.fromScale(1, 1)
end

function U.offset(x, y)
	return UDim2.fromOffset(x, y)
end

function U.add(a, b)
	return UDim2.new(a.X.Scale + b.X.Scale, a.X.Offset + b.X.Offset, a.Y.Scale + b.Y.Scale, a.Y.Offset + b.Y.Offset)
end

function U.sub(a, b)
	return UDim2.new(a.X.Scale - b.X.Scale, a.X.Offset - b.X.Offset, a.Y.Scale - b.Y.Scale, a.Y.Offset - b.Y.Offset)
end

function U.scaleBy(a, s)
	return UDim2.new(a.X.Scale * s, a.X.Offset * s, a.Y.Scale * s, a.Y.Offset * s)
end

function U.lerp(a, b, alpha)
	return UDim2.new(
		Math.lerp(a.X.Scale, b.X.Scale, alpha),
		Math.lerp(a.X.Offset, b.X.Offset, alpha),
		Math.lerp(a.Y.Scale, b.Y.Scale, alpha),
		Math.lerp(a.Y.Offset, b.Y.Offset, alpha)
	)
end

function U.withOffsetX(a, xOffset)
	return UDim2.new(a.X.Scale, xOffset, a.Y.Scale, a.Y.Offset)
end

function U.withOffsetY(a, yOffset)
	return UDim2.new(a.X.Scale, a.X.Offset, a.Y.Scale, yOffset)
end

function U.clampSize(a, minSize, maxSize)
	return UDim2.new(
		a.X.Scale,
		Math.clamp(a.X.Offset, minSize.X.Offset, maxSize.X.Offset),
		a.Y.Scale,
		Math.clamp(a.Y.Offset, minSize.Y.Offset, maxSize.Y.Offset)
	)
end

-- String / formatting ------------------------------------------------------------
local Str = {}
Nocturne.Str = Str

function Str.capitalise(s)
	return (s:gsub("^%l", string.upper))
end

function Str.titleCase(s)
	return (s:gsub("(%a)([%w_']*)", function(first, rest)
		return first:upper() .. rest:lower()
	end))
end

function Str.spaced(s)
	-- "settings" -> "S e t t i n g s" — used sparingly for eyebrow labels.
	return s:gsub("", " "):gsub("^%s", ""):gsub("%s$", "")
end

function Str.truncate(s, maxLen, suffix)
	suffix = suffix or "…"
	if #s <= maxLen then
		return s
	end
	return s:sub(1, maxLen - #suffix) .. suffix
end

function Str.pad(s, width, char, rightAlign)
	char = char or " "
	local padding = char:rep(math.max(0, width - #s))
	if rightAlign then
		return padding .. s
	end
	return s .. padding
end

function Str.split(s, sep)
	local out, pos = {}, 1
	while true do
		local next = s:find(sep, pos, true)
		if not next then
			table.insert(out, s:sub(pos))
			break
		end
		table.insert(out, s:sub(pos, next - 1))
		pos = next + #sep
	end
	return out
end

function Str.join(list, sep)
	return table.concat(list, sep or "")
end

function Str.contains(haystack, needle)
	return haystack:lower():find(needle:lower(), 1, true) ~= nil
end

function Str.slug(s)
	return (s:lower():gsub("[^a-z0-9]+", "-"):gsub("^%-", ""):gsub("%-$", ""))
end

function Str.key(s)
	return (s:lower():gsub("[^a-z0-9]+", "_"))
end

function Str.bool(b)
	return b and "On" or "Off"
end

function Str.commas(n)
	local s = tostring(math.floor(n))
	local guard = 0
	while true do
		local replaced = s:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		if replaced == s or guard > 8 then
			break
		end
		s = replaced
		guard += 1
	end
	return s
end

function Str.percent(v, decimals)
	return string.format("%." .. (decimals or 0) .. "f%%", v * 100)
end

function Str.clock(seconds)
	local m = math.floor(seconds / 60)
	local s = math.floor(seconds % 60)
	return string.format("%d:%02d", m, s)
end

function Str.longDate(unixTime)
	local ok, formatted = pcall(os.date, "%A, %B %d", unixTime)
	return ok and formatted or os.date("!%A, %B %d")
end

function Str.dayMonth(unixTime)
	local ok, formatted = pcall(os.date, "%b %d", unixTime)
	return ok and formatted or "—"
end

function Str.weekday(unixTime)
	local ok, formatted = pcall(os.date, "%a", unixTime)
	return ok and formatted or "—"
end

function Str.hours12(unixTime)
	local ok, t = pcall(os.date, "*t", unixTime)
	if not ok then
		return "—", "—"
	end
	local suffix = t.hour >= 12 and "PM" or "AM"
	local hour12 = t.hour % 12
	if hour12 == 0 then
		hour12 = 12
	end
	return string.format("%d:%02d", hour12, t.min), suffix
end

function Str.bytes(n)
	local units = { "B", "KB", "MB", "GB", "TB" }
	local i = 1
	local v = math.max(0, tonumber(n) or 0)
	while v >= 1024 and i < #units do
		v /= 1024
		i += 1
	end
	return string.format(i == 1 and "%d%s" or "%.1f%s", v, units[i])
end

function Str.kilo(n)
	if n >= 1000000 then
		return string.format("%.1fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("%.1fk", n / 1000)
	end
	return tostring(math.floor(n))
end

function Str.repeatWhile(s, count)
	return s:rep(math.max(0, count))
end

-- Fuzzy match scoring for the command palette. Rewards prefix hits, acronym hits
-- and consecutive runs; ignores everything else. Returns nil when no match.
function Str.fuzzy(text, pattern)
	if pattern == "" then
		return 0, {}
	end
	text = text:lower()
	pattern = pattern:lower()
	local score = 0
	local ti = 1
	local hits = {}
	local consecutive = 0
	local prevHitEnd = 0
	-- Acronym bonus: "osp" matches "open settings panel".
	local acronym = ""
	for word in text:gmatch("%a+") do
		acronym ..= word:sub(1, 1)
	end
	local acronymPos = 1
	for pi = 1, #pattern do
		local needle = pattern:sub(pi, pi)
		local found = nil
		local search = ti
		while search <= #text do
			if text:sub(search, search) == needle then
				found = search
				break
			end
			search += 1
		end
		if not found then
			-- Try the acronym spine before giving up on this character.
			local apos = acronym:find(needle, acronymPos, true)
			if apos then
				acronymPos = apos + 1
				score += 6
				continue
			end
			return nil
		end
		if found == ti then
			consecutive += 1
			score += 3 * consecutive
		else
			consecutive = 0
			score += 1
		end
		if found == 1 then
			score += 5
		else
			local before = text:sub(found - 1, found - 1)
			if before == " " or before == "_" or before == "-" or before == "." then
				score += 4
			end
		end
		table.insert(hits, found)
		prevHitEnd = found
		ti = found + 1
	end
	if prevHitEnd == #text then
		score += 2
	end
	score += math.max(0, 6 - #text / 8)
	return score, hits
end

function Str.escape(s)
	return (s:gsub("%%", "%%%%"))
end

-- Table --------------------------------------------------------------------------
local T = {}
Nocturne.T = T

function T.copy(t)
	local out = {}
	for k, v in t do
		out[k] = v
	end
	return out
end

function T.deepCopy(t, seen)
	if type(t) ~= "table" then
		return t
	end
	seen = seen or {}
	if seen[t] then
		return seen[t]
	end
	local out = {}
	seen[t] = out
	for k, v in t do
		out[T.deepCopy(k, seen)] = T.deepCopy(v, seen)
	end
	return out
end

function T.merge(base, ...)
	local out = T.copy(base or {})
	for _, patch in { ... } do
		if patch then
			for k, v in patch do
				out[k] = v
			end
		end
	end
	return out
end

function T.mergeDeep(base, patch)
	local out = T.copy(base)
	for k, v in patch do
		if type(v) == "table" and type(out[k]) == "table" then
			out[k] = T.mergeDeep(out[k], v)
		else
			out[k] = v
		end
	end
	return out
end

function T.get(t, path, fallback)
	local node = t
	for part in path:gmatch("[^%.]+") do
		if type(node) ~= "table" or node[part] == nil then
			return fallback
		end
		node = node[part]
	end
	return node
end

function T.set(t, path, value)
	local node = t
	local parts = {}
	for part in path:gmatch("[^%.]+") do
		table.insert(parts, part)
	end
	for i = 1, #parts - 1 do
		local part = parts[i]
		if type(node[part]) ~= "table" then
			node[part] = {}
		end
		node = node[part]
	end
	node[parts[#parts]] = value
	return t
end

function T.contains(list, value)
	for _, v in list do
		if v == value then
			return true
		end
	end
	return false
end

function T.indexOf(list, value)
	for i, v in list do
		if v == value then
			return i
		end
	end
	return nil
end

function T.filter(list, predicate)
	local out = {}
	for _, v in list do
		if predicate(v) then
			table.insert(out, v)
		end
	end
	return out
end

function T.map(list, mapper)
	local out = {}
	for i, v in list do
		out[i] = mapper(v, i)
	end
	return out
end

function T.each(list, fn)
	for i, v in list do
		fn(v, i)
	end
end

function T.find(list, predicate)
	for _, v in list do
		if predicate(v) then
			return v
		end
	end
	return nil
end

function T.any(list, predicate)
	for _, v in list do
		if predicate(v) then
			return true
		end
	end
	return false
end

function T.all(list, predicate)
	for _, v in list do
		if not predicate(v) then
			return false
		end
	end
	return true
end

function T.sum(list, key)
	local total = 0
	for _, v in list do
		total += key and v[key] or v
	end
	return total
end

function T.sortBy(list, key)
	table.sort(list, function(a, b)
		if key then
			return a[key] < b[key]
		end
		return a < b
	end)
	return list
end

function T.reverse(list)
	local out = {}
	for i = #list, 1, -1 do
		table.insert(out, list[i])
	end
	return out
end

function T.slice(list, from, to)
	local out = {}
	for i = from or 1, to or #list do
		table.insert(out, list[i])
	end
	return out
end

function T.insertAfter(list, value, after)
	local idx = T.indexOf(list, after) or #list
	table.insert(list, idx + 1, value)
end

function T.removeValue(list, value)
	local idx = T.indexOf(list, value)
	if idx then
		table.remove(list, idx)
		return true
	end
	return false
end

function T.move(list, from, to)
	local item = table.remove(list, from)
	table.insert(list, to, item)
end

function T.keys(t)
	local out = {}
	for k in t do
		table.insert(out, k)
	end
	return out
end

function T.values(t)
	local out = {}
	for _, v in t do
		table.insert(out, v)
	end
	return out
end

function T.size(t)
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

function T.invert(t)
	local out = {}
	for k, v in t do
		out[v] = k
	end
	return out
end

function T.clear(t)
	for k in t do
		t[k] = nil
	end
end

-- Time and function utilities ----------------------------------------------------
local Time = {}
Nocturne.Time = Time

function Time.now()
	return os.clock()
end

function Time.wall()
	return os.time()
end

function Time.stopwatch()
	local start = os.clock()
	local self = {
		elapsed = function()
			return os.clock() - start
		end,
		lap = function()
			local e = os.clock() - start
			start = os.clock()
			return e
		end,
	}
	return self
end

function Time.throttle(fn, interval)
	local last = -math.huge
	return function(...)
		local now = os.clock()
		if now - last >= interval then
			last = now
			return fn(...)
		end
	end
end

function Time.debounce(fn, delay)
	local token = 0
	return function(...)
		token += 1
		local myToken = token
		task.delay(delay, function()
			if myToken == token then
				fn(...)
			end
		end)
	end
end

function Time.cooldown(fn, duration)
	local readyAt = 0
	return function(...)
		local now = os.clock()
		if now >= readyAt then
			readyAt = now + duration
			return fn(...)
		end
	end
end

function Time.retry(times, delaySeconds, fn)
	return task.spawn(function()
		for attempt = 1, times do
			local ok, result = pcall(fn, attempt)
			if ok then
				return result
			end
			task.wait(delaySeconds)
		end
	end)
end

function Time.perf(name, fn)
	local start = os.clock()
	local results = table.pack(pcall(fn))
	local ms = (os.clock() - start) * 1000
	if DebugFlags.verbose and ms > 3 then
		logInfo(("perf %s took %.2fms"):format(name, ms))
	end
	if not results[1] then
		error(results[2])
	end
	return table.unpack(results, 2, results.n)
end
--═══════════════════════════════════════════════════════════════════════════════--
-- § 5  SIGNALS, CONNECTIONS, POOLS
--
-- A tiny signal implementation with connection objects that behave like the
-- engine's RBXScriptConnection (Disconnect, Connected) so callers never have to
-- care whether they hold a real connection or a Nocturne one.
--═══════════════════════════════════════════════════════════════════════════════--

local Scheduler

local Signal, SignalConnection
do
	local connectionMeta = {
		__tostring = function(self)
			return ("SignalConnection [%s]"):format(self.Connected and "connected" or "dead")
		end,
	}

	SignalConnection = {}
	SignalConnection.__index = SignalConnection

	function SignalConnection.new(signal, thread)
		return setmetatable({
			Signal = signal,
			Thread = thread,
			Connected = true,
		}, connectionMeta)
	end

	function SignalConnection:Disconnect()
		if not self.Connected then
			return
		end
		self.Connected = false
		local signal = self.Signal
		local index = T.indexOf(signal._connections, self)
		if index then
			table.remove(signal._connections, index)
		end
	end

	function SignalConnection:Once(fn)
		self.Signal:Once(fn)
		return self
	end

	local signalMeta = {
		__call = function(self, ...)
			return self:Fire(...)
		end,
		__tostring = function(self)
			return ("Signal (%d listeners)"):format(#self._connections)
		end,
	}

	Signal = {}
	Signal.__index = Signal

	function Signal.new(debugName)
		return setmetatable({
			_connections = {},
			_debugName = debugName or "signal",
			_paused = false,
			_queuedWhilePaused = 0,
		}, signalMeta)
	end

	function Signal:Connect(fn)
		local conn = SignalConnection.new(self, coroutine.running())
		table.insert(self._connections, conn)
		conn._fn = fn
		return conn
	end

	function Signal:Once(fn)
		local conn
		conn = self:Connect(function(...)
			if conn._fired then
				return
			end
			conn._fired = true
			conn:Disconnect()
			fn(...)
		end)
		return conn
	end

	function Signal:ConnectParallel(fn)
		-- Semantically identical here; kept for API parity with optimised kits.
		return self:Connect(fn)
	end

	function Signal:Fire(...)
		if self._paused then
			self._queuedWhilePaused += 1
			return
		end
		-- Iterate a copy: handlers commonly disconnect themselves or each other.
		local snapshot = table.clone(self._connections)
		for _, conn in snapshot do
			if conn.Connected and conn._fn then
				local ok, err = pcall(conn._fn, ...)
				if not ok then
					warn(("[Nocturne:signal %s] %s"):format(self._debugName, tostring(err)))
				end
			end
		end
	end

	-- Deferred fire: joins the next scheduler tick so that "layout changed" style
	-- signals do not thrash during construction.
	function Signal:FireDeferred(...)
		local args = table.pack(...)
		Scheduler.nextFrame(function()
			self:Fire(table.unpack(args, 1, args.n))
		end)
	end

	function Signal:Pause()
		self._paused = true
	end

	function Signal:Resume(flush)
		self._paused = false
		self._queuedWhilePaused = 0
	end

	function Signal:DisconnectAll()
		local snapshot = table.clone(self._connections)
		for _, conn in snapshot do
			conn:Disconnect()
		end
		T.clear(self._connections)
	end

	function Signal:Count()
		return #self._connections
	end

	function Signal:Destroy()
		self:DisconnectAll()
	end
end

Nocturne.Signal = Signal

-- Composite connection: own a crowd of connections, kill them together.
local CompositeConnection = {}
CompositeConnection.__index = CompositeConnection

function CompositeConnection.new()
	return setmetatable({ _items = {}, _destroyables = {} }, CompositeConnection)
end

function CompositeConnection:Add(conn)
	if conn then
		table.insert(self._items, conn)
	end
	return conn
end

function CompositeConnection:Manage(instance, signalName, fn)
	local signal = instance and instance[signalName]
	if signal and signal.Connect then
		local conn = signal:Connect(fn)
		table.insert(self._items, conn)
		return conn
	end
	return nil
end

function CompositeConnection:Own(destroyable)
	table.insert(self._destroyables, destroyable)
	return destroyable
end

function CompositeConnection:Disconnect()
	for _, conn in self._items do
		pcall(conn.Disconnect, conn)
	end
	T.clear(self._items)
end

function CompositeConnection:Destroy()
	self:Disconnect()
	for _, d in self._destroyables do
		if typeof(d) == "Instance" then
			pcall(d.Destroy, d)
		elseif type(d) == "table" and d.Destroy then
			pcall(d.Destroy, d)
		end
	end
	T.clear(self._destroyables)
end

Nocturne.CompositeConnection = CompositeConnection

-- Object pool. Ripples, particles, toast rows and palette rows are all short-lived
-- identical objects; allocating them every time is how "nice UI" becomes a GC
-- hazard on low-end devices. One pool per kind, sized lazily.
local Pools = {}
local Pool = {}
Pool.__index = Pool

function Pool.getOrCreate(kind, factory, reset)
	local existing = Pools[kind]
	if existing then
		return existing
	end
	local pool = setmetatable({
		_kind = kind,
		_factory = factory,
		_reset = reset,
		_free = {},
		_live = {},
		_created = 0,
		_reused = 0,
		_cap = 96,
	}, Pool)
	Pools[kind] = pool
	return pool
end

function Pool:Get()
	local item = table.remove(self._free)
	if item == nil then
		item = self._factory()
		self._created += 1
	else
		self._reused += 1
	end
	table.insert(self._live, item)
	if self._reset then
		self._reset(item)
	end
	return item
end

function Pool:Release(item)
	local idx = T.indexOf(self._live, item)
	if idx then
		table.remove(self._live, idx)
		if #self._free < self._cap then
			table.insert(self._free, item)
		else
			-- Over cap: actually destroy, or pools become a slow leak.
			if typeof(item) == "Instance" then
				pcall(item.Destroy, item)
			end
		end
	end
end

function Pool:ReleaseAll()
	while #self._live > 0 do
		self:Release(self._live[1])
	end
end

function Pool:Wipe()
	for _, item in self._live do
		if typeof(item) == "Instance" then
			pcall(item.Destroy, item)
		end
	end
	for _, item in self._free do
		if typeof(item) == "Instance" then
			pcall(item.Destroy, item)
		end
	end
	T.clear(self._free)
	T.clear(self._live)
end

function Pool:Stats()
	return { kind = self._kind, free = #self._free, live = #self._live, created = self._created, reused = self._reused }
end

Nocturne.Pool = Pool

--═══════════════════════════════════════════════════════════════════════════════--
-- § 6a  SCHEDULER — ONE PUMP TO RULE THEM ALL
--
-- Every animation in the kit is driven from a single RenderStepped connection.
-- Tasks opt into a rate (every frame, half rate, throttled hz) and a priority.
-- This is what keeps 200 springs and 3 layers of caustics boring to profile.
--═══════════════════════════════════════════════════════════════════════════════--

Scheduler = {
	_tasks = {},
	_taskCount = 0,
	_dirty = false,
	_paused = false,
	_clock = 0,
	_frame = 0,
	_delta = 1 / 60,
	_realDelta = 1 / 60,
	_lastError = nil,
	_errorCount = 0,
	_budget = 0.006, -- soft ms budget for scheduled work per frame
}
Nocturne.Scheduler = Scheduler

local taskMeta = {
	__tostring = function(self)
		return ("Task(%s)"):format(self._id)
	end,
}

function Scheduler._newId()
	Scheduler._nextId = (Scheduler._nextId or 0) + 1
	return "t" .. Scheduler._nextId
end

-- schedule(fn, opts) -> task handle.
-- opts: { rate = "frame"|"half"|"third"|"quarter"|number hz, priority = 0..9,
--         delay = seconds before first run, repeatCount = run this many times then die,
--         name = string, fireImmediately = bool }
function Scheduler.schedule(fn, opts)
	opts = opts or {}
	local job = setmetatable({
		_id = Scheduler._newId(),
		_name = opts.name or "task",
		_fn = fn,
		_rate = opts.rate or "frame",
		_priority = opts.priority or 5,
		_delay = opts.delay or 0,
		_repeatCount = opts.repeatCount,
		_elapsed = 0,
		_runs = 0,
		_interval = type(opts.rate) == "number" and (1 / opts.rate) or 0,
		_dropped = false,
	}, taskMeta)
	table.insert(Scheduler._tasks, job)
	Scheduler._taskCount += 1
	Scheduler._dirty = true
	if opts.fireImmediately then
		job._next = true
	end
	return job
end

function Scheduler.unschedule(job)
	if task == nil or job._dropped then
		return
	end
	job._dropped = true
	Scheduler._dirty = true
end

function Scheduler.pump()
	if Scheduler._dirty then
		table.sort(Scheduler._tasks, function(a, b)
			return a._priority < b._priority
		end)
		Scheduler._dirty = false
	end

	local now = Scheduler._clock
	local alive = 0
	local tasks = Scheduler._tasks
	for i = 1, #tasks do
		local job = tasks[i]
		if job._dropped then
			continue
		end
		if job._delay > 0 and now < job._delay then
			continue
		end
		local shouldRun = true
		local interval = job._interval
		if interval > 0 then
			if now - (job._lastRun or 0) >= interval then
				job._lastRun = now
			else
				shouldRun = false
			end
		end
		if shouldRun then
			local ok, err
			if job._rate == "half" then
				ok = job._runs % 2 == 0
			elseif job._rate == "third" then
				ok = job._runs % 3 == 0
			elseif job._rate == "quarter" then
				ok = job._runs % 4 == 0
			else
				ok = true
			end
			job._runs += 1
			if ok then
				ok, err = pcall(job._fn, Scheduler._delta, now)
				if not ok then
					Scheduler._errorCount += 1
					Scheduler._lastError = err
					if Scheduler._errorCount > 24 then
						logWarn("task threw too often, parking:", job._name)
						job._dropped = true
					else
						warn(("[Nocturne:scheduler %s] %s"):format(job._name, tostring(err)))
					end
				end
			end
		end
		if job._repeatCount and job._runs >= job._repeatCount then
			job._dropped = true
			Scheduler._dirty = true
		else
			alive += 1
		end
	end

	-- Compact the array when too much of it is dead.
	if #tasks - alive > math.max(32, #tasks * 0.3) then
		local kept = table.create(alive)
		for _, job2 in tasks do
			if not task2._dropped then
				table.insert(kept, job2)
			end
		end
		Scheduler._tasks = kept
		Scheduler._taskCount = #kept
	end
end

function Scheduler.nextFrame(fn)
	local job
	job = Scheduler.schedule(function()
		Scheduler.unschedule(job)
		fn()
	end, { name = "nextFrame", priority = 0, rate = "frame" })
end

function Scheduler.after(seconds, fn)
	local job
	job = Scheduler.schedule(function()
		Scheduler.unschedule(job)
		fn()
	end, { name = "after", delay = seconds, rate = math.huge, priority = 4 })
	return job
end

function Scheduler.every(seconds, fn)
	return Scheduler.schedule(fn, { rate = 1 / math.max(1e-3, seconds), name = "every" })
end

function Scheduler.setPaused(paused)
	Scheduler._paused = paused
end

function Scheduler.stats()
	local byKind = {}
	local total = 0
	for _, job in Scheduler._tasks do
		if not job._dropped then
			total += 1
			byKind[job._name] = (byKind[job._name] or 0) + 1
		end
	end
	return { total = total, byKind = byKind, errors = Scheduler._errorCount }
end

-- The pump itself. Started here, but only after the spring system below defines
-- its step; see the combined pump further down.
local startedPump = false
local function startPump()
	if startedPump then
		return
	end
	startedPump = true
	local accumulator = 0
	RunService.RenderStepped:Connect(function(rawDelta)
		if Scheduler._paused then
			return
		end
		Scheduler._realDelta = rawDelta
		-- Clamp pathological deltas: alt-tab and freeze recovery should not
		-- fast-forward every spring into orbit.
		Scheduler._delta = math.min(rawDelta, 1 / 15)
		Scheduler._clock += Scheduler._delta
		Scheduler._frame += 1
		Scheduler.pump()
	end)
end

Nocturne.startPump = startPump

-- FPS meter lives on the scheduler because it is literally frame accounting.
local fpsTracker = {
	acc = 0,
	frames = 0,
	value = 60,
	frameTime = 1 / 60,
	worst = 1 / 60,
	graph = table.create(120, 0),
}
Scheduler.fpsTracker = fpsTracker

Scheduler.schedule(function(dt)
	fpsTracker.acc += dt
	fpsTracker.frames += 1
	if fpsTracker.acc >= 0.25 then
		fpsTracker.value = fpsTracker.frames / fpsTracker.acc
		fpsTracker.acc = 0
		fpsTracker.frames = 0
		State.fps = fpsTracker.value
	end
	fpsTracker.frameTime = Math.lerp(fpsTracker.frameTime, dt, 0.12)
	if dt > fpsTracker.worst then
		fpsTracker.worst = math.min(dt, 0.5)
	end
	table.insert(fpsTracker.graph, dt)
	if #fpsTracker.graph > 120 then
		table.remove(fpsTracker.graph, 1)
	end
end, { name = "fps", priority = 9, rate = "frame" })

-- Springs ------------------------------------------------------------------------
-- Semi-implicit Euler integration of a damped harmonic oscillator, the same
-- formulation the modern motion libraries converged on. Springs, not tweens,
-- because interrupting a spring mid-flight is free and interruption is what a UI
-- spends all day doing.
local Spring = {}
Spring.__index = Spring
Nocturne.Spring = Spring

local allSprings = setmetatable({}, { __mode = "k" })
local springCount = 0

function Spring.new(initial, preset, opts)
	preset = preset or Config.motion.spring
	local self = setmetatable({
		_position = typeof(initial) == "number" and initial or 0,
		_target = typeof(initial) == "number" and initial or 0,
		_velocity = 0,
		_initial = initial,
		_stiffness = preset.stiffness or 170,
		_damping = preset.damping or 22,
		_mass = preset.mass or 1,
		_precision = preset.precision or 0.012,
		_isVelocity = false,
		_clamp = opts and opts.clamp,
		_onRest = opts and opts.onRest,
		_onUpdate = opts and opts.onUpdate,
		_restitution = opts and opts.restitution,
		_atRest = true,
		_enabled = true,
		_time = 0,
		_kind = opts and opts.kind or "number",
		_vector = typeof(initial) == "Vector2" and initial or nil,
	}, Spring)
	allSprings[self] = true
	springCount += 1
	self._components = nil
	if typeof(initial) == "UDim2" then
		self._kind = "udim2"
		self._components = {
			Spring.new(initial.X.Scale, preset),
			Spring.new(initial.X.Offset, preset),
			Spring.new(initial.Y.Scale, preset),
			Spring.new(initial.Y.Offset, preset),
		}
		for _, c in self._components do
			allSprings[c] = nil
		end
	elseif typeof(initial) == "Vector2" then
		self._kind = "vector2"
		self._components = { Spring.new(initial.X, preset), Spring.new(initial.Y, preset) }
		for _, c in self._components do
			allSprings[c] = nil
		end
	end
	self._position = initial
	self._target = initial
	return self
end

function Spring:getPosition()
	if self._components then
		if self._kind == "udim2" then
			local c = self._components
			return UDim2.new(c[1]._position, c[2]._position, c[3]._position, c[4]._position)
		elseif self._kind == "vector2" then
			local c = self._components
			return Vector2.new(c[1]._position, c[2]._position)
		end
	end
	return self._position
end
Spring.value = Spring.getPosition

function Spring:getTarget()
	return self._target
end

function Spring:getVelocity()
	if self._components then
		return Vector2.new(self._components[1]._velocity, self._components[2]._velocity)
	end
	return self._velocity
end

function Spring:set(value)
	if self._components then
		local c = self._components
		local v = value
		if self._kind == "udim2" then
			c[1]:set(v.X.Scale)
			c[2]:set(v.X.Offset)
			c[3]:set(v.Y.Scale)
			c[4]:set(v.Y.Offset)
		elseif self._kind == "vector2" then
			c[1]:set(v.X)
			c[2]:set(v.Y)
		end
		self._atRest = true
		self._position = value
		self._target = value
		return self
	end
	self._position = value
	self._target = value
	self._velocity = 0
	self._atRest = true
	return self
end

function Spring:setTarget(value)
	if self._components then
		local c = self._components
		if self._kind == "udim2" then
			c[1]:setTarget(value.X.Scale)
			c[2]:setTarget(value.X.Offset)
			c[3]:setTarget(value.Y.Scale)
			c[4]:setTarget(value.Y.Offset)
		elseif self._kind == "vector2" then
			c[1]:setTarget(value.X)
			c[2]:setTarget(value.Y)
		end
		self._atRest = false
		return self
	end
	if value == self._target and math.abs(self._velocity) < self._precision then
		return self
	end
	self._target = value
	self._atRest = false
	return self
end
-- setTarget is the hot method; it is spelled in full on purpose. set() (above)
-- is the hard snap, deliberately not aliased to anything.

function Spring:addVelocity(v)
	self._velocity += v
	self._atRest = false
	return self
end

function Spring:jump(delta)
	if self._components then
		for _, c in self._components do
			c:jump(delta)
		end
		self._position = self:getPosition()
		return self
	end
	self._position += delta
	return self
end

function Spring:reset(value)
	return self:set(value)
end

function Spring:timeUntilRest()
	-- Closed-form-ish estimate for diagnostics only: decay to precision.
	if self._stiffness <= 0 then
		return math.huge
	end
	local omega = math.sqrt(self._stiffness / self._mass)
	local zeta = self._damping / (2 * math.sqrt(self._stiffness * self._mass))
	if zeta >= 1 then
		return 6 / (omega * 0.5)
	end
	return -math.log(self._precision / math.max(1, math.abs(self._target - self._position))) / (zeta * omega)
end

function Spring:step(dt)
	if not self._enabled then
		return true
	end
	if self._components then
		local anyMoving = false
		for _, c in self._components do
			if not c:step(dt) then
				anyMoving = true
			end
		end
		self._atRest = not anyMoving
		self._position = self:getPosition()
		if self._onUpdate then
			self._onUpdate(self._position, self)
		end
		return self._atRest
	end
	if self._atRest then
		return true
	end
	local k = self._stiffness
	local c = self._damping
	local m = self._mass
	local x = self._position
	local v = self._velocity
	local target = self._target
	-- Sub-step at 1/240s for stability when stiffness/mass ratios get silly.
	local remaining = math.min(dt, 1 / 15)
	local stepSize = 1 / 240
	local guard = 0
	while remaining > 0 and guard < 64 do
		guard += 1
		local h = math.min(stepSize, remaining)
		local a = (-k * (x - target) - c * v) / m
		v += a * h
		x += v * h
		remaining -= h
	end
	if self._clamp then
		if x < self._clamp[1] then
			x = self._clamp[1]
			v = -v * (self._restitution or 0)
		elseif x > self._clamp[2] then
			x = self._clamp[2]
			v = -v * (self._restitution or 0)
		end
	end
	self._position = x
	self._velocity = v
	if math.abs(v) < self._precision and math.abs(x - target) < self._precision then
		self._position = target
		self._velocity = 0
		self._atRest = true
		if self._onRest then
			self._onRest(self)
		end
	end
	if self._onUpdate then
		self._onUpdate(x, self)
	end
	return self._atRest
end

function Spring:setEnabled(on)
	self._enabled = on
end

function Spring:destroy()
	allSprings[self] = nil
	springCount -= 1
	self._components = nil
end

-- Bind a spring to an instance property; every scheduler frame, if it is moving,
-- write through. Returns the spring so callers can retarget it.
function Spring.drive(spring, applyFn)
	return Scheduler.schedule(function(dt)
		local atRest = spring:step(dt)
		if not atRest then
			applyFn(spring:getPosition(), spring)
		else
			applyFn(spring._position, spring)
		end
	end, { name = "spring", rate = "frame", priority = 1 })
end

Nocturne.Spring = Spring

-- Tween convenience wrappers ----------------------------------------------------
local Motion = {}
Nocturne.Motion = Motion

function Motion.tween(instance, info, goal)
	local tween =
		TweenService:Create(instance, typeof(info) == "TweenInfo" and info or TweenInfo.new(info or 0.2), goal)
	tween:Play()
	return tween
end

function Motion.presets()
	return Config.motion.tweenPresets
end

function Motion.tweenByPreset(instance, goal, presetName)
	local preset = Config.motion.tweenPresets[presetName] or Config.motion.tweenPresets.hover
	local info = TweenInfo.new(preset.time, preset.style, preset.direction)
	local tween = TweenService:Create(instance, info, goal)
	tween:Play()
	return tween
end

function Motion.cancel(tween)
	if tween then
		tween:Cancel()
	end
end

-- Tween a numeric property with a spring feel for callers too lazy to own a
-- spring; returns a handle with :to(value).
function Motion.springValue(initial, preset, onUpdate)
	local spring = Spring.new(initial, preset, {
		onUpdate = onUpdate,
	})
	local driving = false
	local handle = {
		to = function(_, value)
			spring:setTarget(value)
			if not driving then
				driving = true
				local job
				job = Scheduler.schedule(function(dt)
					local rest = spring:step(dt)
					onUpdate(spring._position, spring)
					if rest then
						driving = false
						Scheduler.unschedule(job)
					end
				end, { name = "springValue", rate = "frame", priority = 1 })
			end
		end,
		set = function(_, value)
			spring:set(value)
			onUpdate(value, spring)
		end,
		get = function(_)
			return spring._position
		end,
		spring = spring,
		destroy = function(_)
			spring:destroy()
		end,
	}
	return handle
end
--═══════════════════════════════════════════════════════════════════════════════--
-- § 7  THEMES
--
-- Eight dark glass palettes plus one "porcelain" light theme, and a set of
-- swappable accents. Themes are plain data; the manager derives every secondary
-- token from the primaries so a fork can add a theme by adding ~20 lines to the
-- table and nothing else.
--═══════════════════════════════════════════════════════════════════════════════--

local Theme = {
	Chosen = Signal.new("themeChosen"),
	_consumerList = {},
	_consumerIndex = {},
}
Nocturne.Theme = Theme

local accentDefs = {
	moonstone = { label = "Moonstone", hex = "#8FD3FF", glow = "#4FB5FF" },
	iris = { label = "Iris", hex = "#A78BFA", glow = "#8B5CF6" },
	nova = { label = "Nova", hex = "#F472B6", glow = "#EC4899" },
	ember = { label = "Ember", hex = "#FB923C", glow = "#F97316" },
	solar = { label = "Solar", hex = "#FACC15", glow = "#EAB308" },
	mint = { label = "Mint", hex = "#34D399", glow = "#10B981" },
	coral = { label = "Coral", hex = "#FF7A6B", glow = "#F43F5E" },
	sky = { label = "Sky", hex = "#38BDF8", glow = "#0EA5E9" },
	lime = { label = "Lime", hex = "#A3E635", glow = "#84CC16" },
	plasma = { label = "Plasma", hex = "#C084FC", glow = "#A855F7" },
	ruby = { label = "Ruby", hex = "#FB7185", glow = "#E11D48" },
	glacier = { label = "Glacier", hex = "#B8E6E0", glow = "#5EC5B9" },
}

local themeDefs = {
	obsidian = {
		label = "Obsidian",
		note = "the house style: volcanic glass, cool cast",
		surface = "#101319",
		surfaceBright = "#1A1F29",
		surfaceDeep = "#07090D",
		desktop = "#05070B",
		wall = { "#0B0F16", "#141A26", "#0A0D13" },
		orb = { "#2B3F58", "#5A4B76" },
		text = "#EDF1F7",
		dim = "#9AA4B2",
		faint = "#5C6672",
		hairline = "#FFFFFF",
		shadow = "#000000",
		gloss = 0.4,
		grain = 0.06,
		tintBias = 0.0,
		vibrancy = 1.22,
	},
	midnight = {
		label = "Midnight",
		note = "blue hour, deeper cool",
		surface = "#0C1222",
		surfaceBright = "#16203A",
		surfaceDeep = "#060A16",
		desktop = "#04060E",
		wall = { "#060B1A", "#12203F", "#080D1C" },
		orb = { "#1E3A6E", "#3B2F6E" },
		text = "#E8EEF9",
		dim = "#8D9BB5",
		faint = "#55627C",
		hairline = "#D6E4FF",
		shadow = "#000208",
		gloss = 0.44,
		grain = 0.055,
		tintBias = 0.02,
		vibrancy = 1.28,
	},
	graphite = {
		label = "Graphite",
		note = "neutral, no colour cast, maximum legibility",
		surface = "#141517",
		surfaceBright = "#202225",
		surfaceDeep = "#0A0B0C",
		desktop = "#08090A",
		wall = { "#0C0D0F", "#1A1C1F", "#0E0F11" },
		orb = { "#3A3D42", "#4A4E55" },
		text = "#F2F2F3",
		dim = "#A3A5A8",
		faint = "#66686C",
		hairline = "#FFFFFF",
		shadow = "#000000",
		gloss = 0.36,
		grain = 0.05,
		tintBias = 0.0,
		vibrancy = 1.12,
	},
	carbon = {
		label = "Carbon",
		note = "warm black with a machined sheen",
		surface = "#151312",
		surfaceBright = "#232019",
		surfaceDeep = "#0B0A09",
		desktop = "#080706",
		wall = { "#0D0B09", "#1E1913", "#0C0A08" },
		orb = { "#4E3D24", "#33261A" },
		text = "#F4EFE6",
		dim = "#ACA294",
		faint = "#6F675C",
		hairline = "#FFF4DC",
		shadow = "#050403",
		gloss = 0.42,
		grain = 0.06,
		tintBias = 0.01,
		vibrancy = 1.18,
	},
	nebula = {
		label = "Nebula",
		note = "violet dust, the show-off theme",
		surface = "#14101F",
		surfaceBright = "#241A3A",
		surfaceDeep = "#0A0713",
		desktop = "#070510",
		wall = { "#0C0718", "#251240", "#120A24" },
		orb = { "#5B2D8A", "#234A9E" },
		text = "#F0E9FA",
		dim = "#A797C0",
		faint = "#6D5F84",
		hairline = "#EBD9FF",
		shadow = "#020008",
		gloss = 0.48,
		grain = 0.05,
		tintBias = 0.03,
		vibrancy = 1.34,
	},
	abyss = {
		label = "Abyss",
		note = "the deep, bioluminescent edges only",
		surface = "#071016",
		surfaceBright = "#0E2029",
		surfaceDeep = "#030709",
		desktop = "#020406",
		wall = { "#03121A", "#062A38", "#03161E" },
		orb = { "#0A4E63", "#123A52" },
		text = "#DFF3FA",
		dim = "#83A9B8",
		faint = "#4E7280",
		hairline = "#9FE8FF",
		shadow = "#000000",
		gloss = 0.5,
		grain = 0.045,
		tintBias = 0.02,
		vibrancy = 1.3,
	},
	eclipse = {
		label = "Eclipse",
		note = "corona warm on an almost-black field",
		surface = "#131008",
		surfaceBright = "#241D0C",
		surfaceDeep = "#090702",
		desktop = "#060502",
		wall = { "#100B03", "#2B1F08", "#120D04" },
		orb = { "#7A4E0E", "#43260A" },
		text = "#F7EFD9",
		dim = "#B5A47C",
		faint = "#776A4C",
		hairline = "#FFE9B8",
		shadow = "#000000",
		gloss = 0.46,
		grain = 0.05,
		tintBias = 0.02,
		vibrancy = 1.24,
	},
	walu = {
		label = "Walu",
		note = "late-night plum, soft on the eyes",
		surface = "#17121E",
		surfaceBright = "#281E33",
		surfaceDeep = "#0D0913",
		desktop = "#08060C",
		wall = { "#100B16", "#2A1B36", "#140E1D" },
		orb = { "#54306B", "#2F2B66" },
		text = "#F1E9F5",
		dim = "#B3A0BF",
		faint = "#796886",
		hairline = "#F4E7FF",
		shadow = "#010004",
		gloss = 0.42,
		grain = 0.05,
		tintBias = 0.01,
		vibrancy = 1.2,
	},
	porcelain = {
		label = "Porcelain",
		note = "light glass for daylight and recordings",
		surface = "#E9E7E4",
		surfaceBright = "#F8F7F5",
		surfaceDeep = "#D2CFCA",
		desktop = "#DEDBD6",
		wall = { "#E7E4DF", "#F6F4F0", "#DFDCD6" },
		orb = { "#C5D8E8", "#E8D5C5" },
		text = "#1A1B1D",
		dim = "#5C5E62",
		faint = "#909296",
		hairline = "#000000",
		shadow = "#3A3630",
		gloss = 0.6,
		grain = 0.03,
		tintBias = -0.06,
		vibrancy = 1.08,
		light = true,
	},
}

-- Shared semantics do not change per theme; contrast tuning keeps them readable
-- on either surface family.
local semantic = {
	success = "#4ADE80",
	warning = "#FACC15",
	danger = "#F87171",
	critical = "#EF4444",
	info = "#7DD3FC",
	rating = "#FBBF24",
}

local function colorFromRGBSafe(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function deriveTokens(def, accentDef)
	local light = def.light == true
	local accent = Color.fromHex(accentDef.hex)
	local accentGlow = Color.fromHex(accentDef.glow)
	local surface = Color.fromHex(def.surface)
	local tokens = {
		id = nil,
		label = def.label,
		note = def.note,
		light = light,
		desktop = Color.fromHex(def.desktop),
		surface = surface,
		surfaceBright = Color.fromHex(def.surfaceBright),
		surfaceDeep = Color.fromHex(def.surfaceDeep),
		wall = T.map(def.wall, Color.fromHex),
		orb = T.map(def.orb, Color.fromHex),
		text = Color.fromHex(def.text),
		dim = Color.fromHex(def.dim),
		faint = Color.fromHex(def.faint),
		hairline = Color.fromHex(def.hairline),
		shadow = Color.fromHex(def.shadow),
		gloss = def.gloss,
		grain = def.grain,
		tintBias = def.tintBias,
		vibrancy = def.vibrancy,
		accent = accent,
		accentGlow = accentGlow,
		accentBright = Color.addWhite(accent, light and -0.12 or 0.22),
		accentSoft = Color.mix(accent, surface, light and 0.72 or 0.55),
		accentDeep = Color.addBlack(accent, light and 0.1 or 0.3),
		accentInk = Color.readableOn(accent),
		selection = Color.mix(accent, surface, 0.45),
		ripple = light and colorFromRGBSafe(0, 0, 0) or colorFromRGBSafe(255, 255, 255),
	}
	for k, hexv in semantic do
		tokens[k] = Color.fromHex(hexv)
	end
	tokens.glassTint = Math.clamp((light and 0.5 or 0.42) + def.tintBias, 0.2, 0.85)
	tokens.hairlineOpacity = light and 0.32 or 0.42
	tokens.strokeOpacity = light and 0.24 or 0.16
	return tokens
end

-- Small guard kept next to the derivation that uses it: Color3.fromRGB rejects
-- nothing, but wrapping gives us one place to add clamping if that ever changes.

local activeTokens = nil

function Theme.tokens()
	return activeTokens
end

function Theme.register(fn)
	local entry = { fn = fn }
	table.insert(Theme._consumerList, entry)
	Theme._consumerIndex[fn] = entry
	fn(activeTokens)
	return function()
		T.removeValue(Theme._consumerList, entry)
		Theme._consumerIndex[fn] = nil
	end
end

function Theme.apply(themeName, accentName, silent)
	local def = themeDefs[themeName] or themeDefs.obsidian
	local accent = accentDefs[accentName or State.currentAccent] or accentDefs.moonstone
	activeTokens = deriveTokens(def, accent)
	activeTokens.id = themeName
	State.currentTheme = themeName
	if accentName then
		State.currentAccent = accentName
	end
	for _, entry in Theme._consumerList do
		local ok, err = pcall(entry.fn, activeTokens)
		if not ok then
			logWarn("theme consumer failed:", tostring(err))
		end
	end
	if not silent then
		Theme.Chosen:Fire(activeTokens)
	end
	return activeTokens
end

function Theme.setAccent(accentName)
	return Theme.apply(State.currentTheme, accentName)
end

function Theme.list()
	local out = {}
	for id, def in themeDefs do
		table.insert(out, { id = id, label = def.label, note = def.note })
	end
	table.sort(out, function(a, b)
		return a.label < b.label
	end)
	return out
end

function Theme.accentList()
	local out = {}
	for id, def in accentDefs do
		table.insert(out, { id = id, label = def.label, swatch = Color.fromHex(def.hex) })
	end
	table.sort(out, function(a, b)
		return a.label < b.label
	end)
	return out
end

Theme._defs = themeDefs
Theme.apply("obsidian", "moonstone", true)

--═══════════════════════════════════════════════════════════════════════════════--
-- § 7b  SCENE DEPTH
--
-- The trick that sells "liquid glass" on Roblox: when translucent panels come
-- forward, the world behind them must fall away. Blur + colour correction on
-- Lighting do exactly what vibrancy does on desktop platforms. We keep ONE blur
-- and ONE correction for the whole UI, driven by how much glass is currently up.
--═══════════════════════════════════════════════════════════════════════════════--

local Depth = {}
Nocturne.Depth = Depth

Depth.blur = nil
Depth.correction = nil
Depth.targetBlur = 0
Depth.currentBlur = 0
Depth.overlayCount = 0
Depth.heavyCount = 0

local function ensureEffects()
	if not Capabilities.sceneBlur then
		return
	end
	if Depth.blur == nil then
		local ok = pcall(function()
			Depth.blur = Instance.new("BlurEffect")
			Depth.blur.Name = "NocturneDepthBlur"
			Depth.blur.Size = 0
			Depth.blur.Enabled = false
			Depth.blur.Parent = Lighting
		end)
		if not ok then
			Capabilities.sceneBlur = false
			return
		end
	end
	if Depth.correction == nil then
		pcall(function()
			Depth.correction = Instance.new("ColorCorrectionEffect")
			Depth.correction.Name = "NocturneDepthVibrance"
			Depth.correction.Enabled = false
			Depth.correction.Brightness = 0
			Depth.correction.Saturation = 0
			Depth.correction.Contrast = 0
			Depth.correction.Parent = Lighting
		end)
	end
end

function Depth.push(heavy)
	ensureEffects()
	Depth.overlayCount += 1
	if heavy then
		Depth.heavyCount += 1
	end
	Depth.recompute()
end

function Depth.pop(heavy)
	Depth.overlayCount = math.max(0, Depth.overlayCount - 1)
	if heavy then
		Depth.heavyCount = math.max(0, Depth.heavyCount - 1)
	end
	Depth.recompute()
end

function Depth.recompute()
	local base = Config.glass.sceneBlurSize * State.blurStrength
	local target = 0
	if Depth.heavyCount > 0 then
		target = base
	elseif Depth.overlayCount > 0 then
		target = base * 0.45
	else
		target = Config.glass.sceneBlurWhenIdle
	end
	if State.reduceMotion then
		target = math.min(target, 10)
	end
	Depth.targetBlur = target
	if Depth.blur ~= nil and not Depth.blur.Enabled then
		Depth.blur.Enabled = true
	end
	if Depth.correction ~= nil and not Depth.correction.Enabled then
		Depth.correction.Enabled = true
	end
end

-- One slow consumer does the smoothing; individual overlays just push/pop.
Scheduler.schedule(function(dt)
	if Depth.blur == nil then
		return
	end
	local changed = math.abs(Depth.currentBlur - Depth.targetBlur) > 0.05
	if not changed then
		return
	end
	Depth.currentBlur = Math.damp(Depth.currentBlur, Depth.targetBlur, 9, dt)
	if Depth.currentBlur < 0.08 and Depth.targetBlur <= 0.01 then
		Depth.blur.Size = 0
		Depth.blur.Enabled = Depth.overlayCount > 0
		if Depth.correction then
			Depth.correction.Enabled = false
		end
		return
	end
	Depth.blur.Size = Depth.currentBlur
	if Depth.correction then
		local t = Math.clamp01(Depth.currentBlur / math.max(1, Config.glass.sceneBlurSize))
		local tokens = Theme.tokens()
		Depth.correction.Brightness = -Config.glass.dimBehind * t
		Depth.correction.Saturation = (tokens and tokens.vibrancy or 1.15) > 1 and (tokens.vibrancy - 1) * t or 0
		Depth.correction.Contrast = Config.glass.contrastBehind * t
	end
end, { name = "depth", rate = 1 / 0.05, priority = 2 })

Nocturne.Depth = Depth
--═══════════════════════════════════════════════════════════════════════════════--
-- § 8  GLASS CORE
--
-- The refractive surface. Everything else — windows, dock, toasts, menus — is a
-- arrangement of these. The layers, bottom to top:
--
--   shadow stack      layered soft offset frames; a cheap volumetric falloff
--   body              the translucent sheet itself (CanvasGroup when supported)
--   refraction veil   slow vertical gradient, the "you can see through me" tell
--   caustics          2-3 drifting light strips inside the material
--   top gloss         the broad highlight from the key light above
--   hairline          a 1.5px bright line across the top edge only
--   rim stroke        gradient stroke, brightest at top-left, like a real edge
--   refraction band   a wide inset stroke that fakes edge lensing
--   specular disc     a cursor-tracking highlight — the live part
--   grain             frosted micro-noise so the glass is never sterile
--
-- All animation for all surfaces is driven from exactly three scheduler jobs
-- (caustics, specular, wobble), never one-per-widget connections.
--═══════════════════════════════════════════════════════════════════════════════--

local Glass = {
	_surfaces = {},
	_surfaceCount = 0,
	_time = 0,
	ripplePool = nil,
}
Nocturne.Glass = Glass

-- Cursor ------------------------------------------------------------------------
-- One shared pointer state. Springs here, consumers everywhere: specular, dock
-- magnification, parallax, hover proximity, the glow overlay.
local Cursor = {
	position = Vector2.new(0, 0),
	smooth = Vector2.new(0, 0),
	velocity = Vector2.new(0, 0),
	down = false,
	downAlpha = 0,
	lastActivity = 0,
	visible = true,
}
Nocturne.Cursor = Cursor

do
	local prev = Vector2.new(0, 0)
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			Cursor.position = input.Position
			Cursor.lastActivity = os.clock()
			Cursor.visible = true
		end
	end)
	UserInputService.InputBegan:Connect(function(input, gpe)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			Cursor.down = true
		elseif input.UserInputType == Enum.UserInputType.Touch then
			Cursor.position = input.Position
			Cursor.down = true
			Cursor.lastActivity = os.clock()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			Cursor.down = false
		end
	end)

	Scheduler.schedule(function(dt)
		prev, Cursor.velocity = Cursor.smooth, (Cursor.position - prev) / math.max(1e-4, dt)
		Cursor.smooth = Math.damp(Cursor.smooth.X, Cursor.position.X, 18, dt)
			and Vector2.new(
				Math.damp(Cursor.smooth.X, Cursor.position.X, 18, dt),
				Math.damp(Cursor.smooth.Y, Cursor.position.Y, 18, dt)
			)
		Cursor.downAlpha = Math.damp(Cursor.downAlpha, Cursor.down and 1 or 0, 14, dt)
	end, { name = "cursor", priority = 0, rate = "frame" })
end

-- Surface construction -----------------------------------------------------------

local function shadowStack(root, tokens, cfg, roundness)
	local frames = {}
	for i = 1, cfg.shadowLayers do
		local spread = cfg.shadowSpread * (i / cfg.shadowLayers)
		local s = create("Frame", {
			Name = "Shadow" .. i,
			BackgroundColor3 = tokens.shadow,
			BackgroundTransparency = Math.lerp(0.82, 0.55, i / cfg.shadowLayers),
			Size = UDim2.new(1, spread * 2, 1, spread * 2 + 4),
			Position = UDim2.new(0, -spread, 0, -spread * 0.45 + i * 3.2 + 4),
			ZIndex = 0,
			Parent = root,
		})
		create("UICorner", { CornerRadius = UDim.new(0, roundness + spread * 0.6), Parent = s })
		-- A vertical fade so the shadow is heavier under the panel than beside it.
		local g = create("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.55),
				NumberSequenceKeypoint.new(0.6, 0.05),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Parent = s,
		})
		frames[i] = { frame = s, gradient = g }
	end
	return frames
end

local function makeCausticStrips(container, count)
	local strips = {}
	for i = 1, count do
		local strip = create("Frame", {
			Name = "Caustic" .. i,
			BackgroundTransparency = 1,
			Size = UDim2.new(1.9, 0, 0.22, 0),
			Position = UDim2.new(-0.45, 0, (i - 0.6) / (count + 0.4), 0),
			Rotation = 12 - i * 9,
			Parent = container,
		})
		local g = create("UIGradient", {
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.32, 0.62),
				NumberSequenceKeypoint.new(0.5, 0.42),
				NumberSequenceKeypoint.new(0.72, 0.62),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Rotation = 0,
			Parent = strip,
		})
		table.insert(strips, { strip = strip, gradient = g, phase = i * 2.1, baseY = (i - 0.6) / (count + 0.4) })
	end
	return strips
end

-- opts: { size, position, roundness, tint, shadow, specular, caustics, interactive,
--         name, parent, stroke, flow, clip, anchor, minSize }
function Glass.new(parent, opts)
	opts = opts or {}
	local tokens = Theme.tokens()
	local cfg = Config.glass
	local roundness = opts.roundness or cfg.roundness
	local interactive = opts.interactive ~= false

	local root = create("Frame", {
		Name = opts.name or "GlassSurface",
		BackgroundTransparency = 1,
		Size = opts.size or UDim2.fromOffset(320, 220),
		Position = opts.position or UDim2.fromScale(0.5, 0.5),
		AnchorPoint = opts.anchor or Vector2.new(0.5, 0.5),
		ZIndex = opts.zIndex or 1,
		Parent = parent,
	})
	register("surfaces", root)

	local body = create(Capabilities.canvasGroup and "CanvasGroup" or "Frame", {
		Name = "Body",
		BackgroundColor3 = tokens.surface,
		BackgroundTransparency = 1 - Math.clamp(cfg.body + tokens.tintBias, 0.18, 0.86),
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		ClipsDescendants = opts.clip ~= false,
		ZIndex = 1,
		Parent = root,
	})
	pcall(function()
		body.GroupTransparency = body.BackgroundTransparency * 0.35
	end)
	local corner = create("UICorner", { CornerRadius = UDim.new(0, roundness), Parent = body })
	if Capabilities.cornerSoftness then
		pcall(function()
			corner.SoftwareAngleSegments = 48
		end)
	end

	local shadows = nil
	if opts.shadow ~= false then
		shadows = shadowStack(root, tokens, cfg, roundness)
	end

	-- Refraction veil: subtle brightness bias toward the top, like light entering
	-- the sheet. On light themes this darkens instead.
	local veil = create("Frame", {
		Name = "RefractionVeil",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
		Parent = body,
	})
	local veilGrad = create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(tokens.light and Color3.fromRGB(24, 26, 30) or Color3.fromRGB(150, 170, 205)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, tokens.light and 0.93 or 0.78),
			NumberSequenceKeypoint.new(0.55, tokens.light and 0.985 or 0.93),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = veil,
	})

	local causticStrips = nil
	if cfg.caustics and opts.caustics ~= false and not State.reduceMotion then
		local container = create("Frame", {
			Name = "Caustics",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 3,
			Parent = body,
		})
		causticStrips = makeCausticStrips(container, cfg.causticsCount)
	end

	local gloss = create("Frame", {
		Name = "Gloss",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0.52, 0),
		Position = UDim2.fromScale(0, 0),
		ZIndex = 4,
		Parent = body,
	})
	create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1 - cfg.topGloss * tokens.gloss),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = gloss,
	})

	-- Hairline: the one-pixel bright kiss along the top edge.
	local hairline = create("Frame", {
		Name = "Hairline",
		BackgroundColor3 = tokens.hairline,
		BackgroundTransparency = 1 - cfg.hairlineOpacity * 0.9,
		Size = UDim2.new(1, -roundness, 0, 1),
		Position = UDim2.new(0, roundness * 0.5, 0, 1),
		ZIndex = 6,
		Parent = body,
	})
	create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.22, 0),
			NumberSequenceKeypoint.new(0.78, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = hairline,
	})

	local stroke = create("UIStroke", {
		Name = "Rim",
		Color = Color.addWhite(tokens.hairline, 0.1),
		Transparency = 1 - cfg.borderOpacity,
		Thickness = cfg.rimWidth,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = body,
	})
	-- The rim is brighter at the top-left and dies toward the bottom-right:
	-- every reference render of glass does this, so we do it too.
	local rimGradient = create("UIGradient", {
		Rotation = 135,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1 - cfg.rimLight),
			NumberSequenceKeypoint.new(0.4, 1 - cfg.rimLight * 0.35),
			NumberSequenceKeypoint.new(1, 0.92),
		}),
		Parent = stroke,
	})

	-- Refraction band: a fat translucent inset stroke faking edge lensing.
	local refract = create("Frame", {
		Name = "RefractionBand",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -cfg.refractionBand, 1, -cfg.refractionBand),
		Position = UDim2.new(0, cfg.refractionBand * 0.5, 0, cfg.refractionBand * 0.5),
		ZIndex = 5,
		Parent = body,
	})
	local refractStroke = create("UIStroke", {
		Color = Color.mix(tokens.surface, Color3.fromRGB(255, 255, 255), 0.85),
		Transparency = 1 - cfg.refraction * 0.18,
		Thickness = cfg.refractionBand * 0.9,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = refract,
	})
	create(
		"UICorner",
		{ CornerRadius = UDim.new(0, math.max(2, roundness - cfg.refractionBand * 0.4)), Parent = refract }
	)

	-- Frosted grain. Uses the one engine-shipped noise texture; if a future client
	-- removes it, the pcall swallows the failure and the glass is just cleaner.
	local grain = nil
	if cfg.grain > 0 then
		grain = create("ImageLabel", {
			Name = "Grain",
			BackgroundTransparency = 1,
			Image = "rbxasset://textures/particles/noise_main.png",
			ImageTransparency = 1 - cfg.grain,
			ImageColor3 = Color3.fromRGB(210, 220, 235),
			ScaleType = Enum.ScaleType.Tile,
			TileSize = UDim2.fromOffset(140, 140),
			Size = UDim2.fromScale(1, 1),
			Rotates = true,
			ZIndex = 5,
			Parent = body,
		})
	end

	local specular = nil
	local specSpringX, specSpringY, specAlpha
	if interactive and cfg.specular > 0 then
		specular = create("Frame", {
			Name = "Specular",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(cfg.specularSize, cfg.specularSize),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = 5,
			Parent = body,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = specular })
		create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color.addWhite(tokens.accent, 0.45)),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1 - cfg.specular),
				NumberSequenceKeypoint.new(0.55, 1 - cfg.specular * 0.4),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = specular,
		})
		specSpringX = Spring.new(0.5, Config.motion.springCinematic)
		specSpringY = Spring.new(0.5, Config.motion.springCinematic)
		specAlpha = Spring.new(1, Config.motion.spring)
		specular.BackgroundTransparency = 1
	end

	local content = create("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 10,
		ClipsDescendants = false,
		Parent = root,
	})

	local wobbleSkew = nil
	local wobbleX, wobbleVX = 0, 0
	local wobbleY, wobbleVY = 0, 0
	if Capabilities.uiskew and cfg.wobble > 0 then
		wobbleSkew = create("UISkew", { Skew = Vector2.zero, Parent = root })
	end

	local surface = {
		root = root,
		body = body,
		content = content,
		corner = corner,
		stroke = stroke,
		rimGradient = rimGradient,
		hairline = hairline,
		gloss = gloss,
		veil = veil,
		veilGrad = veilGrad,
		refract = refract,
		refractStroke = refractStroke,
		grain = grain,
		caustics = causticStrips,
		specular = specular,
		specX = specSpringX,
		specY = specSpringY,
		specA = specAlpha,
		shadows = shadows,
		wobbleSkew = wobbleSkew,
		roundness = roundness,
		roundSpring = Spring.new(roundness, Config.motion.springBouncy, { precision = 0.1 }),
		opts = opts,
		hovering = false,
		lit = 0,
		litSpring = Spring.new(0, Config.motion.spring),
		flow = opts.flow or false,
		alive = true,
	}

	local comp = CompositeConnection.new()
	surface._comp = comp

	-- Theme: re-decorate on every palette flip. Registered per surface so a
	-- surface created after a theme change still paints correctly immediately.
	local unsub = Theme.register(function(t)
		surface._tokens = t
		body.BackgroundColor3 = t.surface
		hairline.BackgroundColor3 = t.hairline
		stroke.Color = Color.addWhite(t.hairline, 0.1)
		veilGrad.Color = ColorSequence.new(t.light and Color3.fromRGB(24, 26, 30) or Color3.fromRGB(150, 170, 205))
		veil.Transparency = 1 -- gradient owns it
		if specular then
			specular:FindFirstChildWhichIsA("UIGradient").Color = ColorSequence.new(Color.addWhite(t.accent, 0.45))
		end
		if shadows then
			for _, layer in shadows do
				layer.frame.BackgroundColor3 = t.shadow
			end
		end
		refractStroke.Color = Color.mix(t.surface, Color3.fromRGB(255, 255, 255), t.light and 0.6 or 0.85)
	end)
	surface._unsubTheme = unsub

	function surface:setRoundness(px)
		self.roundness = px
		self.roundSpring:setTarget(px)
	end

	function surface:setTint(alpha)
		body.BackgroundTransparency = 1 - Math.clamp(alpha, 0.05, 0.95)
	end

	function surface:setFlow(on)
		self.flow = on
	end

	function surface:wobble(impulseX, impulseY)
		if State.reduceMotion or self.wobbleSkew == nil then
			return
		end
		local cfgw = Config.glass
		wobbleVX += (impulseX or 0) * 60
		wobbleVY += (impulseY or 0) * 60
	end

	function surface:kill()
		self.alive = false
		if self._unsubTheme then
			self._unsubTheme()
		end
		self._comp:Destroy()
		pcall(root.Destroy, root)
		local idx = T.indexOf(Glass._surfaces, self)
		if idx then
			table.remove(Glass._surfaces, idx)
			Glass._surfaceCount -= 1
		end
	end

	table.insert(Glass._surfaces, surface)
	Glass._surfaceCount += 1
	return surface
end

-- Alias with friendlier defaults used by panels and cards.
function Glass.panel(parent, opts)
	opts = opts or {}
	opts.name = opts.name or "Panel"
	return Glass.new(parent, opts)
end

-- Embed the sheen onto an already-built frame (popovers, menu rows, chips).
function Glass.embed(frame, opts)
	opts = opts or {}
	local tokens = Theme.tokens()
	local cfg = Config.glass
	local roundness = opts.roundness or 12
	create("UICorner", { CornerRadius = UDim.new(0, roundness), Parent = frame })
	frame.BackgroundColor3 = tokens.surfaceBright
	frame.BackgroundTransparency = opts.transparency
		or (1 - Math.clamp(cfg.body * 0.92 + tokens.tintBias + 0.16, 0.3, 0.94))
	local stroke = create("UIStroke", {
		Color = tokens.hairline,
		Transparency = 1 - (opts.rim or cfg.borderOpacity),
		Thickness = cfg.rimWidth,
		Parent = frame,
	})
	create("UIGradient", {
		Rotation = 135,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1 - cfg.rimLight),
			NumberSequenceKeypoint.new(1, 0.9),
		}),
		Parent = stroke,
	})
	local gloss = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0.5, 0),
		ZIndex = frame.ZIndex + 1,
		Parent = frame,
	})
	create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1 - cfg.topGloss * 0.75 * tokens.gloss),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = gloss,
	})
	return { frame = frame, stroke = stroke, gloss = gloss }
end

-- Shared animation pumps ---------------------------------------------------------

-- Caustics: three thin light strips drift and rotate per surface with a phase
-- offset. Half-rate at 30fps equivalent; nobody will ever see the difference.
Scheduler.schedule(function()
	if State.reduceMotion then
		return
	end
	Glass._time += Scheduler._delta * (State.fps < 30 and 0.6 or 1)
	local t = Glass._time
	local strength = Config.glass.causticsStrength * State.adaptiveQuality
	local speed = Config.glass.causticsSpeed
	for _, surface in Glass._surfaces do
		if surface.caustics and surface.alive then
			for _, strip in surface.caustics do
				local s = t * speed + strip.phase
				strip.gradient.Offset = Vector2.new(math.sin(s) * 0.42 * strength, math.cos(s * 0.7) * 0.1)
				strip.strip.Position = UDim2.new(-0.45, 0, strip.baseY + math.sin(s * 0.6) * 0.035, 0)
				strip.strip.Rotation = 12 + math.sin(s * 0.45) * 6
			end
		end
		if surface.grain then
			-- The grain breathes a few percent; frozen noise reads as a texture bug.
			surface.grain.Rotation = math.sin(t * 0.11) * 3
		end
		if surface.flow and surface.rimGradient then
			-- Focused windows cycle their rim light like a slow tide.
			surface.rimGradient.Rotation = 135 + math.sin(t * 0.6) * 35
		end
	end
end, { name = "caustics", rate = Config.glass and 30 or 30, priority = 6 })

-- Specular + lit state: only surfaces being hovered (or recently) run this maths.
Scheduler.schedule(function(dt)
	local mx, my = Cursor.smooth.X, Cursor.smooth.Y
	for _, surface in Glass._surfaces do
		if surface.specular and surface.alive and (surface.hovering or surface.lit > 0.01) then
			local ap, as = surface.root.AbsolutePosition, surface.root.AbsoluteSize
			if as.X > 1 and as.Y > 1 then
				local lx = Math.clamp01((mx - ap.X) / as.X)
				local ly = Math.clamp01((my - ap.Y) / as.Y)
				surface.specX:setTarget(lx)
				surface.specY:setTarget(ly)
				local edge = Math.clamp01(math.min(lx, ly, 1 - lx, 1 - ly) * 3)
				surface.litSpring:setTarget(surface.hovering and 1 or 0.12 * (1 - edge))
			end
		elseif surface.specular and surface.alive then
			surface.litSpring:setTarget(0)
		end
		if surface.specular and surface.alive then
			local at = surface.litSpring:step(dt)
			surface.lit = surface.litSpring._position
			local sx = surface.specX:step(dt)
			surface.specY:step(dt)
			surface.specular.Position = UDim2.fromScale(surface.specX._position, surface.specY._position)
			local size = math.min(surface.specular.AbsoluteSize.X, 420) * (1 + surface.lit * 0.25)
			surface.specular.Size = UDim2.fromOffset(size, size * 0.78)
			surface.specular.BackgroundTransparency = 1 - Math.clamp01(surface.lit)
		end
	end
end, { name = "specular", rate = "frame", priority = 1 })

-- Global wobble oscillator: all surfaces share one phase clock; each keeps
-- amplitude, so a hundred panels cost one loop with an early exit.
Scheduler.schedule(function(dt)
	if State.reduceMotion then
		return
	end
	local g = Config.glass
	local k = 11.5 * g.wobbleFrequency / 11.5
	local damp = g.wobbleDecay
	for _, surface in Glass._surfaces do
		if surface.wobbleSkew ~= nil and surface.alive then
			local a = surface._wob or { x = 0, vx = 0, y = 0, vy = 0 }
			surface._wob = a
			if a.x == 0 and a.vx == 0 and a.y == 0 and a.vy == 0 then
				continue
			end
			local ax = (-k * a.x - damp * a.vx)
			local ay = (-k * a.y - damp * a.vy)
			a.vx += ax * dt
			a.vy += ay * dt
			a.x += a.vx * dt
			a.y += a.vy * dt
			if math.abs(a.x) + math.abs(a.y) < 0.0004 then
				a.x, a.vx, a.y, a.vy = 0, 0, 0, 0
				surface.wobbleSkew.Skew = Vector2.zero
			else
				surface.wobbleSkew.Skew = Vector2.new(a.x, a.y)
			end
		end
	end
end, { name = "wobble", rate = "frame", priority = 1 })

function Glass.wobbleAll(strength)
	for _, surface in Glass._surfaces do
		if surface.alive and surface.wobbleSkew then
			local a = surface._wob or { x = 0, vx = 0, y = 0, vy = 0 }
			surface._wob = a
			a.vx += Math.randomRange(-1, 1) * strength
			a.vy += Math.randomRange(-1, 1) * strength
		end
	end
end

-- Hover bookkeeping from widgets: we do not connect InputChanged per widget; each
-- interactive root gets one InputBegan/Ended pair via a helper the widgets call.
function Glass.attachHover(surface, frame)
	frame = frame or surface.root
	local comp = surface._comp
	comp:Add(frame.MouseEnter:Connect(function()
		surface.hovering = true
		if surface.specA then
			surface.litSpring:setTarget(1)
		end
	end))
	comp:Add(frame.MouseLeave:Connect(function()
		surface.hovering = false
		surface.litSpring:setTarget(0)
	end))
end

-- Ripples ------------------------------------------------------------------------
-- A tap is answered by a disc of light expanding from the touch point, springed,
-- then released to the pool. This is the micro-interaction the whole kit leans on.
do
	local pool
	local function makeRipple()
		local disc = create("Frame", {
			Name = "Ripple",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.4, 0.4),
			ZIndex = 60,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = disc })
		local ring = create("UIStroke", {
			Thickness = 1.6,
			Transparency = 0.4,
			Parent = disc,
		})
		return { disc = disc, ring = ring }
	end
	local function resetRipple(item, parent)
		item.disc.Parent = parent
		item.disc.Size = UDim2.fromScale(0.4, 0.4)
	end

	function Glass.ripple(frame, x, y, opts)
		if State.reduceMotion then
			return
		end
		opts = opts or {}
		if pool == nil then
			pool = Pool.getOrCreate("ripple", makeRipple, resetRipple)
		end
		local tokens = Theme.tokens()
		local item = pool:Get()
		local disc, ring = item.disc, item.ring
		disc.Parent = frame
		local ap, as = frame.AbsolutePosition, frame.AbsoluteSize
		local ax, ay = (x or ap.X + as.X / 2) - ap.X, (y or ap.Y + as.Y / 2) - ap.Y
		disc.Position = UDim2.fromOffset(ax, ay)
		local diagonal = math.max(as.X, as.Y) * 2.4
		disc.Size = UDim2.fromOffset(6, 6)
		disc.BackgroundColor3 = opts.color or Color.addWhite(tokens.accent, 0.3)
		disc.BackgroundTransparency = 1 - Config.motion.rippleOpacity
		ring.Color = disc.BackgroundColor3
		ring.Transparency = 0.25
		local start = os.clock()
		local taskRef
		taskRef = Scheduler.schedule(function()
			local e = os.clock() - start
			local span = 0.55 / Config.motion.rippleSpeed
			if e > span then
				Scheduler.unschedule(taskRef)
				disc.Parent = nil
				pool:Release(item)
				return
			end
			local t = Easing.outQuint(e / span)
			local size = Math.lerp(6, diagonal, t)
			disc.Size = UDim2.fromOffset(size, size)
			disc.BackgroundTransparency = Math.lerp(1 - Config.motion.rippleOpacity, 1, t)
			ring.Transparency = Math.lerp(0.15, 1, t)
			ring.Thickness = Math.lerp(2.4, 0.4, t)
		end, { name = "ripple", rate = "frame", priority = 2 })
	end
end

-- Press squish used by every control: returns handlers to wire into input.
function Glass.pressSquish(instance, opts)
	opts = opts or {}
	local scaleSpring = Spring.new(1, opts.spring or Config.motion.springQuick)
	local running = false
	local job
	local function ensure()
		if running then
			return
		end
		running = true
		job = Scheduler.schedule(function(dt)
			local rest = scaleSpring:step(dt)
			local s = scaleSpring._position
			instance.Size = UDim2.new(1 - (1 - s) * 0.5, 0, 1 - (1 - s) * 0.5, 0)
			instance.Position = UDim2.new((1 - s) * 0.25, 0, (1 - s) * 0.25, 0)
			if rest then
				Scheduler.unschedule(job)
				running = false
			end
		end, { name = "squish", rate = "frame", priority = 1 })
	end
	return {
		press = function(x, y)
			scaleSpring:setTarget(opts.pressScale or Config.motion.pressScale)
			ensure()
			if opts.surface and opts.surface.wobble then
				opts.surface:wobble(0.2, 0.2)
			end
		end,
		release = function()
			scaleSpring:setTarget(1)
			scaleSpring:addVelocity(opts.releaseKick or 3)
			ensure()
		end,
		spring = scaleSpring,
	}
end

Glass.count = function()
	return Glass._surfaceCount
end

function Glass.wipe()
	local snapshot = table.clone(Glass._surfaces)
	for _, surface in snapshot do
		surface:kill()
	end
end
--═══════════════════════════════════════════════════════════════════════════════--
-- § 9  ICON KIT — VECTOR GLYPHS DRAWN WITH FRAMES
--
-- Zero image assets anywhere in this kit. Every icon is constructed from rotated
-- bars, stroked rings and arcs at request time, which means icons are crisp at
-- any size, tint themselves with the theme, and cost one shared cache entry each.
--
--	IconKit.attach(parent, "gear", { size = 18 }) -> { frame, setColor, destroy }
--
-- Shapes are defined in a normalised 0..1 box; the builder scales to pixels.
--═══════════════════════════════════════════════════════════════════════════════--

local IconKit = {
	_defs = {},
	_cache = {},
	_created = 0,
}
Nocturne.Icons = IconKit

local function deg(angleDegrees)
	return angleDegrees
end

-- Each icon is a function (ctx, s) where ctx provides primitives in a box of s px.
-- Primitives register their instances so setColor() and destroy() can walk them.
local function makeContext(container, colorables)
	local ctx = {}
	local px = function(v)
		return v
	end

	function ctx.bar(x1, y1, x2, y2, thicknessN, cornerN)
		local dx, dy = x2 - x1, y2 - y1
		local len = math.sqrt(dx * dx + dy * dy)
		local midX, midY = (x1 + x2) / 2, (y1 + y2) / 2
		local t = math.max(1, (thicknessN or 0.09) * container._s)
		local bar = create("Frame", {
			Name = "i",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(len, t),
			Position = UDim2.fromOffset(midX, midY),
			Rotation = math.atan2(dy, dx) * 180 / math.pi,
			ZIndex = 90,
			Parent = container,
		})
		create("UICorner", { CornerRadius = UDim.new(0, (cornerN or 0.5) * t), Parent = bar })
		local stroke = create("UIStroke", {
			Thickness = t,
			Color = Color3.fromRGB(255, 255, 255),
			Transparency = 0,
			Parent = bar,
		})
		-- Drawing everything as stroke keeps line joins clean and lets a single
		-- colour write recolour the whole glyph.
		bar.BackgroundTransparency = 1
		table.insert(colorables, stroke)
		return bar
	end

	function ctx.ring(cx, cy, rN, thicknessN, startFrac, endFrac)
		local s = container._s
		local r = (rN or 0.38) * s
		local size = r * 2
		local ring = create("Frame", {
			Name = "i",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(size, size),
			Position = UDim2.fromOffset(cx * s, cy * s),
			ZIndex = 90,
			Parent = container,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ring })
		local stroke = create("UIStroke", {
			Thickness = math.max(1, (thicknessN or 0.09) * s),
			Color = Color3.fromRGB(255, 255, 255),
			Transparency = 0,
			Parent = ring,
		})
		table.insert(colorables, stroke)
		return ring
	end

	function ctx.arc(cx, cy, rN, startDeg, sweepDeg, thicknessN)
		local s = container._s
		local r = (rN or 0.36) * s
		local segments = math.max(3, math.ceil(math.abs(sweepDeg) / 24))
		for i = 0, segments - 1 do
			local a0 = math.rad(startDeg + sweepDeg * (i / segments))
			local a1 = math.rad(startDeg + sweepDeg * ((i + 1) / segments))
			local p0x, p0y = cx * s + math.cos(a0) * r, cy * s + math.sin(a0) * r
			local p1x, p1y = cx * s + math.cos(a1) * r, cy * s + math.sin(a1) * r
			ctx.bar(p0x / s, p0y / s, p1x / s, p1y / s, thicknessN or 0.09)
		end
	end

	function ctx.poly(points, closed, thicknessN)
		for i = 1, #points - 1 do
			local a, b = points[i], points[i + 1]
			ctx.bar(a[1], a[2], b[1], b[2], thicknessN)
		end
		if closed then
			local a, b = points[#points], points[1]
			ctx.bar(a[1], a[2], b[1], b[2], thicknessN)
		end
	end

	function ctx.dot(cx, cy, rN)
		local s = container._s
		local d = (rN or 0.06) * s * 2
		local dot = create("Frame", {
			Name = "i",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(d, d),
			Position = UDim2.fromOffset(cx * s, cy * s),
			ZIndex = 90,
			Parent = container,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
		table.insert(colorables, dot)
		return dot
	end

	function ctx.squircle(cx, cy, wN, hN, rN, thicknessN, filled)
		local s = container._s
		local w, h = wN * s, hN * s
		local box = create("Frame", {
			Name = "i",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = filled and 0.15 or 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(w, h),
			Position = UDim2.fromOffset(cx * s, cy * s),
			ZIndex = 90,
			Parent = container,
		})
		create("UICorner", { CornerRadius = UDim.new(0, (rN or 0.06) * s), Parent = box })
		if not filled then
			local stroke = create("UIStroke", {
				Thickness = math.max(1, (thicknessN or 0.07) * s),
				Color = Color3.fromRGB(255, 255, 255),
				Transparency = 0,
				Parent = box,
			})
			table.insert(colorables, stroke)
		else
			table.insert(colorables, box)
		end
		return box
	end

	function ctx.gearTeeth(cx, cy, rN, count, toothLenN, thicknessN)
		local s = container._s
		local r = rN * s
		for i = 1, count do
			local a = (i / count) * math.pi * 2
			local x0, y0 = cx * s + math.cos(a) * r * 0.72, cy * s + math.sin(a) * r * 0.72
			local x1, y1 = cx * s + math.cos(a) * (r + toothLenN * s), cy * s + math.sin(a) * (r + toothLenN * s)
			ctx.bar(x0 / s, y0 / s, x1 / s, y1 / s, thicknessN or 0.11)
		end
	end

	return ctx
end

local D = 1 -- normalized box units

local defs = IconKit._defs

defs.gear = function(c, s)
	c.ring(0.5, 0.5, 0.30, 0.10)
	c.gearTeeth(0.5, 0.5, 0.30, 8, 0.14, 0.10)
	c.dot(0.5, 0.5, 0.055)
end

defs.sliders = function(c, s)
	c.bar(0.18 * D, 0.30 * D, 0.82 * D, 0.30 * D, 0.08)
	c.bar(0.18 * D, 0.70 * D, 0.82 * D, 0.70 * D, 0.08)
	c.dot(0.38, 0.30, 0.085)
	c.dot(0.66, 0.70, 0.085)
end

defs.close = function(c, s)
	c.bar(0.27 * D, 0.27 * D, 0.73 * D, 0.73 * D, 0.10)
	c.bar(0.73 * D, 0.27 * D, 0.27 * D, 0.73 * D, 0.10)
end

defs.check = function(c, s)
	c.bar(0.22 * D, 0.54 * D, 0.43 * D, 0.74 * D, 0.11)
	c.bar(0.43 * D, 0.74 * D, 0.79 * D, 0.29 * D, 0.11)
end

defs.plus = function(c, s)
	c.bar(0.5 * D, 0.24 * D, 0.5 * D, 0.76 * D, 0.10)
	c.bar(0.24 * D, 0.5 * D, 0.76 * D, 0.5 * D, 0.10)
end

defs.minus = function(c, s)
	c.bar(0.24 * D, 0.5 * D, 0.76 * D, 0.5 * D, 0.10)
end

defs.search = function(c, s)
	c.ring(0.44, 0.44, 0.26, 0.10)
	c.bar(0.62 * D, 0.62 * D, 0.82 * D, 0.82 * D, 0.11)
end

defs.home = function(c, s)
	c.poly({ { 0.5, 0.18 }, { 0.16, 0.5 }, { 0.84, 0.5 } }, false, 0.10)
	c.bar(0.24 * D, 0.5 * D, 0.24 * D, 0.82 * D, 0.10)
	c.bar(0.76 * D, 0.5 * D, 0.76 * D, 0.82 * D, 0.10)
	c.bar(0.24 * D, 0.82 * D, 0.76 * D, 0.82 * D, 0.10)
end

defs.play = function(c, s)
	-- A closed triangle reads as "play" at 14px; drawn as three butt-joined bars.
	c.bar(0.34 * D, 0.22 * D, 0.74 * D, 0.5 * D, 0.13)
	c.bar(0.74 * D, 0.5 * D, 0.34 * D, 0.78 * D, 0.13)
	c.bar(0.34 * D, 0.24 * D, 0.34 * D, 0.76 * D, 0.11)
end

defs.pause = function(c, s)
	c.bar(0.38 * D, 0.26 * D, 0.38 * D, 0.74 * D, 0.12)
	c.bar(0.62 * D, 0.26 * D, 0.62 * D, 0.74 * D, 0.12)
end

defs.skipForward = function(c, s)
	c.bar(0.30 * D, 0.26 * D, 0.58 * D, 0.5 * D, 0.11)
	c.bar(0.58 * D, 0.5 * D, 0.30 * D, 0.74 * D, 0.11)
	c.bar(0.70 * D, 0.26 * D, 0.70 * D, 0.74 * D, 0.10)
end

defs.skipBack = function(c, s)
	c.bar(0.70 * D, 0.26 * D, 0.42 * D, 0.5 * D, 0.11)
	c.bar(0.42 * D, 0.5 * D, 0.70 * D, 0.74 * D, 0.11)
	c.bar(0.30 * D, 0.26 * D, 0.30 * D, 0.74 * D, 0.10)
end

defs.shuffle = function(c, s)
	c.poly({ { 0.2, 0.28 }, { 0.42, 0.28 }, { 0.66, 0.72 }, { 0.84, 0.72 } }, false, 0.085)
	c.poly({ { 0.2, 0.72 }, { 0.42, 0.72 }, { 0.66, 0.28 }, { 0.84, 0.28 } }, false, 0.085)
	c.bar(0.74 * D, 0.18 * D, 0.84 * D, 0.28 * D, 0.085)
	c.bar(0.84 * D, 0.28 * D, 0.74 * D, 0.38 * D, 0.085)
	c.bar(0.74 * D, 0.62 * D, 0.84 * D, 0.72 * D, 0.085)
	c.bar(0.84 * D, 0.72 * D, 0.74 * D, 0.82 * D, 0.085)
end

defs["repeat"] = function(c, s)
	c.bar(0.22 * D, 0.34 * D, 0.72 * D, 0.34 * D, 0.085)
	c.bar(0.28 * D, 0.66 * D, 0.78 * D, 0.66 * D, 0.085)
	c.bar(0.72 * D, 0.24 * D, 0.82 * D, 0.34 * D, 0.085)
	c.bar(0.82 * D, 0.34 * D, 0.72 * D, 0.44 * D, 0.085)
	c.bar(0.28 * D, 0.56 * D, 0.18 * D, 0.66 * D, 0.085)
	c.bar(0.18 * D, 0.66 * D, 0.28 * D, 0.76 * D, 0.085)
end

defs.volume = function(c, s)
	c.squircle(0.3, 0.5, 0.2, 0.26, 0.05, 0, true)
	c.poly({ { 0.4, 0.5 }, { 0.56, 0.32 }, { 0.56, 0.68 } }, true, 0.09)
	c.arc(0.62, 0.5, 0.22, -38, 76, 0.08)
end

defs.volumeMute = function(c, s)
	c.squircle(0.3, 0.5, 0.2, 0.26, 0.05, 0, true)
	c.bar(0.60 * D, 0.36 * D, 0.80 * D, 0.64 * D, 0.085)
	c.bar(0.80 * D, 0.36 * D, 0.60 * D, 0.64 * D, 0.085)
end

defs.mic = function(c, s)
	c.squircle(0.5, 0.38, 0.16, 0.24, 0.1, 0, true)
	c.arc(0.5, 0.44, 0.28, 10, 160, 0.08)
	c.bar(0.5 * D, 0.74 * D, 0.5 * D, 0.84 * D, 0.085)
	c.bar(0.36 * D, 0.84 * D, 0.64 * D, 0.84 * D, 0.085)
end

defs.sun = function(c, s)
	c.ring(0.5, 0.5, 0.22, 0.10)
	for i = 1, 8 do
		local a = (i / 8) * math.pi * 2
		local x0 = 0.5 + math.cos(a) * 0.32
		local y0 = 0.5 + math.sin(a) * 0.32
		local x1 = 0.5 + math.cos(a) * 0.44
		local y1 = 0.5 + math.sin(a) * 0.44
		c.bar(x0 * D, y0 * D, x1 * D, y1 * D, 0.07)
	end
end

defs.moon = function(c, s)
	-- crescent via offset ring subtraction is impossible with frames; use an arc
	-- sweep which reads beautifully small.
	c.arc(0.52, 0.5, 0.32, -100, 200, 0.11)
	c.dot(0.62, 0.34, 0.045)
end

defs.cloud = function(c, s)
	c.arc(0.44, 0.56, 0.2, 180, 180, 0.09)
	c.bar(0.24 * D, 0.56 * D, 0.74 * D, 0.56 * D, 0.09)
	c.arc(0.62, 0.5, 0.14, 200, 140, 0.09)
end

defs.rain = function(c, s)
	c.bar(0.26 * D, 0.36 * D, 0.68 * D, 0.36 * D, 0.09)
	c.arc(0.42, 0.32, 0.14, 180, 180, 0.085)
	for i = 1, 3 do
		local x = 0.32 + (i - 1) * 0.16
		c.bar(x * D, 0.58 * D, (x - 0.05) * D, 0.78 * D, 0.07)
	end
end

defs.bolt = function(c, s)
	c.poly({ { 0.56, 0.14 }, { 0.32, 0.54 }, { 0.5, 0.54 }, { 0.4, 0.86 }, { 0.68, 0.44 }, { 0.5, 0.44 } }, false, 0.09)
end

defs.bell = function(c, s)
	c.poly({ { 0.26, 0.62 }, { 0.74, 0.62 } }, false, 0.09)
	c.arc(0.5, 0.62, 0.24, 180, 180, 0.09)
	c.bar(0.5 * D, 0.26 * D, 0.5 * D, 0.34 * D, 0.09)
	c.dot(0.5, 0.72, 0.05)
end

defs.lock = function(c, s)
	c.squircle(0.5, 0.62, 0.4, 0.32, 0.08, 0.09, false)
	c.arc(0.5, 0.44, 0.16, 180, 180, 0.09)
	c.dot(0.5, 0.6, 0.05)
end

defs.unlock = function(c, s)
	c.squircle(0.5, 0.62, 0.4, 0.32, 0.08, 0.09, false)
	c.arc(0.42, 0.44, 0.16, 200, 140, 0.09)
	c.dot(0.5, 0.6, 0.05)
end

defs.eye = function(c, s)
	c.arc(0.5, 0.62, 0.42, -148, 96, 0.085)
	c.arc(0.5, 0.38, 0.42, 52, 96, 0.085)
	c.dot(0.5, 0.5, 0.09)
end

defs.folder = function(c, s)
	c.poly({
		{ 0.18, 0.72 },
		{ 0.18, 0.34 },
		{ 0.4, 0.34 },
		{ 0.48, 0.44 },
		{ 0.82, 0.44 },
		{ 0.82, 0.72 },
		{ 0.18, 0.72 },
	}, false, 0.09)
end

defs.file = function(c, s)
	c.poly(
		{ { 0.28, 0.16 }, { 0.62, 0.16 }, { 0.74, 0.3 }, { 0.74, 0.84 }, { 0.28, 0.84 }, { 0.28, 0.16 } },
		false,
		0.085
	)
	c.bar(0.62 * D, 0.16 * D, 0.62 * D, 0.3 * D, 0.07)
	c.bar(0.62 * D, 0.3 * D, 0.74 * D, 0.3 * D, 0.07)
end

defs.image = function(c, s)
	c.squircle(0.5, 0.5, 0.64, 0.56, 0.09, 0.085, false)
	c.dot(0.36, 0.4, 0.06)
	c.poly({ { 0.24, 0.68 }, { 0.44, 0.5 }, { 0.56, 0.62 }, { 0.68, 0.46 }, { 0.78, 0.66 } }, false, 0.08)
end

defs.music = function(c, s)
	c.bar(0.60 * D, 0.2 * D, 0.60 * D, 0.7 * D, 0.085)
	c.bar(0.60 * D, 0.2 * D, 0.8 * D, 0.26 * D, 0.085)
	c.dot(0.52, 0.72, 0.11)
	c.dot(0.74, 0.66, 0.1)
end

defs.heart = function(c, s)
	c.arc(0.35, 0.36, 0.16, 120, 240, 0.09)
	c.arc(0.65, 0.36, 0.16, 120, 240, 0.09)
	c.poly({ { 0.22, 0.46 }, { 0.5, 0.8 } }, false, 0.09)
	c.poly({ { 0.78, 0.46 }, { 0.5, 0.8 } }, false, 0.09)
end

defs.star = function(c, s)
	c.poly({
		{ 0.5, 0.14 },
		{ 0.61, 0.4 },
		{ 0.88, 0.42 },
		{ 0.67, 0.59 },
		{ 0.74, 0.86 },
		{ 0.5, 0.7 },
		{ 0.26, 0.86 },
		{ 0.33, 0.59 },
		{ 0.12, 0.42 },
		{ 0.39, 0.4 },
	}, false, 0.085)
end

defs.sparkle = function(c, s)
	c.bar(0.5 * D, 0.14 * D, 0.5 * D, 0.5 * D, 0.09)
	c.bar(0.5 * D, 0.5 * D, 0.5 * D, 0.86 * D, 0.09)
	c.bar(0.14 * D, 0.5 * D, 0.5 * D, 0.5 * D, 0.09)
	c.bar(0.5 * D, 0.5 * D, 0.86 * D, 0.5 * D, 0.09)
	c.bar(0.26 * D, 0.26 * D, 0.38 * D, 0.38 * D, 0.07)
	c.bar(0.74 * D, 0.26 * D, 0.62 * D, 0.38 * D, 0.07)
end

defs.palette = function(c, s)
	c.arc(0.5, 0.52, 0.34, -30, 300, 0.1)
	c.dot(0.34, 0.36, 0.05)
	c.dot(0.56, 0.3, 0.05)
	c.dot(0.7, 0.46, 0.05)
	c.dot(0.66, 0.68, 0.05)
end

defs.terminal = function(c, s)
	c.squircle(0.5, 0.5, 0.72, 0.62, 0.1, 0.08, false)
	c.bar(0.28 * D, 0.38 * D, 0.44 * D, 0.5 * D, 0.08)
	c.bar(0.44 * D, 0.5 * D, 0.28 * D, 0.62 * D, 0.08)
	c.bar(0.5 * D, 0.62 * D, 0.66 * D, 0.62 * D, 0.08)
end

defs.cpu = function(c, s)
	c.squircle(0.5, 0.5, 0.44, 0.44, 0.08, 0.085, false)
	c.squircle(0.5, 0.5, 0.2, 0.2, 0.04, 0.07, false)
	for i = 1, 4 do
		local t = 0.3 + (i - 1) * 0.133
		c.bar(t * D, 0.14 * D, t * D, 0.28 * D, 0.06)
		c.bar(t * D, 0.72 * D, t * D, 0.86 * D, 0.06)
		c.bar(0.14 * D, t * D, 0.28 * D, t * D, 0.06)
		c.bar(0.72 * D, t * D, 0.86 * D, t * D, 0.06)
	end
end

defs.ram = function(c, s)
	c.squircle(0.5, 0.5, 0.76, 0.44, 0.07, 0.08, false)
	for i = 1, 5 do
		local x = 0.26 + (i - 1) * 0.12
		c.bar(x * D, 0.38 * D, x * D, 0.62 * D, 0.06)
	end
end

defs.globe = function(c, s)
	c.ring(0.5, 0.5, 0.36, 0.085)
	c.arc(0.5, 0.5, 0.16, 90, 180, 0.07)
	c.arc(0.5, 0.5, 0.16, 270, 180, 0.07)
	c.bar(0.14 * D, 0.5 * D, 0.86 * D, 0.5 * D, 0.07)
end

defs.user = function(c, s)
	c.ring(0.5, 0.36, 0.15, 0.09)
	c.arc(0.5, 0.86, 0.3, 180, 180, 0.09)
end

defs.users = function(c, s)
	c.ring(0.4, 0.36, 0.13, 0.085)
	c.arc(0.4, 0.82, 0.26, 180, 180, 0.085)
	c.ring(0.66, 0.32, 0.1, 0.07)
	c.arc(0.66, 0.66, 0.2, 180, 180, 0.07)
end

defs.power = function(c, s)
	c.arc(0.5, 0.54, 0.32, -124, 248, 0.09)
	c.bar(0.5 * D, 0.16 * D, 0.5 * D, 0.5 * D, 0.09)
end

defs.trash = function(c, s)
	c.bar(0.2 * D, 0.3 * D, 0.8 * D, 0.3 * D, 0.09)
	c.poly({ { 0.28, 0.3 }, { 0.32, 0.82 }, { 0.68, 0.82 }, { 0.72, 0.3 } }, false, 0.085)
	c.bar(0.38 * D, 0.42 * D, 0.41 * D, 0.7 * D, 0.06)
	c.bar(0.59 * D, 0.42 * D, 0.56 * D, 0.7 * D, 0.06)
	c.bar(0.4 * D, 0.18 * D, 0.6 * D, 0.18 * D, 0.07)
	c.bar(0.4 * D, 0.18 * D, 0.4 * D, 0.3 * D, 0.07)
	c.bar(0.6 * D, 0.18 * D, 0.6 * D, 0.3 * D, 0.07)
end

defs.copy = function(c, s)
	c.squircle(0.4, 0.4, 0.44, 0.48, 0.08, 0.08, false)
	c.squircle(0.6, 0.6, 0.44, 0.48, 0.08, 0.08, false)
end

defs.download = function(c, s)
	c.bar(0.5 * D, 0.16 * D, 0.5 * D, 0.62 * D, 0.09)
	c.bar(0.32 * D, 0.44 * D, 0.5 * D, 0.62 * D, 0.09)
	c.bar(0.68 * D, 0.44 * D, 0.5 * D, 0.62 * D, 0.09)
	c.poly({ { 0.22, 0.72 }, { 0.22, 0.84 }, { 0.78, 0.84 }, { 0.78, 0.72 } }, false, 0.09)
end

defs.upload = function(c, s)
	c.bar(0.5 * D, 0.62 * D, 0.5 * D, 0.16 * D, 0.09)
	c.bar(0.32 * D, 0.34 * D, 0.5 * D, 0.16 * D, 0.09)
	c.bar(0.68 * D, 0.34 * D, 0.5 * D, 0.16 * D, 0.09)
	c.poly({ { 0.22, 0.72 }, { 0.22, 0.84 }, { 0.78, 0.84 }, { 0.78, 0.72 } }, false, 0.09)
end

defs.refresh = function(c, s)
	c.arc(0.5, 0.5, 0.32, -40, 260, 0.09)
	c.bar(0.62 * D, 0.12 * D, 0.76 * D, 0.22 * D, 0.09)
	c.bar(0.76 * D, 0.22 * D, 0.7 * D, 0.09 * D, 0.09)
end

defs.panelLeft = function(c, s)
	c.squircle(0.5, 0.5, 0.76, 0.66, 0.09, 0.08, false)
	c.bar(0.36 * D, 0.17 * D, 0.36 * D, 0.83 * D, 0.075)
end

defs.panelRight = function(c, s)
	c.squircle(0.5, 0.5, 0.76, 0.66, 0.09, 0.08, false)
	c.bar(0.64 * D, 0.17 * D, 0.64 * D, 0.83 * D, 0.075)
end

defs.window = function(c, s)
	c.squircle(0.5, 0.52, 0.76, 0.64, 0.09, 0.08, false)
	c.bar(0.12 * D, 0.32 * D, 0.88 * D, 0.32 * D, 0.07)
	c.dot(0.2, 0.24, 0.035)
	c.dot(0.29, 0.24, 0.035)
	c.dot(0.38, 0.24, 0.035)
end

defs.grid = function(c, s)
	for i = 0, 1 do
		for j = 0, 1 do
			c.squircle(0.32 + i * 0.36, 0.32 + j * 0.36, 0.26, 0.26, 0.05, 0, true)
		end
	end
end

defs.list = function(c, s)
	for i = 0, 2 do
		local y = 0.28 + i * 0.22
		c.dot(0.24, y, 0.05)
		c.bar(0.38 * D, y * D, 0.82 * D, y * D, 0.07)
	end
end

defs.layers = function(c, s)
	c.poly({ { 0.5, 0.16 }, { 0.86, 0.36 }, { 0.5, 0.56 }, { 0.14, 0.36 } }, true, 0.08)
	c.poly({ { 0.14, 0.56 }, { 0.5, 0.76 }, { 0.86, 0.56 } }, false, 0.08)
	c.poly({ { 0.14, 0.72 }, { 0.5, 0.92 }, { 0.86, 0.72 } }, false, 0.08)
end

defs.chat = function(c, s)
	c.squircle(0.5, 0.44, 0.7, 0.5, 0.14, 0.08, false)
	c.poly({ { 0.34, 0.68 }, { 0.3, 0.86 }, { 0.52, 0.69 } }, false, 0.08)
end

defs.mail = function(c, s)
	c.squircle(0.5, 0.5, 0.74, 0.56, 0.07, 0.08, false)
	c.poly({ { 0.15, 0.26 }, { 0.5, 0.54 }, { 0.85, 0.26 } }, false, 0.08)
end

defs.calendar = function(c, s)
	c.squircle(0.5, 0.54, 0.68, 0.64, 0.08, 0.08, false)
	c.bar(0.16 * D, 0.4 * D, 0.84 * D, 0.4 * D, 0.075)
	c.bar(0.32 * D, 0.16 * D, 0.32 * D, 0.32 * D, 0.075)
	c.bar(0.68 * D, 0.16 * D, 0.68 * D, 0.32 * D, 0.075)
	c.dot(0.36, 0.58, 0.05)
	c.dot(0.5, 0.58, 0.05)
	c.dot(0.64, 0.58, 0.05)
	c.dot(0.36, 0.74, 0.05)
	c.dot(0.5, 0.74, 0.05)
end

defs.clock = function(c, s)
	c.ring(0.5, 0.5, 0.36, 0.085)
	c.bar(0.5 * D, 0.5 * D, 0.5 * D, 0.28 * D, 0.08)
	c.bar(0.5 * D, 0.5 * D, 0.66 * D, 0.58 * D, 0.08)
end

defs.gamepad = function(c, s)
	c.squircle(0.5, 0.5, 0.78, 0.5, 0.16, 0.08, false)
	c.bar(0.28 * D, 0.5 * D, 0.4 * D, 0.5 * D, 0.075)
	c.bar(0.34 * D, 0.44 * D, 0.34 * D, 0.56 * D, 0.075)
	c.dot(0.62, 0.44, 0.045)
	c.dot(0.72, 0.54, 0.045)
end

defs.shield = function(c, s)
	c.poly({ { 0.5, 0.14 }, { 0.8, 0.26 }, { 0.8, 0.52 }, { 0.5, 0.86 }, { 0.2, 0.52 }, { 0.2, 0.26 } }, true, 0.085)
	c.bar(0.38 * D, 0.48 * D, 0.48 * D, 0.6 * D, 0.075)
	c.bar(0.48 * D, 0.6 * D, 0.64 * D, 0.38 * D, 0.075)
end

defs.wand = function(c, s)
	c.bar(0.2 * D, 0.8 * D, 0.66 * D, 0.34 * D, 0.09)
	c.dot(0.74, 0.2, 0.06)
	c.dot(0.58, 0.14, 0.035)
	c.dot(0.84, 0.4, 0.04)
end

defs.pin = function(c, s)
	c.poly({ { 0.5, 0.16 }, { 0.66, 0.42 }, { 0.5, 0.68 }, { 0.34, 0.42 } }, true, 0.08)
	c.bar(0.5 * D, 0.68 * D, 0.5 * D, 0.86 * D, 0.08)
end

defs.eyeoff = function(c, s)
	c.arc(0.5, 0.62, 0.42, -148, 96, 0.08)
	c.arc(0.5, 0.38, 0.42, 52, 96, 0.08)
	c.bar(0.18 * D, 0.82 * D, 0.82 * D, 0.18 * D, 0.08)
end

defs.chevronRight = function(c, s)
	c.bar(0.4 * D, 0.22 * D, 0.66 * D, 0.5 * D, 0.1)
	c.bar(0.66 * D, 0.5 * D, 0.4 * D, 0.78 * D, 0.1)
end

defs.chevronDown = function(c, s)
	c.bar(0.22 * D, 0.4 * D, 0.5 * D, 0.66 * D, 0.1)
	c.bar(0.5 * D, 0.66 * D, 0.78 * D, 0.4 * D, 0.1)
end

defs.chevronUp = function(c, s)
	c.bar(0.22 * D, 0.6 * D, 0.5 * D, 0.34 * D, 0.1)
	c.bar(0.5 * D, 0.34 * D, 0.78 * D, 0.6 * D, 0.1)
end

defs.chevronLeft = function(c, s)
	c.bar(0.6 * D, 0.22 * D, 0.34 * D, 0.5 * D, 0.1)
	c.bar(0.34 * D, 0.5 * D, 0.6 * D, 0.78 * D, 0.1)
end

defs.arrowUp = function(c, s)
	c.bar(0.5 * D, 0.78 * D, 0.5 * D, 0.22 * D, 0.09)
	c.bar(0.28 * D, 0.42 * D, 0.5 * D, 0.2 * D, 0.09)
	c.bar(0.72 * D, 0.42 * D, 0.5 * D, 0.2 * D, 0.09)
end

defs.arrowDown = function(c, s)
	c.bar(0.5 * D, 0.22 * D, 0.5 * D, 0.78 * D, 0.09)
	c.bar(0.28 * D, 0.58 * D, 0.5 * D, 0.8 * D, 0.09)
	c.bar(0.72 * D, 0.58 * D, 0.5 * D, 0.8 * D, 0.09)
end

defs.keyboard = function(c, s)
	c.squircle(0.5, 0.5, 0.82, 0.52, 0.09, 0.075, false)
	for row = 0, 1 do
		for col = 0, 4 do
			c.dot(0.26 + col * 0.12, 0.4 + row * 0.16, 0.028)
		end
	end
	c.bar(0.38 * D, 0.68 * D, 0.62 * D, 0.68 * D, 0.055)
end

defs.dock = function(c, s)
	c.squircle(0.5, 0.78, 0.78, 0.24, 0.09, 0.075, false)
	c.dot(0.3, 0.78, 0.05)
	c.dot(0.5, 0.78, 0.05)
	c.dot(0.7, 0.78, 0.05)
end

defs.cmd = function(c, s)
	c.poly({ { 0.3, 0.3 }, { 0.3, 0.7 }, { 0.7, 0.7 }, { 0.7, 0.3 } }, false, 0.09)
	c.bar(0.3 * D, 0.3 * D, 0.2 * D, 0.2 * D, 0.09)
	c.bar(0.7 * D, 0.3 * D, 0.8 * D, 0.2 * D, 0.09)
	c.bar(0.7 * D, 0.7 * D, 0.8 * D, 0.8 * D, 0.09)
	c.bar(0.3 * D, 0.7 * D, 0.2 * D, 0.8 * D, 0.09)
end

defs.info = function(c, s)
	c.ring(0.5, 0.5, 0.36, 0.085)
	c.dot(0.5, 0.3, 0.05)
	c.bar(0.5 * D, 0.44 * D, 0.5 * D, 0.72 * D, 0.09)
end

defs.warning = function(c, s)
	c.poly({ { 0.5, 0.14 }, { 0.88, 0.8 }, { 0.12, 0.8 } }, true, 0.085)
	c.bar(0.5 * D, 0.38 * D, 0.5 * D, 0.58 * D, 0.08)
	c.dot(0.5, 0.69, 0.045)
end

defs.cast = function(c, s)
	c.bar(0.16 * D, 0.82 * D, 0.16 * D, 0.74 * D, 0.09)
	c.arc(0.16, 0.74, 0.24, -90, 90, 0.085)
	c.arc(0.16, 0.74, 0.44, -90, 90, 0.085)
	c.squircle(0.62, 0.36, 0.56, 0.42, 0.08, 0.08, false)
end

defs.airplay = defs.cast

defs.castIcon = defs.cast

Nocturne.IconKit = IconKit

function IconKit.define(name, fn)
	IconKit._defs[name] = fn
end

-- Attach an icon; returns a handle with setColor for live theming.
function IconKit.attach(parent, name, opts)
	opts = opts or {}
	local def = IconKit._defs[name]
	if def == nil then
		if DebugFlags.verbose then
			logWarn("unknown icon:", name)
		end
		def = IconKit._defs.close
	end
	local size = (opts.size or 18) * (opts.unscaled and 1 or Config.accessibility.largerText)
	local container = create("Frame", {
		Name = "Icon_" .. name,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size),
		ZIndex = opts.zIndex or 5,
		Parent = parent,
	})
	container._s = size
	local colorables = {}
	local ctx = makeContext(container, colorables)
	local ok, err = pcall(def, ctx, size)
	if not ok and DebugFlags.verbose then
		logWarn(("icon %s failed: %s"):format(name, tostring(err)))
	end
	local handle = {
		frame = container,
		_colorables = colorables,
		_name = name,
		_size = size,
	}
	local baseColor = opts.color or Theme.tokens().text
	local function apply(col, trans)
		for _, c in colorables do
			if c:IsA("UIStroke") then
				c.Color = col
				c.Transparency = trans
			else
				c.BackgroundColor3 = col
				c.BackgroundTransparency = trans
			end
		end
	end
	handle.setColor = function(col, trans)
		apply(col or baseColor, trans or 0)
	end
	handle.setTransparency = function(trans)
		for _, c in colorables do
			if c:IsA("UIStroke") then
				c.Transparency = trans
			else
				c.BackgroundTransparency = trans
			end
		end
	end
	handle.destroy = function()
		pcall(container.Destroy, container)
	end
	if opts.subscribeToTheme ~= false then
		local tokens0 = Theme.tokens()
		local col = opts.color
			or (opts.emphasis and tokens0.accent or Color.mix(tokens0.text, tokens0.dim, opts.dim or 0))
		handle.setColor(col, opts.transparency or 0.06)
		if opts.color == nil then
			local unsub = Theme.register(function(t)
				apply(opts.emphasis and t.accent or Color.mix(t.text, t.dim, opts.dim or 0), opts.transparency or 0.06)
			end)
			handle._unsub = unsub
		end
	else
		handle.setColor(baseColor, opts.transparency)
	end
	local okDestroying, destroyingSignal = pcall(function()
		return container.Destroying
	end)
	if okDestroying and destroyingSignal then
		destroyingSignal:Connect(function()
			if handle._unsub then
				handle._unsub()
			end
		end)
	end
	IconKit._created += 1
	return handle
end

function IconKit.list()
	return T.keys(IconKit._defs)
end

function IconKit.has(name)
	return IconKit._defs[name] ~= nil
end
--═══════════════════════════════════════════════════════════════════════════════--
-- § 10a  PROCEDURAL SFX
--
-- Interface sounds with zero assets: a tiny synth streamed through the engine's
-- AudioPlayer API. If the client lacks it (or the place forbids the feature),
-- everything degrades to silence and nobody notices. Each cue contributes a note
-- object { age, life, fn }; the Started callback mixes the active notes into the
-- next Float32Array buffer at the sample rate.
--═══════════════════════════════════════════════════════════════════════════════--

local Sfx = {
	ready = false,
	enabled = true,
	player = nil,
	queue = {},
	master = 0.34,
	fails = 0,
}
Nocturne.Sfx = Sfx

local cues = {}

local function tone(freq, dur, vol, sweep, timbre)
	-- A short percussive blip; sweep is a frequency multiplier over life.
	local note = { age = 0, life = dur, fn = nil }
	note.fn = function(t)
		local x = t / dur
		local f = freq * (1 + (sweep or 0) * x)
		local wave = math.sin(2 * math.pi * f * t)
		if timbre == "tri" then
			wave = 2 / math.pi * math.asin(math.sin(2 * math.pi * f * t))
		elseif timbre == "soft" then
			wave = wave * (0.6 + 0.4 * math.sin(4 * math.pi * f * t))
		end
		local env = (1 - x) ^ 2.4 * math.min(1, x * 60)
		return wave * env * vol
	end
	return note
end

local function noiseBurst(dur, vol, decayPow)
	local note = { age = 0, life = dur, fn = nil }
	note.fn = function(t)
		local x = t / dur
		return Math.randomRange(-1, 1) * (1 - x) ^ (decayPow or 6) * vol
	end
	return note
end

local function queue(...)
	for _, note in { ... } do
		table.insert(Sfx.queue, note)
	end
end

cues.tap = function()
	queue(tone(880, 0.05, 0.5, -0.35, "soft"))
end
cues.click = function()
	queue(tone(640, 0.055, 0.62, -0.3), noiseBurst(0.018, 0.14))
end
cues.tick = function()
	queue(tone(1320, 0.03, 0.28, -0.2, "tri"))
end
cues.hover = function()
	queue(tone(1560, 0.032, 0.1, 0.06, "soft"))
end
cues.toggleOn = function()
	queue(tone(520, 0.07, 0.5, 0.55, "tri"), tone(1040, 0.09, 0.22, 0.35, "soft"))
end
cues.toggleOff = function()
	queue(tone(700, 0.07, 0.42, -0.5, "tri"))
end
local function rngSlide()
	return Math.randomRange(-0.5, 0.5)
end
cues.slide = function()
	queue(tone(400 + rngSlide() * 200, 0.04, 0.2, 0.1, "soft"))
end
cues.swipe = function()
	queue(noiseBurst(0.09, 0.2, 3), tone(240, 0.12, 0.3, 1.2, "soft"))
end
cues.windowOpen = function()
	queue(tone(180, 0.16, 0.5, 1.6, "soft"), tone(360, 0.2, 0.25, 0.8, "tri"))
end
cues.windowClose = function()
	queue(tone(360, 0.14, 0.45, -0.75, "soft"), noiseBurst(0.04, 0.1))
end
cues.notify = function()
	queue(tone(784, 0.09, 0.4, 0, "tri"), tone(1047, 0.16, 0.35, 0, "soft"))
end
cues.error = function()
	queue(tone(196, 0.18, 0.5, -0.12, "tri"), tone(185, 0.22, 0.4, -0.1, "tri"))
end
cues.boot = function()
	queue(tone(110, 0.6, 0.4, 0.9, "soft"), tone(220, 0.5, 0.3, 0.5, "soft"))
end
cues.lock = function()
	queue(tone(494, 0.1, 0.4, -0.2, "tri"), tone(370, 0.16, 0.35, -0.2, "tri"))
end
cues.cheat = function()
	queue(
		tone(523, 0.16, 0.35, 0, "tri"),
		tone(659, 0.16, 0.32, 0, "tri"),
		tone(784, 0.18, 0.3, 0, "tri"),
		tone(1047, 0.28, 0.3, 0, "tri")
	)
end

function Sfx.play(name)
	if not Sfx.enabled or not Config.motion.enableSounds or State.hidden then
		return
	end
	if State.reduceMotion and (name == "hover" or name == "tick") then
		return
	end
	Sfx.master = Config.motion.soundVolume
	local cue = cues[name]
	if cue then
		cue()
	end
end

-- Mix the note stack into `buffer` for `sampleCount` frames; advances ages.
local function render(buffer, sampleCount, sampleDt)
	local notes = Sfx.queue
	local i = #notes
	while i > 0 do
		if notes[i].life + 0.02 < notes[i].age then
			table.remove(notes, i)
		end
		i -= 1
	end
	local n = #notes
	if n == 0 then
		return false
	end
	for s = 0, sampleCount - 1 do
		local acc = 0
		for j = 1, n do
			local note = notes[j]
			local t = note.age + s * sampleDt
			if t <= note.life then
				acc += note.fn(t)
			end
		end
		buffer[s] = math.max(-1, math.min(1, acc * Sfx.master))
	end
	for j = 1, n do
		notes[j].age += sampleCount * sampleDt
	end
	return true
end

local function startSynth()
	local ok = pcall(function()
		local player = Instance.new("AudioPlayer")
		player.Name = "NocturneSfx"
		player.SampleRate = 48000
		player.Volume = 0.85
		pcall(function()
			player.BufferedArraysLength = 2
		end)
		player.Parent = SoundService
		Sfx.player = player
		local sampleDt = 1 / 48000
		local buffer = Float32Array.new(768)
		player.Started:Connect(function()
			local produced = render(buffer, 768, sampleDt)
			if not produced then
				for i = 0, 767 do
					buffer[i] = 0
				end
			end
			player:PopulateNextBuffer(buffer)
		end)
		player:Resume()
		Sfx.ready = true
	end)
	if not ok then
		-- Older or restricted clients: stay silent, stay perfect.
		Sfx.enabled = false
		Sfx.ready = false
		if DebugFlags.verbose then
			logInfo("procedural sfx unavailable on this client; running silent")
		end
	end
end

-- Boot the synth lazily: nobody wants AudioPlayer churn during scene load.
task.delay(1.5, function()
	if Config.motion.enableSounds and Capabilities.soundFx then
		startSynth()
	end
end)

--═══════════════════════════════════════════════════════════════════════════════--
-- § 10b  APP SHELL + FONTS
--
-- App owns the ScreenGui and the layer frames everything renders into. Widgets
-- below and systems above all resolve `App.*` at call time, so load order
-- between this chunk and the bootstrap does not matter.
--═══════════════════════════════════════════════════════════════════════════════--

local App = {
	rootGui = nil,
	layers = nil,
	ready = false,
}
Nocturne.App = App

local FONT_CACHE = {}
local function fontBy(weight)
	local cached = FONT_CACHE[weight]
	if cached then
		return cached
	end
	local candidates = {
		regular = { "Gotham", "Bodegas", "SourceSans" },
		medium = { "GothamMedium", "Gotham", "Bodegas" },
		bold = { "GothamBold", "Gotham", "Bodegas" },
		black = { "GothamBlack", "GothamBold", "Gotham" },
		mono = { "Code", "SourceSans", "Gotham" },
		display = { "GothamBlack", "ArialBlack", "Gotham" },
		number = { "GothamBold", "Gotham", "Arial" },
	}
	local chosen = Enum.Font.Gotham
	for _, name in candidates[weight] or candidates.regular do
		local found = pcall(function()
			chosen = Enum.Font[name]
		end)
		if found then
			break
		end
	end
	FONT_CACHE[weight] = chosen
	return chosen
end
App.fontBy = fontBy

function App.init()
	if App.ready then
		return App
	end
	local gui = create("ScreenGui", {
		Name = "Nocturne",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 900,
	})
	adopt(gui, PlayerGui)
	App.rootGui = gui
	register("frames", gui)

	local makeLayer = function(name, order)
		local layer = create("Frame", {
			Name = name,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = order * 10,
			Parent = gui,
		})
		return layer
	end
	App.layers = {
		wallpaper = makeLayer("Wallpaper", 1),
		desktop = makeLayer("Desktop", 2),
		windows = makeLayer("Windows", 3),
		chrome = makeLayer("Chrome", 4),
		overlay = makeLayer("Overlay", 5),
		toast = makeLayer("Toast", 6),
	}

	-- Mobile probe for layout heuristics; touch alone also implies phone-ish UI.
	State.mobile = Capabilities.touch and not UserInputService.KeyboardEnabled
	State.tablet = Capabilities.touch and UserInputService.KeyboardEnabled and Capabilities.touch

	App.ready = true
	logInfo("app shell ready")
	return App
end

--═══════════════════════════════════════════════════════════════════════════════--
-- § 11a  WIDGETS — LABELS, BUTTONS, ICONS
--═══════════════════════════════════════════════════════════════════════════════--

local W = {}
Nocturne.Widgets = W

-- A themed text label with the defaults every other widget borrows.
function W.label(parent, opts)
	opts = opts or {}
	local alignMap =
		{ Left = Enum.TextXAlignment.Left, Center = Enum.TextXAlignment.Center, Right = Enum.TextXAlignment.Right }
	local alignX = opts.alignX or (opts.align and alignMap[opts.align]) or Enum.TextXAlignment.Left
	local label = create("TextLabel", {
		Name = opts.name or "Label",
		BackgroundTransparency = 1,
		Text = opts.text or "",
		Font = fontBy(opts.weight or (opts.bold and "bold" or "regular")),
		TextSize = (opts.size or 15) * Config.accessibility.largerText,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextXAlignment = alignX,
		TextYAlignment = opts.alignY or Enum.TextYAlignment.Center,
		TextWrapped = opts.wrapped or false,
		TextTruncate = opts.truncate and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None,
		RichText = opts.rich or false,
		Size = opts.size2 and UDim2.fromOffset(opts.size2[1], opts.size2[2]) or UDim2.fromScale(1, 1),
		Position = opts.position or UDim2.fromScale(0, 0),
		AnchorPoint = opts.anchor or Vector2.new(0, 0.5),
		ZIndex = opts.zIndex or 20,
		Parent = parent,
	})
	local function paint(tokens)
		local col = tokens.text
		local wanted = opts.color
		if wanted == "dim" then
			col = tokens.dim
		elseif wanted == "faint" then
			col = tokens.faint
		elseif wanted == "accent" then
			col = tokens.accent
		elseif wanted == "danger" then
			col = tokens.danger
		elseif wanted == "success" then
			col = tokens.success
		elseif wanted == "warning" then
			col = tokens.warning
		elseif type(wanted) == "string" and wanted:sub(1, 1) == "#" then
			col = Color.fromHex(wanted)
		elseif typeof(wanted) == "Color3" then
			col = wanted
		end
		label.TextColor3 = col
	end
	Theme.register(paint)
	return label
end

function W.sectionLabel(parent, text, opts)
	opts = opts or {}
	return W.label(parent, {
		text = opts.raw and text or Str.spaced((text or ""):upper()),
		size = 9.5,
		weight = "black",
		color = "faint",
		position = opts.position,
		size2 = opts.size2,
		anchor = opts.anchor,
	})
end

-- Button ------------------------------------------------------------------------
-- Variants: primary (solid accent), glass (clear sheet), tint (accent wash),
-- danger/success (semantic wash), ghost (text only), bordered (rim only).
function W.button(parent, opts)
	opts = opts or {}
	local variant = opts.variant or "glass"
	local height = opts.height or (opts.size == "sm" and Config.layout.smallButtonHeight or Config.layout.buttonHeight)

	local holder = create("Frame", {
		Name = opts.name or "Button",
		BackgroundTransparency = 1,
		Position = opts.position,
		AnchorPoint = opts.anchor or Vector2.new(0, 0),
		ZIndex = opts.zIndex or 20,
		Size = opts.fill and UDim2.new(1, 0, 0, height) or UDim2.fromOffset(opts.widthPx or 130, height),
		Parent = parent,
	})
	local uiScale = create("UIScale", { Scale = 1, Parent = holder })

	local body = create(Capabilities.canvasGroup and "CanvasGroup" or "Frame", {
		Name = "Body",
		BackgroundColor3 = Color3.fromRGB(30, 34, 42),
		BackgroundTransparency = 0.4,
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		ZIndex = holder.ZIndex,
		Parent = holder,
	})
	local roundness = opts.roundness or (opts.capsule and height / 2 or 14)
	create("UICorner", { CornerRadius = UDim.new(0, roundness), Parent = body })
	local stroke = create("UIStroke", {
		Transparency = 0.75,
		Thickness = 1.1,
		Color = Color3.fromRGB(255, 255, 255),
		Parent = body,
	})
	create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 0.35),
		}),
		Parent = body,
	})
	local sheen = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0.5, 0),
		ZIndex = body.ZIndex + 1,
		Parent = body,
	})
	create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.68),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = sheen,
	})

	local clickArea = create("TextButton", {
		Name = "Click",
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		ZIndex = body.ZIndex + 3,
		Parent = body,
	})

	local iconHandle = nil
	local textOffset = 0
	if opts.icon then
		iconHandle = IconKit.attach(body, opts.icon, {
			size = opts.iconSize or 15,
		})
		iconHandle.frame.AnchorPoint = Vector2.new(0, 0.5)
		iconHandle.frame.Position = UDim2.new(0, opts.iconPad or 13, 0.5, 0)
		iconHandle.frame.ZIndex = body.ZIndex + 4
		textOffset = (opts.iconSize or 15) + (opts.iconPad or 13) + 8
	end

	local caption = create("TextLabel", {
		Name = "Caption",
		BackgroundTransparency = 1,
		Text = opts.label or "Button",
		Font = fontBy(opts.bold and "bold" or "medium"),
		TextSize = (opts.size == "sm" and 12.5 or 14) * Config.accessibility.largerText,
		TextTruncate = Enum.TextTruncate.AtEnd,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, -textOffset - 12, 1, 0),
		Position = UDim2.new(0, textOffset, 0, 0),
		ZIndex = body.ZIndex + 4,
		Parent = body,
	})
	if opts.icon and not opts.leftText then
		caption.Position = UDim2.new(0, (textOffset - 12) * 0.5, 0, 0)
	end

	local state = {
		disabled = opts.disabled or false,
		holder = holder,
		body = body,
		stroke = stroke,
		caption = caption,
		icon = iconHandle,
		variant = variant,
		uiScale = uiScale,
	}

	local function paint(tokens)
		local bgT, col, strokeT, strokeC
		if variant == "primary" then
			bgT = 0.14
			col = tokens.light and tokens.text or tokens.accentInk
			strokeC = Color.addWhite(tokens.accent, 0.2)
			strokeT = 0.35
			body.BackgroundColor3 = tokens.accent
		elseif variant == "tint" then
			bgT = 0.72
			col = tokens.accent
			body.BackgroundColor3 = tokens.accentSoft
			strokeC = tokens.accent
			strokeT = 0.55
		elseif variant == "danger" then
			bgT = 0.68
			col = Color3.fromRGB(255, 255, 255)
			body.BackgroundColor3 = tokens.danger
			strokeC = tokens.danger
			strokeT = 0.45
		elseif variant == "success" then
			bgT = 0.68
			col = tokens.surfaceDeep
			body.BackgroundColor3 = tokens.success
			strokeC = tokens.success
			strokeT = 0.45
		elseif variant == "ghost" then
			bgT = 1
			col = tokens.dim
			body.BackgroundColor3 = tokens.surfaceBright
			strokeC = tokens.hairline
			strokeT = 1
		elseif variant == "bordered" then
			bgT = 0.96
			col = tokens.text
			body.BackgroundColor3 = tokens.surface
			strokeC = tokens.hairline
			strokeT = 0.4
		else -- glass
			bgT = 0.66
			col = tokens.text
			body.BackgroundColor3 = tokens.surfaceBright
			strokeC = tokens.hairline
			strokeT = 0.62
		end
		if state.disabled then
			col = tokens.faint
			bgT = math.min(0.97, bgT + 0.2)
			strokeT = 0.92
		end
		body.BackgroundTransparency = bgT
		caption.TextColor3 = col
		if iconHandle then
			iconHandle.setColor(
				variant == "primary" and col or (state.disabled and tokens.faint or (opts.iconColor or tokens.accent)),
				state.disabled and 0.55 or 0.05
			)
		end
		stroke.Color = strokeC or tokens.hairline
		stroke.Transparency = strokeT or 0.6
	end
	local unsubTheme = Theme.register(paint)

	-- One scale spring for hover + press states, driven only while it moves.
	local scaleSpring = Spring.new(1, Config.motion.springQuick)
	local job
	local function ensure()
		if job then
			return
		end
		job = Scheduler.schedule(function(dt)
			local rest = scaleSpring:step(dt)
			uiScale.Scale = math.max(0.5, scaleSpring._position)
			if rest then
				Scheduler.unschedule(job)
				job = nil
			end
		end, { name = "btnScale", rate = "frame", priority = 1 })
	end
	state.ensureMotion = ensure
	state.scaleSpring = scaleSpring

	clickArea.MouseEnter:Connect(function()
		if state.disabled then
			return
		end
		scaleSpring:setTarget(Config.motion.hoverScale)
		ensure()
		Sfx.play("hover")
	end)
	clickArea.MouseLeave:Connect(function()
		scaleSpring:setTarget(1)
		ensure()
	end)
	clickArea.InputBegan:Connect(function(input)
		if state.disabled then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			scaleSpring:setTarget(Config.motion.pressScale)
			ensure()
			Glass.ripple(body, input.Position.X - body.AbsolutePosition.X, input.Position.Y - body.AbsolutePosition.Y, {
				color = variant == "primary" and Color3.fromRGB(255, 255, 255) or nil,
			})
			Sfx.play("click")
		end
	end)
	clickArea.InputEnded:Connect(function(input)
		if state.disabled then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			scaleSpring:setTarget(1)
			ensure()
			local inside = Math.pointInRect(
				input.Position.X,
				input.Position.Y,
				body.AbsolutePosition.X,
				body.AbsolutePosition.Y,
				body.AbsoluteSize.X,
				body.AbsoluteSize.Y
			)
			if inside and opts.onClicked then
				task.spawn(function()
					local ok, err = pcall(opts.onClicked, state)
					if not ok then
						logWarn("button handler:", err)
					end
				end)
			end
		end
	end)
	clickArea.MouseButton2Click:Connect(function()
		if opts.onContext then
			opts.onContext()
		end
	end)

	function state:setDisabled(b)
		state.disabled = b
		paint(Theme.tokens())
	end

	function state:setLabel(text)
		caption.Text = text
	end

	function state:setIcon(name)
		if iconHandle then
			iconHandle.destroy()
			iconHandle = nil
		end
		if name then
			iconHandle = IconKit.attach(body, name, { size = opts.iconSize or 15 })
			iconHandle.frame.AnchorPoint = Vector2.new(0, 0.5)
			iconHandle.frame.Position = UDim2.new(0, opts.iconPad or 13, 0.5, 0)
			iconHandle.frame.ZIndex = body.ZIndex + 4
			state.icon = iconHandle
			paint(Theme.tokens())
		end
	end

	function state:flash(colorOverride, dur)
		local token = (state._flashToken or 0) + 1
		state._flashToken = token
		task.spawn(function()
			local oldBg = body.BackgroundColor3
			body.BackgroundColor3 = colorOverride or Theme.tokens().accent
			task.wait(dur or 0.12)
			if state._flashToken == token then
				body.BackgroundColor3 = oldBg
				paint(Theme.tokens())
			end
		end)
	end

	function state:destroy()
		if unsubTheme then
			unsubTheme()
		end
		pcall(holder.Destroy, holder)
	end

	-- Entrance stagger hook used by demo screens.
	if opts.reveal then
		scaleSpring:set(0.8)
		task.delay(opts.revealDelay or 0, function()
			scaleSpring:setTarget(1)
			ensure()
		end)
	end

	return state
end

-- Icon-only button: title bars, tool rows, dock extras.
function W.iconButton(parent, opts)
	opts = opts or {}
	local size = opts.size or 30
	local btn = W.button(parent, {
		name = "IconButton",
		label = "",
		icon = opts.icon,
		iconSize = opts.iconSize or size * 0.5,
		iconPad = (size - (opts.iconSize or size * 0.5)) / 2,
		variant = opts.variant or "ghost",
		fill = opts.fill,
		widthPx = opts.widthPx or size,
		height = opts.height or size,
		position = opts.position,
		anchor = opts.anchor,
		zIndex = opts.zIndex,
		roundness = opts.roundness or size * 0.32,
		onClicked = opts.onClicked,
		disabled = opts.disabled,
	})
	btn.caption.TextTransparency = 1
	local clickArea = btn.body:FindFirstChild("Click")
	if btn.icon then
		btn.icon.frame.AnchorPoint = Vector2.new(0.5, 0.5)
		btn.icon.frame.Position = UDim2.fromScale(0.5, 0.5)
	end
	return btn
end

-- Badge ------------------------------------------------------------------------
function W.badge(parent, opts)
	opts = opts or {}
	local frame = create("Frame", {
		Name = "Badge",
		BackgroundColor3 = Color3.fromRGB(60, 70, 90),
		BackgroundTransparency = 0.55,
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		ZIndex = opts.zIndex or 25,
		Parent = parent,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = frame })
	create("UIStroke", { Transparency = 0.72, Thickness = 0.8, Parent = frame })
	create("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = frame,
	})
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Text = opts.text or "•",
		Font = fontBy("bold"),
		TextSize = (opts.size or 9.5) * Config.accessibility.largerText,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromScale(0, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 26,
		Parent = frame,
	})
	local unsub = Theme.register(function(t)
		local bg, fg = t.accent, t.accentInk
		local kind = opts.kind or "accent"
		if kind == "success" then
			bg, fg = t.success, Color3.fromRGB(6, 20, 12)
		elseif kind == "warning" then
			bg, fg = t.warning, t.surfaceDeep
		elseif kind == "danger" then
			bg, fg = t.danger, Color3.fromRGB(255, 255, 255)
		elseif kind == "muted" then
			bg, fg = t.surfaceBright, t.dim
		end
		frame.BackgroundColor3 = bg
		label.TextColor3 = fg
		label.Text = opts.text or label.Text
	end)
	frame.Destroying:Connect(function()
		unsub()
	end)
	return { frame = frame, label = label }
end

-- Keycap ------------------------------------------------------------------------
function W.keycap(parent, text, opts)
	opts = opts or {}
	local cap = create("Frame", {
		Name = "Keycap",
		BackgroundColor3 = Color3.fromRGB(50, 56, 70),
		BackgroundTransparency = 0.45,
		Size = UDim2.fromOffset(opts.width or 22, opts.height or 20),
		ZIndex = opts.zIndex or 30,
		Parent = parent,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = cap })
	create("UIStroke", { Transparency = 0.55, Thickness = 0.9, Parent = cap })
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		Text = text or "cmd",
		Font = fontBy("bold"),
		TextSize = (opts.size or 11) * Config.accessibility.largerText,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 31,
		Parent = cap,
	})
	local unsub = Theme.register(function(t)
		cap.BackgroundColor3 = t.surfaceBright
		cap.BackgroundTransparency = 0.35
		label.TextColor3 = t.dim
	end)
	cap.Destroying:Connect(function()
		unsub()
	end)
	return cap
end

-- Divider ------------------------------------------------------------------------
function W.divider(parent, opts)
	opts = opts or {}
	local line = create("Frame", {
		Name = "Divider",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9,
		ZIndex = opts.zIndex or 12,
		Parent = parent,
	})
	if opts.vertical then
		line.Size = UDim2.new(0, 1, 1, -12)
		line.Position = UDim2.new(0, 0, 0, 6)
	else
		line.Size = UDim2.new(1, -16, 0, 1)
		line.Position = UDim2.new(0, 8, 0, 0)
	end
	local unsub = Theme.register(function(t)
		line.BackgroundColor3 = t.hairline
		line.BackgroundTransparency = 1 - t.hairlineOpacity
	end)
	line.Destroying:Connect(function()
		unsub()
	end)
	return line
end

-- Tooltip: one shared bubble for the whole app. Widgets call Tooltip.attach(instance, text)
-- during construction and nothing else.
local Tooltip = { bubble = nil, current = nil, hideAt = 0 }
Nocturne.Tooltip = Tooltip

function Tooltip.ensure()
	if Tooltip.bubble then
		return Tooltip.bubble
	end
	local layer = App.layers and App.layers.overlay
	if not layer then
		return nil
	end
	local surf = Glass.new(layer, {
		name = "Tooltip",
		size = UDim2.fromOffset(120, 30),
		roundness = 9,
		tint = 0.5,
		shadow = true,
		caustics = false,
		interactive = false,
	})
	local text = W.label(
		surf.content,
		{ text = "", size = 12, weight = "medium", anchor = Vector2.new(0, 0.5), position = UDim2.new(0, 10, 0.5, 0) }
	)
	Tooltip.bubble = { surface = surf, text = text }
	surf.root.Visible = false
	return Tooltip.bubble
end

function Tooltip.attach(instance, text, align)
	if not instance then
		return
	end
	local comp = CompositeConnection.new()
	local delayTask = nil
	comp:Add(instance.MouseEnter:Connect(function()
		delayTask = task.delay(0.45, function()
			local bubble = Tooltip.ensure()
			if not bubble then
				return
			end
			bubble.text.Text = text
			-- Measure then size the bubble to content.
			local tx = bubble.text
			local abs = instance.AbsoluteSize
			local pos = instance.AbsolutePosition
			local width = 24 + #text * 7
			bubble.surface.root.Size = UDim2.fromOffset(width, 28)
			local x = pos.X + abs.X / 2 - width / 2
			local y = pos.Y - 36
			if align == "below" then
				y = pos.Y + abs.Y + 8
			end
			local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
			x = Math.clamp(x, 6, vp.X - width - 6)
			bubble.surface.root.Position = UDim2.fromOffset(x, y)
			bubble.surface.root.Visible = true
			bubble.surface.litSpring:set(1)
			Tooltip.current = instance
		end)
	end))
	comp:Add(instance.MouseLeave:Connect(function()
		if delayTask then
			task.cancel(delayTask)
			delayTask = nil
		end
		local bubble = Tooltip.bubble
		if bubble and Tooltip.current == instance then
			bubble.surface.root.Visible = false
			Tooltip.current = nil
		end
	end))
	instance.Destroying:Connect(function()
		comp:Destroy()
	end)
	return comp
end
--────────────────────────────────────────────────────────────────────────────────
-- Controls: the switches, sliders and fields. Each returns a state table with
-- get/set so the settings app can treat them uniformly, and each one is a pure
-- placeholder: state lives in the UI and nowhere else.
--────────────────────────────────────────────────────────────────────────────────

-- iOS switch: capsule track, liquid knob, colour flows in from the left.
function W.switch(parent, opts)
	opts = opts or {}
	local w = opts.width or 46
	local h = opts.height or 27
	local track = create("Frame", {
		Name = "Switch",
		BackgroundColor3 = Color3.fromRGB(42, 47, 58),
		BackgroundTransparency = 0.35,
		Size = UDim2.fromOffset(w, h),
		Position = opts.position,
		AnchorPoint = opts.anchor or Vector2.new(0, 0.5),
		ZIndex = opts.zIndex or 21,
		Parent = parent,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })
	local stroke = create("UIStroke", { Transparency = 0.62, Thickness = 1, Parent = track })
	local fill = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
		ZIndex = track.ZIndex + 1,
		Parent = track,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
	local knob = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(250, 251, 253),
		Size = UDim2.fromOffset(h - 6, h - 6),
		Position = UDim2.new(0, 3, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ZIndex = track.ZIndex + 2,
		Parent = track,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
	local knobShadow =
		create("UIStroke", { Color = Color3.fromRGB(0, 0, 0), Transparency = 0.62, Thickness = 1.6, Parent = knob })

	local pos = Spring.new(opts.value and 1 or 0, Config.motion.springBouncy, { precision = 0.002 })
	local squish = Spring.new(1, Config.motion.springQuick)
	local job
	local function drive()
		if job then
			return
		end
		job = Scheduler.schedule(function(dt)
			local a = pos:step(dt)
			local b = squish:step(dt)
			local p = pos._position
			local s = squish._position
			knob.Position = UDim2.new(p, (3 - p * 6) + p * (w - h + 3) - 3, 0.5, 0)
			knob.Size = UDim2.fromOffset((h - 6) * (1 + (s - 1) * 2.2), (h - 6) / s)
			fill.Size = UDim2.fromScale(p, 1)
			if a and b then
				Scheduler.unschedule(job)
				job = nil
			end
		end, { name = "switch", rate = "frame", priority = 1 })
	end
	knob.Position = UDim2.new(opts.value and 1 or 0, 0, 0.5, 0)
	fill.Size = UDim2.fromScale(opts.value and 1 or 0, 1)
	drive()

	local click = create("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		ZIndex = knob.ZIndex + 1,
		Parent = track,
	})

	local state = { value = opts.value or false, track = track, knob = knob }
	local function paint(t)
		stroke.Color = t.hairline
		if state.value then
			track.BackgroundColor3 = t.accent
			track.BackgroundTransparency = 0.05
			stroke.Transparency = 0.5
		else
			track.BackgroundColor3 = t.surfaceBright
			track.BackgroundTransparency = 0.4
			stroke.Transparency = 0.62
		end
	end
	local unsub = Theme.register(paint)

	local function setValue(v, silent)
		state.value = v and true or false
		pos:setTarget(state.value and 1 or 0)
		drive()
		paint(Theme.tokens())
		Sfx.play(state.value and "toggleOn" or "toggleOff")
		if not silent and opts.onChanged then
			opts.onChanged(state.value, state)
		end
	end
	state.set = function(_, v, silent)
		setValue(v, silent)
	end
	state.toggle = function(_)
		setValue(not state.value)
	end
	click.MouseButton1Click:Connect(function()
		setValue(not state.value)
	end)
	click.MouseButton1Down:Connect(function()
		squish:setTarget(1.3)
		drive()
	end)
	click.MouseButton1Up:Connect(function()
		squish:setTarget(1)
		drive()
	end)
	track.Destroying:Connect(function()
		unsub()
		if job then
			Scheduler.unschedule(job)
			job = nil
		end
	end)
	return state
end

-- Checkbox with a springed tick.
function W.checkbox(parent, opts)
	opts = opts or {}
	local box = create("Frame", {
		Name = "Checkbox",
		BackgroundColor3 = Color3.fromRGB(40, 45, 56),
		BackgroundTransparency = 0.3,
		Size = UDim2.fromOffset(22, 22),
		Position = opts.position,
		AnchorPoint = opts.anchor or Vector2.new(0, 0.5),
		ZIndex = opts.zIndex or 21,
		Parent = parent,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = box })
	local stroke = create("UIStroke", { Transparency = 0.55, Thickness = 1.2, Parent = box })
	local tickHolder = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = box.ZIndex + 1,
		Parent = box,
	})
	local tick = IconKit.attach(
		tickHolder,
		"check",
		{ size = 14, color = Color3.fromRGB(255, 255, 255), subscribeToTheme = false }
	)
	tick.frame.AnchorPoint = Vector2.new(0.5, 0.5)
	tick.frame.Position = UDim2.fromScale(0.5, 0.5)
	local tickScale = create("UIScale", { Scale = 0, Parent = tick.frame })
	local label = opts.text
			and W.label(parent, {
				text = opts.text,
				size = 13,
				position = UDim2.new(0, (opts.positionX or 0) + 30, 0.5, 0),
				zIndex = box.ZIndex,
			})
		or nil

	local scaleSpring = Spring.new(0, Config.motion.springBouncy)
	local job
	local click = create("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		ZIndex = tickHolder.ZIndex + 1,
		Parent = box,
	})
	local state = { value = opts.value or false, frame = box }
	local function drive()
		if job then
			return
		end
		job = Scheduler.schedule(function(dt)
			local rest = scaleSpring:step(dt)
			tickScale.Scale = math.max(0, scaleSpring._position)
			tick.frame.Rotation = (1 - math.min(1, scaleSpring._position)) * -30
			if rest then
				Scheduler.unschedule(job)
				job = nil
			end
		end, { name = "check", rate = "frame", priority = 1 })
	end
	local function paint(t)
		if state.value then
			box.BackgroundColor3 = t.accent
			box.BackgroundTransparency = 0.05
			stroke.Transparency = 0.4
			stroke.Color = Color.addWhite(t.accent, 0.35)
		else
			box.BackgroundColor3 = t.surfaceBright
			box.BackgroundTransparency = 0.35
			stroke.Color = t.hairline
			stroke.Transparency = 0.55
		end
	end
	local unsub = Theme.register(paint)
	scaleSpring:set(state.value and 1 or 0)
	drive()
	local function setValue(v, silent)
		state.value = v and true or false
		scaleSpring:setTarget(state.value and 1 or 0)
		drive()
		paint(Theme.tokens())
		Sfx.play(state.value and "toggleOn" or "toggleOff")
		if not silent and opts.onChanged then
			opts.onChanged(state.value)
		end
	end
	state.set = function(_, v, silent)
		setValue(v, silent)
	end
	click.MouseButton1Click:Connect(function()
		setValue(not state.value)
	end)
	box.Destroying:Connect(function()
		unsub()
		if job then
			Scheduler.unschedule(job)
		end
	end)
	return state
end

-- Radio: a group of mutually exclusive picks.
function W.radioGroup(parent, opts)
	opts = opts or {}
	local container = create("Frame", {
		Name = "RadioGroup",
		BackgroundTransparency = 1,
		Size = opts.size or UDim2.fromScale(1, 0),
		Position = opts.position,
		ZIndex = opts.zIndex or 21,
		Parent = parent,
	})
	create("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = container,
	})
	local group = { value = opts.selected, buttons = {} }
	for i, item in opts.options do
		local row = create("Frame", {
			Name = "Radio_" .. i,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 24),
			LayoutOrder = i,
			ZIndex = container.ZIndex,
			Parent = container,
		})
		local dot = create("Frame", {
			BackgroundColor3 = Color3.fromRGB(40, 45, 56),
			BackgroundTransparency = 0.3,
			Size = UDim2.fromOffset(18, 18),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 0, 0.5, 0),
			ZIndex = row.ZIndex,
			Parent = row,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
		local stroke = create("UIStroke", { Transparency = 0.55, Thickness = 1.1, Parent = dot })
		local inner = create("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Size = UDim2.fromScale(0.4, 0.4),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			ZIndex = dot.ZIndex + 1,
			Parent = dot,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = inner })
		local innerScale = create("UIScale", { Scale = 0, Parent = inner })
		W.label(
			row,
			{ text = item.label, size = 13, position = UDim2.new(0, 28, 0.5, 0), color = "dim", zIndex = row.ZIndex }
		)
		local spring = Spring.new(0, Config.motion.springBouncy)
		local job
		local function drive()
			if job then
				return
			end
			job = Scheduler.schedule(function(dt)
				local rest = spring:step(dt)
				innerScale.Scale = math.max(0.0001, spring._position)
				if rest then
					Scheduler.unschedule(job)
					job = nil
				end
			end, { name = "radio", rate = "frame", priority = 1 })
		end
		local click = create("TextButton", {
			BackgroundTransparency = 1,
			Text = "",
			Size = UDim2.fromScale(1, 1),
			AutoButtonColor = false,
			Parent = row,
		})
		local function select(selected)
			spring:setTarget(selected and 1 or 0)
			drive()
			stroke.Transparency = selected and 0.25 or 0.55
		end
		click.MouseButton1Click:Connect(function()
			group.value = item.value
			for _, b in group.buttons do
				b.select(b.id == item.value)
			end
			Sfx.play("toggleOn")
			if opts.onChanged then
				opts.onChanged(item.value)
			end
		end)
		table.insert(group.buttons, { id = item.value, select = select, row = row })
		if group.value == item.value then
			task.defer(select, true)
		end
	end
	function group:set(value, silent)
		group.value = value
		for _, b in group.buttons do
			b.select(b.id == value)
		end
		if not silent and opts.onChanged then
			opts.onChanged(value)
		end
	end
	return group
end

-- Slider: glass track, liquid fill, spring knob, bubble read-out, tick detents.
function W.slider(parent, opts)
	opts = opts or {}
	local min, max = opts.min or 0, opts.max or 1
	local value = opts.value or min
	local height = opts.height or 8
	local trackH = height + 6
	local track = create("Frame", {
		Name = "Slider",
		BackgroundTransparency = 1,
		Size = opts.size or UDim2.new(1, 0, 0, trackH),
		Position = opts.position,
		AnchorPoint = opts.anchor or Vector2.new(0, 0.5),
		ZIndex = opts.zIndex or 21,
		Parent = parent,
	})
	local rail = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(38, 42, 52),
		BackgroundTransparency = 0.25,
		Size = UDim2.new(1, 0, 0, height),
		Position = UDim2.new(0, 0, 0.5, -height / 2),
		ZIndex = track.ZIndex,
		Parent = track,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = rail })
	create("UIStroke", { Transparency = 0.75, Thickness = 0.8, Parent = rail })
	local fillFrame = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(120, 200, 255),
		Size = UDim2.fromScale(0.4, 1),
		BorderSizePixel = 0,
		ZIndex = rail.ZIndex + 1,
		Parent = rail,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fillFrame })
	create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(1, 0),
		}),
		Parent = fillFrame,
	})
	-- Detent ticks: little notches under the rail when a step is declared.
	if opts.ticks and opts.step and opts.step > 0 then
		local steps = math.floor((max - min) / opts.step + 0.5)
		if steps <= 40 then
			local holder = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 3),
				Position = UDim2.new(0, 0, 0, trackH * 0.72),
				ZIndex = rail.ZIndex - 1,
				Parent = track,
			})
			for i = 0, steps do
				local tick = create("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.8,
					AnchorPoint = Vector2.new(0.5, 0),
					Size = UDim2.fromOffset(1, 3),
					Position = UDim2.fromScale(i / steps, 0),
					Parent = holder,
				})
			end
		end
	end
	local knob = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(245, 248, 252),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(trackH + 2, trackH + 2),
		Position = UDim2.fromScale(0.4, 0.5),
		ZIndex = rail.ZIndex + 3,
		Parent = track,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })
	local knobStroke = create("UIStroke", { Transparency = 0.4, Thickness = 1, Parent = knob })
	local knobScale = create("UIScale", { Scale = 1, Parent = knob })

	local posSpring =
		Spring.new(value, Config.motion.springQuick, { clamp = { min, max }, precision = (max - min) / 1e5 })
	local grabSpring = Spring.new(1, Config.motion.springBouncy)
	local bubbleText = nil
	local bubble = nil
	if opts.showValue ~= false then
		bubble = create("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(46, 20),
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.4, 0, 0, -8),
			ZIndex = knob.ZIndex + 1,
			Parent = track,
		})
		bubbleText = W.label(bubble, {
			text = "",
			size = 11,
			weight = "bold",
			alignX = Enum.TextXAlignment.Center,
			color = "dim",
			anchor = Vector2.new(0, 0),
			size2 = { 46, 20 },
			position = UDim2.fromScale(0, 0),
		})
		bubble.Visible = false
	end

	local state = { value = value, track = track, min = min, max = max, step = opts.step }
	local dragging = false
	local job
	local function format(v)
		if opts.format then
			return opts.format(v)
		end
		if max - min <= 1.0001 then
			return Str.percent(v)
		end
		return tostring(math.floor(v + 0.5))
	end
	local function drive()
		if job then
			return
		end
		job = Scheduler.schedule(function(dt)
			local a = posSpring:step(dt)
			local b = grabSpring:step(dt)
			local frac = Math.clamp01(Math.invLerp(min, max, posSpring._position))
			fillFrame.Size = UDim2.fromScale(frac, 1)
			knob.Position = UDim2.fromScale(frac, 0.5)
			knobScale.Scale = grabSpring._position
			if bubble then
				bubble.Position = UDim2.fromScale(frac, 0)
			end
			if a and b then
				Scheduler.unschedule(job)
				job = nil
			end
		end, { name = "slider", rate = "frame", priority = 1 })
	end
	drive()

	local function setValue(v, fromDrag)
		if state.step then
			v = Math.roundTo(v, state.step)
		end
		v = Math.clamp(v, min, max)
		if math.abs(v - state.value) < 1e-9 then
			return
		end
		state.value = v
		posSpring:setTarget(v)
		drive()
		if bubbleText then
			bubbleText.Text = format(v)
		end
		if opts.onChanged and (fromDrag or opts.notifyProgrammatic) then
			opts.onChanged(v, state)
		end
	end

	-- Interaction: click-anywhere-on-rail + drag.
	local function beginDrag(input)
		dragging = true
		grabSpring:setTarget(1.45)
		drive()
		if bubble then
			bubble.Visible = true
		end
		local rx = input.Position.X - rail.AbsolutePosition.X
		local frac = Math.clamp01(rx / math.max(1, rail.AbsoluteSize.X))
		setValue(Math.lerp(min, max, frac), true)
	end
	track.InputBegan:Connect(function(input, gpe)
		if gpe then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			beginDrag(input)
			Sfx.play("click")
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			local rx = input.Position.X - rail.AbsolutePosition.X
			local frac = Math.clamp01(rx / math.max(1, rail.AbsoluteSize.X))
			local old = state.value
			setValue(Math.lerp(min, max, frac), true)
			if state.step and math.abs(old - state.value) >= state.step then
				Sfx.play("tick")
			end
		end
	end)
	local function endDrag()
		if not dragging then
			return
		end
		dragging = false
		grabSpring:setTarget(1)
		drive()
		task.delay(0.4, function()
			if not dragging and bubble then
				bubble.Visible = false
			end
		end)
	end
	UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			endDrag()
		end
	end)
	track.MouseWheelForward:Connect(function()
		setValue(state.value + (opts.step or (max - min) / 20))
	end)
	track.MouseWheelBackward:Connect(function()
		setValue(state.value - (opts.step or (max - min) / 20))
	end)

	local unsub = Theme.register(function(t)
		rail.BackgroundColor3 = t.surfaceBright
		fillFrame.BackgroundColor3 = t.accent
		knobStroke.Color = Color.addWhite(t.accent, 0.5)
		knob.BackgroundColor3 = Color.addWhite(t.text, -0.02)
	end)
	track.Destroying:Connect(function()
		unsub()
		if job then
			Scheduler.unschedule(job)
		end
	end)

	setValue(value, false)
	if bubbleText then
		bubbleText.Text = format(value)
	end
	function state:set(v, silent)
		setValue(v, not silent)
	end
	function state:get()
		return state.value
	end
	return state
end

-- Stepper: number with - / + glass buttons.
function W.stepper(parent, opts)
	opts = opts or {}
	local min, max, step = opts.min or 0, opts.max or 10, opts.step or 1
	local value = opts.value or min
	local setValue -- forward: the +/- buttons capture this upvalue
	local holder = create("Frame", {
		Name = "Stepper",
		BackgroundTransparency = 1,
		Size = opts.size or UDim2.fromOffset(132, 30),
		Position = opts.position,
		AnchorPoint = opts.anchor or Vector2.new(1, 0.5),
		ZIndex = opts.zIndex or 21,
		Parent = parent,
	})
	local row = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(35, 40, 51),
		BackgroundTransparency = 0.25,
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		ZIndex = holder.ZIndex,
		Parent = holder,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = row })
	create("UIStroke", { Transparency = 0.68, Thickness = 1, Parent = row })
	local valueLabel = W.label(row, {
		text = tostring(value),
		size = 13,
		weight = "bold",
		alignX = Enum.TextXAlignment.Center,
		anchor = Vector2.new(0, 0.5),
		position = UDim2.new(0.5, 0, 0.5, 0),
		size2 = { 60, 20 },
		zIndex = row.ZIndex + 2,
	})
	local minusBtn = W.iconButton(row, {
		icon = "minus",
		size = 26,
		position = UDim2.new(0, 2, 0.5, 0),
		anchor = Vector2.new(0, 0.5),
		variant = "ghost",
		iconSize = 12,
		zIndex = row.ZIndex + 3,
		onClicked = function()
			setValue(math.max(min, value - step))
		end,
	})
	local plusBtn = W.iconButton(row, {
		icon = "plus",
		size = 26,
		position = UDim2.new(1, -2, 0.5, 0),
		anchor = Vector2.new(1, 0.5),
		variant = "ghost",
		iconSize = 12,
		zIndex = row.ZIndex + 3,
		onClicked = function()
			setValue(math.min(max, value + step))
		end,
	})
	local pop = Spring.new(1, Config.motion.springBouncy)
	local popScale = create("UIScale", { Scale = 1, Parent = valueLabel })
	function setValue(v)
		value = Math.clamp(math.floor(v / step + 0.5) * step, min, max)
		valueLabel.Text = tostring(Math.round(value, 2))
		pop:set(0.6)
		pop:setTarget(1)
		local job
		job = Scheduler.schedule(function(dt)
			local rest = pop:step(dt)
			popScale.Scale = pop._position
			if rest then
				Scheduler.unschedule(job)
			end
		end, { name = "stepper", rate = "frame", priority = 1 })
		Sfx.play("tick")
		if opts.onChanged then
			opts.onChanged(value)
		end
	end
	local unsub = Theme.register(function(t)
		row.BackgroundColor3 = t.surfaceBright
	end)
	holder.Destroying:Connect(function()
		unsub()
	end)
	return {
		frame = holder,
		set = setValue,
		get = function()
			return value
		end,
	}
end

-- Text input with a floating placeholder and focus glow.
function W.input(parent, opts)
	opts = opts or {}
	local holder = create("Frame", {
		Name = "Input",
		BackgroundTransparency = 1,
		Size = opts.size or UDim2.new(1, 0, 0, 36),
		Position = opts.position,
		ZIndex = opts.zIndex or 21,
		Parent = parent,
	})
	local body = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(30, 34, 44),
		BackgroundTransparency = 0.2,
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		ZIndex = holder.ZIndex,
		Parent = holder,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = body })
	local stroke = create("UIStroke", { Transparency = 0.66, Thickness = 1, Parent = body })
	local glow = create("Frame", {
		Name = "FocusGlow",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = body.ZIndex - 1,
		Parent = body,
	})
	local glowStroke = create("UIStroke", {
		Color = Color3.fromRGB(120, 200, 255),
		Transparency = 1,
		Thickness = 5,
		Parent = glow,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = glowStroke })

	local field = create("TextBox", {
		Name = "Field",
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		Text = opts.text or "",
		PlaceholderText = opts.placeholder or "",
		Font = fontBy(opts.mono and "mono" or "regular"),
		TextSize = (opts.textSize or 13.5) * Config.accessibility.largerText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = opts.multiline or false,
		MultiLine = opts.multiline or false,
		CursorPosition = -1,
		Size = UDim2.new(1, -24, opts.multiline and 1 or 0, opts.multiline and 0 or 36),
		Position = UDim2.new(0, 12, opts.multiline and 0 or 0.5, opts.multiline and 8 or 0),
		AnchorPoint = Vector2.new(0, opts.multiline and 0 or 0.5),
		ZIndex = body.ZIndex + 2,
		Parent = body,
	})
	field.TextTruncate = opts.multiline and Enum.TextTruncate.None or Enum.TextTruncate.Clip

	local glowSpring = Spring.new(0.92, Config.motion.spring)
	local job
	local function drive()
		if job then
			return
		end
		job = Scheduler.schedule(function(dt)
			local rest = glowSpring:step(dt)
			glowStroke.Transparency = 1 - glowSpring._position * 0.42
			stroke.Transparency = 1 - (0.35 + glowSpring._position * 0.25)
			if rest then
				Scheduler.unschedule(job)
				job = nil
			end
		end, { name = "inputGlow", rate = "frame", priority = 1 })
	end
	field.Focused:Connect(function()
		glowSpring:setTarget(1)
		drive()
		Sfx.play("tap")
	end)
	field.FocusLost:Connect(function(enterPressed)
		glowSpring:setTarget(0.15)
		drive()
		if opts.onEnter and enterPressed then
			opts.onEnter(field.Text)
		end
		if opts.onChanged then
			opts.onChanged(field.Text)
		end
	end)
	field:GetPropertyChangedSignal("Text"):Connect(function()
		if opts.onInput then
			opts.onInput(field.Text)
		end
	end)

	local unsub = Theme.register(function(t)
		body.BackgroundColor3 = t.surface
		stroke.Color = t.hairline
		field.TextColor3 = t.text
		field.PlaceholderColor3 = t.faint
		glowStroke.Color = t.accent
	end)
	holder.Destroying:Connect(function()
		unsub()
		if job then
			Scheduler.unschedule(job)
		end
	end)

	return {
		frame = holder,
		field = field,
		set = function(text)
			field.Text = text
		end,
		get = function()
			return field.Text
		end,
		focus = function()
			pcall(field.CaptureFocus, field)
		end,
	}
end

-- Segmented control: sliding glass pill over the active segment.
function W.segmented(parent, opts)
	opts = opts or {}
	local count = #opts.options
	local holder = create("Frame", {
		Name = "Segmented",
		BackgroundColor3 = Color3.fromRGB(26, 30, 40),
		BackgroundTransparency = 0.25,
		Size = opts.size or UDim2.fromOffset(opts.widthPx or 260, opts.height or 32),
		Position = opts.position,
		AnchorPoint = opts.anchor or Vector2.new(0.5, 0.5),
		ZIndex = opts.zIndex or 21,
		Parent = parent,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = holder })
	create("UIStroke", { Transparency = 0.7, Thickness = 1, Parent = holder })
	local selected = opts.selected or 1
	local thumb = create("Frame", {
		Name = "Thumb",
		BackgroundColor3 = Color3.fromRGB(64, 72, 88),
		BackgroundTransparency = 0.1,
		Size = UDim2.fromScale(1 / count, 1),
		ZIndex = holder.ZIndex + 1,
		Parent = holder,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = thumb })
	create("UIStroke", { Transparency = 0.5, Thickness = 0.8, Parent = thumb })
	local thumbGrad = create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 0.5),
		}),
		Parent = thumb,
	})
	local posSpring = Spring.new(selected - 1, Config.motion.springBouncy)
	local scaleSpring = Spring.new(1, Config.motion.springQuick)
	local thumbScale = create("UIScale", { Scale = 1, Parent = thumb })
	local job
	local function drive()
		if job then
			return
		end
		job = Scheduler.schedule(function(dt)
			local a = posSpring:step(dt)
			local b = scaleSpring:step(dt)
			thumb.Position = UDim2.fromScale(posSpring._position / count, 0)
			thumbScale.Scale = scaleSpring._position
			if a and b then
				Scheduler.unschedule(job)
				job = nil
			end
		end, { name = "segmented", rate = "frame", priority = 1 })
	end
	drive()
	local row = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = thumb.ZIndex + 1,
		Parent = holder,
	})
	create(
		"UIListLayout",
		{ FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, Parent = row }
	)
	local labels = {}
	for i, item in opts.options do
		local btn = create("TextButton", {
			BackgroundTransparency = 1,
			Text = item.label or item,
			AutoButtonColor = false,
			Font = fontBy("medium"),
			TextSize = (opts.textSize or 12.5) * Config.accessibility.largerText,
			Size = UDim2.fromScale(1 / count, 1),
			LayoutOrder = i,
			ZIndex = row.ZIndex,
			Parent = row,
		})
		labels[i] = btn
		btn.MouseButton1Click:Connect(function()
			selected = i
			for j, l in labels do
				l.TextTransparency = j == i and 0 or 0.45
			end
			posSpring:setTarget(i - 1)
			scaleSpring:set(0.94)
			scaleSpring:setTarget(1)
			drive()
			Sfx.play("tap")
			if opts.onChanged then
				opts.onChanged((item.value or i))
			end
		end)
		btn.MouseEnter:Connect(function()
			scaleSpring:setTarget(1.03)
			drive()
		end)
		btn.MouseLeave:Connect(function()
			scaleSpring:setTarget(1)
			drive()
		end)
	end
	local function paint(t)
		holder.BackgroundColor3 = t.surfaceDeep
		thumb.BackgroundColor3 = Color.mix(t.accent, t.surfaceBright, 0.35)
		for i, l in labels do
			l.TextColor3 = i == selected and Color.readableOn(t.accent) or t.dim
		end
	end
	local unsub = Theme.register(paint)
	holder.Destroying:Connect(function()
		unsub()
		if job then
			Scheduler.unschedule(job)
		end
	end)
	return {
		frame = holder,
		set = function(_, index)
			local btn = labels[index]
			if btn then
				btn.MouseButton1Click:Fire()
			end
		end,
	}
end

-- Dropdown: input-looking trigger, floating glass list, checkmark on the pick.
function W.dropdown(parent, opts)
	opts = opts or {}
	local holder = create("Frame", {
		Name = "Dropdown",
		BackgroundTransparency = 1,
		Size = opts.size or UDim2.new(1, 0, 0, 34),
		Position = opts.position,
		ZIndex = opts.zIndex or 22,
		Parent = parent,
	})
	local trigger = W.button(holder, {
		label = tostring(opts.selected or opts.options[1] or "Select"),
		variant = "bordered",
		icon = "chevronDown",
		iconSize = 12,
		iconPad = 8,
		fill = true,
		roundness = 10,
		zIndex = holder.ZIndex,
	})
	trigger.caption.TextXAlignment = Enum.TextXAlignment.Left
	trigger.caption.Position = UDim2.new(0, 12, 0, 0)
	local chev = trigger.icon
	chev.frame.AnchorPoint = Vector2.new(1, 0.5)
	chev.frame.Position = UDim2.new(1, -10, 0.5, 0)

	local open = false
	local menu = create("Frame", {
		Name = "Menu",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		Position = UDim2.new(0, 0, 1, 4),
		ZIndex = 999,
		Parent = App.layers and App.layers.overlay or holder,
	})
	local menuSurface = Glass.new(menu, {
		name = "DropdownMenu",
		size = UDim2.new(1, 0, 0, 8),
		roundness = 12,
		position = UDim2.fromScale(0, 0),
		anchor = Vector2.new(0, 0),
		caustics = false,
		interactive = true,
		tint = 0.32,
	})
	local list = menuSurface.content
	local layout =
		create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	create("UIPadding", {
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		Parent = list,
	})
	local height = 0
	local value = opts.selected or opts.options[1]
	local closeMenu -- forward declaration; row handlers capture this
	for i, optionText in opts.options do
		local rowBtn = W.button(list, {
			label = tostring(optionText),
			variant = "ghost",
			fill = true,
			height = 26,
			roundness = 8,
			size = "sm",
			bold = false,
			zIndex = 5 + i,
		})
		rowBtn.caption.TextXAlignment = Enum.TextXAlignment.Left
		rowBtn.caption.Position = UDim2.new(0, 8, 0, 0)
		height += 30
		local id = i
		local orig = rowBtn.body
		rowBtn.holder.ZIndex = 5 + id
		local clickBtn = orig:FindFirstChild("Click")
		if clickBtn then
			clickBtn.MouseButton1Click:Connect(function()
				value = opts.options[id]
				trigger:setLabel(tostring(value))
				closeMenu()
				Sfx.play("click")
				if opts.onChanged then
					opts.onChanged(value)
				end
			end)
		end
	end
	local springH = Spring.new(0, Config.motion.springBouncy, { precision = 0.4 })
	local menuSurfaceRoot = menuSurface.root
	local function syncMenuRect()
		local ap = holder.AbsolutePosition
		local asz = holder.AbsoluteSize
		menu.Position = UDim2.fromOffset(ap.X, ap.Y + asz.Y + 4)
		menuSurfaceRoot.Position = UDim2.fromOffset(0, 0)
	end
	local menuJob
	local function driveMenu()
		if menuJob then
			return
		end
		menuJob = Scheduler.schedule(function(dt)
			local rest = springH:step(dt)
			local h = math.max(0, springH._position)
			local aw = holder.AbsoluteSize.X
			menu.Size = UDim2.fromOffset(aw, h)
			menuSurfaceRoot.Size = UDim2.fromOffset(aw, h)
			menuSurfaceRoot.Visible = h > 3
			if rest then
				Scheduler.unschedule(menuJob)
				menuJob = nil
			end
		end, { name = "dropdown", rate = "frame", priority = 1 })
	end
	closeMenu = function()
		if open then
			Depth.pop(false)
		end
		open = false
		springH:setTarget(0)
		driveMenu()
		if chev then
			chev.frame.Rotation = 0
		end
	end
	local function toggle()
		open = not open
		if open then
			syncMenuRect()
			Depth.push(false)
			springH:setTarget(math.min(240, height + 8))
			if chev then
				chev.frame.Rotation = 180
			end
			Sfx.play("windowOpen")
		else
			closeMenu()
		end
		driveMenu()
	end
	local clickZone = trigger.body and trigger.body:FindFirstChild("Click")
	if clickZone then
		clickZone.MouseButton1Click:Connect(toggle)
	end
	return {
		frame = holder,
		get = function()
			return value
		end,
		set = function(v)
			value = v
			trigger:setLabel(tostring(v))
		end,
	}
end

-- Progress: liquid fill bar with shimmer. percent in 0..1.
function W.progress(parent, opts)
	opts = opts or {}
	local holder = create("Frame", {
		Name = "Progress",
		BackgroundTransparency = 1,
		Size = opts.size or UDim2.new(1, 0, 0, 6),
		Position = opts.position,
		AnchorPoint = opts.anchor or Vector2.new(0, 0.5),
		ZIndex = opts.zIndex or 20,
		Parent = parent,
	})
	local rail = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(40, 44, 55),
		BackgroundTransparency = 0.25,
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		Parent = holder,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = rail })
	local fill = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(120, 200, 255),
		Size = UDim2.fromScale(opts.value or 0.4, 1),
		BorderSizePixel = 0,
		ZIndex = rail.ZIndex + 1,
		Parent = rail,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })
	local shimmer = create("UIGradient", {
		Rotation = 0,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.9),
			NumberSequenceKeypoint.new(0.5, 0.45),
			NumberSequenceKeypoint.new(1, 0.9),
		}),
		Offset = Vector2.new(-1, 0),
		Parent = fill,
	})
	local spring = Spring.new(opts.value or 0, Config.motion.spring)
	local job
	local function drive()
		if job then
			return
		end
		job = Scheduler.schedule(function(dt)
			local rest = spring:step(dt)
			fill.Size = UDim2.fromScale(Math.clamp01(spring._position), 1)
			if rest then
				Scheduler.unschedule(job)
				job = nil
			end
		end, { name = "progress", rate = "frame", priority = 1 })
	end
	drive()
	if opts.indeterminate ~= false then
		Scheduler.schedule(function()
			shimmer.Offset = Vector2.new(Math.pingPong(os.clock() * 0.6, 2) - 1, 0)
		end, { name = "shimmer", rate = 24, priority = 7 })
	end
	local unsub = Theme.register(function(t)
		rail.BackgroundColor3 = t.surfaceDeep
		fill.BackgroundColor3 = opts.color or t.accent
	end)
	holder.Destroying:Connect(function()
		unsub()
		if job then
			Scheduler.unschedule(job)
		end
	end)
	return {
		frame = holder,
		set = function(v, silent)
			spring:setTarget(Math.clamp01(v))
			drive()
		end,
		spring = spring,
	}
end

-- Ring progress: stroked circle whose thickness pulses while filling.
function W.ring(parent, opts)
	opts = opts or {}
	local size = opts.size or 54
	local holder = create("Frame", {
		Name = "Ring",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size),
		Position = opts.position,
		AnchorPoint = opts.anchor or Vector2.new(0.5, 0.5),
		ZIndex = opts.zIndex or 21,
		Parent = parent,
	})
	local base = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = holder,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = base })
	local baseStroke = create("UIStroke", { Thickness = opts.thickness or 4, Transparency = 0.8, Parent = base })
	local arcHolder = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Rotation = -90,
		ZIndex = base.ZIndex + 1,
		Parent = holder,
	})
	local segments = {}
	local segCount = 28
	for i = 1, segCount do
		local a0 = (i - 1) / segCount * 360
		local a1 = i / segCount * 360
		local mid = (a0 + a1) / 2
		local bar = create("Frame", {
			BackgroundColor3 = Color3.fromRGB(120, 200, 255),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(math.max(2, size * math.pi / segCount), opts.thickness or 4),
			Position = UDim2.fromScale(0.5 + math.cos(math.rad(mid)) * 0.455, 0.5 + math.sin(math.rad(mid)) * 0.455),
			Rotation = mid + 90,
			ZIndex = arcHolder.ZIndex,
			Parent = arcHolder,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })
		segments[i] = bar
	end
	local center = W.label(holder, {
		text = opts.centerText or "",
		size = opts.centerSize or 12,
		weight = "bold",
		color = opts.centerColor or "text",
		anchor = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.5),
		size2 = { size, size },
		alignX = Enum.TextXAlignment.Center,
		zIndex = holder.ZIndex + 3,
	})
	local value = opts.value or 0.62
	local reveal = Spring.new(0, Config.motion.spring)
	local job
	local function drive()
		if job then
			return
		end
		job = Scheduler.schedule(function(dt)
			local rest = reveal:step(dt)
			local shown = reveal._position * segCount
			for i, seg in segments do
				seg.BackgroundTransparency = i <= shown and 0 or 1
			end
			if rest then
				Scheduler.unschedule(job)
				job = nil
			end
		end, { name = "ring", rate = "frame", priority = 1 })
	end
	local function set(v)
		value = Math.clamp01(v)
		reveal:setTarget(value)
		drive()
	end
	set(value)
	if opts.onChanged then
		opts.onChanged(value)
	end
	local unsub = Theme.register(function(t)
		baseStroke.Color = t.hairline
		for _, seg in segments do
			seg.BackgroundColor3 = value > 0.9 and t.success or t.accent
		end
	end)
	holder.Destroying:Connect(function()
		unsub()
		if job then
			Scheduler.unschedule(job)
		end
	end)
	return {
		frame = holder,
		set = set,
		setCenter = function(text)
			center.Text = text
		end,
	}
end

-- Spinner: rotating arc built from fading segment blocks.
function W.spinner(parent, opts)
	opts = opts or {}
	local size = opts.size or 22
	local holder = create("Frame", {
		Name = "Spinner",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size),
		Position = opts.position,
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = opts.zIndex or 30,
		Parent = parent,
	})
	local rot = create("UIRotation", { Angle = 0, Parent = holder })
	local segs = {}
	for i = 1, 10 do
		local a = (i / 10) * math.pi * 2
		local bar = create("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(math.max(2, size * 0.12), size * 0.3),
			Position = UDim2.fromScale(0.5 + math.cos(a) * 0.34, 0.5 + math.sin(a) * 0.34),
			Rotation = math.deg(a) + 90,
			BackgroundTransparency = i / 12,
			Parent = holder,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bar })
		table.insert(segs, bar)
	end
	local spinTask = task.spawn(function()
		local t0 = os.clock()
		while holder.Parent do
			rot.Angle = ((os.clock() - t0) * 240) % 360 * math.pi / 180
			task.wait()
		end
	end)
	local unsub = Theme.register(function(t)
		for _, bar in segs do
			bar.BackgroundColor3 = opts.color or t.dim
		end
	end)
	holder.Destroying:Connect(function()
		task.cancel(spinTask)
		unsub()
	end)
	return holder
end

-- Skeleton shimmer placeholder rows (used in loading states of demo apps).
function W.skeleton(parent, opts)
	opts = opts or {}
	local row = create("Frame", {
		Name = "Skeleton",
		BackgroundColor3 = Color3.fromRGB(45, 50, 62),
		BackgroundTransparency = 0.35,
		Size = opts.size or UDim2.new(1, 0, 0, 14),
		Position = opts.position,
		ZIndex = opts.zIndex or 5,
		Parent = parent,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = row })
	local sheen = create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 0.6),
		}),
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
		Offset = Vector2.new(-1, 0),
		Parent = row,
	})
	local phase = opts.phase or 0
	local job = Scheduler.schedule(function()
		local t = (os.clock() * 0.5 + phase) % 1
		sheen.Offset = Vector2.new(t * 3 - 1.5, 0)
		row.BackgroundTransparency = 0.3 + 0.1 * math.sin(t * math.pi * 2)
	end, { name = "skeleton", rate = 20, priority = 7 })
	local unsub = Theme.register(function(t)
		row.BackgroundColor3 = t.surfaceBright
	end)
	row.Destroying:Connect(function()
		Scheduler.unschedule(job)
		unsub()
	end)
	return row
end
--═══════════════════════════════════════════════════════════════════════════════--
-- § 12  WINDOWS + WINDOW MANAGER + MISSION CONTROL
--
-- A window is a glass surface with chrome: traffic lights that bloom their
-- glyphs on hover, a titlebar that drags with spring lag (the window follows you
-- like it has mass), snap zones that preview where you're about to drop, resize
-- handles on every edge, and a rim that "flows" when it is the focused one.
--═══════════════════════════════════════════════════════════════════════════════--

local WM = {
	windows = {},
	order = {},
	focused = nil,
	nextCascade = 0,
	snapGhost = nil,
	dragThreshold = Config.input.dragThreshold,
}
Nocturne.Window = WM
Nocturne.WM = WM

local function viewport()
	local cam = workspace.CurrentCamera
	if cam then
		return cam.ViewportSize
	end
	return Vector2.new(1280, 720)
end

WM.viewport = viewport

local function chromeTop()
	local bar = Nocturne.MenuBar
	return (bar and bar.visible) and Config.layout.menuBarHeight or 6
end

-- Snap ghost --------------------------------------------------------------------
local function ensureGhost()
	if WM.snapGhost then
		return WM.snapGhost
	end
	local layer = App.layers and App.layers.overlay
	if not layer then
		return nil
	end
	local ghost = create("Frame", {
		Name = "SnapGhost",
		BackgroundColor3 = Color3.fromRGB(140, 190, 255),
		BackgroundTransparency = 0.82,
		Size = UDim2.fromScale(0, 0),
		Visible = false,
		ZIndex = 500,
		Parent = layer,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 20), Parent = ghost })
	local stroke = create("UIStroke", {
		Color = Color3.fromRGB(190, 220, 255),
		Transparency = 0.25,
		Thickness = 1.6,
		Parent = ghost,
	})
	local scale = create("UIScale", { Scale = 1, Parent = ghost })
	local data = { frame = ghost, stroke = stroke, scale = scale, target = nil, current = UDim2.fromScale(0, 0) }
	Theme.register(function(t)
		ghost.BackgroundColor3 = t.accent
		stroke.Color = Color.addWhite(t.accent, 0.4)
	end)
	WM.snapGhost = data
	return data
end

local function showGhost(rect)
	local ghost = ensureGhost()
	if not ghost then
		return
	end
	ghost.target = rect
	ghost.frame.Visible = true
	ghost.spring = ghost.spring or Spring.new(0, Config.motion.springBouncy)
	ghost.spring:setTarget(1)
end

local function hideGhost()
	local ghost = WM.snapGhost
	if ghost and ghost.spring then
		ghost.spring:setTarget(0)
	end
end

-- The ghost eases its own geometry so snapping feels poured, not pasted.
Scheduler.schedule(function(dt)
	local ghost = WM.snapGhost
	if ghost == nil or ghost.spring == nil then
		return
	end
	local rest = ghost.spring:step(dt)
	local p = ghost.spring._position
	if ghost.target then
		local cur, g = ghost.current, ghost.target
		local k = 0.35
		ghost.current = UDim2.new(
			Math.lerp(cur.X.Scale, g.X.Scale, k),
			Math.lerp(cur.X.Offset, g.X.Offset, k),
			Math.lerp(cur.Y.Scale, g.Y.Scale, k),
			Math.lerp(cur.Y.Offset, g.Y.Offset, k)
		)
		ghost.frame.Position = ghost.current
		if ghost.targetSize then
			ghost.frame.Size = ghost.targetSize
		end
		ghost.scale.Scale = p
		ghost.frame.Visible = p > 0.02
	end
	if rest and p < 0.02 then
		ghost.frame.Visible = false
	end
end, { name = "ghost", rate = "frame", priority = 1 })

-- Traffic lights ----------------------------------------------------------------
local function makeTrafficLight(parent, kind, onClick)
	-- kind: close | minimise | maximise. The glyph is drawn (never an emoji),
	-- hidden until hover, exactly like the real thing.
	local size = Config.layout.trafficLightSize + 6
	local btn = create("TextButton", {
		Name = "Light_" .. kind,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromOffset(size, size),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = parent.ZIndex + 40,
		Parent = parent,
	})
	local disc = create("Frame", {
		Name = "Disc",
		BackgroundColor3 = Color3.fromRGB(60, 60, 66),
		BackgroundTransparency = 0.1,
		Size = UDim2.fromScale(1, 1),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = btn.ZIndex,
		Parent = btn,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = disc })
	local ring = create(
		"UIStroke",
		{ Transparency = 0.55, Thickness = 0.8, Color = Color3.fromRGB(255, 255, 255), Parent = disc }
	)
	local glyph = create("Frame", {
		Name = "Glyph",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = disc.ZIndex + 1,
		Parent = disc,
	})
	local glyphColor = Color3.fromRGB(30, 22, 14)
	if kind == "close" then
		local a = create("Frame", {
			BackgroundColor3 = glyphColor,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0.46, 0, 0, 1.3),
			Position = UDim2.fromScale(0.5, 0.5),
			Rotation = 45,
			ZIndex = glyph.ZIndex,
			Parent = glyph,
		})
		create("Frame", {
			BackgroundColor3 = glyphColor,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0.46, 0, 0, 1.3),
			Position = UDim2.fromScale(0.5, 0.5),
			Rotation = -45,
			ZIndex = glyph.ZIndex,
			Parent = glyph,
		})
	elseif kind == "minimise" then
		create("Frame", {
			BackgroundColor3 = glyphColor,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0.44, 0, 0, 1.4),
			Position = UDim2.fromScale(0.5, 0.52),
			ZIndex = glyph.ZIndex,
			Parent = glyph,
		})
	else
		local t = create("Frame", {
			BackgroundColor3 = glyphColor,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0.2, 0, 0, 1.2),
			Position = UDim2.new(0.32, 0, 0.3, 0),
			Rotation = -45,
			Parent = glyph,
		})
		create("Frame", {
			BackgroundColor3 = glyphColor,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0.2, 0, 0, 1.2),
			Position = UDim2.new(0.68, 0, 0.3, 0),
			Rotation = 45,
			Parent = glyph,
		})
		create("Frame", {
			BackgroundColor3 = glyphColor,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0.2, 0, 0, 1.2),
			Position = UDim2.new(0.32, 0, 0.7, 0),
			Rotation = 45,
			Parent = glyph,
		})
		create("Frame", {
			BackgroundColor3 = glyphColor,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0.2, 0, 0, 1.2),
			Position = UDim2.new(0.68, 0, 0.7, 0),
			Parent = glyph,
			Rotation = -45,
		})
	end
	glyph.ZIndex = disc.ZIndex + 2
	for _, ch in glyph:GetChildren() do
		if ch:IsA("GuiObject") then
			ch.ZIndex = glyph.ZIndex + 1
			ch.BackgroundTransparency = 1
		end
	end

	local colors = {
		close = { off = Color3.fromRGB(58, 60, 68), on = Color3.fromRGB(255, 95, 86) },
		minimise = { off = Color3.fromRGB(58, 60, 68), on = Color3.fromRGB(255, 189, 46) },
		maximise = { off = Color3.fromRGB(58, 60, 68), on = Color3.fromRGB(40, 205, 65) },
	}
	local cset = colors[kind] or colors.close
	local hoverSpring = Spring.new(0, Config.motion.springQuick)
	local pressSpring = Spring.new(1, Config.motion.springBouncy)
	local job
	local function drive()
		if job then
			return
		end
		job = Scheduler.schedule(function(dt)
			local a = hoverSpring:step(dt)
			local b = pressSpring:step(dt)
			local p = hoverSpring._position
			disc.BackgroundColor3 = Color.mix(cset.off, cset.on, p)
			disc.BackgroundTransparency = Math.lerp(0.28, 0.02, p)
			ring.Transparency = Math.lerp(0.55, 0.15, p)
			for _, ch in glyph:GetChildren() do
				if ch:IsA("GuiObject") then
					ch.BackgroundTransparency = 1 - p
				end
			end
			local sc = pressSpring._position
			for _, inst in btn:GetChildren() do
				if inst:IsA("UIScale") then
					inst.Scale = sc
				end
			end
			if a and b then
				Scheduler.unschedule(job)
				job = nil
			end
		end, { name = "traffic", rate = "frame", priority = 1 })
	end
	local uiScale = create("UIScale", { Scale = 1, Parent = btn })
	btn.MouseEnter:Connect(function()
		hoverSpring:setTarget(1)
		drive()
	end)
	btn.MouseLeave:Connect(function()
		hoverSpring:setTarget(0)
		drive()
	end)
	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			pressSpring:setTarget(0.72)
			drive()
		end
	end)
	btn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			pressSpring:setTarget(1)
			pressSpring:addVelocity(4)
			drive()
			Sfx.play("tap")
			if onClick then
				onClick()
			end
		end
	end)
	drive()
	return btn
end

WM._makeTrafficLight = makeTrafficLight

-- Window creation ----------------------------------------------------------------
-- spec: { id, title, subtitle, icon, size = {w,h}, min = {w,h}, position,
--         appId, content = function(win) end, frameless, closable, resizable,
--         flowOnFocus, roundness, tab }
function WM.open(spec)
	spec = spec or {}
	local id = spec.id or ("win_" .. HttpService:GenerateGUID(false):sub(1, 8))
	local existing = WM.windows[spec.appId or id]
	if existing and not spec.forceNew then
		if existing.minimized then
			WM.restore(existing)
		end
		WM.focus(existing)
		return existing
	end

	local layer = App.layers and App.layers.windows
	assert(layer, "Nocturne: App.init() must run before opening windows")

	local vw = viewport()
	local fill = math.min(vw.X, vw.Y)
	local defaultW = Math.clamp((spec.size and spec.size[1] or 560), Config.layout.minWindowWidth, vw.X * 0.9)
	local defaultH = Math.clamp((spec.size and spec.size[2] or 420), Config.layout.minWindowHeight, vw.Y * 0.86)
	local cascade = (WM.nextCascade % 6) * 26
	WM.nextCascade += 1

	local targetSize = UDim2.fromOffset(defaultW, defaultH)
	local startX = Math.clamp((vw.X - defaultW) / 2 + cascade - 40, 8, vw.X - defaultW - 8)
	local startY = Math.clamp(chromeTop() + 30 + cascade * 0.5, chromeTop() + 6, vw.Y - defaultH - 76)

	local surface = Glass.new(layer, {
		name = "Window_" .. id,
		size = targetSize,
		position = UDim2.fromOffset(startX, startY + 26),
		anchor = Vector2.new(0, 0),
		roundness = spec.roundness or 22,
		interactive = true,
		caustics = not spec.noCaustics,
		shadow = true,
	})
	local root = surface.root
	local win -- forward: titlebar buttons and drag wiring capture this below

	-- Titlebar ---------------------------------------------------------------
	local titlebar = create("Frame", {
		Name = "Titlebar",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, Config.layout.titleBarHeight),
		ZIndex = 15,
		Parent = root,
	})
	local dragZone = create("TextButton", {
		Name = "DragZone",
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(1, -120, 1, 0),
		Position = UDim2.new(0, 68, 0, 0),
		ZIndex = 16,
		Parent = titlebar,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 16), Parent = dragZone })

	local lights = {}
	local gap = Config.layout.trafficLightGap
	local lightSize = Config.layout.trafficLightSize + 6
	local lightsRow = create("Frame", {
		Name = "Lights",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(lightSize * 3 + gap * 2, lightSize),
		Position = UDim2.new(0, 14, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ZIndex = 20,
		Parent = titlebar,
	})
	local order = { "close", "minimise", "maximise" }
	for i, kind in order do
		local light = makeTrafficLight(lightsRow, kind, function()
			if kind == "close" then
				WM.close(win)
			elseif kind == "minimise" then
				WM.minimize(win)
			else
				WM.toggleMaximize(win)
			end
		end)
		light.Position = UDim2.fromOffset((lightSize + gap) * (i - 1), 0)
		light.AnchorPoint = Vector2.new(0, 0)
		light.Size = UDim2.fromOffset(lightSize, lightSize)
		table.insert(lights, light)
	end
	-- Group-reveal: hovering any light blooms all three, like the real chrome.
	lightsRow.MouseEnter:Connect(function()
		for _, l in lights do
			local child = l:FindFirstChild("Disc", true)
			local hb = child and child._hoverPush
		end
	end)

	-- Title text + icon ------------------------------------------------------
	local titleIcon = nil
	if spec.icon then
		titleIcon = IconKit.attach(titlebar, spec.icon, { size = 14, emphasis = true })
		titleIcon.frame.AnchorPoint = Vector2.new(0, 0.5)
		titleIcon.frame.Position = UDim2.new(0, 0, 0.5, 0)
		titleIcon.frame.ZIndex = 17
	end
	local titleLabel = W.label(titlebar, {
		text = spec.title or id,
		size = 13.5,
		weight = "bold",
		color = "text",
		position = UDim2.new(0, 0, 0.42, 0),
		truncate = true,
		zIndex = 17,
	})
	local subLabel = nil
	if spec.subtitle then
		subLabel = W.label(titlebar, {
			text = spec.subtitle,
			size = 9.5,
			color = "faint",
			position = UDim2.new(0, 0, 0.72, 0),
			truncate = true,
			zIndex = 17,
		})
	end
	local function layoutTitle()
		local left = 14 + lightSize * 3 + gap * 2 + 12
		if titleIcon then
			titleIcon.frame.Position = UDim2.fromOffset(left, titlebar.AbsoluteSize.Y * 0.42)
			titleIcon.frame.AnchorPoint = Vector2.new(0, 0.5)
			left += 20
		end
		titleLabel.Position = UDim2.fromOffset(left, titlebar.AbsoluteSize.Y * (subLabel and 0.36 or 0.5))
		titleLabel.AnchorPoint = Vector2.new(0, 0.5)
		if subLabel then
			subLabel.Position = UDim2.fromOffset(left, titlebar.AbsoluteSize.Y * 0.68)
			subLabel.AnchorPoint = Vector2.new(0, 0.5)
		end
	end
	layoutTitle()
	task.defer(layoutTitle)

	-- Content ------------------------------------------------------------------
	local contentInset = create("Frame", {
		Name = "ClientArea",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -2, 1, -Config.layout.titleBarHeight - 10),
		Position = UDim2.new(0, 1, 0, Config.layout.titleBarHeight + 8),
		ZIndex = 12,
		Parent = root,
	})

	-- Scroll surface: the client area is a ScrollingFrame so long apps breathe.
	local scroller = create("ScrollingFrame", {
		Name = "Scroll",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollingEnabled = true,
		ElasticBehavior = Enum.ElasticBehavior.Always,
		ZIndex = contentInset.ZIndex,
		Parent = contentInset,
	})
	local pad = create("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 18),
		PaddingLeft = UDim.new(0, 14),
		PaddingRight = UDim.new(0, 14),
		Parent = scroller,
	})
	local vlist = create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
		Parent = scroller,
	})

	-- Dragging -----------------------------------------------------------------
	local posSpringX = Spring.new(startX, Config.motion.spring, { precision = 0.05 })
	local posSpringY = Spring.new(startY + 26, Config.motion.spring, { precision = 0.05 })
	local sizeSpringX = Spring.new(defaultW, Config.motion.springQuick, { precision = 0.2 })
	local sizeSpringY = Spring.new(defaultH, Config.motion.springQuick, { precision = 0.2 })
	local dragging = false
	local dragOffset = Vector2.new(0, 0)
	local motionJob
	local function ensureMotion()
		if motionJob then
			return
		end
		motionJob = Scheduler.schedule(function(dt)
			local a = posSpringX:step(dt)
			local b = posSpringY:step(dt)
			local c = sizeSpringX:step(dt)
			local d = sizeSpringY:step(dt)
			root.Position = UDim2.fromOffset(posSpringX._position, posSpringY._position)
			root.Size = UDim2.fromOffset(math.max(60, sizeSpringX._position), math.max(60, sizeSpringY._position))
			if a and b and c and d and not dragging then
				Scheduler.unschedule(motionJob)
				motionJob = nil
			end
		end, { name = "windowMotion", rate = "frame", priority = 1 })
	end
	ensureMotion()

	local snapCandidate = nil
	local function detectSnap(mouseX, mouseY)
		local vw2 = viewport()
		local m = Config.layout.snapMargin
		local th = Config.input.snapThreshold
		if mouseX < m + th then
			if mouseY < vw2.Y * 0.33 then
				return "topLeft"
			elseif mouseY > vw2.Y * 0.67 then
				return "bottomLeft"
			end
			return "left"
		elseif mouseX > vw2.X - m - th then
			if mouseY < vw2.Y * 0.33 then
				return "topRight"
			elseif mouseY > vw2.Y * 0.67 then
				return "bottomRight"
			end
			return "right"
		elseif mouseY < m + chromeTop() + th then
			return "full"
		end
		return nil
	end
	local function snapRectFor(kind)
		local vw2 = viewport()
		local m = Config.layout.snapMargin
		local top = chromeTop() + m + 4
		local h = vw2.Y - top - Config.layout.dockSize - m - 14
		local half = (vw2.X - m * 2) / 2 - 4
		if kind == "left" then
			return UDim2.new(0, m, 0, top), UDim2.fromOffset(half, h)
		elseif kind == "right" then
			return UDim2.new(0, m + half + 8, 0, top), UDim2.fromOffset(half, h)
		elseif kind == "full" then
			return UDim2.new(0, m, 0, top), UDim2.fromOffset(vw2.X - m * 2, h)
		elseif kind == "topLeft" then
			return UDim2.new(0, m, 0, top), UDim2.fromOffset(half, h / 2 - 4)
		elseif kind == "bottomLeft" then
			return UDim2.new(0, m, 0, top + h / 2 + 4), UDim2.fromOffset(half, h / 2 - 4)
		elseif kind == "topRight" then
			return UDim2.new(0, m + half + 8, 0, top), UDim2.fromOffset(half, h / 2 - 4)
		elseif kind == "bottomRight" then
			return UDim2.new(0, m + half + 8, 0, top + h / 2 + 4), UDim2.fromOffset(half, h / 2 - 4)
		end
		return nil
	end

	dragZone.InputBegan:Connect(function(input, gpe)
		if gpe then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			WM.focus(win)
			local mp = Vector2.new(input.Position.X, input.Position.Y)
			dragOffset = mp - Vector2.new(root.AbsolutePosition.X, root.AbsolutePosition.Y)
			surface:wobble(0.06, 0.03)
			Sfx.play("swipe")
		end
	end)
	local lastTitleClick = 0
	dragZone.MouseButton1Click:Connect(function()
		local now = os.clock()
		if now - lastTitleClick < Config.input.doubleClickMs / 1000 then
			WM.toggleMaximize(win)
		end
		lastTitleClick = now
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not dragging then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			local p = Vector2.new(input.Position.X, input.Position.Y)
			local newX = p.X - dragOffset.X
			local newY = math.max(chromeTop() - 8, p.Y - dragOffset.Y)
			newX = Math.clamp(newX, -sizeSpringX._position + 140, vw.X - 140)
			newY = Math.clamp(newY, chromeTop() - 26, vw.Y - 80)
			posSpringX:set(newX)
			posSpringY:set(newY)
			local kind = detectSnap(p.X, p.Y)
			if kind ~= snapCandidate then
				snapCandidate = kind
				if kind and Config.input.snapAssist then
					local pos, size = snapRectFor(kind)
					showGhost(UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset))
					if WM.snapGhost then
						WM.snapGhost.targetSize = size
						WM.snapGhost.frame.Size = size
					end
				else
					hideGhost()
				end
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if not dragging then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
			hideGhost()
			if snapCandidate then
				local pos, size = snapRectFor(snapCandidate)
				posSpringX:setTarget(pos.X.Offset)
				posSpringY:setTarget(pos.Y.Offset)
				sizeSpringX:setTarget(size.X.Offset)
				sizeSpringY:setTarget(size.Y.Offset)
				win.snapped = snapCandidate
				surface:wobble(0.16, 0.1)
				Sfx.play("windowOpen")
			else
				surface:wobble(0.05, 0.05)
			end
			snapCandidate = nil
			ensureMotion()
		end
	end)

	-- Resize handles -------------------------------------------------------------
	local resizeJobs = {}
	if spec.resizable ~= false then
		local edges = {
			e = { cursor = "RightResize", size = UDim2.new(0, 8, 1, -24), pos = UDim2.new(1, -4, 0, 12) },
			w = { cursor = "LeftResize", size = UDim2.new(0, 8, 1, -24), pos = UDim2.new(0, -4, 0, 12) },
			s = { cursor = "BottomResize", size = UDim2.new(1, -24, 0, 8), pos = UDim2.new(0, 12, 1, -4) },
			n = { cursor = "TopResize", size = UDim2.new(1, -24, 0, 8), pos = UDim2.new(0, 12, 0, -2) },
			se = { cursor = "BottomRightResize", size = UDim2.fromOffset(16, 16), pos = UDim2.new(1, -8, 1, -8) },
			sw = { cursor = "BottomLeftResize", size = UDim2.fromOffset(16, 16), pos = UDim2.new(0, -8, 1, -8) },
			ne = { cursor = "TopRightResize", size = UDim2.fromOffset(16, 16), pos = UDim2.new(1, -8, 0, 6) },
		}
		for name, cfg2 in edges do
			local grip = create("TextButton", {
				Name = "Resize_" .. name,
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				Size = cfg2.size,
				Position = cfg2.pos,
				AnchorPoint = Vector2.new(0.5, 0.5),
				ZIndex = 30,
				Parent = root,
			})
			local resizing = false
			local startInput = nil
			local startGeom = nil
			grip.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					resizing = true
					startInput = Vector2.new(input.Position.X, input.Position.Y)
					startGeom = {
						x = posSpringX._position,
						y = posSpringY._position,
						w = sizeSpringX._position,
						h = sizeSpringY._position,
					}
					WM.focus(win)
					ensureMotion()
					Sfx.play("tick")
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if not resizing or input.UserInputType ~= Enum.UserInputType.MouseMovement then
					return
				end
				local d = Vector2.new(input.Position.X, input.Position.Y) - startInput
				local minW = spec.min and spec.min[1] or Config.layout.minWindowWidth
				local minH = spec.min and spec.min[2] or Config.layout.minWindowHeight
				local nx, ny, nw, nh = startGeom.x, startGeom.y, startGeom.w, startGeom.h
				if name:find("e") then
					nw = math.max(minW, startGeom.w + d.X)
				end
				if name:find("w") then
					nw = math.max(minW, startGeom.w - d.X)
					nx = startGeom.x + (startGeom.w - nw)
				end
				if name:find("s") then
					nh = math.max(minH, startGeom.h + d.Y)
				end
				if name:find("n") then
					nh = math.max(minH, startGeom.h - d.Y)
					ny = math.max(chromeTop() + 2, startGeom.y + (startGeom.h - nh))
				end
				sizeSpringX:set(nw)
				sizeSpringY:set(nh)
				posSpringX:set(nx)
				posSpringY:set(ny)
				win._resizingTo = { w = nw, h = nh, edge = name }
			end)
			UserInputService.InputEnded:Connect(function(input)
				if resizing and input.UserInputType == Enum.UserInputType.MouseButton1 then
					resizing = false
					surface:wobble(0.1, 0.06)
					if win.onResize and win._resizingTo then
						win.onResize(win._resizingTo.w, win._resizingTo.h)
					end
				end
			end)
		end
	end

	win = {
		id = id,
		appId = spec.appId or id,
		surface = surface,
		root = root,
		titlebar = titlebar,
		content = contentInset,
		scroll = scroller,
		list = vlist,
		title = titleLabel,
		subtitle = subLabel,
		spec = spec,
		minimized = false,
		maximized = false,
		snapped = nil,
		preMax = nil,
		posX = posSpringX,
		posY = posSpringY,
		sizeX = sizeSpringX,
		sizeY = sizeSpringY,
		ensureMotion = ensureMotion,
	}
	WM.windows[win.appId] = win
	table.insert(WM.order, win)

	scroller.CanvasPosition = Vector2.new(0, 0)
	local unsubTheme = Theme.register(function(t)
		scroller.ScrollBarImageColor3 = t.dim
	end)
	root.Destroying:Connect(function()
		unsubTheme()
	end)

	-- Reveal: pour the window in from slightly below with a wobble.
	posSpringY:set(startY + 26 + 18)
	sizeSpringX:set(defaultW * 0.9)
	sizeSpringY:set(defaultH * 0.9)
	posSpringX:setTarget(startX)
	posSpringY:setTarget(startY + 26)
	sizeSpringX:setTarget(defaultW)
	sizeSpringY:setTarget(defaultH)
	ensureMotion()
	Sfx.play("windowOpen")

	-- Populate content (the placeholder apps live here) -------------------------
	if spec.content then
		local ok, err = pcall(spec.content, win.content, win)
		if not ok then
			logWarn("window content builder failed:", err)
		end
	end

	WM.focus(win)
	return win
end

function WM.focus(win)
	if win == nil then
		return
	end
	State.focusedWindow = win
	State.activeSurface = win.surface
	table.removeValue(WM.order, win)
	table.insert(WM.order, win)
	State.zCounter += 1
	local z = State.zCounter
	for i, w in WM.order do
		w.root.ZIndex = 1 + i
		w.surface:setFlow(w == win)
		w.surface.body.BackgroundTransparency = (w == win) and 1 - Math.clamp(Config.glass.body + 0.08, 0.2, 0.9)
			or 1 - Math.clamp(Config.glass.body - 0.04, 0.2, 0.9)
	end
	win.surface:wobble(0.02, 0.01)
end

function WM.close(win)
	if win == nil then
		return
	end
	-- Shrink toward the dock while fading: reverse of a launch bounce.
	local sx, sy = win.posX, win.posY
	local sizeX, sizeY = win.sizeX, win.sizeY
	sizeX:setTarget(math.max(90, sizeX._position * 0.6))
	sizeY:setTarget(math.max(70, sizeY._position * 0.6))
	sy:setTarget(sy._position + 120)
	win.ensureMotion()
	Sfx.play("windowClose")
	if win.onClose then
		pcall(win.onClose)
	end
	task.delay(0.32, function()
		if win.surface then
			win.surface:kill()
		end
		WM.windows[win.appId] = nil
		table.removeValue(WM.order, win)
		if State.focusedWindow == win then
			State.focusedWindow = WM.order[#WM.order]
			if State.focusedWindow then
				WM.focus(State.focusedWindow)
			end
		end
	end)
end

function WM.minimize(win)
	if win == nil or win.minimized then
		return
	end
	win.minimized = true
	win.preMin = { x = win.posX._position, y = win.posY._position }
	local vw2 = viewport()
	win.posX:setTarget(vw2.X * 0.5 - 60)
	win.posY:setTarget(vw2.Y - 30)
	win.sizeX:setTarget(120)
	win.sizeY:setTarget(24)
	win.root.ZIndex = 0
	win.ensureMotion()
	Sfx.play("windowClose")
	task.delay(0.34, function()
		if win.minimized then
			win.surface.root.Visible = false
		end
	end)
end

function WM.restore(win)
	if win == nil or not win.minimized then
		return
	end
	win.minimized = false
	win.surface.root.Visible = true
	local pre = win.preMin or { x = 120, y = 90 }
	win.posX:setTarget(pre.x)
	win.posY:setTarget(pre.y)
	win.sizeX:setTarget(win.preMax and win.preMax.w or win.sizeX._position)
	local targetH = win.preMax and win.preMax.h or math.max(Config.layout.minWindowHeight, 300)
	if not win.preMax then
		targetH = math.max(targetH, 220)
	end
	win.sizeY:setTarget(targetH)
	win.ensureMotion()
	WM.focus(win)
	Sfx.play("windowOpen")
end

function WM.toggleMaximize(win)
	if win.maximized then
		win.maximized = false
		local pre = win.preMax
		if pre then
			win.posX:setTarget(pre.x)
			win.posY:setTarget(pre.y)
			win.sizeX:setTarget(pre.w)
			win.sizeY:setTarget(pre.h)
		end
		win.preMax = nil
	else
		win.preMax =
			{ x = win.posX._position, y = win.posY._position, w = win.sizeX._position, h = win.sizeY._position }
		win.maximized = true
		local vw2 = viewport()
		local m = Config.layout.snapMargin
		local top = chromeTop() + m
		local dock = Config.layout.dockSize + m + 10
		win.posX:setTarget(m)
		win.posY:setTarget(top)
		win.sizeX:setTarget(vw2.X - m * 2)
		win.sizeY:setTarget(vw2.Y - top - dock)
	end
	win.snapped = nil
	win.ensureMotion()
	win.surface:wobble(0.22, 0.12)
	Sfx.play("windowOpen")
end

WM.isAnyOpen = function()
	return next(WM.windows) ~= nil
end

-- Mission control (exposé) --------------------------------------------------------
local MC = { active = false, saved = nil }
Nocturne.MissionControl = MC

function MC.toggle()
	if MC.active then
		MC.exit()
	else
		MC.enter()
	end
end

function MC.enter()
	if MC.active then
		return
	end
	local wins = table.clone(WM.order)
	if #wins == 0 then
		return
	end
	MC.active = true
	State.missionControl = true
	Depth.push(false)
	MC.saved = {}
	local vw2 = viewport()
	local cols = math.ceil(math.sqrt(#wins))
	local rows = math.ceil(#wins / cols)
	local cellW = (vw2.X - 80) / cols
	local cellH = (vw2.Y - 150) / rows
	for i, win in wins do
		MC.saved[win] = {
			x = win.posX._position,
			y = win.posY._position,
			w = win.sizeX._position,
			h = win.sizeY._position,
			min = win.minimized,
		}
		win.minimized = false
		win.surface.root.Visible = true
		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)
		local targetW = math.max(240, cellW - 28)
		local targetH = targetW * (MC.saved[win].h / math.max(1, MC.saved[win].w))
		if targetH > cellH - 40 then
			targetH = cellH - 40
			targetW = targetH * (MC.saved[win].w / math.max(1, MC.saved[win].h))
		end
		win.posX:setTarget(40 + col * cellW + (cellW - targetW) / 2)
		win.posY:setTarget(60 + row * cellH + (cellH - targetH) / 2)
		win.sizeX:setTarget(targetW)
		win.sizeY:setTarget(targetH)
		win.ensureMotion()
		win.surface:setFlow(false)
	end
	-- Dim veil so the floating windows pop.
	local veil = create("Frame", {
		Name = "MCVeil",
		BackgroundColor3 = Color3.fromRGB(4, 6, 10),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 400,
		Parent = App.layers.overlay,
	})
	MC.veil = veil
	local t = TweenService:Create(veil, TweenInfo.new(0.32), { BackgroundTransparency = 0.38 })
	t:Play()
	local hint = W.label(App.layers.overlay, {
		text = "click a window to open it  ·  esc to leave",
		size = 12,
		color = "dim",
		anchor = Vector2.new(0.5, 0),
		position = UDim2.new(0.5, 0, 0, 22),
		zIndex = 460,
	})
	hint.Name = "MCHint"
	MC.hint = hint
	Sfx.play("swipe")
end

function MC.exit()
	if not MC.active then
		return
	end
	MC.active = false
	State.missionControl = false
	Depth.pop(false)
	for _, w in WM.order do
		if w._mcClick then
			w._mcClick:Destroy()
			w._mcClick = nil
		end
	end
	for win, geom in MC.saved do
		win.posX:setTarget(geom.x)
		win.posY:setTarget(geom.y)
		win.sizeX:setTarget(geom.w)
		win.sizeY:setTarget(geom.h)
		win.ensureMotion()
		win.minimized = geom.min
		if geom.min then
			task.delay(0.3, function()
				if win.minimized then
					win.surface.root.Visible = false
				end
			end)
		end
	end
	if MC.veil then
		local v = MC.veil
		local t = TweenService:Create(v, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
		t.Completed:Connect(function()
			v:Destroy()
		end)
		t:Play()
		MC.veil = nil
	end
	if MC.hint then
		local h2 = MC.hint
		TweenService:Create(h2, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
		task.delay(0.24, function()
			pcall(h2.Destroy, h2)
		end)
		MC.hint = nil
	end
	Sfx.play("swipe")
end

-- Click-through capture while in mission control.
Scheduler.schedule(function()
	if not MC.active then
		return
	end
	for _, win in WM.order do
		if win.root.Parent then
			-- raise click handlers lazily once
			if not win._mcClick then
				local clicker = create("TextButton", {
					Name = "MCClick",
					BackgroundTransparency = 1,
					Text = "",
					AutoButtonColor = false,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 200,
					Parent = win.root,
				})
				clicker.MouseButton1Click:Connect(function()
					MC.exit()
					WM.focus(win)
				end)
				win._mcClick = clicker
			end
		end
	end
end, { name = "mcWatch", rate = 4, priority = 3 })

function MC.isActive()
	return MC.active
end
-- Forward reference: the notification system is defined in a later section.
local Notifications = {}

--═══════════════════════════════════════════════════════════════════════════════--
-- § 13  MENUS — shared popover menu used by the menu bar, dock right-clicks and
--         the desktop context menu. One implementation, three consumers.
--═══════════════════════════════════════════════════════════════════════════════--

local Menu = {
	openMenus = {},
}
Nocturne.Menu = Menu

-- item: { label, icon, shortcut, checked, disabled, kind="default"|"danger",
--         divider=true, submenu={...}, onHover, onClick }
function Menu.open(opts)
	-- opts: { items, position (UDim2 offset-space), anchorItem, width, align="left"|"right" }
	local layer = App.layers and App.layers.overlay
	if not layer then
		return nil
	end
	Menu.closeAll()
	local items = opts.items or {}
	local width = opts.width or 230
	local rowH = 28
	local height = 10
	for _, item in items do
		height += item.divider and 9 or rowH
	end

	local surface = Glass.new(layer, {
		name = "Menu",
		size = UDim2.fromOffset(width, 10),
		position = opts.position or UDim2.fromOffset(40, 40),
		anchor = Vector2.new(0, 0),
		roundness = 14,
		tint = 0.30,
		caustics = false,
		interactive = true,
		shadow = true,
	})
	surface:setTint(0.34)

	local springH = Spring.new(0, Config.motion.springBouncy, { precision = 0.6 })
	local springW = Spring.new(width * 0.8, Config.motion.springBouncy, { precision = 0.6 })
	local job
	local function drive()
		if job then
			return
		end
		job = Scheduler.schedule(function(dt)
			local a = springH:step(dt)
			local b = springW:step(dt)
			surface.root.Size = UDim2.fromOffset(math.max(120, springW._position), math.max(8, springH._position))
			if a and b then
				Scheduler.unschedule(job)
				job = nil
			end
		end, { name = "menu", rate = "frame", priority = 1 })
	end
	springW:setTarget(width)
	springH:setTarget(height)
	drive()
	Depth.push(false)

	local list = surface.content
	create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	create("UIPadding", {
		PaddingTop = UDim.new(0, 5),
		PaddingBottom = UDim.new(0, 5),
		PaddingLeft = UDim.new(0, 5),
		PaddingRight = UDim.new(0, 5),
		Parent = list,
	})

	local highlight = create("Frame", {
		Name = "SlideHighlight",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9,
		Size = UDim2.new(1, -10, 0, rowH - 4),
		Position = UDim2.new(0, 5, 0, 0),
		ZIndex = 1,
		Parent = list,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 9), Parent = highlight })
	local hlY = Spring.new(0, Config.motion.springQuick, { precision = 0.08 })
	local hlVisible = Spring.new(0, Config.motion.spring)
	local hlJob
	local function hlDrive()
		if hlJob then
			return
		end
		hlJob = Scheduler.schedule(function(dt)
			local a = hlY:step(dt)
			local b = hlVisible:step(dt)
			highlight.Position = UDim2.new(0, 5, 0, hlY._position)
			highlight.BackgroundTransparency = 0.92 - hlVisible._position * 0.45
			if a and b then
				Scheduler.unschedule(hlJob)
				hlJob = nil
			end
		end, { name = "menuHl", rate = "frame", priority = 1 })
	end

	local menu = { surface = surface, items = items, rowH = rowH, index = 0, subMenu = nil }
	local order = 0

	local function buildRow(item, rowY, container, zIndexBase)
		order += 1
		if item.divider then
			local divHolder = create("Frame", {
				Name = "Divider",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 9),
				LayoutOrder = order,
				Parent = container,
			})
			local d = W.divider(divHolder)
			d.Position = UDim2.new(0, 10, 0.5, 0)
			return
		end
		local row = create("Frame", {
			Name = "Item_" .. (item.label or "?"),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -10, 0, rowH - 4),
			LayoutOrder = order,
			ZIndex = zIndexBase,
			Parent = container,
		})
		local rowBtn = create("TextButton", {
			Name = "Click",
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.fromScale(1, 1),
			ZIndex = row.ZIndex + 2,
			Parent = row,
		})
		local padL = 8
		if item.icon then
			local ic = IconKit.attach(row, item.icon, { size = 14 })
			ic.frame.AnchorPoint = Vector2.new(0, 0.5)
			ic.frame.Position = UDim2.fromOffset(8, row.AbsoluteSize.Y / 2)
			rowBtn.MouseEnter:Connect(function() end)
			padL = 30
			row._icon = ic
		end
		if item.checked ~= nil then
			local mark = IconKit.attach(row, item.checked and "check" or "minus", { size = 10 })
			mark.frame.AnchorPoint = Vector2.new(0, 0.5)
			mark.frame.Position = UDim2.fromOffset(6, row.AbsoluteSize.Y / 2)
			padL = math.max(padL, 22)
			row._mark = mark
		end
		local label = W.label(row, {
			text = item.label or "—",
			size = 12.5,
			weight = "medium",
			color = item.kind == "danger" and "danger" or "text",
			position = UDim2.new(0, padL, 0.5, 0),
			zIndex = row.ZIndex + 3,
			truncate = true,
		})
		label.AnchorPoint = Vector2.new(0, 0.5)
		label.Size = UDim2.new(1, -(padL + 60), 1, 0)
		if item.shortcut then
			local sc = W.label(row, {
				text = item.shortcut,
				size = 11,
				weight = "medium",
				color = "faint",
				position = UDim2.new(1, -10, 0.5, 0),
				zIndex = row.ZIndex + 3,
			})
			sc.AnchorPoint = Vector2.new(1, 0.5)
		end
		if item.submenu then
			local chev = IconKit.attach(row, "chevronRight", { size = 11, color = "faint" })
			chev.frame.AnchorPoint = Vector2.new(1, 0.5)
			chev.frame.Position = UDim2.new(1, -8, 0.5, 0)
		end
		row.LayoutOrder = order
		rowBtn.MouseEnter:Connect(function()
			hlY:setTarget(row.Position.Y.Offset + 2)
			hlVisible:setTarget(1)
			hlDrive()
			Sfx.play("hover")
			if item.onHover then
				item.onHover()
			end
			if item.submenu and menu.surface then
				-- Lazy-open a nested menu to the right.
				local pos = UDim2.fromOffset(
					surface.root.AbsolutePosition.X + surface.root.AbsoluteSize.X - 6,
					surface.root.AbsolutePosition.Y + row.Position.Y.Offset
				)
				Menu.openSub(menu, item.submenu, pos)
			elseif menu.subMenu then
				menu.subMenu:kill()
				menu.subMenu = nil
			end
		end)
		rowBtn.MouseButton1Click:Connect(function()
			local ok, err = pcall(function()
				if item.onClick then
					item.onClick(item, menu)
				end
				if not item.keepOpen then
					Menu.closeAll()
				end
			end)
			if not ok then
				logWarn("menu action:", err)
			end
			Sfx.play("click")
		end)
		return row
	end

	for _, item in items do
		buildRow(item, 0, list, 2)
	end

	-- Staggered row reveal: opacity + tiny slide, per row, 14ms apart.
	do
		local children = {}
		for _, ch in list:GetChildren() do
			if ch:IsA("Frame") and ch.Name:sub(1, 4) == "Item" then
				table.insert(children, ch)
			end
		end
		for i, row in children do
			local delay = i * 0.014
			task.delay(delay, function()
				local spring = Spring.new(0, Config.motion.springQuick)
				local j
				j = Scheduler.schedule(function(dt)
					local rest = spring:step(dt)
					for _, ch2 in row:GetChildren() do
						if ch2:IsA("TextLabel") then
							ch2.TextTransparency = (1 - Math.clamp01(spring._position)) * 1
						end
					end
					row.Position = UDim2.new(
						row.Position.X.Scale,
						row.Position.X.Offset,
						row.Position.Y.Scale,
						row.Position.Y.Offset + (1 - Math.clamp01(spring._position)) * 4
					)
					if rest then
						Scheduler.unschedule(j)
					end
				end, { name = "menuReveal", rate = "frame", priority = 2 })
				spring:setTarget(1)
			end)
		end
	end

	-- Outside-click + escape dismissal, armed next frame so the opening click
	-- does not instantly close it.
	task.defer(function()
		local conn
		conn = UserInputService.InputBegan:Connect(function(input, gpe)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				local p = Vector2.new(input.Position.X, input.Position.Y)
				local ap, as = surface.root.AbsolutePosition, surface.root.AbsoluteSize
				if not Math.pointInRect(p.X, p.Y, ap.X - 4, ap.Y - 4, as.X + 8, as.Y + 8) then
					Menu.closeAll()
				end
			elseif input.KeyCode == Enum.KeyCode.Escape then
				Menu.closeAll()
			end
		end)
		menu._outside = conn
	end)

	function menu:kill()
		if menu._outside then
			menu._outside:Disconnect()
		end
		if menu.subMenu then
			menu.subMenu:kill()
		end
		Depth.pop(false)
		surface:kill()
		local idx = T.indexOf(Menu.openMenus, menu)
		if idx then
			table.remove(Menu.openMenus, idx)
		end
	end

	table.insert(Menu.openMenus, menu)
	return menu
end

function Menu.openSub(parentMenu, items, position)
	if parentMenu.subMenu then
		parentMenu.subMenu:kill()
	end
	local sub = Menu.open({ items = items, position = position, width = 190 })
	parentMenu.subMenu = sub
	return sub
end

function Menu.closeAll()
	local snapshot = table.clone(Menu.openMenus)
	for _, m in snapshot do
		m:kill()
	end
end

Menu.anyOpen = function()
	return #Menu.openMenus > 0
end

--═══════════════════════════════════════════════════════════════════════════════--
-- § 13b  DOCK — magnifying glass shelf, the macOS signature
--
-- Icons scale with a gaussian falloff around the cursor; the whole shelf stretches
-- to accommodate (springed, so neighbours shove each other like real magnified
-- icons do); running apps get a dot; launching gets the genie bounce.
--═════════════════════════════════════════════════════════════════════════════--

local Dock = {
	visible = true,
	apps = {},
	instances = {},
	root = nil,
	surface = nil,
	widthSpring = nil,
}
Nocturne.Dock = Dock

local function dockAppIcon(app, index)
	local size = Config.layout.dockSize
	local slot = create("Frame", {
		Name = "Dock_" .. app.id,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size + 12),
		AnchorPoint = Vector2.new(0.5, 1),
		ZIndex = 5,
		Parent = Dock.row,
	})
	local iconHolder = create("Frame", {
		Name = "IconHolder",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size),
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		ZIndex = slot.ZIndex,
		Parent = slot,
	})
	local scale = create("UIScale", { Scale = 1, Parent = iconHolder })
	local posLift = create("UIAspectRatioConstraint", { AspectRatio = 1, Parent = iconHolder })
	local tile = create(Capabilities.canvasGroup and "CanvasGroup" or "Frame", {
		Name = "Tile",
		BackgroundColor3 = app.color or Color3.fromRGB(60, 70, 90),
		BackgroundTransparency = 0.14,
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		ZIndex = iconHolder.ZIndex,
		Parent = iconHolder,
	})
	create("UICorner", { CornerRadius = UDim.new(0, size * 0.24), Parent = tile })
	create("UIStroke", { Transparency = 0.5, Thickness = 1, Parent = tile })
	local grad = create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.05),
			NumberSequenceKeypoint.new(1, 0.3),
		}),
		Parent = tile,
	})
	local ic = IconKit.attach(tile, app.icon or "grid", { size = size * 0.5, subscribeToTheme = true, dim = 0 })
	ic.frame.AnchorPoint = Vector2.new(0.5, 0.5)
	ic.frame.Position = UDim2.fromScale(0.5, 0.5)
	ic.frame.ZIndex = tile.ZIndex + 2
	local dot = create("Frame", {
		Name = "RunningDot",
		BackgroundColor3 = Color3.fromRGB(235, 240, 250),
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(4, 4),
		Position = UDim2.new(0.5, 0, 1, 2),
		ZIndex = 6,
		Parent = slot,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
	local bounce = Spring.new(0, Config.motion.springBouncy, { precision = 0.08 })
	local mag = Spring.new(1, Config.motion.springQuick)
	local hoverLbl = W.label(slot, {
		text = app.label,
		size = 11,
		weight = "bold",
		color = "text",
		align = "Center",
		position = UDim2.new(0.5, 0, 0, -16),
		anchor = Vector2.new(0.5, 0.5),
		size2 = { 90, 14 },
		zIndex = 30,
		truncate = true,
	})
	hoverLbl.TextTransparency = 1

	local click = create("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 20,
		Parent = slot,
	})

	local state = {
		app = app,
		slot = slot,
		scale = scale,
		mag = mag,
		bounce = bounce,
		tile = tile,
		dot = dot,
		label = hoverLbl,
		icon = ic,
		setRunning = function(running)
			dot.BackgroundTransparency = running and 0.1 or 1
		end,
	}

	local job
	local function ensureJob()
		if job then
			return
		end
		job = Scheduler.schedule(function(dt)
			local a = bounce:step(dt)
			local b = mag:step(dt)
			iconHolder.Position = UDim2.new(0.5, 0, 1, -8 + bounce._position)
			scale.Scale = mag._position
			if a and b then
				Scheduler.unschedule(job)
				job = nil
			end
		end, { name = "dockItem", rate = "frame", priority = 1 })
	end

	click.MouseButton1Click:Connect(function()
		-- The bounce: rise, overshoot, settle, like the icon is on a spring board.
		bounce:set(0)
		ensureJob()
		task.spawn(function()
			for i = 1, 2 do
				bounce:setTarget(-14)
				ensureJob()
				task.wait(0.13)
				bounce:setTarget(0)
				ensureJob()
				task.wait(0.15)
			end
		end)
		Sfx.play("tap")
		if app.onLaunch then
			task.spawn(function()
				local ok, err = pcall(app.onLaunch, app)
				if not ok then
					logWarn("dock launch failed:", err)
				end
			end)
		else
			WM.toggle(app.id)
		end
	end)
	click.MouseEnter:Connect(function()
		hoverLbl.TextTransparency = 0.1
		state.hover = true
		Sfx.play("hover")
	end)
	click.MouseLeave:Connect(function()
		hoverLbl.TextTransparency = 1
		state.hover = false
	end)
	click.MouseButton2Down:Connect(function()
		Menu.open({
			items = {
				{
					label = "Open",
					icon = "window",
					onClick = function()
						WM.toggle(app.id)
					end,
				},
				{
					label = "Show in mission control",
					icon = "grid",
					onClick = function()
						Nocturne.MissionControl.enter()
					end,
				},
				{ divider = true },
				{
					label = "Quit placeholder",
					icon = "power",
					kind = "danger",
					onClick = function()
						Nocturne.Notifications.push({
							title = app.label,
							body = "There is nothing to quit. This is all glass.",
							icon = "info",
						})
					end,
				},
			},
			position = UDim2.fromOffset(click.AbsolutePosition.X - 60, click.AbsolutePosition.Y - 140),
			width = 220,
		})
	end)

	-- Bounce offset + magnification both write one position from the job above.
	ensureJob()
	Dock.instances[app.id] = state
	return state
end

function Dock.build(apps)
	if Dock.root then
		return Dock.root
	end
	local layer = App.layers and App.layers.chrome
	if not layer then
		return nil
	end
	Dock.apps = apps
	local size = Config.layout.dockSize
	local n = #apps
	local baseW = n * (size + 10) + 24

	local surface = Glass.new(layer, {
		name = "Dock",
		size = UDim2.fromOffset(baseW, size + 26),
		position = UDim2.new(0.5, 0, 1, -14),
		anchor = Vector2.new(0.5, 1),
		roundness = 26,
		tint = 0.34,
		caustics = true,
		shadow = true,
		interactive = true,
	})
	Dock.surface = surface
	Dock.root = surface.root
	Dock.row = create("Frame", {
		Name = "DockRow",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 12,
		Parent = surface.content,
	})
	local layout = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, Config.layout.dockGap),
		Parent = Dock.row,
	})

	Dock.widthSpring = Spring.new(baseW, Config.motion.spring)
	Dock.baseW = baseW
	Dock.itemW = size + Config.layout.dockGap

	for i, app in apps do
		local st = dockAppIcon(app, i)
		st.slot.LayoutOrder = i
	end

	-- One pump for the whole magnification field.
	Scheduler.schedule(function(dt)
		if not Dock.visible or not Dock.root then
			return
		end
		local mx = Cursor.position.X
		local ap = Dock.row.AbsolutePosition
		local asz = Dock.row.AbsoluteSize
		local magnify = Config.layout.dockMagnify
		local sigma = asz.X / math.max(4, #Dock.apps * 2.1)
		for _, app in Dock.apps do
			local st = Dock.instances[app.id]
			if st then
				local cx = st.slot.AbsolutePosition.X + st.slot.AbsoluteSize.X / 2
				local d = (mx - cx) / math.max(40, sigma)
				local bell = math.exp(-0.5 * d * d)
				local targetScale = 1 + (magnify - 1) * bell
				if math.abs(st.mag:getTarget() - targetScale) > 0.012 then
					st.mag:setTarget(targetScale)
				end
				if st.hover then
					st.label.TextTransparency = 0.1
				end
			end
		end
		local stretch = 1
			+ (magnify - 1)
				* 0.55
				* math.exp(-0.5 * math.pow(((mx - (ap.X + asz.X / 2)) / math.max(80, asz.X * 0.7)), 2))
		Dock.widthSpring:setTarget(Dock.baseW * stretch)
	end, { name = "dockMag", rate = "frame", priority = 2 })

	-- Width spring writes back to the surface each frame it moves.
	do
		local job
		job = Scheduler.schedule(function(dt)
			local rest = Dock.widthSpring:step(dt)
			Dock.root.Size = UDim2.fromOffset(Dock.widthSpring._position, Config.layout.dockSize + 26)
			if rest then
				Scheduler.unschedule(job)
				task.delay(0.5, function() end)
			end
		end, { name = "dockWidth", rate = "frame", priority = 2 })
	end

	-- Slide in from below on first build.
	do
		local slide = Spring.new(90, Config.motion.springCinematic)
		local j
		j = Scheduler.schedule(function(dt)
			local rest = slide:step(dt)
			Dock.root.Position = UDim2.new(0.5, 0, 1, -14 + slide._position)
			if rest then
				Scheduler.unschedule(j)
			end
		end, { name = "dockSlide", rate = "frame", priority = 1 })
		slide:setTarget(0)
	end

	Tooltip.attach(Dock.root, "The dock is a placeholder. So is everything. Relax.", "above")
	return Dock.root
end

function Dock.setAppRunning(appId, running)
	local st = Dock.instances[appId]
	if st then
		st.setRunning(running)
	end
end

function Dock.toggle()
	Dock.visible = not Dock.visible
	State.dockVisible = Dock.visible
	if Dock.root then
		local slide = Spring.new(Dock.visible and 90 or 0, Config.motion.springCinematic)
		local j
		j = Scheduler.schedule(function(dt)
			local rest = slide:step(dt)
			Dock.root.Position = UDim2.new(0.5, 0, 1, -14 + slide._position)
			Dock.root.Visible = slide._position < 88
			if rest then
				Scheduler.unschedule(j)
			end
		end, { name = "dockToggle", rate = "frame", priority = 1 })
		slide:setTarget(Dock.visible and 0 or 90)
	end
	Sfx.play(Dock.visible and "swipe" or "windowClose")
end

WM.toggle = function(appId)
	local win = WM.windows[appId]
	if win then
		if win.minimized then
			WM.restore(win)
		else
			WM.focus(win)
		end
	else
		local appDef = Nocturne.Apps and Nocturne.Apps[appId]
		if appDef and appDef.open then
			appDef.open()
		end
	end
	Dock.setAppRunning(appId, true)
end
--═══════════════════════════════════════════════════════════════════════════════--
-- § 13c  MENU BAR + STATUS + CONTROL CENTRE
--═══════════════════════════════════════════════════════════════════════════════--

local MenuBar = {
	visible = true,
	root = nil,
	menus = {},
	clock = nil,
	ampm = nil,
	openMenu = nil,
}
Nocturne.MenuBar = MenuBar

function MenuBar.build()
	if MenuBar.root then
		return MenuBar.root
	end
	local layer = App.layers and App.layers.chrome
	if not layer then
		return nil
	end
	local h = Config.layout.menuBarHeight
	local root = create("Frame", {
		Name = "MenuBar",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 0, h),
		Position = UDim2.new(0, 8, 0, 4),
		ZIndex = 5,
		Parent = layer,
	})
	local bar = create(Capabilities.canvasGroup and "CanvasGroup" or "Frame", {
		Name = "Bar",
		BackgroundColor3 = Color3.fromRGB(14, 17, 23),
		BackgroundTransparency = 0.5,
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		Parent = root,
	})
	create("UICorner", { CornerRadius = UDim.new(0, h / 2), Parent = bar })
	create("UIStroke", { Transparency = 0.72, Thickness = 1, Parent = bar })
	create("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(1, 0.5),
		}),
		Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
		Parent = bar,
	})
	MenuBar.root = root
	MenuBar.bar = bar

	-- Logo mark: ring + inner dot, the Nocturne monogram.
	local logoHolder = create("TextButton", {
		Name = "Logo",
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromOffset(34, h),
		Position = UDim2.new(0, 6, 0, 0),
		ZIndex = 7,
		Parent = bar,
	})
	local ring = create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(15, 15),
		Position = UDim2.fromScale(0.5, 0.5),
		ZIndex = 8,
		Parent = logoHolder,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ring })
	local ringStroke = create("UIStroke", { Thickness = 2.2, Transparency = 0.1, Parent = ring })
	local dot = create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(4.5, 4.5),
		Position = UDim2.new(0.5, 0, 0.5, -3.4),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		ZIndex = 8,
		Parent = ring,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
	local ringSpin = create("UIRotation", { Angle = 0, Parent = ring })
	local spinning = 0
	logoHolder.MouseButton1Click:Connect(function()
		spinning += math.pi * 2
		Sfx.play("tap")
		Notifications.wave()
	end)
	Scheduler.schedule(function(dt)
		if math.abs(ringSpin.Angle - spinning) > 0.004 then
			ringSpin.Angle = Math.damp(ringSpin.Angle, spinning, 5, dt)
		end
	end, { name = "logo", rate = "frame", priority = 3 })

	-- Menus -------------------------------------------------------------------
	local menuDefs = {
		Nocturne = {
			{
				label = "About Nocturne",
				icon = "info",
				onClick = function()
					Notifications.push({
						title = "Nocturne UI",
						body = "Liquid glass framework · v"
							.. Nocturne.VERSION
							.. " · MIT licensed · zero assets, zero features, zero regrets.",
						icon = "sparkle",
					})
				end,
			},
			{
				label = "Settings…",
				icon = "gear",
				shortcut = "⌃,",
				onClick = function()
					Nocturne.Apps.settings.open()
				end,
			},
			{ divider = true },
			{
				label = "Change theme",
				icon = "palette",
				submenu = {
					{
						label = "Obsidian",
						icon = "moon",
						onClick = function()
							Theme.apply("obsidian")
						end,
					},
					{
						label = "Midnight",
						icon = "moon",
						onClick = function()
							Theme.apply("midnight")
						end,
					},
					{
						label = "Nebula",
						icon = "sparkle",
						onClick = function()
							Theme.apply("nebula")
						end,
					},
					{
						label = "Abyss",
						icon = "globe",
						onClick = function()
							Theme.apply("abyss")
						end,
					},
					{
						label = "Porcelain",
						icon = "sun",
						onClick = function()
							Theme.apply("porcelain")
						end,
					},
				},
			},
			{
				label = "Accent",
				icon = "wand",
				submenu = (function()
					local out = {}
					for _, a in Theme.accentList() do
						table.insert(out, {
							label = a.label,
							onClick = function()
								Theme.setAccent(a.id)
							end,
						})
					end
					return out
				end)(),
			},
			{ divider = true },
			{
				label = "Hide all windows",
				icon = "eyeoff",
				onClick = function()
					for _, w in table.clone(WM.order) do
						WM.close(w)
					end
				end,
			},
			{
				label = "Lock screen",
				icon = "lock",
				shortcut = "⌃⇧L",
				onClick = function()
					Nocturne.Boot.lock()
				end,
			},
		},
		File = {
			{
				label = "New window",
				icon = "plus",
				onClick = function()
					WM.open({
						title = "Untitled glass",
						icon = "window",
						size = { 420, 300 },
						content = function(parent)
							W.label(parent, {
								text = "A fresh placeholder. Nothing in here is connected to anything, by design.",
								size = 13,
								color = "dim",
								wrapped = true,
								anchor = Vector2.new(0, 0),
								position = UDim2.new(0, 0, 0, 6),
								size2 = { 340, 60 },
							})
						end,
					})
				end,
			},
			{
				label = "Duplicate panel",
				icon = "copy",
				onClick = function()
					Notifications.push({
						title = "Copy",
						body = "Placeholder action — there is nothing to duplicate but vibes.",
						icon = "copy",
					})
				end,
			},
			{ divider = true },
			{
				label = "Export theme JSON",
				icon = "download",
				onClick = function()
					local ok = pcall(function()
						local tokens = Theme.tokens()
						local payload = {
							theme = State.currentTheme,
							accent = State.currentAccent,
							glass = Config.glass,
							motion = Config.motion.springQuick,
						}
						local encoded = HttpService:JSONEncode(payload)
						print("[Nocturne] theme export:\n" .. encoded)
						pcall(function()
							if writefile and isfile and isfolder("NocturneExports") then
								writefile("NocturneExports/theme.json", encoded)
							end
						end)
						Notifications.push({
							title = "Exported",
							body = "Theme JSON printed to the console (Studio) or saved to NocturneExports/.",
							icon = "download",
							kind = "success",
						})
					end)
					if not ok then
						Notifications.push({
							title = "Export failed",
							body = "This environment blocked the export. Console only, sorry.",
							icon = "warning",
							kind = "warning",
						})
					end
				end,
			},
		},
		View = {
			{
				label = "Mission control",
				icon = "grid",
				shortcut = "⌃E",
				onClick = function()
					Nocturne.MissionControl.toggle()
				end,
			},
			{
				label = "Show dock",
				checked = true,
				icon = "dock",
				onClick = function()
					Dock.toggle()
				end,
			},
			{
				label = "Wallpaper drift",
				checked = true,
				icon = "sparkle",
				onClick = function()
					Nocturne.Wallpaper.toggle()
				end,
			},
			{ divider = true },
			{
				label = "Reduce motion",
				checked = State.reduceMotion,
				icon = "eye",
				onClick = function()
					Config.accessibility.reduceMotion = not Config.accessibility.reduceMotion
					State.reduceMotion = Config.accessibility.reduceMotion
					Notifications.push({
						title = "Motion",
						body = State.reduceMotion and "Reduced. Springs are calmer now."
							or "Full liquid motion restored.",
						icon = "sparkles",
						kind = "info",
					})
				end,
			},
			{
				label = "Higher contrast",
				checked = State.contrastBoost,
				icon = "sun",
				onClick = function()
					State.contrastBoost = not State.contrastBoost
					Theme.apply(State.currentTheme, State.currentAccent)
				end,
			},
		},
		Window = {
			{
				label = "Cascade",
				icon = "layers",
				onClick = function()
					WM.cascade()
				end,
			},
			{
				label = "Tidy up",
				icon = "grid",
				onClick = function()
					WM.tile()
				end,
			},
			{ divider = true },
			{
				label = "Minimise",
				icon = "minus",
				shortcut = "⌃M",
				onClick = function()
					local w = State.focusedWindow
					if w then
						WM.minimize(w)
					end
				end,
			},
			{
				label = "Zoom",
				icon = "window",
				onClick = function()
					local w = State.focusedWindow
					if w then
						WM.toggleMaximize(w)
					end
				end,
			},
		},
		Help = {
			{
				label = "Command palette…",
				icon = "search",
				shortcut = "⌃K",
				onClick = function()
					Nocturne.Spotlight.toggle()
				end,
			},
			{
				label = "Hotkeys cheat sheet",
				icon = "keyboard",
				onClick = function()
					Nocturne.Apps.cheats.open()
				end,
			},
			{ divider = true },
			{
				label = "Try the Konami code",
				icon = "gamepad",
				onClick = function()
					Notifications.push({
						title = "Achievement unlocked",
						body = "Now actually type it: ↑ ↑ ↓ ↓ ← → ← → B A.",
						icon = "star",
						kind = "success",
					})
				end,
			},
		},
	}

	local leftX = 34 + 8
	local orderIdx = 0
	for _, menuName in { "Nocturne", "File", "Edit", "View", "Window", "Help" } do
		orderIdx += 1
		local label = (menuName == "Nocturne") and "Nocturne" or menuName
		local btn = create("TextButton", {
			Name = "Menu_" .. menuName,
			BackgroundTransparency = 1,
			Text = " " .. label .. " ",
			Font = fontBy(menuName == "Nocturne" and "bold" or "medium"),
			TextSize = 12.5 * Config.accessibility.largerText,
			AutoButtonColor = false,
			Size = UDim2.fromOffset(#label * 7.4 + 18, h),
			Position = UDim2.fromOffset(leftX, 0),
			ZIndex = 8,
			Parent = bar,
		})
		leftX += #label * 7.4 + 18
		local hoverBg = create("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -4, 1, -6),
			Position = UDim2.new(0, 2, 0, 3),
			ZIndex = 7,
			Parent = btn,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = hoverBg })
		if menuDefs[menuName] then
			MenuBar.menus[label] = { button = btn, items = menuDefs[menuName], hoverBg = hoverBg }
		end
		btn.MouseEnter:Connect(function()
			hoverBg.BackgroundTransparency = 0.9
			if MenuBar.openMenu and MenuBar.openMenu ~= label then
				btn.MouseButton1Click:Fire()
			end
		end)
		btn.MouseLeave:Connect(function()
			hoverBg.BackgroundTransparency = 1
		end)
		btn.MouseButton1Click:Connect(function()
			local items = menuDefs[menuName]
			if items == nil then
				Notifications.push({
					title = "Placeholder",
					body = menuName .. " exists purely to complete the vibe.",
					icon = "warning",
				})
				return
			end
			if MenuBar.openMenu == label then
				Menu.closeAll()
				MenuBar.openMenu = nil
				return
			end
			MenuBar.openMenu = label
			Menu.open({
				items = items,
				position = UDim2.fromOffset(btn.AbsolutePosition.X, h + 8),
				width = math.max(200, #label + 200),
			})
		end)
	end

	-- Right side: status cluster ------------------------------------------------
	local status = create("Frame", {
		Name = "Status",
		BackgroundTransparency = 1,
		Size = UDim2.new(0, 330, 1, 0),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 0),
		ZIndex = 8,
		Parent = bar,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 2),
		Parent = status,
	})

	local function statusBtn(name, icon, size, layoutOrder, onClick, tooltip)
		local b = W.iconButton(status, {
			icon = icon,
			size = size or 26,
			variant = "ghost",
			iconSize = (size or 26) * 0.52,
			zIndex = 9,
			onClicked = onClick,
		})
		b.holder.LayoutOrder = layoutOrder
		b.holder.Name = "Status_" .. name
		if tooltip then
			Tooltip.attach(b.holder, tooltip)
		end
		return b
	end

	statusBtn("search", "search", 26, 5, function()
		Nocturne.Spotlight.toggle()
	end, "Command palette  ·  ⌃K")

	-- Clock + battery + wifi as text/mini widgets ------------------------------
	local clockHolder = create("Frame", {
		Name = "Clock",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(96, h),
		LayoutOrder = 4,
		ZIndex = 8,
		Parent = status,
	})
	MenuBar.clock = W.label(clockHolder, {
		text = "--:--",
		size = 12.5,
		weight = "bold",
		color = "text",
		align = "Center",
		position = UDim2.new(0.5, -8, 0.5, 0),
		anchor = Vector2.new(0.5, 0.5),
		size2 = { 80, h },
	})
	local function tickClock()
		local t = os.date("*t")
		if t then
			local hour12 = t.hour % 12
			if hour12 == 0 then
				hour12 = 12
			end
			MenuBar.clock.Text = string.format("%d:%02d %@", hour12, t.min, t.hour >= 12 and "PM" or "AM")
		else
			MenuBar.clock.Text = os.date("!%H:%M")
		end
	end
	tickClock()
	Scheduler.schedule(tickClock, { name = "clock", rate = 0.5, priority = 8 })

	-- Battery: drawn pill with fill + percent text.
	local battery = create("Frame", {
		Name = "Battery",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(58, h),
		LayoutOrder = 3,
		ZIndex = 8,
		Parent = status,
	})
	local pctText = W.label(battery, {
		text = "78%",
		size = 11.5,
		weight = "medium",
		color = "dim",
		align = "Center",
		position = UDim2.new(0, 0, 0.5, 0),
		anchor = Vector2.new(0, 0.5),
		size2 = { 26, h },
	})
	local shell = create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(23, 11),
		Position = UDim2.new(0, 28, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ZIndex = 9,
		Parent = battery,
	})
	local shellStroke = create("UIStroke", { Thickness = 1.1, Transparency = 0.25, Parent = shell })
	create("UICorner", { CornerRadius = UDim.new(0, 3.4), Parent = shell })
	local nub = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.6,
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(2, 4),
		Position = UDim2.new(1, 1, 0.5, 0),
		ZIndex = 9,
		Parent = shell,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = nub })
	local fillBar = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(74, 222, 128),
		Size = UDim2.fromScale(0.78, 1),
		BorderSizePixel = 1,
		ZIndex = 9,
		Parent = shell,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = fillBar })
	create("UIPadding", {
		PaddingTop = UDim.new(0, 2),
		PaddingBottom = UDim.new(0, 2),
		PaddingLeft = UDim.new(0, 2),
		PaddingRight = UDim.new(0, 2),
		Parent = shell,
	})
	local batteryLevel = Config.content.battery
	local function paintBattery(t)
		shellStroke.Color = t.dim
		nub.BackgroundColor3 = t.dim
		pctText.Text = string.format("%d%%", math.floor(batteryLevel * 100))
		fillBar.Size = UDim2.fromScale(Math.clamp01(batteryLevel), 1)
		fillBar.BackgroundColor3 = batteryLevel < 0.2 and t.danger or t.success
	end
	Theme.register(paintBattery)
	battery.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			batteryLevel = Math.clamp01(batteryLevel - 0.13)
			paintBattery(Theme.tokens())
			MenuBar.notifyBattery(batteryLevel)
		end
	end)
	function MenuBar.notifyBattery(level)
		Nocturne.StatusHUD.show("battery", string.format("%.0f%%", level * 100), level)
		if level < 0.2 then
			Notifications.push({
				title = "Low battery",
				body = "This battery is fictional. Yours probably isn't. Charge it.",
				icon = "bolt",
				kind = "warning",
				duration = 4,
			})
		end
	end

	MenuBar.wifiBtn = statusBtn("wifi", "globe", 26, 2, function()
		Nocturne.ControlCentre.toggle()
	end, "Network · placeholder")
	MenuBar.ccBtn = statusBtn("sliders", "sliders", 26, 1, function()
		Nocturne.ControlCentre.toggle()
	end, "Control Centre")
	MenuBar.dndBtn = statusBtn("moon", "moon", 26, 0, function()
		Notifications.setDoNotDisturb(not Notifications.dnd)
	end, "Focus / Do Not Disturb")

	-- Slide the whole bar down on boot.
	do
		local slide = Spring.new(-40, Config.motion.springCinematic)
		local j
		j = Scheduler.schedule(function(dt)
			local rest = slide:step(dt)
			root.Position = UDim2.new(0, 8, 0, 4 + slide._position)
			if rest then
				Scheduler.unschedule(j)
			end
		end, { name = "barSlide", rate = "frame", priority = 1 })
		slide:setTarget(0)
	end

	Theme.register(function(t)
		bar.BackgroundColor3 = t.surfaceDeep
		bar.BackgroundTransparency = 0.42
	end)
	return root
end

function MenuBar.toggleVisible()
	MenuBar.visible = not MenuBar.visible
	State.menuBarVisible = MenuBar.visible
	if MenuBar.root then
		MenuBar.root.Visible = MenuBar.visible
	end
end

-- Menu-bar helpers used by View menu.
function WM.cascade()
	local i = 0
	local vw2 = viewport()
	for _, win in WM.order do
		i += 1
		win.minimized = false
		win.surface.root.Visible = true
		local w = math.min(560, vw2.X * 0.55)
		local h = math.min(430, vw2.Y * 0.6)
		win.posX:setTarget(40 + i * 26)
		win.posY:setTarget(50 + i * 22)
		win.sizeX:setTarget(w)
		win.sizeY:setTarget(h)
		win.ensureMotion()
	end
	Sfx.play("swipe")
end

function WM.tile()
	local vw2 = viewport()
	local wins = {}
	for _, win in WM.order do
		table.insert(wins, win)
	end
	local n = #wins
	if n == 0 then
		return
	end
	local cols = math.ceil(math.sqrt(n))
	local rows = math.ceil(n / cols)
	local pad = Config.layout.snapMargin
	local cellW = (vw2.X - pad * (cols + 1)) / cols
	local cellH = (vw2.Y - pad - chromeTop() - Config.layout.dockSize - 20 - pad * rows) / rows
	for i, win in wins do
		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)
		win.minimized = false
		win.surface.root.Visible = true
		win.posX:setTarget(pad + col * (cellW + pad))
		win.posY:setTarget(chromeTop() + pad + row * (cellH + pad))
		win.sizeX:setTarget(cellW)
		win.sizeY:setTarget(cellH)
		win.ensureMotion()
	end
	Sfx.play("swipe")
end

-- Control centre ------------------------------------------------------------------
local ControlCentre = { open = false, panel = nil }
Nocturne.ControlCentre = ControlCentre

function ControlCentre.toggle(force)
	local shouldOpen = force ~= nil and force or not ControlCentre.open
	if shouldOpen == ControlCentre.open and ControlCentre.panel then
		return
	end
	ControlCentre.open = shouldOpen
	if shouldOpen then
		ControlCentre.build()
		Depth.push(false)
		Sfx.play("windowOpen")
	else
		if ControlCentre.panel then
			ControlCentre.panel.surface:kill()
			ControlCentre.panel = nil
		end
		Depth.pop(false)
		Sfx.play("windowClose")
	end
end

function ControlCentre.build()
	if ControlCentre.panel then
		return ControlCentre.panel
	end
	local layer = App.layers and App.layers.overlay
	local w, h = 300, 300
	local surface = Glass.new(layer, {
		name = "ControlCentre",
		size = UDim2.fromOffset(w, h),
		position = UDim2.new(1, -12, 0, 40),
		anchor = Vector2.new(1, 0),
		roundness = 22,
		tint = 0.4,
		interactive = true,
	})
	local root = surface.root
	local reveal = Spring.new(-16, Config.motion.springBouncy)
	local j
	j = Scheduler.schedule(function(dt)
		local rest = reveal:step(dt)
		root.Position = UDim2.new(1, -12, 0, 40 + reveal._position)
		if rest then
			Scheduler.unschedule(j)
		end
	end, { name = "cc", rate = "frame", priority = 1 })
	reveal:setTarget(0)

	local content = surface.content
	local grid = create("Frame", {
		Name = "Tiles",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 0, 128),
		Position = UDim2.new(0, 10, 0, 10),
		ZIndex = 12,
		Parent = content,
	})
	create("UIGridLayout", {
		CellSize = UDim2.new(0.5, -6, 0, 58),
		CellPadding = UDim2.new(0, 8, 0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})

	local tileState = {}
	local function tile(name, icon, order, initial, onToggle)
		local b = create("TextButton", {
			Name = "Tile_" .. name,
			BackgroundColor3 = Color3.fromRGB(46, 52, 66),
			BackgroundTransparency = 0.25,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = order,
			ZIndex = 13,
			Parent = grid,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 16), Parent = b })
		local stroke = create("UIStroke", { Transparency = 0.65, Thickness = 1, Parent = b })
		local ic = IconKit.attach(b, icon, { size = 17 })
		ic.frame.AnchorPoint = Vector2.new(0.5, 0.5)
		ic.frame.Position = UDim2.new(0.5, 0, 0.5, -6)
		ic.frame.ZIndex = 14
		local cap = W.label(b, {
			text = name,
			size = 9.5,
			weight = "bold",
			color = "dim",
			align = "Center",
			position = UDim2.new(0.5, 0, 0.5, 14),
			anchor = Vector2.new(0.5, 0.5),
			size2 = { 80, 12 },
			zIndex = 14,
		})
		local stateSpring = Spring.new(initial and 1 or 0, Config.motion.springQuick)
		local st = { on = initial, spring = stateSpring }
		tileState[name] = st
		local jj
		local function drive()
			if jj then
				return
			end
			jj = Scheduler.schedule(function(dt)
				local rest = stateSpring:step(dt)
				local p = stateSpring._position
				local t0 = Theme.tokens()
				b.BackgroundColor3 = Color.mix(t0.surfaceBright, t0.accent, p)
				b.BackgroundTransparency = Math.lerp(0.3, 0.05, p)
				cap.TextColor3 = p > 0.5 and Color3.fromRGB(255, 255, 255) or t0.dim
				ic.setColor(p > 0.5 and Color3.fromRGB(255, 255, 255) or t0.text, 0.05)
				if rest then
					Scheduler.unschedule(jj)
					jj = nil
				end
			end, { name = "ccTile", rate = "frame", priority = 2 })
		end
		drive()
		b.MouseButton1Click:Connect(function()
			st.on = not st.on
			stateSpring:setTarget(st.on and 1 or 0)
			drive()
			Sfx.play(st.on and "toggleOn" or "toggleOff")
			if onToggle then
				onToggle(st.on)
			end
		end)
		return st
	end

	tile("Wi-Fi", "globe", 1, true)
	tile("Bluetooth", "cast", 2, true)
	tile("Focus", "moon", 3, false, function(on)
		Notifications.setDoNotDisturb(on)
	end)
	tile("AirDrop", "airplay", 4, false)
	tile("Keyboard", "keyboard", 5, true)
	tile("Screensaver", "sparkle", 6, false, function()
		Glass.wobbleAll(0.35)
	end)

	-- Brightness / volume mini sliders
	local sliders = create("Frame", {
		Name = "Sliders",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -20, 0, 54),
		Position = UDim2.new(0, 10, 0, 150),
		ZIndex = 13,
		Parent = content,
	})
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = sliders })
	local function miniSlider(name, icon, initial, hudKind)
		local row = create("Frame", {
			Name = name,
			BackgroundColor3 = Color3.fromRGB(38, 43, 55),
			BackgroundTransparency = 0.3,
			Size = UDim2.new(1, 0, 0, 22),
			LayoutOrder = 0,
			ZIndex = 13,
			Parent = sliders,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = row })
		local fillR = create("Frame", {
			BackgroundColor3 = Color3.fromRGB(240, 245, 252),
			BackgroundTransparency = 0.06,
			Size = UDim2.fromScale(initial, 1),
			BorderSizePixel = 0,
			ZIndex = 12,
			Parent = row,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fillR })
		local ic =
			IconKit.attach(row, icon, { size = 12, color = Color3.fromRGB(30, 34, 40), subscribeToTheme = false })
		ic.frame.AnchorPoint = Vector2.new(0, 0.5)
		ic.frame.Position = UDim2.new(0, 8, 0.5, 0)
		ic.frame.ZIndex = 14
		local drag = create("TextButton", {
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 15,
			Parent = row,
		})
		local dragging = false
		local function setVal(frac)
			frac = Math.clamp01(frac)
			fillR.Size = UDim2.fromScale(frac, 1)
			Nocturne.StatusHUD.show(hudKind, math.floor(frac * 100) .. "%", frac)
		end
		drag.InputBegan:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			then
				dragging = true
				setVal((input.Position.X - row.AbsolutePosition.X) / row.AbsoluteSize.X)
			end
		end)
		drag.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement) then
				setVal((input.Position.X - row.AbsolutePosition.X) / row.AbsoluteSize.X)
			end
		end)
		drag.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)
	end
	miniSlider("Brightness", "sun", 0.72, "brightness")
	miniSlider("Volume", "volume", 0.45, "volume")

	-- Media mini card
	local mediaCard = create("Frame", {
		Name = "NowPlaying",
		BackgroundColor3 = Color3.fromRGB(34, 39, 51),
		BackgroundTransparency = 0.2,
		Size = UDim2.new(1, -20, 0, 66),
		Position = UDim2.new(0, 10, 1, -76),
		ZIndex = 13,
		Parent = content,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 16), Parent = mediaCard })
	create("UIStroke", { Transparency = 0.7, Thickness = 1, Parent = mediaCard })
	local art = create("Frame", {
		Name = "Art",
		BackgroundColor3 = Color3.fromRGB(90, 80, 160),
		Size = UDim2.fromOffset(46, 46),
		Position = UDim2.new(0, 10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ZIndex = 14,
		Parent = mediaCard,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = art })
	local artGrad = create("UIGradient", {
		Rotation = 45,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 120, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 180, 255)),
		}),
		Parent = art,
	})
	W.label(mediaCard, {
		text = Config.content.trackName,
		size = 11.5,
		weight = "bold",
		position = UDim2.new(0, 66, 0.36, 0),
		truncate = true,
		size2 = { 150, 14 },
		zIndex = 14,
	})
	W.label(mediaCard, {
		text = Config.content.trackArtist,
		size = 10,
		color = "dim",
		position = UDim2.new(0, 66, 0.62, 0),
		truncate = true,
		size2 = { 150, 12 },
		zIndex = 14,
	})
	local playBtn = W.iconButton(mediaCard, {
		icon = "play",
		size = 26,
		variant = "tint",
		position = UDim2.new(1, -38, 0.5, 0),
		anchor = Vector2.new(0.5, 0.5),
		zIndex = 15,
	})
	local skip = W.iconButton(mediaCard, {
		icon = "skipForward",
		size = 22,
		variant = "ghost",
		position = UDim2.new(1, -10, 0.5, 0),
		anchor = Vector2.new(1, 0.5),
		zIndex = 15,
	})
	local playing = true
	local playClick = playBtn.body:FindFirstChild("Click")
	if playClick then
		playClick.MouseButton1Click:Connect(function()
			playing = not playing
			playBtn:setIcon(playing and "pause" or "play")
			Sfx.play("tap")
			Nocturne.StatusHUD.show("volume", playing and "Playing" or "Paused", playing and 0.66 or 0.15)
		end)
	end
	skip.holder.MouseButton1Click:Connect(function()
		Nocturne.StatusHUD.show("volume", "skipped ahead", 1)
		Sfx.play("swipe")
	end)

	ControlCentre.panel = { surface = surface, mediaCard = mediaCard, artGrad = artGrad }
	return ControlCentre.panel
end

-- Status HUD: the volume-style centered pill -------------------------------------
local StatusHUD = { pill = nil }
Nocturne.StatusHUD = StatusHUD

function StatusHUD.show(kind, text, value01)
	local layer = App.layers and App.layers.overlay
	if not layer then
		return
	end
	if not StatusHUD.pill then
		local surface = Glass.new(layer, {
			name = "StatusHUD",
			size = UDim2.fromOffset(190, 60),
			position = UDim2.new(0.5, 0, 0.5, 0),
			anchor = Vector2.new(0.5, 0.5),
			roundness = 20,
			tint = 0.42,
			caustics = false,
			interactive = false,
		})
		surface.root.Visible = false
		local iconHandle = IconKit.attach(surface.content, "volume", { size = 22 })
		iconHandle.frame.AnchorPoint = Vector2.new(0, 0.5)
		iconHandle.frame.Position = UDim2.new(0, 14, 0.5, 0)
		local value = W.label(surface.content, {
			text = "",
			size = 13,
			weight = "bold",
			position = UDim2.new(0, 50, 0.5, 0),
			size2 = { 60, 20 },
			zIndex = 22,
		})
		local bar = W.progress(surface.content, {
			size = UDim2.new(1, -64, 0, 5),
			position = UDim2.new(0, 50, 0.8, 0),
			value = 0.5,
		})
		bar.frame.AnchorPoint = Vector2.new(0, 0.5)
		StatusHUD.pill = { surface = surface, icon = iconHandle, value = value, bar = bar }
		StatusHUD.spring = Spring.new(0, Config.motion.springBouncy)
		StatusHUD.uiScale = create("UIScale", { Scale = 1, Parent = surface.root })
		local spring = StatusHUD.spring
		local j
		function StatusHUD.ensure()
			if j then
				return
			end
			j = Scheduler.schedule(function(dt)
				local rest = spring:step(dt)
				local p = spring._position
				surface.root.Visible = p > 0.01
				StatusHUD.uiScale.Scale = 0.6 + 0.4 * Math.clamp01(p)
				if rest and p < 0.02 then
					surface.root.Visible = false
					Scheduler.unschedule(j)
					j = nil
				end
			end, { name = "hud", rate = "frame", priority = 1 })
		end
	end
	local pill = StatusHUD.pill
	pill.icon.destroy()
	local iconName = kind == "brightness" and "sun"
		or kind == "battery" and "bolt"
		or kind == "volume" and "volume"
		or "info"
	pill.icon = IconKit.attach(pill.surface.content, iconName, { size = 22 })
	pill.icon.frame.AnchorPoint = Vector2.new(0, 0.5)
	pill.icon.frame.Position = UDim2.new(0, 14, 0.5, 0)
	pill.value.Text = text
	pill.bar.set(Math.clamp01(value01 or 0.5))
	StatusHUD.spring:set(0.2)
	StatusHUD.spring:setTarget(1)
	StatusHUD.ensure()
	if StatusHUD.hideToken then
		task.cancel(StatusHUD.hideToken)
	end
	StatusHUD.hideToken = task.delay(1.4, function()
		StatusHUD.spring:setTarget(0)
		StatusHUD.ensure()
	end)
end
--═══════════════════════════════════════════════════════════════════════════════--
-- § 14  NOTIFICATIONS + NOTIFICATION CENTRE
--
-- Toasts spring in from the right edge with a lifetime shimmer bar; history is
-- kept for the slide-out centre; "focus" (DND) quiets toasts but still files
-- history. Everything is fake fire — that is the entire point of this file.
--═══════════════════════════════════════════════════════════════════════════════--

-- (Notifications is forward-declared in the dock section; we fill that local here
-- so earlier closures that captured it see the real implementation.)
local N = {
	toasts = {},
	history = {},
	dnd = false,
	maxVisible = 4,
	column = nil,
	centre = nil,
}

local function ensureColumn()
	if N.column and N.column.Parent then
		return N.column
	end
	local layer = App.layers and App.layers.toast
	if not layer then
		return nil
	end
	local col = create("Frame", {
		Name = "ToastColumn",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(Config.layout.toastWidth + 8, 400),
		Position = UDim2.new(1, -8, 0, Config.layout.menuBarHeight + 14),
		AnchorPoint = Vector2.new(1, 0),
		ZIndex = 50,
		Parent = layer,
	})
	create("UIListLayout", {
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Parent = col,
	})
	N.column = col
	return col
end

local function toastCard(data, index)
	local col = ensureColumn()
	local surface = Glass.new(col, {
		name = "Toast",
		size = UDim2.fromOffset(Config.layout.toastWidth, 74),
		position = UDim2.fromScale(1, 0),
		anchor = Vector2.new(1, 0),
		roundness = 18,
		tint = 0.36,
		caustics = false,
		interactive = true,
		shadow = true,
	})
	surface.root.LayoutOrder = index
	local content = surface.content

	local disc = create("Frame", {
		Name = "Icon",
		BackgroundColor3 = Color3.fromRGB(70, 110, 160),
		BackgroundTransparency = 0.08,
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(36, 36),
		Position = UDim2.new(0, 12, 0.5, 0),
		ZIndex = 22,
		Parent = content,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = disc })
	create("UIStroke", { Transparency = 0.5, Thickness = 1, Parent = disc })
	local iconHandle = IconKit.attach(
		disc,
		data.icon or "bell",
		{ size = 17, color = Color3.fromRGB(255, 255, 255), subscribeToTheme = false }
	)
	iconHandle.frame.AnchorPoint = Vector2.new(0.5, 0.5)
	iconHandle.frame.Position = UDim2.fromScale(0.5, 0.5)

	W.label(content, {
		text = data.title or "Notification",
		size = 12.5,
		weight = "bold",
		position = UDim2.new(0, 58, 0, 12),
		truncate = true,
		size2 = { Config.layout.toastWidth - 100, 16 },
		zIndex = 22,
	})
	W.label(content, {
		text = data.body or "",
		size = 11,
		color = "dim",
		position = UDim2.new(0, 58, 0, 30),
		wrapped = true,
		anchor = Vector2.new(0, 0),
		size2 = { Config.layout.toastWidth - 74, 34 },
		zIndex = 22,
	})

	local life = (data.duration or 5.5)
	local bar = W.progress(content, {
		size = UDim2.new(1, -24, 0, 3),
		position = UDim2.new(0, 12, 1, -10),
		value = 1,
		indeterminate = false,
	})
	bar.frame.AnchorPoint = Vector2.new(0, 1)

	-- Slide in from off-screen with the list reflowing around it.
	local slide = Spring.new(120, Config.motion.springCinematic, { precision = 0.4 })
	local uiScale = create("UIScale", { Scale = 1, Parent = surface.root })
	local j
	j = Scheduler.schedule(function(dt)
		local rest = slide:step(dt)
		surface.root.Position = UDim2.new(1, slide._position, 0, 0)
		uiScale.Scale = Math.clamp01(1 - slide._position / 400)
		if rest then
			Scheduler.unschedule(j)
			j = nil
		end
	end, { name = "toast", rate = "frame", priority = 1 })
	slide:setTarget(0)

	local startT = os.clock()
	local expireTask
	local card
	local function dismiss()
		if N.dismissing[surface] then
			return
		end
		N.dismissing[surface] = true
		slide:setTarget(-260)
		uiScale:Destroy()
		local jj
		jj = Scheduler.schedule(function(dt)
			local rest = slide:step(dt)
			surface.root.Position = UDim2.new(1, slide._position, 0, 0)
			if rest then
				Scheduler.unschedule(jj)
				surface:kill()
				T.removeValue(N.toasts, card)
			end
		end, { name = "toastOut", rate = "frame", priority = 1 })
		if expireTask then
			task.cancel(expireTask)
		end
	end
	card = { surface = surface, dismiss = dismiss, data = data }

	local clickCatcher = create("TextButton", {
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 40,
		Parent = content,
	})
	clickCatcher.MouseButton1Click:Connect(dismiss)
	clickCatcher.MouseEnter:Connect(function()
		if expireTask then
			task.cancel(expireTask)
		end
	end)
	clickCatcher.MouseLeave:Connect(function()
		local remaining = math.max(0.4, life - (os.clock() - startT))
		expireTask = task.delay(remaining, dismiss)
	end)

	local function pulseBar()
		local e = os.clock() - startT
		local frac = Math.clamp01(1 - e / life)
		bar.set(frac)
		if frac <= 0 then
			dismiss()
			return false
		end
		return true
	end
	expireTask = task.delay(life, dismiss)
	Scheduler.schedule(function()
		pulseBar()
	end, { name = "toastBar", rate = 20, priority = 6, repeatCount = math.ceil(life * 20) + 2 })

	return card
end

N.dismissing = setmetatable({}, { __mode = "k" })

function N.push(data)
	table.insert(N.history, 1, data)
	if #N.history > 60 then
		table.remove(N.history)
	end
	if N.dnd and not data.force then
		if N.centre then
			N.centre:refresh()
		end
		return nil
	end
	table.insert(N.toasts, toastCard(data, #N.toasts + 100))
	while #N.toasts > N.maxVisible do
		local old = table.remove(N.toasts, 1)
		old.dismiss()
	end
	Sfx.play(data.sound or "notify")
	-- The desktop reacts to a notification: every surface gets a small shared
	-- jiggle. Silly? Yes. Is that the problem? No.
	Glass.wobbleAll(0.05)
	return N.toasts[#N.toasts]
end

function N.wave()
	for _, surface in Glass._surfaces do
		if surface.alive then
			task.delay(Math.randomRange(0, 0.4), function()
				surface:wobble(Math.randomRange(-0.2, 0.2), Math.randomRange(-0.14, 0.14))
			end)
		end
	end
	Sfx.play("cheat")
end

function N.setDoNotDisturb(on)
	N.dnd = on and true or false
	N.push({
		title = on and "Focus on" or "Focus off",
		body = on and "Toasts are silenced; history keeps recording." or "Notifications may bother you again.",
		icon = on and "moon" or "bell",
		kind = "info",
		force = true,
		duration = 2.6,
	})
end

-- Notification centre --------------------------------------------------------------
local centreDef = {}
function N.toggleCentre()
	if N.centre then
		N.centre:close()
		return
	end
	N.centre = centreDef.build()
end

function centreDef.build()
	local layer = App.layers and App.layers.overlay
	local surface = Glass.new(layer, {
		name = "NotificationCenter",
		size = UDim2.fromOffset(330, 0),
		position = UDim2.new(1, 10, 0, 0),
		anchor = Vector2.new(0, 0),
		roundness = 0,
		tint = 0.3,
		caustics = false,
		interactive = true,
	})
	surface.root.Size = UDim2.fromOffset(330, surface.root.Parent.AbsoluteSize.Y)
	local root = surface.root
	local slide = Spring.new(340, Config.motion.springCinematic)
	local j
	j = Scheduler.schedule(function(dt)
		local rest = slide:step(dt)
		root.Position = UDim2.new(1, -330 + slide._position, 0, 0)
		if rest then
			Scheduler.unschedule(j)
		end
	end, { name = "nc", rate = "frame", priority = 1 })
	Depth.push(true)

	local content = surface.content
	content.Size = UDim2.new(1, -20, 1, -20)
	content.Position = UDim2.new(0, 10, 0, 10)
	W.label(content, {
		text = "Notification Centre",
		size = 15,
		weight = "black",
		position = UDim2.new(0, 4, 0, 14),
		anchor = Vector2.new(0, 0),
	})
	local centre
	local clearBtn = W.button(content, {
		label = "Clear all",
		icon = "trash",
		variant = "ghost",
		size = "sm",
		position = UDim2.new(1, -92, 0, 4),
		anchor = Vector2.new(1, 0),
		widthPx = 86,
		height = 26,
		onClicked = function()
			T.clear(N.history)
			centre:refresh()
			Sfx.play("windowClose")
		end,
	})
	local listHolder = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, -64),
		Position = UDim2.new(0, 0, 0, 52),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 3,
		BorderSizePixel = 0,
		Parent = content,
		ZIndex = 21,
	})
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = listHolder })
	create("UIPadding", { PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 20), Parent = listHolder })

	centre = {
		surface = surface,
		refresh = function()
			for _, ch in listHolder:GetChildren() do
				if ch:IsA("Frame") then
					ch:Destroy()
				end
			end
			if #N.history == 0 then
				W.label(listHolder, {
					text = "All quiet. Beautifully empty glass.",
					size = 12,
					color = "dim",
					position = UDim2.new(0, 2, 0, 6),
					anchor = Vector2.new(0, 0),
				})
				return
			end
			for i, data in N.history do
				local row = create("Frame", {
					Name = "NC_" .. i,
					BackgroundColor3 = Color3.fromRGB(40, 45, 58),
					BackgroundTransparency = 0.35,
					Size = UDim2.new(1, -6, 0, 54),
					LayoutOrder = i,
					ZIndex = 22,
					Parent = listHolder,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = row })
				local ic = IconKit.attach(row, data.icon or "bell", { size = 14 })
				ic.frame.AnchorPoint = Vector2.new(0, 0.5)
				ic.frame.Position = UDim2.new(0, 10, 0.5, 0)
				W.label(row, {
					text = data.title or "",
					size = 11.5,
					weight = "bold",
					position = UDim2.new(0, 32, 0, 9),
					anchor = Vector2.new(0, 0),
					truncate = true,
					size2 = { 200, 14 },
					zIndex = 23,
				})
				W.label(row, {
					text = data.body or "",
					size = 10.5,
					color = "dim",
					position = UDim2.new(0, 32, 0, 26),
					anchor = Vector2.new(0, 0),
					wrapped = true,
					size2 = { 250, 26 },
					zIndex = 23,
				})
				do
					local tt = os.date("*t", data.at or (os.time() - i * 61))
					local hh, mm = (tt and tt.hour) or 0, (tt and tt.min) or 0
					W.label(row, {
						text = string.format("%02d:%02d", hh, mm),
						size = 9,
						color = "faint",
						position = UDim2.new(1, -12, 0, 10),
						anchor = Vector2.new(1, 0),
						zIndex = 23,
					})
				end
				local kill = create("TextButton", {
					BackgroundTransparency = 1,
					Text = "",
					AutoButtonColor = false,
					Size = UDim2.fromScale(1, 1),
					Parent = row,
					ZIndex = 24,
				})
				kill.MouseButton1Click:Connect(function()
					table.remove(N.history, i)
					centre:refresh()
					Sfx.play("tick")
				end)
			end
		end,
		close = function()
			if j then
				Scheduler.unschedule(j)
			end
			local jj
			jj = Scheduler.schedule(function(dt)
				local rest = slide:step(dt)
				root.Position = UDim2.new(1, -330 + slide._position, 0, 0)
				if rest then
					Scheduler.unschedule(jj)
					surface:kill()
					N.centre = nil
				end
			end, { name = "ncOut", rate = "frame", priority = 1 })
			slide:setTarget(340)
			Depth.pop(true)
		end,
	}
	centreDef["build"] = centreDef.build
	centre:refresh()
	slide:setTarget(0)
	return centre
end

N.centreDef = centreDef

-- Auto-stamp history entry times without threading it through every caller:
-- wrap the raw pusher once.
do
	local rawPush = N.push
	N.push = function(data)
		data.at = os.time()
		return rawPush(data)
	end
end

--═══════════════════════════════════════════════════════════════════════════════--
-- § 15  DESKTOP CONTEXT MENU + GLOBAL RIGHT-CLICK
--═══════════════════════════════════════════════════════════════════════════════--

local Context = {
	attached = {},
}
Nocturne.ContextMenu = Context

function Context.attach(instance, itemsFn)
	local comp = CompositeConnection.new()
	comp:Add(instance.InputBegan:Connect(function(input, gpe)
		if gpe then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			local items = itemsFn(input) or {}
			if #items > 0 then
				Menu.open({
					items = items,
					position = UDim2.fromOffset(input.Position.X, input.Position.Y),
					width = 240,
				})
				Sfx.play("tap")
			end
		end
	end))
	local entry = { instance = instance, comp = comp }
	table.insert(Context.attached, entry)
	instance.Destroying:Connect(function()
		comp:Destroy()
		T.removeValue(Context.attached, entry)
	end)
	return comp
end

function Context.buildDesktopMenu()
	return {
		{
			label = "New window here",
			icon = "plus",
			onClick = function()
				WM.open({
					title = "Window from nowhere",
					icon = "window",
					size = { 380, 280 },
					content = function(parent)
						W.label(parent, {
							text = "Poured from thin air at your cursor's request.",
							size = 12.5,
							color = "dim",
							wrapped = true,
							anchor = Vector2.new(0, 0),
							position = UDim2.new(0, 0, 0, 4),
							size2 = { 300, 40 },
						})
					end,
				})
			end,
		},
		{ divider = true },
		{
			label = "Theme",
			icon = "palette",
			submenu = (function()
				local out = {}
				for _, th in Theme.list() do
					table.insert(out, {
						label = th.label,
						checked = th.id == State.currentTheme,
						onClick = function()
							Theme.apply(th.id)
							Notifications.push({
								title = "Theme",
								body = th.label .. " applied. " .. (th.note or ""),
								icon = "palette",
								duration = 3,
							})
						end,
					})
				end
				return out
			end)(),
		},
		{
			label = "Accent",
			icon = "wand",
			submenu = (function()
				local out = {}
				for _, a in Theme.accentList() do
					table.insert(out, {
						label = a.label,
						onClick = function()
							Theme.setAccent(a.id)
						end,
					})
				end
				return out
			end)(),
		},
		{ divider = true },
		{
			label = "Mission control",
			icon = "grid",
			shortcut = "⌃E",
			onClick = function()
				Nocturne.MissionControl.toggle()
			end,
		},
		{
			label = "Shuffle wallpaper",
			icon = "sparkle",
			onClick = function()
				Nocturne.Wallpaper.shuffle()
			end,
		},
		{
			label = "Wobble everything",
			icon = "cloud",
			onClick = function()
				Glass.wobbleAll(0.5)
			end,
		},
		{ divider = true },
		{
			label = "About Nocturne",
			icon = "info",
			onClick = function()
				Nocturne.Apps.about.open()
			end,
		},
	}
end

--═══════════════════════════════════════════════════════════════════════════════--
-- § 16  COMMAND PALETTE (a.k.a. "the spotlight")
--
-- Ctrl+K. Fuzzy search across registered commands. Everything it can "do" is a
-- UI-side placeholder or a self-configuration — deliberately.
--═══════════════════════════════════════════════════════════════════════════════--

local Spotlight = {
	commands = {},
	visible = false,
	root = nil,
	query = "",
	selected = 1,
	rows = {},
	highlight = nil,
}
Nocturne.Spotlight = Spotlight

function Spotlight.register(cmd)
	-- cmd: { id, label, icon, group, keywords, run, disabled }
	cmd.id = cmd.id or Str.key(cmd.label)
	table.insert(Spotlight.commands, cmd)
	return cmd
end

local function searchResults(q)
	local out = {}
	for _, cmd in Spotlight.commands do
		local haystack = (cmd.label or "") .. " " .. (cmd.group or "") .. " " .. (cmd.keywords or "")
		local score
		if q == "" then
			score = 1 - #out * 0.001
		else
			score = Str.fuzzy(haystack, q)
		end
		if score then
			table.insert(out, { cmd = cmd, score = score })
		end
	end
	table.sort(out, function(a, b)
		return a.score > b.score
	end)
	local capped = {}
	for i = 1, math.min(9, #out) do
		table.insert(capped, out[i])
	end
	return capped
end

function Spotlight.build()
	if Spotlight.root then
		return Spotlight.root
	end
	local layer = App.layers and App.layers.overlay
	local dim = create("TextButton", {
		Name = "SpotlightDim",
		BackgroundColor3 = Color3.fromRGB(3, 5, 9),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 400,
		Parent = layer,
	})
	Spotlight.dim = dim
	local w = Config.layout.paletteWidth
	local surface = Glass.new(layer, {
		name = "Spotlight",
		size = UDim2.fromOffset(w, 120),
		position = UDim2.new(0.5, 0, 0.3, 0),
		anchor = Vector2.new(0.5, 0),
		roundness = 24,
		tint = 0.34,
		interactive = true,
		caustics = false,
		shadow = true,
	})
	Spotlight.root = surface.root
	Spotlight.surface = surface
	local content = surface.content

	local searchIcon = IconKit.attach(content, "search", { size = 18 })
	searchIcon.frame.AnchorPoint = Vector2.new(0, 0.5)
	searchIcon.frame.Position = UDim2.new(0, 16, 0, 30)
	searchIcon.frame.ZIndex = 25

	local input = W.input(content, {
		size = UDim2.new(1, -64, 0, 40),
		position = UDim2.new(0, 44, 0, 10),
		placeholder = "Type a command…  (everything here is a placeholder)",
		textSize = 16,
	})
	Spotlight.input = input
	local listHolder = create("Frame", {
		Name = "Results",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, -66),
		Position = UDim2.new(0, 8, 0, 58),
		ZIndex = 24,
		Parent = content,
	})
	local rowsFrame = create("ScrollingFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ScrollBarThickness = 0,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = listHolder,
		ZIndex = 24,
	})
	create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = rowsFrame })

	local hl = create("Frame", {
		Name = "PaletteHL",
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9,
		Size = UDim2.new(1, 0, 0, Config.layout.paletteRowHeight),
		ZIndex = 0,
		Parent = rowsFrame,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = hl })
	create("UIStroke", { Transparency = 0.75, Thickness = 1, Parent = hl })
	Spotlight.highlight = hl
	local hlSpring = Spring.new(0, Config.motion.springQuick, { precision = 0.06 })
	local hlJob
	local function hlDrive()
		if hlJob then
			return
		end
		hlJob = Scheduler.schedule(function(dt)
			local rest = hlSpring:step(dt)
			hl.Position = UDim2.new(0, 0, 0, hlSpring._position)
			if rest then
				Scheduler.unschedule(hlJob)
				hlJob = nil
			end
		end, { name = "paletteHl", rate = "frame", priority = 1 })
	end
	Spotlight.hlDrive = hlDrive
	Spotlight.hlSpring = hlSpring
	Spotlight.rowsFrame = rowsFrame

	-- Entrance/exit springs
	local openSpring = Spring.new(0, Config.motion.springBouncy)
	Spotlight.openSpring = openSpring
	local sizeSpring = Spring.new(120, Config.motion.springCinematic)
	Spotlight.sizeSpring = sizeSpring
	Spotlight.pumpArmed = true
	return surface.root
end

function Spotlight.rebuildRows()
	local results = searchResults(Spotlight.query)
	local rf = Spotlight.rowsFrame
	for _, ch in rf:GetChildren() do
		if ch:IsA("TextButton") then
			ch:Destroy()
		end
	end
	Spotlight.rows = {}
	for i, entry in results do
		local cmd = entry.cmd
		local row = create("TextButton", {
			Name = "Row_" .. i,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.new(1, 0, 0, Config.layout.paletteRowHeight),
			LayoutOrder = i,
			ZIndex = 3,
			Parent = rf,
		})
		local ic = IconKit.attach(row, cmd.icon or "sparkle", { size = 15, emphasis = i == Spotlight.selected })
		ic.frame.AnchorPoint = Vector2.new(0, 0.5)
		ic.frame.Position = UDim2.new(0, 10, 0.5, 0)
		local lbl = W.label(row, {
			text = cmd.label,
			size = 13,
			weight = "medium",
			position = UDim2.new(0, 36, 0.5, 0),
			truncate = true,
			size2 = { 320, 18 },
			zIndex = 4,
		})
		if cmd.group then
			local g = W.label(row, {
				text = cmd.group,
				size = 10,
				color = "faint",
				position = UDim2.new(1, -10, 0.5, 0),
				anchor = Vector2.new(1, 0.5),
				zIndex = 4,
			})
		end
		Spotlight.rows[i] = { row = row, cmd = cmd, icon = ic, label = lbl }
		row.MouseEnter:Connect(function()
			Spotlight.select(i)
		end)
		row.MouseButton1Click:Connect(function()
			Spotlight.run(cmd)
		end)
	end
	local count = #results
	Spotlight.sizeSpring:setTarget(66 + count * (Config.layout.paletteRowHeight + 2))
	Spotlight.openSpring:setTarget(1)
	Spotlight.select(Math.clamp(Spotlight.selected, 1, math.max(1, count)))
	Spotlight.startPump()
end

function Spotlight.startPump()
	if Spotlight._pump then
		return
	end
	Spotlight._pump = Scheduler.schedule(function(dt)
		local openRest = Spotlight.openSpring:step(dt)
		local sizeRest = Spotlight.sizeSpring:step(dt)
		local surface = Spotlight.surface
		if not surface then
			return
		end
		local p = Math.clamp01(Spotlight.openSpring._position)
		surface.root.Visible = p > 0.02
		Spotlight.dim.BackgroundTransparency = 1 - 0.42 * p
		Spotlight.dim.Visible = p > 0.02
		local uiS = surface.root:FindFirstChild("SpotlightScale")
		if uiS then
			uiS.Scale = 0.92 + 0.08 * p
		end
		surface.root.Position = UDim2.new(0.5, 0, 0.3, (1 - p) * 26)
		surface.root.Size = UDim2.fromOffset(Config.layout.paletteWidth, math.max(64, Spotlight.sizeSpring._position))
		Spotlight.hlSpring:step(dt)
		Spotlight.highlight.Position = UDim2.new(0, 0, 0, math.max(0, Spotlight.hlSpring._position))
		if openRest and sizeRest and p <= 0.01 then
			Scheduler.unschedule(Spotlight._pump)
			Spotlight._pump = nil
		end
	end, { name = "spotlightPump", rate = "frame", priority = 1 })
end

function Spotlight.select(i)
	Spotlight.selected = i
	for j2, r in Spotlight.rows do
		local active = j2 == i
		r.row.BackgroundTransparency = active and 1 or 1
		r.label.TextColor3 = active and Theme.tokens().text or Theme.tokens().dim
	end
	Spotlight.hlSpring:setTarget((i - 1) * (Config.layout.paletteRowHeight + 2))
	Spotlight.hlDrive()
end

function Spotlight.run(cmd)
	if cmd.disabled then
		Sfx.play("error")
		return
	end
	Spotlight.toggle(false)
	task.delay(0.05, function()
		local ok, err = pcall(cmd.run or function() end)
		if not ok then
			logWarn("palette command failed:", err)
			Notifications.push({
				title = "Command error",
				body = tostring(err):sub(1, 120),
				icon = "warning",
				kind = "warning",
			})
		end
	end)
end

function Spotlight.toggle(force)
	local open = force ~= nil and force or not Spotlight.visible
	Spotlight.visible = open
	if open then
		Spotlight.build()
		Depth.push(false)
		Spotlight.query = ""
		Spotlight.input.set("")
		task.defer(function()
			Spotlight.input.focus()
		end)
		Spotlight.rebuildRows()
		Sfx.play("windowOpen")
	else
		Spotlight.openSpring:setTarget(0)
		Spotlight.startPump()
		Depth.pop(false)
		Sfx.play("windowClose")
	end
	State.paletteVisible = open
end

-- Wiring: query updates + keyboard nav ------------------------------------------------
task.defer(function()
	Spotlight.build()
	if not Spotlight.input then
		return
	end
	if Spotlight.input and Spotlight.input.field then
		Spotlight.input.field:GetPropertyChangedSignal("Text"):Connect(function()
			Spotlight.query = Spotlight.input.field.Text
			Spotlight.selected = 1
			Spotlight.rebuildRows()
		end)
	end
	local keyConn
	keyConn = UserInputService.InputBegan:Connect(function(input, gpe)
		if not Spotlight.visible then
			return
		end
		local k = input.KeyCode
		if k == Enum.KeyCode.Down then
			Spotlight.select(Math.modulo(Spotlight.selected, #Spotlight.rows) + 1)
			Sfx.play("tick")
		elseif k == Enum.KeyCode.Up then
			Spotlight.select(Spotlight.selected <= 1 and #Spotlight.rows or Spotlight.selected - 1)
			Sfx.play("tick")
		elseif k == Enum.KeyCode.Return then
			local entry = Spotlight.rows[Spotlight.selected]
			if entry then
				Spotlight.run(entry.cmd)
			end
		elseif k == Enum.KeyCode.Escape then
			Spotlight.toggle(false)
		end
	end)
	if Spotlight.dim then
		Spotlight.dim.MouseButton1Click:Connect(function()
			Spotlight.toggle(false)
		end)
	end
end)

Nocturne.Notifications = N
Notifications = N -- fills the forward local declared beside the dock

--═══════════════════════════════════════════════════════════════════════════════--
-- § 16b  KEYBINDS + CHEAT CODES
--═══════════════════════════════════════════════════════════════════════════════--

local Keys = {
	bindings = {}, -- { {mods={}, key=, fn=, label=, id=} }
	ctrl = false,
	shift = false,
	alt = false,
	meta = false,
}
Nocturne.Keys = Keys

local modLookup = {
	ctrl = function()
		return Keys.ctrl
	end,
	shift = function()
		return Keys.shift
	end,
	alt = function()
		return Keys.alt
	end,
	meta = function()
		return Keys.meta or Keys.ctrl -- on Roblox, ⌘ and ctrl both mean "the modifier"
	end,
}

function Keys.register(id, combo, label, fn)
	-- combo: { key = Enum.KeyCode.X, modifiers = {"ctrl","shift"} }
	table.insert(Keys.bindings, {
		id = id,
		key = combo.key,
		mods = combo.modifiers or {},
		label = label,
		fn = fn,
	})
end

function Keys.modString(binding)
	local out = {}
	for _, m in binding.mods do
		if m == "ctrl" then
			table.insert(out, "⌃")
		elseif m == "shift" then
			table.insert(out, "⇧")
		elseif m == "alt" then
			table.insert(out, "⌥")
		elseif m == "meta" then
			table.insert(out, "⌘")
		end
	end
	table.insert(out, binding.key and binding.key.Name or "?")
	return table.concat(out, "")
end

function Keys.matches(input)
	local changed = {
		[Enum.KeyCode.LeftControl] = "ctrl",
		[Enum.KeyCode.RightControl] = "ctrl",
		[Enum.KeyCode.LeftShift] = "shift",
		[Enum.KeyCode.RightShift] = "shift",
		[Enum.KeyCode.LeftAlt] = "alt",
		[Enum.KeyCode.RightAlt] = "alt",
		[Enum.KeyCode.LeftMeta] = "meta",
		[Enum.KeyCode.RightMeta] = "meta",
	}
	local mod = changed[input.KeyCode]
	if mod then
		Keys[mod] = true
		return nil
	end
	local ctrlOrMeta = Keys.ctrl or Keys.meta
	for _, binding in Keys.bindings do
		if binding.key == input.KeyCode then
			local wantCtrl, wantShift, wantAlt = false, false, false
			for _, m in binding.mods do
				if m == "ctrl" or m == "meta" then
					wantCtrl = true
				elseif m == "shift" then
					wantShift = true
				elseif m == "alt" then
					wantAlt = true
				end
			end
			if
				wantCtrl == (ctrlOrMeta == true)
				and wantShift == (Keys.shift == true)
				and wantAlt == (Keys.alt == true)
			then
				return binding
			end
		end
	end
	return nil
end

-- Konami-ish cheat codes ---------------------------------------------------------
local CheatCodes = {
	buffer = {},
	defs = {
		{
			seq = { "Up", "Up", "Down", "Down", "Left", "Right", "Left", "Right", "B", "A" },
			name = "liquid",
			label = "LIQUID MODE",
		},
		{ seq = { "R", "I", "G", "H", "T" }, name = "contrast", label = "MAX CONTRAST" },
		{ seq = { "Q", "U", "I", "E", "T" }, name = "quiet", label = "SILENT MODE" },
		{ seq = { "W", "O", "B", "B", "L", "E" }, name = "wobble", label = "EVERYTHING WOBBLES" },
	},
}
Nocturne.CheatCodes = CheatCodes

function CheatCodes.feed(keyName)
	table.insert(CheatCodes.buffer, keyName)
	while #CheatCodes.buffer > 10 do
		table.remove(CheatCodes.buffer, 1)
	end
	for _, def in CheatCodes.defs do
		local n = #def.seq
		if #CheatCodes.buffer >= n then
			local match = true
			for i = 1, n do
				if CheatCodes.buffer[#CheatCodes.buffer - n + i] ~= def.seq[i] then
					match = false
					break
				end
			end
			if match then
				CheatCodes.activate(def)
				table.clear(CheatCodes.buffer)
				return
			end
		end
	end
end

function CheatCodes.activate(def)
	Sfx.play("cheat")
	Notifications.push({
		title = def.label,
		body = "You found it. There was never a reward. There is only more glass.",
		icon = "sparkle",
		kind = "success",
		duration = 4,
		force = true,
	})
	if def.name == "liquid" then
		State.viewMode = State.viewMode == "liquid" and "standard" or "liquid"
		Config.glass.wobble = State.viewMode == "liquid" and 0.06 or 0.018
		Config.glass.causticsStrength = State.viewMode == "liquid" and 0.5 or 0.22
		Glass.wobbleAll(0.8)
		Theme.apply(State.currentTheme, State.currentAccent)
	elseif def.name == "wobble" then
		Glass.wobbleAll(1.4)
	elseif def.name == "contrast" then
		State.contrastBoost = not State.contrastBoost
		Theme.apply(State.currentTheme, State.currentAccent)
	elseif def.name == "quiet" then
		Config.motion.enableSounds = not Config.motion.enableSounds
	end
end
--═══════════════════════════════════════════════════════════════════════════════--
-- § 17  DEMO APPS
--
-- Ten "applications" that exist to show off the framework: each is a window with
-- live, reactive UI and zero real functionality, which is precisely what a
-- placeholder kit should ship. Settings is the one app with genuine purpose: it
-- drives Config, so you can feel the glass from every angle.
--═══════════════════════════════════════════════════════════════════════════════--

local Apps = {}
Nocturne.Apps = Apps

-- Swatch previews for the settings theme buttons, derived from the theme table.
local themeDefsLookup = {}
for id, def in pairs(Theme._defs) do
	themeDefsLookup[id] = {
		surfaceC = Color.fromHex(def.surface),
		textC = Color.fromHex(def.text),
	}
end

local function headerBlock(parent, title, subtitle, order)
	local holder = create("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 54),
		LayoutOrder = order or 0,
		ZIndex = 21,
		Parent = parent,
	})
	W.label(holder, {
		text = title,
		size = 19,
		weight = "black",
		anchor = Vector2.new(0, 0),
		position = UDim2.new(0, 0, 0, 2),
		size2 = { 400, 24 },
	})
	if subtitle then
		W.label(holder, {
			text = subtitle,
			size = 11.5,
			color = "dim",
			anchor = Vector2.new(0, 0),
			position = UDim2.new(0, 0, 0, 28),
			size2 = { 420, 16 },
		})
	end
	return holder
end

local function card(parent, opts)
	local holder = create("Frame", {
		Name = opts.name or "Card",
		BackgroundTransparency = 1,
		Size = opts.size or UDim2.new(1, 0, 0, opts.height or 66),
		LayoutOrder = opts.order or 1,
		ZIndex = 21,
		Parent = parent,
	})
	local surf = Glass.new(holder, {
		name = "CardGlass",
		size = UDim2.fromScale(1, 1),
		position = UDim2.fromScale(0, 0),
		anchor = Vector2.new(0, 0),
		roundness = opts.roundness or 16,
		tint = 0.30,
		caustics = opts.caustics,
		shadow = false,
		interactive = true,
	})
	local content = surf.content
	content.Size = UDim2.new(1, -(opts.pad or 14) * 2, 1, -16)
	content.Position = UDim2.new(0, opts.pad or 14, 0, 8)
	content.ZIndex = 24
	return surf, content, holder
end

local function settingRow(parent, opts)
	local surf, content, holder = card(parent, { order = opts.order, height = opts.height or 56, name = opts.title })
	W.label(content, {
		text = opts.title,
		size = 13,
		weight = "bold",
		position = UDim2.new(0, 0, 0.42, 0),
		truncate = true,
		size2 = { 200, 16 },
	})
	if opts.note then
		W.label(content, {
			text = opts.note,
			size = 10.5,
			color = "dim",
			position = UDim2.new(0, 0, 0.74, 0),
			truncate = true,
			size2 = { 240, 14 },
		})
	end
	return content, holder, surf
end

-- SETTINGS ------------------------------------------------------------------------
Apps.settings = {
	id = "settings",
	label = "Settings",
	icon = "gear",
	color = nil,
}
function Apps.settings.open(size)
	local spec = {
		appId = "settings",
		id = "settings",
		title = "Settings",
		subtitle = "the one app that actually does something — to itself",
		icon = "gear",
		size = size or { 640, 460 },
		content = function(parent, win)
			local tabsHost = create("Frame", {
				Name = "SettingsTabs",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 34),
				LayoutOrder = 1,
				Parent = parent,
			})
			local body = create("Frame", {
				Name = "SettingsBody",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 2600),
				LayoutOrder = 2,
				Parent = parent,
			})
			create("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })
			local pages = {}

			-- GENERAL
			local general = create("Frame", {
				Name = "General",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 1,
				Parent = body,
			})
			create(
				"UIListLayout",
				{ Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = general }
			)
			pages.general = general
			local c1 = settingRow(general, { title = "Show menu bar", note = "the strip with the clock", order = 1 })
			W.switch(c1, {
				value = true,
				anchor = Vector2.new(1, 0.5),
				position = UDim2.new(1, -4, 0.5, 0),
				onChanged = function(v)
					MenuBar.toggleVisible()
				end,
			})
			local c2 = settingRow(general, { title = "Show dock", note = "the magnifying shelf", order = 2 })
			W.switch(c2, {
				value = true,
				anchor = Vector2.new(1, 0.5),
				position = UDim2.new(1, -4, 0.5, 0),
				onChanged = function(v)
					Dock.toggle()
				end,
			})
			local c3 = settingRow(general, { title = "Interface sounds", note = "synthesised, zero assets", order = 3 })
			W.switch(c3, {
				value = true,
				anchor = Vector2.new(1, 0.5),
				position = UDim2.new(1, -4, 0.5, 0),
				onChanged = function(v)
					Config.motion.enableSounds = v
				end,
			})
			local c4 = settingRow(
				general,
				{ title = "Snap while dragging", note = "windows pour into halves and quarters", order = 4 }
			)
			W.switch(c4, {
				value = Config.input.snapAssist,
				anchor = Vector2.new(1, 0.5),
				position = UDim2.new(1, -4, 0.5, 0),
				onChanged = function(v)
					Config.input.snapAssist = v
				end,
			})

			-- APPEARANCE
			local appearance = create("Frame", {
				Name = "Appearance",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 2,
				Visible = false,
				Parent = body,
			})
			create(
				"UIListLayout",
				{ Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = appearance }
			)
			pages.appearance = appearance
			local themeCard = settingRow(
				appearance,
				{ title = "Theme", note = "eight dark palettes, one porcelain", order = 1, height = 96 }
			)
			local themeGrid = create("Frame", {
				Name = "ThemeGrid",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 58),
				Position = UDim2.new(0, 0, 0, 34),
				Parent = themeCard,
			})
			do
				local themes = Theme.list()
				local cols = math.min(5, #themes)
				create("UIGridLayout", {
					CellSize = UDim2.new(1 / cols, -8, 0, 52),
					CellPadding = UDim2.new(0, 8, 0, 6),
					SortOrder = Enum.SortOrder.LayoutOrder,
					Parent = themeGrid,
				})
				for i, th in themes do
					local b = create("TextButton", {
						Name = "Theme_" .. th.id,
						AutoButtonColor = false,
						Text = th.label,
						Font = fontBy("bold"),
						TextSize = 10.5,
						LayoutOrder = i,
						Parent = themeGrid,
					})
					create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = b })
					local st = create("UIStroke", {
						Transparency = th.id == State.currentTheme and 0.1 or 0.6,
						Thickness = th.id == State.currentTheme and 1.8 or 1,
						Parent = b,
					})
					local g = create("UIGradient", { Rotation = 120, Parent = b })
					b.MouseButton1Click:Connect(function()
						Theme.apply(th.id)
						for _, ch in themeGrid:GetChildren() do
							if ch:IsA("TextButton") then
								local s = ch:FindFirstChildOfClass("UIStroke")
								if s then
									s.Transparency = ch.Name == "Theme_" .. th.id and 0.1 or 0.6
									s.Thickness = ch.Name == "Theme_" .. th.id and 1.8 or 1
								end
							end
						end
						Notifications.push({
							title = "Theme",
							body = th.label .. " applied.",
							icon = "palette",
							duration = 2.5,
						})
					end)
					local function paintThemeBtn()
						local t = Theme.tokens()
						local defs = themeDefsLookup[th.id]
						b.BackgroundColor3 = defs and defs.surfaceC or t.surfaceBright
						b.TextColor3 = defs and defs.textC or t.text
						st.Color = t.accent
					end
					Theme.register(paintThemeBtn)
				end
			end

			local accentCard = settingRow(
				appearance,
				{ title = "Accent", note = "tints rims, fills, and ripples", order = 2, height = 74 }
			)
			local swatchRow = create("Frame", {
				Name = "Accents",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 30),
				Position = UDim2.new(0, 0, 0, 38),
				Parent = accentCard,
			})
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 7),
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Parent = swatchRow,
			})
			for i, a in Theme.accentList() do
				local sw = create("TextButton", {
					BackgroundColor3 = a.swatch,
					AutoButtonColor = false,
					Text = "",
					Size = UDim2.fromOffset(22, 22),
					LayoutOrder = i,
					Parent = swatchRow,
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = sw })
				local sStroke = create("UIStroke", {
					Transparency = a.id == State.currentAccent and 0.05 or 0.65,
					Thickness = a.id == State.currentAccent and 2.2 or 1,
					Parent = sw,
				})
				sw.MouseButton1Click:Connect(function()
					Theme.setAccent(a.id)
					for _, ch in swatchRow:GetChildren() do
						if ch:IsA("TextButton") then
							local s = ch:FindFirstChildOfClass("UIStroke")
							if s then
								s.Transparency = ch.BackgroundColor3 == a.swatch and 0.05 or 0.65
								s.Thickness = ch.BackgroundColor3 == a.swatch and 2.2 or 1
							end
						end
					end
					Sfx.play("toggleOn")
				end)
				Tooltip.attach(sw, a.label)
			end

			local glassCard = settingRow(
				appearance,
				{ title = "Glass thickness", note = "how opaque the material reads", order = 3, height = 88 }
			)
			local thickness = W.slider(glassCard, {
				size = UDim2.new(1, -4, 0, 12),
				position = UDim2.new(0, 0, 0, 44),
				min = 0.18,
				max = 0.85,
				value = Config.glass.body,
				notifyProgrammatic = true,
				format = function(v)
					return Str.percent((v - 0.18) / 0.67)
				end,
				onChanged = function(v)
					Config.glass.body = v
					Theme.apply(State.currentTheme, State.currentAccent, true)
					for _, surface in Glass._surfaces do
						if surface.alive then
							surface.body.BackgroundTransparency = 1
								- Math.clamp(v + (surface._tokens and surface._tokens.tintBias or 0), 0.05, 0.95)
						end
					end
				end,
			})
			local rimCard = settingRow(
				appearance,
				{ title = "Rim light", note = "the edge that sells the material", order = 4, height = 88 }
			)
			W.slider(rimCard, {
				size = UDim2.new(1, -4, 0, 12),
				position = UDim2.new(0, 0, 0, 44),
				min = 0,
				max = 1,
				value = Config.glass.rimLight,
				notifyProgrammatic = true,
				onChanged = function(v)
					Config.glass.rimLight = v
					Theme.apply(State.currentTheme, State.currentAccent, true)
				end,
			})
			local causticsRow =
				settingRow(appearance, { title = "Caustics", note = "drifting light inside the glass", order = 5 })
			W.switch(causticsRow, {
				value = Config.glass.caustics,
				anchor = Vector2.new(1, 0.5),
				position = UDim2.new(1, -4, 0.5, 0),
				onChanged = function(v)
					Config.glass.caustics = v
					for _, surface in Glass._surfaces do
						if surface.caustics then
							surface.caustics[1].strip.Parent.Visible = v
						end
					end
				end,
			})

			-- MOTION
			local motion = create("Frame", {
				Name = "Motion",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 3,
				Visible = false,
				Parent = body,
			})
			create(
				"UIListLayout",
				{ Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = motion }
			)
			pages.motion = motion
			local rm =
				settingRow(motion, { title = "Reduce motion", note = "calmer springs, no drifting light", order = 1 })
			W.switch(rm, {
				value = State.reduceMotion,
				anchor = Vector2.new(1, 0.5),
				position = UDim2.new(1, -4, 0.5, 0),
				onChanged = function(v)
					Config.accessibility.reduceMotion = v
					State.reduceMotion = v
				end,
			})
			local wob = settingRow(
				motion,
				{ title = "Wobble strength", note = "membrane flex on interaction", order = 2, height = 88 }
			)
			W.slider(wob, {
				size = UDim2.new(1, -4, 0, 12),
				position = UDim2.new(0, 0, 0, 44),
				min = 0,
				max = 0.08,
				value = Config.glass.wobble,
				notifyProgrammatic = true,
				format = function(v)
					return string.format("%.3f", v)
				end,
				onChanged = function(v)
					Config.glass.wobble = v
				end,
			})
			local blur = settingRow(
				motion,
				{ title = "Scene blur", note = "the world dims and softens behind glass", order = 3, height = 88 }
			)
			W.slider(blur, {
				size = UDim2.new(1, -4, 0, 12),
				position = UDim2.new(0, 0, 0, 44),
				min = 0,
				max = 2,
				value = State.blurStrength,
				notifyProgrammatic = true,
				format = function(v)
					return string.format("%.1f×", v)
				end,
				onChanged = function(v)
					State.blurStrength = v
					Depth.recompute()
				end,
			})
			local soundRow = settingRow(
				motion,
				{ title = "Sound volume", note = "synth cues for taps and toggles", order = 4, height = 88 }
			)
			W.slider(soundRow, {
				size = UDim2.new(1, -4, 0, 12),
				position = UDim2.new(0, 0, 0, 44),
				min = 0,
				max = 1,
				value = Config.motion.soundVolume,
				notifyProgrammatic = true,
				format = function(v)
					return Str.percent(v)
				end,
				onChanged = function(v)
					Config.motion.soundVolume = v
					Sfx.play("tick")
				end,
			})

			-- ADVANCED
			local advanced = create("Frame", {
				Name = "Advanced",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 4,
				Visible = false,
				Parent = body,
			})
			create(
				"UIListLayout",
				{ Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = advanced }
			)
			pages.advanced = advanced
			local fpsRow =
				settingRow(advanced, { title = "FPS overlay", note = "tiny telemetry, bottom-left", order = 1 })
			W.switch(fpsRow, {
				value = Config.diagnostics.showFps,
				anchor = Vector2.new(1, 0.5),
				position = UDim2.new(1, -4, 0.5, 0),
				onChanged = function(v)
					Config.diagnostics.showFps = v
					Nocturne.Diagnostics.setFpsVisible(v)
				end,
			})
			local poolRow = settingRow(advanced, { title = "Instance registry", note = "", order = 2 })
			local poolLabel = W.label(poolRow, {
				text = "",
				size = 11,
				color = "accent",
				anchor = Vector2.new(1, 0.5),
				position = UDim2.new(1, -4, 0.5, 0),
			})
			task.spawn(function()
				while poolLabel.Parent do
					poolLabel.Text = string.format(
						"%d surfaces · %d windows · %d pools live",
						Glass.count(),
						WM and #WM.order or 0,
						0
					)
					task.wait(0.5)
				end
			end)
			local dumpRow = settingRow(
				advanced,
				{ title = "Export config", note = "print the whole Config table as JSON", order = 3, height = 78 }
			)
			W.button(dumpRow, {
				label = "Copy to console",
				icon = "download",
				variant = "tint",
				size = "sm",
				position = UDim2.new(0, 0, 0, 34),
				widthPx = 140,
				height = 28,
				onClicked = function()
					local ok, encoded = pcall(function()
						return HttpService:JSONEncode({
							theme = State.currentTheme,
							accent = State.currentAccent,
							glass = {
								body = Config.glass.body,
								rimLight = Config.glass.rimLight,
								caustics = Config.glass.caustics,
								wobble = Config.glass.wobble,
							},
							motion = {
								enableSounds = Config.motion.enableSounds,
								soundVolume = Config.motion.soundVolume,
							},
							accessibility = Config.accessibility,
						})
					end)
					print("[Nocturne config]", ok and encoded or "encoding failed")
					Notifications.push({
						title = "Config dumped",
						body = ok and "JSON is in the output console (Studio)." or "Encoding failed — check console.",
						icon = "terminal",
						duration = 3.2,
					})
				end,
			})
			local resetRow = settingRow(advanced, {
				title = "Reset everything",
				note = "back to factory values (the numbers, not the vibes)",
				order = 4,
				height = 78,
			})
			W.button(resetRow, {
				label = "Reset",
				icon = "refresh",
				variant = "danger",
				size = "sm",
				position = UDim2.new(0, 0, 0, 34),
				widthPx = 110,
				height = 28,
				onClicked = function()
					Config.glass.body = 0.55
					Config.glass.rimLight = 0.72
					Config.glass.caustics = true
					Config.glass.wobble = 0.018
					State.blurStrength = 1
					State.reduceMotion = false
					Theme.apply("obsidian", "moonstone")
					Notifications.push({
						title = "Factory reset",
						body = "Glass recalibrated to Obsidian/Moonstone.",
						icon = "refresh",
						kind = "success",
					})
				end,
			})

			-- TABS ---------------------------------------------------------------
			W.segmented(tabsHost, {
				size = UDim2.new(0.62, 0, 1, 0),
				widthPx = nil,
				options = {
					{ label = "General", value = "general" },
					{ label = "Appearance", value = "appearance" },
					{ label = "Motion", value = "motion" },
					{ label = "Advanced", value = "advanced" },
				},
				selected = 1,
				onChanged = function(value)
					for name, page in pages do
						page.Visible = name == value
					end
					win.scroll.CanvasPosition = Vector2.new(0, 0)
				end,
			})
		end,
	}
	return WM.open(spec)
end

-- HOME / DASHBOARD -------------------------------------------------------------------
Apps.home = {
	id = "home",
	label = "Home",
	icon = "home",
}
function Apps.home.open()
	return WM.open({
		appId = "home",
		id = "home",
		title = "Good evening",
		subtitle = "a shelf of living placeholders",
		icon = "home",
		size = { 600, 470 },
		content = function(parent, win)
			local surf1, content1, holder1 = card(parent, { order = 1, height = 130, name = "ClockCard" })
			do
				local big = W.label(content1, {
					text = "--:--",
					size = 44,
					weight = "display",
					anchor = Vector2.new(0, 0.5),
					position = UDim2.new(0, 4, 0.4, 0),
				})
				local sub = W.label(content1, {
					text = "",
					size = 12,
					color = "dim",
					anchor = Vector2.new(0, 0.5),
					position = UDim2.new(0, 4, 0.74, 0),
				})
				local secondsHand = create("Frame", {
					BackgroundColor3 = Color3.fromRGB(200, 210, 225),
					AnchorPoint = Vector2.new(0.5, 1),
					Size = UDim2.fromOffset(2, 34),
					Position = UDim2.new(0.9, 0, 0.78, 0),
					BorderSizePixel = 0,
					Parent = content1,
					ZIndex = 25,
				})
				local face = create("Frame", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromOffset(78, 78),
					Position = UDim2.new(0.9, 0, 0.52, 4),
					Parent = content1,
					ZIndex = 24,
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = face })
				local faceStroke = create("UIStroke", { Thickness = 2, Transparency = 0.3, Parent = face })
				local hourHand = create("Frame", {
					BackgroundColor3 = Color3.fromRGB(235, 240, 248),
					AnchorPoint = Vector2.new(0.5, 1),
					Size = UDim2.fromOffset(3, 20),
					Position = UDim2.fromScale(0.5, 0.5),
					Parent = face,
					ZIndex = 25,
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hourHand })
				local minuteHand = create("Frame", {
					BackgroundColor3 = Color3.fromRGB(140, 200, 255),
					AnchorPoint = Vector2.new(0.5, 1),
					Size = UDim2.fromOffset(2, 30),
					Position = UDim2.fromScale(0.5, 0.5),
					Parent = face,
					ZIndex = 25,
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = minuteHand })
				for i = 1, 12 do
					local a = (i / 12) * math.pi * 2
					create("Frame", {
						BackgroundColor3 = Color3.fromRGB(160, 170, 185),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Size = UDim2.fromOffset(i % 3 == 0 and 4 or 2, i % 3 == 0 and 4 or 2),
						Position = UDim2.new(0.5 + math.sin(a) * 0.42, 0, 0.5 - math.cos(a) * 0.42, 0),
						Parent = face,
						ZIndex = 25,
					})
				end
				local pivot = create("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromOffset(5, 5),
					Position = UDim2.fromScale(0.5, 0.5),
					Parent = face,
					ZIndex = 26,
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = pivot })
				local smoothSec = 0
				local job = Scheduler.schedule(function(dt)
					local t = os.date("*t")
					if not t then
						return
					end
					smoothSec = Math.lerp(smoothSec, t.sec + t.min * 60, 0.16)
					local sec = smoothSec % 60
					local totalSec = t.sec
					big.Text = string.format("%d:%02d", (t.hour % 12 == 0) and 12 or t.hour % 12, t.min)
					sub.Text = Str.longDate()
					minuteHand.Rotation = (t.min + totalSec / 60) * 6
					hourHand.Rotation = ((t.hour % 12) + t.min / 60) * 30
					secondsHand.Rotation = sec * 6
					if State.fps < 30 then
						secondsHand.Rotation = sec * 6 + math.sin(os.clock() * 30) * 1.5 -- jank shimmer, honestly
					end
				end, { name = "clockCard", rate = 30, priority = 5 })
				face:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() end)
			end

			-- Quick action grid
			local actions = create("Frame", {
				Name = "QuickActions",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 120),
				LayoutOrder = 2,
				Parent = parent,
			})
			create("UIGridLayout", {
				CellSize = UDim2.new(0.25, -8, 0, 56),
				CellPadding = UDim2.new(0, 10, 0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = actions,
			})
			local quickDefs = {
				{
					label = "Focus",
					icon = "moon",
					act = function()
						Notifications.setDoNotDisturb(not Notifications.dnd)
					end,
				},
				{
					label = "Wobble",
					icon = "cloud",
					act = function()
						Glass.wobbleAll(0.7)
					end,
				},
				{
					label = "Cascade",
					icon = "layers",
					act = function()
						WM.cascade()
					end,
				},
				{
					label = "Palette",
					icon = "search",
					act = function()
						Nocturne.Spotlight.toggle(true)
					end,
				},
			}
			for i, q in quickDefs do
				local b = W.button(actions, {
					label = q.label,
					icon = q.icon,
					variant = "glass",
					size = "sm",
					bold = true,
					layoutOrder = i,
					onClicked = q.act,
				})
				b.holder.LayoutOrder = i
			end

			local sysSurf, sysContent, sysHolder =
				card(parent, { order = 3, height = 150, name = "SysCard", caustics = true })
			W.label(sysContent, {
				text = "SYSTEM GLANCE",
				size = 9.5,
				weight = "black",
				color = "faint",
				anchor = Vector2.new(0, 0),
				position = UDim2.new(0, 0, 0, 0),
				size2 = { 200, 14 },
			})
			local gauges = { { "Session", 0.2 }, { "Surfaces", 0.5 }, { "Windows", 0.7 } }
			local gaugeBars = {}
			for i, g in gauges do
				local row = create("Frame", {
					Name = "Gauge" .. i,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 26),
					Position = UDim2.new(0, 0, 0, 24 + (i - 1) * 32),
					Parent = sysContent,
					ZIndex = 24,
				})
				W.label(row, {
					text = g[1],
					size = 11,
					weight = "medium",
					color = "dim",
					anchor = Vector2.new(0, 0.5),
					position = UDim2.new(0, 0, 0.5, 0),
					size2 = { 70, 14 },
				})
				local bar = W.progress(
					row,
					{ size = UDim2.new(1, -80, 0, 6), position = UDim2.new(0, 76, 0.5, 0), value = g[2] }
				)
				bar.frame.AnchorPoint = Vector2.new(0, 0.5)
				table.insert(gaugeBars, bar)
			end
			task.spawn(function()
				while sysHolder.Parent do
					local secs = os.clock() - State.sessionStart
					gaugeBars[1].set(Math.clamp01(secs / 600))
					gaugeBars[2].set(Math.clamp01(Glass.count() / 90))
					gaugeBars[3].set(Math.clamp01(#WM.order / 8))
					task.wait(0.5)
				end
			end)
		end,
	})
end

-- MEDIA PLAYER -----------------------------------------------------------------------
Apps.media = {
	id = "media",
	label = "Sound Lab",
	icon = "music",
}
local mediaVisualizerTask = nil
function Apps.media.open()
	return WM.open({
		appId = "media",
		id = "media",
		title = Config.content.playlistName,
		subtitle = "the waveform is a sine wave with confidence issues",
		icon = "music",
		size = { 520, 430 },
		content = function(parent, win)
			local artSurf, artContent, artHolder =
				card(parent, { order = 1, height = 210, name = "ArtCard", caustics = true })
			local disc = create("Frame", {
				BackgroundColor3 = Color3.fromRGB(90, 80, 170),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(120, 120),
				Position = UDim2.new(0.5, 0, 0.46, 0),
				BorderSizePixel = 0,
				ZIndex = 24,
				Parent = artContent,
			})
			create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = disc })
			local discGrad = create("UIGradient", {
				Rotation = 40,
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 130, 255)),
					ColorSequenceKeypoint.new(0.55, Color3.fromRGB(70, 140, 255)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 220, 200)),
				}),
				Parent = disc,
			})
			create("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.4),
					NumberSequenceKeypoint.new(1, 0),
				}),
				Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)),
				Parent = disc,
			})
			local hole = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(10, 12, 18),
				Size = UDim2.fromOffset(16, 16),
				Position = UDim2.fromScale(0.5, 0.5),
				ZIndex = 25,
				Parent = disc,
			})
			create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hole })
			local discSpin = create("UIRotation", { Angle = 0, Parent = disc })

			W.label(artContent, {
				text = Config.content.trackName,
				size = 16,
				weight = "black",
				anchor = Vector2.new(0.5, 0),
				position = UDim2.new(0.5, 0, 1, -52),
				size2 = { 300, 20 },
			})
			W.label(artContent, {
				text = Config.content.trackArtist,
				size = 11.5,
				color = "dim",
				anchor = Vector2.new(0.5, 0),
				position = UDim2.new(0.5, 0, 1, -30),
				size2 = { 300, 16 },
			})

			-- Visualizer bars
			local vizHolder = create("Frame", {
				Name = "Visualizer",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 64),
				LayoutOrder = 2,
				Parent = parent,
			})
			local bars = {}
			local barCount = 44
			create("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				Padding = UDim.new(0, 3),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = vizHolder,
			})
			for i = 1, barCount do
				local bar = create("Frame", {
					Name = "Bar" .. i,
					BackgroundColor3 = Color3.fromRGB(120, 200, 255),
					BackgroundTransparency = 0.25,
					Size = UDim2.new(1 / barCount, -4, 0, 8),
					LayoutOrder = i,
					Parent = vizHolder,
					ZIndex = 22,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = bar })
				local g = create("UIGradient", {
					Rotation = 90,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(1, 0.6),
					}),
					Parent = bar,
				})
				table.insert(bars, { frame = bar, grad = g, i = i })
			end

			-- Controls
			local controls = create("Frame", {
				Name = "Controls",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 52),
				LayoutOrder = 3,
				Parent = parent,
			})
			local posSlider = W.slider(controls, {
				size = UDim2.new(1, -8, 0, 8),
				position = UDim2.new(0, 4, 0, 6),
				min = 0,
				max = Config.content.trackDuration,
				value = 51,
				format = Str.clock,
				notifyProgrammatic = true,
			})
			local shuffle = W.iconButton(controls, {
				icon = "shuffle",
				size = 34,
				variant = "ghost",
				position = UDim2.new(0.22, 0, 1, -34),
				anchor = Vector2.new(0, 1),
			})
			local prev = W.iconButton(controls, {
				icon = "skipBack",
				size = 38,
				variant = "glass",
				position = UDim2.new(0.36, 0, 1, -36),
				anchor = Vector2.new(0, 1),
			})
			local play = W.button(controls, {
				label = "",
				icon = "pause",
				variant = "primary",
				widthPx = 52,
				height = 44,
				roundness = 16,
				position = UDim2.new(0.5, 0, 1, -39),
				anchor = Vector2.new(0.5, 1),
				iconSize = 18,
				iconPad = 17,
			})
			local nextBtn = W.iconButton(controls, {
				icon = "skipForward",
				size = 38,
				variant = "glass",
				position = UDim2.new(0.64, 0, 1, -36),
				anchor = Vector2.new(0, 1),
			})
			local repeatBtn = W.iconButton(controls, {
				icon = "repeat",
				size = 34,
				variant = "ghost",
				position = UDim2.new(0.78, 0, 1, -34),
				anchor = Vector2.new(0, 1),
			})
			local volSurf = create("Frame", {
				Name = "VolumeRow",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 40),
				LayoutOrder = 4,
				Parent = parent,
			})
			local volIcon = IconKit.attach(volSurf, "volume", { size = 14 })
			volIcon.frame.AnchorPoint = Vector2.new(0, 0.5)
			volIcon.frame.Position = UDim2.new(0, 0, 0.5, 0)
			W.slider(volSurf, {
				size = UDim2.new(1, -40, 0, 8),
				position = UDim2.new(0, 30, 0.5, 0),
				min = 0,
				max = 1,
				value = 0.7,
				format = function(v)
					return Str.percent(v)
				end,
				notifyProgrammatic = true,
				onChanged = function(v)
					Nocturne.StatusHUD.show("volume", Str.percent(v), v)
					Config.motion.soundVolume = v
				end,
			})

			local playing = true
			local discRot = 0
			if mediaVisualizerTask then
				task.cancel(mediaVisualizerTask)
			end
			mediaVisualizerTask = Scheduler.schedule(function()
				local t = os.clock()
				for _, b in bars do
					local seed = Math.fbm(t * (playing and 1.6 or 0.2) + b.i * 0.7, b.i * 0.31, 3)
					local v = playing and (0.16 + 0.84 * Math.clamp01(seed * 0.5 + 0.5)) or 0.06
					b.frame.Size = UDim2.new(1 / barCount, -4, 0, 6 + v * 54)
					b.frame.BackgroundTransparency = 0.28 - v * 0.14
				end
				if playing then
					discRot += 0.7
					discSpin.Angle = math.rad(discRot)
					local cur = posSlider.get()
					if cur < Config.content.trackDuration then
						posSlider.set(cur + 0.08, true)
					else
						posSlider.set(0, true)
					end
				end
			end, { name = "visualizer", rate = 30, priority = 6 })

			local playClick = play.body:FindFirstChild("Click")
			if playClick then
				playClick.MouseButton1Click:Connect(function()
					playing = not playing
					play:setIcon(playing and "pause" or "play")
					Sfx.play("toggleOn")
					win.onClose = function()
						if mediaVisualizerTask then
							Scheduler.unschedule(mediaVisualizerTask)
							mediaVisualizerTask = nil
						end
					end
				end)
			end
			local function skipHandler(dir)
				return function()
					Notifications.push({
						title = dir > 0 and "Next" or "Previous",
						body = "Track " .. math.random(1, 999) .. " begins in an alternate universe.",
						icon = "music",
						duration = 2.5,
					})
					posSlider.set(0, true)
					Glass.ripple(vizHolder, vizHolder.AbsoluteSize.X / 2, vizHolder.AbsoluteSize.Y / 2)
				end
			end
			local prevClick = prev.body:FindFirstChild("Click")
			local nextClick = nextBtn.body:FindFirstChild("Click")
			if prevClick then
				prevClick.MouseButton1Click:Connect(skipHandler(-1))
			end
			if nextClick then
				nextClick.MouseButton1Click:Connect(skipHandler(1))
			end
			local shuffleClick = shuffle.body:FindFirstChild("Click")
			if shuffleClick then
				shuffleClick.MouseButton1Click:Connect(function()
					Notifications.push({
						title = "Shuffle",
						body = "Order: whatever the sine waves feel like.",
						icon = "shuffle",
						duration = 2,
					})
				end)
			end
			-- Tear the pump down with the window.
			artHolder.Destroying:Connect(function()
				if mediaVisualizerTask then
					Scheduler.unschedule(mediaVisualizerTask)
					mediaVisualizerTask = nil
				end
			end)
		end,
	})
end
-- TASKS -------------------------------------------------------------------------
Apps.tasks = {
	id = "tasks",
	label = "Tasks",
	icon = "check",
}
local taskSeed = {
	{ text = "Stare at the refraction rims", done = true },
	{ text = "Drag a window into a snap zone", done = false },
	{ text = "Type ↑↑↓↓←→←→BA somewhere", done = false },
	{ text = "Open the command palette with Ctrl+K", done = false },
	{ text = "Right-click the desktop", done = false },
	{ text = "Ship nothing. Admire the glass.", done = true },
}

function Apps.tasks.open()
	return WM.open({
		appId = "tasks",
		id = "tasks",
		title = "Placeholder Checklist",
		subtitle = "achievable goals, achieved locally",
		icon = "check",
		size = { 400, 420 },
		content = function(parent, win)
			local listHolder = create("Frame", {
				Name = "TaskList",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 40),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 1,
				Parent = parent,
			})
			create(
				"UIListLayout",
				{ Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = listHolder }
			)
			local remaining = W.label(listHolder, {
				text = "",
				size = 11,
				color = "faint",
				LayoutOrder = 999,
				anchor = Vector2.new(0, 0),
				position = UDim2.fromScale(0, 0),
				size2 = { 300, 14 },
			})
			local function refreshRemaining()
				local left = 0
				for _, t in taskSeed do
					if not t.done then
						left += 1
					end
				end
				remaining.Text = left == 0 and "All done. The glass is proud of you."
					or string.format("%d left · tap a row to toggle", left)
			end
			for i, t in taskSeed do
				local rowSurf = card(listHolder, { order = i, height = 42, name = "Task_" .. i })
				local content = rowSurf.content or rowSurf[2]
				local cb = W.checkbox(content, {
					value = t.done,
					position = UDim2.new(0, 2, 0.5, 0),
					onChanged = function(v)
						t.done = v
						refreshRemaining()
						if v and i == 2 then
							Glass.wobbleAll(0.25)
						end
					end,
				})
				local lbl = W.label(content, {
					text = t.text,
					size = 12.5,
					weight = "medium",
					position = UDim2.new(0, 34, 0.5, 0),
					truncate = true,
					size2 = { 280, 16 },
				})
				local function styleStruck()
					lbl.TextTransparency = t.done and 0.45 or 0
				end
				styleStruck()
				local rowClick = rowSurf.root:FindFirstChildOfClass("Content")
			end
			refreshRemaining()
			local addSurf = card(parent, { order = 500, height = 52, name = "TaskAdd" })
		end,
	})
end

-- CHAT ----------------------------------------------------------------------------
Apps.chat = {
	id = "chat",
	label = "Messages",
	icon = "chat",
}
local chatSeed = {
	{ me = false, text = "did you see the new glass framework?" },
	{ me = true, text = "the one that's all buttons and no consequence?" },
	{ me = false, text = "yes!! the caustics alone" },
	{ me = true, text = "i dragged a window into the corner and it SNAPPED" },
	{ me = false, text = "right click the desktop. thank me later." },
}
function Apps.chat.open()
	return WM.open({
		appId = "chat",
		id = "chat",
		title = "Messages",
		subtitle = "a conversation entirely about the UI",
		icon = "chat",
		size = { 420, 470 },
		content = function(parent, win)
			local thread = create("Frame", {
				Name = "Thread",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 40),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 1,
				Parent = parent,
			})
			local layout = create(
				"UIListLayout",
				{ Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = thread }
			)
			local order = 0
			local function addBubble(msg)
				order += 1
				local mine = msg.me
				local rowFrame = create("Frame", {
					Name = "Row" .. order,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 44),
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = order,
					ZIndex = 22,
					Parent = thread,
				})
				local bubble = create("Frame", {
					Name = "Bubble",
					BackgroundColor3 = mine and Color3.fromRGB(90, 150, 240) or Color3.fromRGB(44, 49, 62),
					BackgroundTransparency = mine and 0.12 or 0.25,
					Size = UDim2.fromScale(0.84, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					AnchorPoint = Vector2.new(mine and 1 or 0, 0),
					Position = UDim2.fromScale(mine and 1 or 0, 0),
					LayoutOrder = 1,
					ZIndex = 22,
					Parent = rowFrame,
				})
				local minR = mine and 16 or 0
				local maxR = mine and 0 or 16
				create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = bubble })
				create("UIPadding", {
					PaddingTop = UDim.new(0, 8),
					PaddingBottom = UDim.new(0, 8),
					PaddingLeft = UDim.new(0, 12),
					PaddingRight = UDim.new(0, 12),
					Parent = bubble,
				})
				local txt = W.label(bubble, {
					text = msg.text,
					size = 12.5,
					color = mine and Color3.fromRGB(255, 255, 255) or "text",
					wrapped = true,
					anchor = Vector2.new(0, 0),
					position = UDim2.new(0, 12, 0, 8),
					size2 = { 260, 16 },
					zIndex = 23,
				})
				txt.Size = UDim2.new(1, -24, 0, 14)
				txt.AutomaticSize = Enum.AutomaticSize.Y
				txt.TextYAlignment = Enum.TextYAlignment.Top
				-- pop-in spring
				local pop = Spring.new(0.6, Config.motion.springBouncy)
				local sc = create("UIScale", { Scale = 0.6, Parent = bubble })
				local j
				j = Scheduler.schedule(function(dt)
					local rest = pop:step(dt)
					sc.Scale = pop._position
					if rest then
						Scheduler.unschedule(j)
					end
				end, { name = "bubble", rate = "frame", priority = 2 })
				pop:setTarget(1)
				task.defer(function()
					win.scroll.CanvasPosition = Vector2.new(0, math.huge)
				end)
				return bubble
			end

			for _, msg in chatSeed do
				addBubble(msg)
			end
			local typingRow = W.label(parent, {
				text = "",
				size = 10.5,
				color = "faint",
				anchor = Vector2.new(0, 0),
				position = UDim2.new(0, 4, 0, 0),
				size2 = { 200, 14 },
				weight = "medium",
			})
			typingRow.LayoutOrder = 2
			local inputSurf = create("Frame", {
				Name = "Composer",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 40),
				LayoutOrder = 3,
				Parent = parent,
			})
			local inp = W.input(inputSurf, {
				size = UDim2.new(1, -60, 1, 0),
				placeholder = "Say something glassy…",
				textSize = 13,
			})
			local sendBtn = W.button(inputSurf, {
				label = "",
				icon = "arrowUp",
				iconSize = 15,
				iconPad = 12,
				variant = "primary",
				widthPx = 48,
				height = 36,
				position = UDim2.new(1, -50, 0.5, 0),
				anchor = Vector2.new(0, 0.5),
				capsule = true,
				roundness = 18,
			})
			local replies = {
				"magnificent",
				"the rims are doing numbers",
				"placeholder supremacy",
				"i right-clicked and got feelings",
				"ship it? ship nothing. it is art.",
			}
			local function send()
				local text = inp.get()
				if text == "" then
					return
				end
				inp.set("")
				addBubble({ me = true, text = text })
				typingRow.Text = "someone is typing"
				task.delay(1.1, function()
					typingRow.Text = ""
					addBubble({ me = false, text = Math.randomChoice(replies) })
					Sfx.play("notify")
				end)
				Sfx.play("click")
			end
			local sendClick = sendBtn.body:FindFirstChild("Click")
			if sendClick then
				sendClick.MouseButton1Click:Connect(send)
			end
			task.spawn(function()
				while sendBtn.holder.Parent do
					task.wait(0.12)
					local t = os.clock() % 1.6 / 1.6
					typingRow.Text = typingRow.Text ~= "" and typingRow.Text .. (" "):rep(1 + math.floor(t * 3) % 3)
						or typingRow.Text
				end
			end)
		end,
	})
end

-- TERMINAL (self-aware fake shell) ---------------------------------------------------
Apps.terminal = {
	id = "terminal",
	label = "Terminal",
	icon = "terminal",
}
function Apps.terminal.open()
	return WM.open({
		appId = "terminal",
		id = "terminal",
		title = "nocturne-sh",
		subtitle = "commands affect the UI, never the game",
		icon = "terminal",
		size = { 520, 400 },
		content = function(parent, win)
			local screenSurf = card(parent, { order = 1, height = 300, name = "TermScreen", pad = 12 })
			local screen = create("ScrollingFrame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				ScrollBarThickness = 3,
				BorderSizePixel = 0,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.fromScale(0, 0),
				ZIndex = 24,
				Parent = screenSurf.content,
			})
			if typeof(screen) ~= "Instance" then
				return
			end
			local list = create(
				"UIListLayout",
				{ Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder, Parent = screen }
			)
			local lineCount = 0
			local function writeLine(text, colour, prefix)
				lineCount += 1
				local line = W.label(screen, {
					text = (prefix or "") .. text,
					size = 11.5,
					weight = "medium",
					color = colour or "text",
					anchor = Vector2.new(0, 0),
					position = UDim2.fromScale(0, 0),
					size2 = { screen.AbsoluteSize.X - 14, 15 },
					wrapped = true,
					zIndex = 25,
					LayoutOrder = lineCount,
				})
				line.LayoutOrder = lineCount
				task.defer(function()
					screen.CanvasPosition = Vector2.new(0, math.huge)
				end)
				return line
			end
			local runCommand -- forward: the history wrapper below rebinds this
			-- typewriter boot log
			local bootLines = {
				{ "nocturne sh 1.0.0 (" .. Nocturne.CODENAME .. ")", "accent" },
				{ "probing glass primitives .............. ok", "dim" },
				{ "mounting refractive surfaces ........... ok", "dim" },
				{ "synthesising interface sfx ............. ok", "dim" },
				{ "features ................................ NONE (by design)", "success" },
				{ "type `help` for the command list.", "text" },
			}
			task.spawn(function()
				for _, bl in bootLines do
					if not screen.Parent then
						return
					end
					local line = writeLine("", bl[2], "❯ ")
					local full = bl[1]
					for i = 1, #full do
						if not line.Parent then
							return
						end
						line.Text = "❯ " .. full:sub(1, i)
						task.wait(State.reduceMotion and 0 or 0.012)
					end
					task.wait(0.05)
				end
			end)
			local cmdPrompt = W.input(parent, {
				size = UDim2.new(1, 0, 0, 36),
				position = UDim2.new(0, 0, 0, 0),
				placeholder = "",
				textSize = 12,
				mono = true,
				zIndex = 25,
			})
			runCommand = function(raw)
				local cmd = (raw or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower()
				writeLine(raw, "accent", "❯ ")
				if cmd == "" then
					return
				end
				local parts = Str.split(cmd, " ")
				local head = parts[1]
				if head == "help" then
					for _, h in
						{
							"help              this list",
							"theme [name]      obsidian · midnight · nebula · abyss · porcelain · walu · …",
							"accent [name]     moonstone · iris · ember · mint · solar · coral · glacier",
							"blur [0-100]      scene blur strength",
							"wobble [n]        kick every glass surface",
							"open [app]        settings · home · media · stats · tasks · chat · files · about",
							"close all         dismiss all windows",
							"count             surfaces, windows, springs in use",
							"echo [text]       print text back, purely because",
							"sudo [anything]   nice try",
						}
					do
						writeLine(h, "dim")
					end
				elseif head == "theme" then
					local name = parts[2]
					if name and Theme._defs[name] then
						Theme.apply(name)
						writeLine("theme → " .. name, "success")
					else
						writeLine("available: " .. Str.join(
							T.map(Theme.list(), function(x)
								return x.id
							end),
							", "
						), "warning")
					end
				elseif head == "accent" then
					local name = parts[2]
					local found = false
					for _, a in Theme.accentList() do
						if a.id == name then
							Theme.setAccent(name)
							found = true
							break
						end
					end
					writeLine(
						found and ("accent → " .. name) or ("unknown accent: " .. tostring(name)),
						found and "success" or "danger"
					)
				elseif head == "blur" then
					local v = tonumber(parts[2] or "")
					if v then
						State.blurStrength = Math.clamp(v / 100, 0, 2)
						Depth.recompute()
						writeLine(string.format("scene blur strength = %.2f", State.blurStrength), "success")
					else
						writeLine("usage: blur [0-100]", "warning")
					end
				elseif head == "wobble" then
					Glass.wobbleAll(tonumber(parts[2]) or 0.6)
					writeLine("wobbled " .. Glass.count() .. " surfaces", "success")
				elseif head == "open" then
					local app = parts[2]
					if Apps[app] and Apps[app].open then
						Apps[app].open()
						writeLine("launched " .. app, "success")
					else
						writeLine("no such app: " .. tostring(app), "danger")
					end
				elseif head == "close" then
					for _, w in table.clone(WM.order) do
						WM.close(w)
					end
					writeLine("cleared", "success")
				elseif head == "count" then
					writeLine(
						string.format("%d surfaces · %d windows · fps %.0f", Glass.count(), #WM.order, State.fps),
						"text"
					)
				elseif head == "echo" then
					writeLine(raw:gsub("^echo%s+", ""), "text")
				elseif head == "sudo" then
					writeLine("this terminal has no privileges and no responsibilities", "warning")
				else
					writeLine("command not found: " .. head .. "  (try help)", "danger")
				end
			end
			cmdPrompt.field.FocusLost:Connect(function(enter)
				if enter then
					local t = cmdPrompt.get()
					cmdPrompt.set("")
					runCommand(t)
				end
			end)
			-- Up-arrow history, because a shell without history is a suggestion box.
			do
				local history, histIndex = {}, 0
				local conn = UserInputService.InputBegan:Connect(function(input, gpe)
					if gpe or not cmdPrompt.field:IsFocused() then
						return
					end
					if input.KeyCode == Enum.KeyCode.Up then
						histIndex = math.min(#history, histIndex + 1)
						if history[histIndex] then
							cmdPrompt.set(history[histIndex])
						end
					elseif input.KeyCode == Enum.KeyCode.Down then
						histIndex = math.max(0, histIndex - 1)
						cmdPrompt.set(history[histIndex] or "")
					end
				end)
				local origRun = runCommand
				runCommand = function(raw)
					if raw and raw ~= "" then
						table.insert(history, 1, raw)
						if #history > 32 then
							table.remove(history)
						end
					end
					histIndex = 0
					origRun(raw)
				end
			end
		end,
	})
end

-- FILES (fake tree, real glass) ------------------------------------------------------
Apps.files = {
	id = "files",
	label = "Files",
	icon = "folder",
}
local fakeTree = {
	["Nocturne"] = {
		kind = "folder",
		children = {
			{
				name = "glass",
				kind = "folder",
				children = {
					{ name = "refraction.lua", kind = "lua", size = 4821 },
					{ name = "caustics.lua", kind = "lua", size = 3310 },
					{ name = "specular.lua", kind = "lua", size = 2955 },
				},
			},
			{
				name = "themes",
				kind = "folder",
				children = {
					{ name = "obsidian.theme", kind = "theme", size = 1203 },
					{ name = "nebula.theme", kind = "theme", size = 1288 },
				},
			},
			{ name = "README.md", kind = "md", size = 6612 },
			{ name = "LICENSE", kind = "text", size = 1074 },
			{ name = "features", kind = "folder", children = {} },
		},
	},
}
local fileColors = {
	lua = Color3.fromRGB(90, 150, 240),
	theme = Color3.fromRGB(170, 120, 240),
	md = Color3.fromRGB(120, 200, 160),
	text = Color3.fromRGB(160, 170, 185),
	folder = Color3.fromRGB(250, 200, 90),
}
function Apps.files.open(node, pathName)
	node = node or fakeTree["Nocturne"]
	pathName = pathName or "Nocturne"
	return WM.open({
		appId = "files_" .. pathName,
		id = "files_" .. pathName,
		title = pathName,
		subtitle = "the folder named `features` is empty. that's the joke.",
		icon = "folder",
		size = { 430, 400 },
		content = function(parent, win)
			local crumbs = create("Frame", {
				Name = "Crumbs",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 22),
				LayoutOrder = 1,
				Parent = parent,
			})
			W.label(crumbs, {
				text = "📁 " .. pathName,
				size = 11,
				color = "dim",
				anchor = Vector2.new(0, 0.5),
				position = UDim2.new(0, 2, 0.5, 0),
				size2 = { 300, 14 },
			})
			local listHolder = create("Frame", {
				Name = "Entries",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 40),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = 2,
				Parent = parent,
			})
			create(
				"UIListLayout",
				{ Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder, Parent = listHolder }
			)
			local entries = node.children or {}
			if #entries == 0 then
				W.label(listHolder, {
					text = "empty — like the feature list",
					size = 12,
					color = "faint",
					anchor = Vector2.new(0, 0),
					position = UDim2.fromScale(0, 6),
					size2 = { 300, 20 },
				})
			end
			for i, entry in entries do
				local row = create("Frame", {
					Name = "Entry" .. i,
					BackgroundColor3 = Color3.fromRGB(38, 43, 56),
					BackgroundTransparency = 0.35,
					Size = UDim2.new(1, 0, 0, 36),
					LayoutOrder = i,
					ZIndex = 22,
					Parent = listHolder,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = row })
				local icHolder = create("Frame", {
					BackgroundColor3 = fileColors[entry.kind] or Color3.fromRGB(120, 130, 150),
					BackgroundTransparency = 0.78,
					AnchorPoint = Vector2.new(0, 0.5),
					Size = UDim2.fromOffset(26, 26),
					Position = UDim2.new(0, 6, 0.5, 0),
					ZIndex = 23,
					Parent = row,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = icHolder })
				local icon = entry.kind == "folder" and "folder" or (entry.kind == "lua" and "terminal" or "file")
				if not IconKit.has(icon) then
					icon = "file"
				end
				local ic = IconKit.attach(icHolder, icon, {
					size = 14,
					color = fileColors[entry.kind] or Color3.fromRGB(200, 210, 225),
					subscribeToTheme = false,
				})
				ic.frame.AnchorPoint = Vector2.new(0.5, 0.5)
				ic.frame.Position = UDim2.fromScale(0.5, 0.5)
				W.label(row, {
					text = entry.name,
					size = 12.5,
					weight = "medium",
					position = UDim2.new(0, 40, 0.44, 0),
					truncate = true,
					size2 = { 220, 14 },
				})
				if entry.size then
					W.label(row, {
						text = Str.bytes(entry.size),
						size = 10,
						color = "faint",
						anchor = Vector2.new(1, 0),
						position = UDim2.new(1, -8, 0.3, 0),
						size2 = { 60, 12 },
					})
				end
				local click = create("TextButton", {
					BackgroundTransparency = 1,
					Text = "",
					AutoButtonColor = false,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 24,
					Parent = row,
				})
				if entry.kind == "folder" then
					click.MouseButton1Click:Connect(function()
						Apps.files.open(entry, pathName .. "/" .. entry.name)
						Sfx.play("windowOpen")
					end)
				else
					click.MouseButton1Click:Connect(function()
						Notifications.push({
							title = entry.name,
							body = "Opening text files is a feature, and features are out of scope.",
							icon = "file",
							duration = 3,
						})
						Sfx.play("error")
					end)
				end
				local enterConn = click.MouseEnter:Connect(function()
					row.BackgroundTransparency = 0.22
				end)
				click.MouseLeave:Connect(function()
					row.BackgroundTransparency = 0.35
				end)
			end
		end,
	})
end

-- ABOUT -----------------------------------------------------------------------------
Apps.about = {
	id = "about",
	label = "About",
	icon = "info",
}
function Apps.about.open()
	return WM.open({
		appId = "about",
		id = "about",
		title = "About Nocturne",
		icon = "sparkle",
		size = { 430, 440 },
		content = function(parent, win)
			local hero = card(parent, { order = 1, height = 150, name = "Hero", caustics = true })
			local hc = hero[2] or hero.content
			local mark = create("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0),
				Size = UDim2.fromOffset(56, 56),
				Position = UDim2.new(0.5, 0, 0, 10),
				ZIndex = 25,
				Parent = hc,
			})
			create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = mark })
			local markStroke = create("UIStroke", { Thickness = 4, Transparency = 0.1, Parent = mark })
			local markDot = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(12, 12),
				Position = UDim2.new(0.5, 0, 0.5, -12),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				ZIndex = 25,
				Parent = mark,
			})
			create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = markDot })
			local markRot = create("UIRotation", { Angle = 0, Parent = mark })
			Scheduler.schedule(function(dt)
				markRot.Angle += dt * 0.35
			end, { name = "aboutSpin", rate = "frame", priority = 5 })
			W.label(hc, {
				text = "Nocturne UI",
				size = 22,
				weight = "display",
				anchor = Vector2.new(0.5, 0),
				position = UDim2.new(0.5, 0, 0, 76),
				size2 = { 300, 26 },
			})
			W.label(hc, {
				text = "v" .. Nocturne.VERSION .. " · " .. Nocturne.CODENAME,
				size = 11,
				color = "dim",
				anchor = Vector2.new(0.5, 0),
				position = UDim2.new(0.5, 0, 0, 104),
				size2 = { 300, 14 },
			})
			local body = card(parent, { order = 2, height = 200, name = "License" })
			local bc = body[2] or body.content
			W.label(bc, {
				text = "A dark liquid-glass interface kit for Roblox. 100% Luau, one script, zero assets, zero features. MIT licensed — fork it, strip it, ship it, give it to a friend.\n\nEverything on screen is a placeholder demonstrating the material: refraction rims, cursor-tracking specular, drifting caustics, spring physics, and a dock that magnifies out of pure respect.\n\nBuilt for people who want their UI to look like iOS and macOS had a night out.",
				size = 12,
				color = "dim",
				wrapped = true,
				anchor = Vector2.new(0, 0),
				position = UDim2.fromScale(0, 0),
				size2 = { 370, 150 },
				zIndex = 25,
			})
			local row = create("Frame", {
				Name = "BtnRow",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 40),
				LayoutOrder = 3,
				Parent = parent,
			})
			W.button(row, {
				label = "MIT License",
				icon = "shield",
				variant = "tint",
				widthPx = 128,
				height = 36,
				position = UDim2.new(0, 0, 0, 2),
				onClicked = function()
					Notifications.push({
						title = "MIT",
						body = "Do whatever, keep the header. That's the whole contract.",
						icon = "shield",
						duration = 4,
					})
				end,
			})
			W.button(row, {
				label = "Star it (in your heart)",
				icon = "star",
				variant = "glass",
				widthPx = 176,
				height = 36,
				position = UDim2.new(0, 136, 0, 2),
				onClicked = function()
					Sfx.play("cheat")
					Glass.wobbleAll(0.4)
					Notifications.push({
						title = "★",
						body = "Registered. Emotionally.",
						icon = "star",
						kind = "success",
						duration = 2.4,
					})
				end,
			})
			local _ = markStroke
		end,
	})
end

-- CHEAT SHEET ------------------------------------------------------------------------
Apps.cheats = {
	id = "cheats",
	label = "Hotkeys",
	icon = "keyboard",
}
function Apps.cheats.open()
	return WM.open({
		appId = "cheats",
		id = "cheats",
		title = "Hotkeys & Cheat Codes",
		subtitle = "muscle memory, formatted nicely",
		icon = "keyboard",
		size = { 420, 430 },
		content = function(parent, win)
			local entries = {
				{ keys = { "Ctrl/⌘", "K" }, what = "Command palette" },
				{ keys = { "Ctrl/⌘", "," }, what = "Settings" },
				{ keys = { "Ctrl/⌘", "J" }, what = "Toggle dock" },
				{ keys = { "Ctrl/⌘", "E" }, what = "Mission control" },
				{ keys = { "Ctrl/⌘", "M" }, what = "Minimise focused window" },
				{ keys = { "Ctrl/⌘", "N" }, what = "Notification centre" },
				{ keys = { "Ctrl/⌘", "⇧", "F" }, what = "Hide/show all glass" },
				{ keys = { "Ctrl/⌘", "⇧", "L" }, what = "Lock screen" },
				{ keys = { "Ctrl/⌘", "⇧", "P" }, what = "Capture flash" },
				{ keys = { "Ctrl/⌘", "⇧", "/" }, what = "Diagnostics panel" },
				{ keys = { "Esc" }, what = "Close topmost surface" },
				{ keys = { "↑↑↓↓←→←→", "B", "A" }, what = "The liquid ascension" },
				{ keys = { "W", "O", "B", "B", "L", "E" }, what = "Typo simulator (real)" },
			}
			for i, e in entries do
				local row = create("Frame", {
					Name = "Key_" .. i,
					BackgroundColor3 = Color3.fromRGB(40, 45, 58),
					BackgroundTransparency = 0.4,
					Size = UDim2.new(1, 0, 0, 34),
					LayoutOrder = i,
					ZIndex = 22,
					Parent = parent,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 9), Parent = row })
				W.label(row, {
					text = e.what,
					size = 12.5,
					weight = "medium",
					anchor = Vector2.new(1, 0.5),
					position = UDim2.new(1, -10, 0.5, 0),
					truncate = true,
					size2 = { 210, 14 },
				})
				local keyH = create("Frame", {
					Name = "Keys",
					BackgroundTransparency = 1,
					Size = UDim2.new(0.5, -8, 1, -8),
					Position = UDim2.new(0, 8, 0, 4),
					ZIndex = 23,
					Parent = row,
				})
				create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 4),
					Parent = keyH,
				})
				for j, k in e.keys do
					W.keycap(keyH, k, { width = math.max(22, #k * 9 + 12), height = 20, size = 10.5 })
				end
				local click = create("TextButton", {
					BackgroundTransparency = 1,
					Text = "",
					AutoButtonColor = false,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 24,
					Parent = row,
				})
				click.MouseButton1Click:Connect(function()
					-- Demo the action itself where it is safe and silly to do so.
					if e.what:find("palette") then
						Nocturne.Spotlight.toggle(true)
					elseif e.what:find("dock") then
						Dock.toggle()
					elseif e.what:find("Mission") then
						Nocturne.MissionControl.toggle()
					elseif e.what:find("Settings") then
						Apps.settings.open()
					else
						Notifications.push({
							title = "Nice try (in a good way)",
							body = "Type it for real: " .. table.concat(e.keys, " + "),
							icon = "keyboard",
							duration = 3,
						})
					end
				end)
			end
		end,
	})
end

-- STATS -------------------------------------------------------------------------------
Apps.stats = {
	id = "stats",
	label = "Stats",
	icon = "cpu",
}
function Apps.stats.open()
	return WM.open({
		appId = "stats",
		id = "stats",
		title = "Activity",
		subtitle = "real numbers about a fake UI",
		icon = "cpu",
		size = { 480, 400 },
		content = function(parent, win)
			local grids = create("Frame", {
				Name = "Grids",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 230),
				LayoutOrder = 1,
				Parent = parent,
			})
			create(
				"UIGridLayout",
				{ CellSize = UDim2.new(0.5, -8, 0, 108), CellPadding = UDim2.new(0, 12, 0, 12), Parent = grids }
			)
			local series = {
				{
					name = "FRAME TIME",
					unit = "ms",
					color = nil,
					data = table.create(60),
					push = function(self, v)
						table.insert(self.data, v)
						if #self.data > 60 then
							table.remove(self.data, 1)
						end
					end,
				},
				{ name = "GLASS SURFACES", unit = "", data = table.create(60) },
				{ name = "OPEN WINDOWS", unit = "", data = table.create(60) },
				{ name = "CPU GHOST", unit = "%", data = table.create(60) },
			}
			local ghosts = { 40, 55, 30 }
			local graphs = {}
			for i, s in series do
				local surf = card(grids, { order = i, height = 108, name = "Graph_" .. s.name, pad = 10 })
				local content = surf[2] or surf.content
				W.label(content, {
					text = s.name,
					size = 9,
					weight = "black",
					color = "faint",
					anchor = Vector2.new(0, 0),
					position = UDim2.new(0, 0, 0, 0),
					size2 = { 120, 12 },
				})
				local val = W.label(content, {
					text = "—",
					size = 20,
					weight = "display",
					anchor = Vector2.new(1, 0),
					position = UDim2.new(1, 0, 0, -2),
					size2 = { 110, 24 },
				})
				local graphFrame = create("Frame", {
					Name = "Bars",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 52),
					Position = UDim2.new(0, 0, 1, -8),
					AnchorPoint = Vector2.new(0, 1),
					ZIndex = 24,
					Parent = content,
				})
				create("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Bottom,
					Padding = UDim.new(0, 1),
					SortOrder = Enum.SortOrder.LayoutOrder,
					Parent = graphFrame,
				})
				local bars = {}
				for b = 1, 40 do
					local bar = create("Frame", {
						Name = "B",
						BackgroundColor3 = Color3.fromRGB(120, 200, 255),
						BackgroundTransparency = 0.4,
						Size = UDim2.new(1 / 40, 0, 0, 4),
						LayoutOrder = b,
						Parent = graphFrame,
						ZIndex = 24,
					})
					create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = bar })
					table.insert(bars, bar)
				end
				table.insert(graphs, { bars = bars, val = val, series = s, frame = graphFrame })
			end
			local function pushSeries(idx, v)
				local s = series[idx]
				table.insert(s.data, v)
				if #s.data > 60 then
					table.remove(s.data, 1)
				end
			end
			local cpuGhost = 35
			task.spawn(function()
				while parent.Parent do
					local ft = Scheduler.fpsTracker.frameTime * 1000
					pushSeries(1, ft)
					pushSeries(2, Glass.count())
					pushSeries(3, #WM.order)
					cpuGhost = Math.clamp(
						cpuGhost + Math.randomRange(-9, 9) + (Scheduler._taskCount > 60 and 1.5 or -1),
						4,
						96
					)
					pushSeries(4, cpuGhost)
					for gi, g in graphs do
						local data = g.series.data
						local count = #g.bars
						local slice = #data - count + 1
						local maxV = 1
						for k = math.max(1, slice), #data do
							if data[k] and data[k] > maxV then
								maxV = data[k]
							end
						end
						for b = 1, count do
							local idx = slice + b - 1
							local v = data[idx] or 0
							g.bars[b].Size = UDim2.new(1 / count, 0, 0, math.max(2, v / maxV * 48))
							g.bars[b].BackgroundTransparency = 0.15 + 0.5 * (1 - v / maxV)
						end
						local last = data[#data] or 0
						g.val.Text = (gi == 1) and string.format("%.1f ms", last)
							or (gi == 4) and string.format("%.0f%%", last)
							or string.format("%d", last)
					end
					task.wait(0.1)
				end
			end)
			local schedSurf = card(parent, { order = 2, height = 86, name = "SchedCard" })
			local schedVal = W.label(schedSurf[2] or schedSurf.content, {
				text = "",
				size = 12,
				color = "dim",
				anchor = Vector2.new(0, 0),
				position = UDim2.new(0, 0, 0, 22),
				size2 = { 400, 40 },
				wrapped = true,
			})
			W.label(schedSurf[2] or schedSurf.content, {
				text = "SCHEDULER",
				size = 9,
				weight = "black",
				color = "faint",
				anchor = Vector2.new(0, 0),
				position = UDim2.fromScale(0, 0),
				size2 = { 100, 12 },
			})
			task.spawn(function()
				while schedVal.Parent do
					local st = Scheduler.stats()
					schedVal.Text = string.format(
						"%d live tasks · %d total errors · pump %.2f ms avg (engine frame)",
						st.total or 0,
						st.errors or 0,
						Scheduler.fpsTracker.frameTime * 1000
					)
					task.wait(0.4)
				end
			end)
		end,
	})
end
--═══════════════════════════════════════════════════════════════════════════════--
-- § 18  WALLPAPER ENGINE + AMBIENCE
--
-- The desktop is not a flat colour. It is a slow lava lamp: gradient bed, three
-- drifting orbs (the "aurora"), a twinkling starfield on dark themes, all nudged
-- by the cursor for parallax. This is the layer that makes translucent windows
-- look like they float above a place instead of sitting on a rectangle.
--═══════════════════════════════════════════════════════════════════════════════--

local Wallpaper = {
	orbs = {},
	stars = {},
	bed = nil,
	bedGrad = nil,
	drift = true,
	phase = 0,
	root = nil,
}
Nocturne.Wallpaper = Wallpaper

function Wallpaper.build()
	if Wallpaper.root then
		return Wallpaper.root
	end
	local layer = App.layers and App.layers.wallpaper
	if not layer then
		return nil
	end
	local root = create("Frame", {
		Name = "Wallpaper",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
		Parent = layer,
	})
	Wallpaper.root = root

	-- Gradient bed: three stops that breathe.
	local bed = create("Frame", {
		Name = "Bed",
		BackgroundColor3 = Color3.fromRGB(8, 10, 15),
		Size = UDim2.fromScale(1, 1),
		BorderSizePixel = 0,
		ZIndex = 1,
		Parent = root,
	})
	local bedGrad = create("UIGradient", {
		Rotation = 118,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 14, 22)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(18, 24, 36)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 8, 12)),
		}),
		Offset = Vector2.new(0, 0),
		Parent = bed,
	})
	Wallpaper.bed = bed
	Wallpaper.bedGrad = bedGrad

	-- Orbs: huge soft discs. Without true blur, a triple-stacked radial illusion
	-- (disc + gradient fade + low alpha) reads remarkably close at these sizes.
	local orbDefs = {
		{ r = 0.62, sx = 0.16, sy = 0.22, speed = 0.045, depth = 1.0 },
		{ r = 0.5, sx = -0.2, sy = 0.3, speed = 0.036, depth = 0.7 },
		{ r = 0.42, sx = 0.1, sy = -0.26, speed = 0.058, depth = 0.5 },
	}
	for i, od in orbDefs do
		local orb = create("Frame", {
			Name = "Orb" .. i,
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(od.r, od.r * 0.86),
			Position = UDim2.fromScale(0.5 + od.sx, 0.5 + od.sy),
			ZIndex = 2 + i,
			Parent = root,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = orb })
		local g = create("UIGradient", {
			Rotation = 90 + i * 40,
			Color = ColorSequence.new(Color3.fromRGB(40, 60, 90)),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.35),
				NumberSequenceKeypoint.new(0.55, 0.62),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Offset = Vector2.new(0.08, 0),
			Parent = orb,
		})
		local glow = create("UIStroke", {
			Thickness = 2.5,
			Transparency = 0.86,
			Color = Color3.fromRGB(120, 160, 220),
			Parent = orb,
		})
		table.insert(Wallpaper.orbs, { orb = orb, grad = g, glow = glow, def = od, seed = i * 17.3 })
	end

	-- Starfield.
	local starCount = IsAppView and 26 or 52
	for i = 1, starCount do
		local star = create("Frame", {
			Name = "Star" .. i,
			BackgroundColor3 = Color3.fromRGB(215, 228, 245),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(i % 7 == 0 and 3 or 2, i % 7 == 0 and 3 or 2),
			Position = UDim2.fromScale(Math.hash1D(i * 3.7), Math.hash1D(i * 9.1)),
			BackgroundTransparency = 0.4,
			ZIndex = 6,
			Parent = root,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = star })
		table.insert(
			Wallpaper.stars,
			{ frame = star, phase = Math.hash1D(i * 11.9) * math.pi * 2, speed = 0.3 + Math.hash1D(i * 5.3) * 0.8 }
		)
	end

	-- Vignette: corners darker, focus centre.
	local vignette = create("Frame", {
		Name = "Vignette",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 8,
		Parent = root,
	})
	local vg = create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(0, 0, 0)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.45, 0.85),
			NumberSequenceKeypoint.new(1, 0.2),
		}),
		Parent = vignette,
	})
	Wallpaper.vignette = vignette
	Wallpaper.vignetteGrad = vg

	-- Theme-reactive paint ------------------------------------------------------
	local function paintWall(t)
		bedGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, t.wall[1]),
			ColorSequenceKeypoint.new(0.5, t.wall[2]),
			ColorSequenceKeypoint.new(1, t.wall[3]),
		})
		for i, o in Wallpaper.orbs do
			local col = t.orb[((i - 1) % #t.orb) + 1]
			local lifted = Color.addWhite(col, t.light and -0.1 or 0.12)
			o.grad.Color = ColorSequence.new(lifted)
			o.glow.Color = Color.addWhite(lifted, 0.3)
			o.grad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, t.light and 0.5 or 0.32),
				NumberSequenceKeypoint.new(0.55, t.light and 0.72 or 0.62),
				NumberSequenceKeypoint.new(1, 1),
			})
		end
		local starBase = t.light and 0.9 or 0.3
		for _, s in Wallpaper.stars do
			s.baseTransparency = starBase
			s.frame.BackgroundColor3 = t.text
		end
	end
	Theme.register(paintWall)

	-- One drift pump for the whole scene. Half-rate: this is weather, not animation.
	Scheduler.schedule(function(dt)
		if not Wallpaper.drift or State.reduceMotion then
			return
		end
		Wallpaper.phase += dt
		local t = Wallpaper.phase
		local px = (Cursor.smooth.X / math.max(1, viewport().X) - 0.5) * 2
		local py = (Cursor.smooth.Y / math.max(1, viewport().Y) - 0.5) * 2
		for _, o in Wallpaper.orbs do
			local d = o.def
			local nx = 0.5
				+ d.sx
				+ math.sin(t * d.speed + o.seed) * 0.16
				+ px * Config.motion.parallaxStrength * d.depth * 3
			local ny = 0.5
				+ d.sy
				+ math.cos(t * d.speed * 0.8 + o.seed) * 0.12
				+ py * Config.motion.parallaxStrength * d.depth * 3
			o.orb.Position = UDim2.fromScale(nx, ny)
			local wob = 1 + math.sin(t * d.speed * 1.7 + o.seed) * 0.06
			o.orb.Size = UDim2.fromScale(d.r * wob, d.r * 0.86 * (2 - wob))
		end
		for _, s in Wallpaper.stars do
			local tw = 0.5 + 0.5 * math.sin(t * s.speed + s.phase)
			s.frame.BackgroundTransparency = Math.clamp01((s.baseTransparency or 0.4) + tw * 0.55)
		end
	end, { name = "wallpaper", rate = 30, priority = 7 })

	return root
end

function Wallpaper.toggle()
	Wallpaper.drift = not Wallpaper.drift
end

function Wallpaper.shuffle()
	for i, o in Wallpaper.orbs do
		o.def.sx = Math.randomRange(-0.32, 0.32)
		o.def.sy = Math.randomRange(-0.3, 0.3)
		o.def.speed = Math.randomRange(0.028, 0.075)
		o.seed = Math.randomRange(0, 60)
	end
end

-- Dust: ambient motes that drift upward through the scene. Pooled, budgeted,
-- and completely harmless.
local Particles = {
	pool = {},
	live = {},
	enabled = true,
}
Nocturne.Particles = Particles

function Particles.build()
	local layer = App.layers and App.layers.wallpaper
	if not layer then
		return
	end
	for i = 1, 40 do
		local mote = create("Frame", {
			Name = "Dust" .. i,
			BackgroundColor3 = Color3.fromRGB(190, 210, 240),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(2, 2),
			BackgroundTransparency = 1,
			ZIndex = 7,
			Visible = false,
			Parent = layer,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = mote })
		table.insert(Particles.pool, { frame = mote, active = false })
	end
	Scheduler.schedule(function(dt)
		if not Particles.enabled or State.reduceMotion then
			return
		end
		local vp = viewport()
		for _, m in Particles.pool do
			if m.active then
				m.y += m.vy * dt
				m.x += math.sin(os.clock() * m.wobSpeed + m.wobPhase) * m.wobAmp * dt
				m.life -= dt
				if m.life <= 0 or m.y < -20 then
					m.active = false
					m.frame.Visible = false
				else
					m.frame.Position = UDim2.fromOffset(m.x, m.y)
					local fade = Math.clamp01(m.life / m.maxLife)
					m.frame.BackgroundTransparency = 1 - 0.45 * fade * m.alpha
				end
			else
				if math.random() < dt * 1.4 and State.particlesAlive < Config.performance.particleBudget / 6 then
					m.active = true
					m.x = math.random() * vp.X
					m.y = vp.Y + 10
					m.vy = -math.random(6, 22)
					m.wobSpeed = math.random(0.4, 1.6)
					m.wobPhase = math.random(0, 6)
					m.wobAmp = math.random(4, 14)
					m.maxLife = math.random(6, 16)
					m.life = m.maxLife
					m.alpha = math.random(0.35, 1)
					local size = math.random(1.5, 3.2)
					m.frame.Size = UDim2.fromOffset(size, size)
					m.frame.Visible = true
				end
			end
		end
	end, { name = "dust", rate = 30, priority = 7 })
end

-- Cursor glow: a soft light under the pointer that pools over glass rims.
local CursorGlow = { frame = nil, spring = nil }
Nocturne.CursorGlow = CursorGlow

function CursorGlow.build()
	local layer = App.layers and App.layers.wallpaper
	if not layer then
		return
	end
	local glow = create("Frame", {
		Name = "CursorGlow",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(260, 220),
		ZIndex = 9,
		Parent = layer,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = glow })
	local g = create("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.fromRGB(140, 190, 255)),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.82),
			NumberSequenceKeypoint.new(0.5, 0.92),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = glow,
	})
	CursorGlow.frame = glow
	Theme.register(function(t)
		g.Color = ColorSequence.new(Color.addWhite(t.accent, 0.25))
	end)
	local pulse = Spring.new(1, Config.motion.springCinematic)
	Scheduler.schedule(function(dt)
		glow.Position = UDim2.fromOffset(Cursor.smooth.X, Cursor.smooth.Y)
		pulse:setTarget(Cursor.down and 1.35 or 1)
		pulse:step(dt)
		glow.Size = UDim2.fromOffset(260 * pulse._position, 220 * pulse._position)
		local idleFor = os.clock() - Cursor.lastActivity
		glow.Visible = idleFor < 6 and not State.mobile
	end, { name = "glow", rate = "frame", priority = 4 })
end

-- Capture flash ---------------------------------------------------------------------
local Capture = { flash = nil }
Nocturne.Capture = Capture

function Capture.flashScreen()
	local layer = App.layers and App.layers.toast
	if not layer then
		return
	end
	if not Capture.flash then
		Capture.flash = create("Frame", {
			Name = "CaptureFlash",
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 900,
			Parent = layer,
		})
	end
	local f = Capture.flash
	f.BackgroundTransparency = 0.1
	local startT = os.clock()
	local job
	job = Scheduler.schedule(function()
		local e = os.clock() - startT
		f.BackgroundTransparency = Math.clamp01(e / 0.28) * 0.9 + 0.1
		if e > 0.28 then
			f.BackgroundTransparency = 1
			Scheduler.unschedule(job)
		end
	end, { name = "flash", rate = "frame", priority = 0 })
	Sfx.play("swipe")
	Notifications.push({
		title = "Moment captured",
		body = "Pretend this screenshot went somewhere. In this kit, it goes to your heart.",
		icon = "camera",
		duration = 2.6,
	})
end

--═══════════════════════════════════════════════════════════════════════════════--
-- § 19  BOOT SEQUENCE + LOCK SCREEN
--═══════════════════════════════════════════════════════════════════════════════--

local Boot = { screen = nil, locked = false, lockPanel = nil }
Nocturne.Boot = Boot

function Boot.run(onDone)
	if not Config.boot.showBootSequence then
		onDone()
		return
	end
	local layer = App.layers and App.layers.toast
	local root = create("Frame", {
		Name = "BootScreen",
		BackgroundColor3 = Color3.fromRGB(5, 7, 11),
		BackgroundTransparency = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1000,
		Parent = layer,
	})
	local grad = create("UIGradient", {
		Rotation = 120,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 14, 22)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(4, 5, 8)),
		}),
		Parent = root,
	})
	-- centre stack
	local stack = create("Frame", {
		Name = "Stack",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(300, 220),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.46),
		Parent = root,
	})
	local mark = create("Frame", {
		Name = "Mark",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(64, 64),
		Position = UDim2.new(0.5, 0, 0, 10),
		Parent = stack,
		ZIndex = 3,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = mark })
	local markStroke =
		create("UIStroke", { Color = Color3.fromRGB(150, 190, 255), Thickness = 4, Transparency = 0.08, Parent = mark })
	local markDot = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(14, 14),
		Position = UDim2.new(0.5, 0, 0.5, -15),
		Parent = mark,
		ZIndex = 3,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = markDot })
	local markRot = create("UIRotation", { Angle = -14, Parent = mark })
	local markScale = create("UIScale", { Scale = 0.2, Parent = mark })
	local word = W.label(stack, {
		text = "N O C T U R N E",
		size = 19,
		weight = "black",
		color = Color3.fromRGB(235, 242, 252),
		anchor = Vector2.new(0.5, 0),
		position = UDim2.new(0.5, 0, 0, 96),
		size2 = { 300, 26 },
		align = "Center",
	})
	local wordTrans = create("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.5, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Offset = Vector2.new(-1, 0),
		Parent = word,
	})
	local sub = W.label(stack, {
		text = "liquid glass · obsidian refraction",
		size = 11,
		color = "dim",
		anchor = Vector2.new(0.5, 0),
		position = UDim2.new(0.5, 0, 0, 126),
		size2 = { 300, 16 },
		align = "Center",
	})
	local barRail = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(28, 34, 46),
		BackgroundTransparency = 0.1,
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.fromOffset(180, 4),
		Position = UDim2.new(0.5, 0, 0, 164),
		Parent = stack,
		ZIndex = 3,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = barRail })
	local barFill = create("Frame", {
		BackgroundColor3 = Color3.fromRGB(140, 190, 255),
		Size = UDim2.fromScale(0, 1),
		BorderSizePixel = 0,
		ZIndex = 4,
		Parent = barRail,
	})
	create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = barFill })
	local statusLine = W.label(stack, {
		text = "mounting surfaces",
		size = 10,
		color = "faint",
		anchor = Vector2.new(0.5, 0),
		position = UDim2.new(0.5, 0, 0, 186),
		size2 = { 300, 14 },
		align = "Center",
		weight = "mono",
	})

	Sfx.play("boot")
	local t0 = os.clock()
	local duration = math.max(0.9, Config.boot.minimumBootSeconds)
	local lines =
		{ "mounting surfaces", "seeding caustics", "polishing rims", "warming springs", "hiding features", "ready" }
	local job
	job = Scheduler.schedule(function()
		local e = (os.clock() - t0) / duration
		local frac = Math.clamp01(Easing.inOutQuart(Math.clamp01(e)))
		barFill.Size = UDim2.fromScale(frac, 1)
		markRot.Angle = -14 + e * 380
		local pop = Math.clamp01(e * 4)
		markScale.Scale = 0.2 + 0.8 * Easing.outBack(pop)
		wordTrans.Offset = Vector2.new(Math.pingPong(os.clock() * 1.2, 2) - 1, 0)
		statusLine.Text = lines[math.min(#lines, math.floor(frac * #lines) + 1)] or "ready"
		if e >= 1 then
			Scheduler.unschedule(job)
			-- curtain: scale up slightly and fade out with a scene wobble behind.
			local out = TweenService:Create(
				root,
				TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
				{ BackgroundTransparency = 1 }
			)
			local us = TweenService:Create(
				markScale,
				TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
				{ Scale = 1.06 }
			)
			out:Play()
			us:Play()
			task.delay(0.46, function()
				root:Destroy()
				onDone()
			end)
		end
	end, { name = "boot", rate = "frame", priority = 0 })
	Boot.screen = root
	return root
end

-- Lock screen ---------------------------------------------------------------------
function Boot.lock()
	if Boot.lockPanel then
		return
	end
	Boot.locked = true
	State.locked = true
	local layer = App.layers and App.layers.toast
	local root = create("Frame", {
		Name = "LockScreen",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 950,
		Parent = layer,
	})
	local dim = create("TextButton", {
		Name = "Dim",
		BackgroundColor3 = Color3.fromRGB(3, 4, 8),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
		Parent = root,
	})
	local surf = Glass.new(root, {
		name = "LockGlass",
		size = UDim2.new(1, -16, 1, -16),
		position = UDim2.new(0, 8, 0, 8),
		anchor = Vector2.new(0, 0),
		roundness = 30,
		tint = 0.18,
		caustics = true,
		interactive = false,
		shadow = true,
	})
	local content = surf.content
	local clock = W.label(content, {
		text = "--:--",
		size = 96,
		weight = "display",
		color = "text",
		anchor = Vector2.new(0.5, 0),
		position = UDim2.new(0.5, 0, 0.2, 0),
		size2 = { 500, 110 },
		align = "Center",
	})
	local date = W.label(content, {
		text = "",
		size = 17,
		weight = "medium",
		color = "dim",
		anchor = Vector2.new(0.5, 0),
		position = UDim2.new(0.5, 0, 0.2, 118),
		size2 = { 500, 24 },
		align = "Center",
	})
	local hint = W.label(content, {
		text = "click anywhere · this lock keeps nothing out but bad vibes",
		size = 12,
		color = "faint",
		anchor = Vector2.new(0.5, 1),
		position = UDim2.new(0.5, 0, 1, -26),
		size2 = { 500, 18 },
		align = "Center",
	})
	local hintPulse = create("UIScale", { Scale = 1, Parent = hint })
	local notifsMini = create("Frame", {
		Name = "LockNotifs",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -40, 0, 120),
		Position = UDim2.new(0, 20, 0.44, 0),
		ZIndex = 25,
		Parent = content,
	})
	create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = notifsMini })
	for i = 1, math.min(3, #Notifications.history) do
		local data = Notifications.history[i]
		local mini = create("Frame", {
			BackgroundColor3 = Color3.fromRGB(30, 36, 50),
			BackgroundTransparency = 0.35,
			Size = UDim2.new(1, 0, 0, 56),
			LayoutOrder = i,
			ZIndex = 26,
			Parent = notifsMini,
		})
		create("UICorner", { CornerRadius = UDim.new(0, 14), Parent = mini })
		local ic = IconKit.attach(mini, data.icon or "bell", { size = 15 })
		ic.frame.AnchorPoint = Vector2.new(0, 0.5)
		ic.frame.Position = UDim2.new(0, 12, 0.5, 0)
		W.label(mini, {
			text = data.title or "",
			size = 12,
			weight = "bold",
			position = UDim2.new(0, 40, 0.34, 0),
			truncate = true,
			size2 = { 240, 14 },
		})
		W.label(mini, {
			text = data.body or "",
			size = 10.5,
			color = "dim",
			position = UDim2.new(0, 40, 0.66, 0),
			truncate = true,
			size2 = { 260, 12 },
		})
	end
	local function tick()
		local t = os.date("*t")
		if t then
			local h12 = t.hour % 12
			if h12 == 0 then
				h12 = 12
			end
			clock.Text = string.format("%d:%02d", h12, t.min)
		end
		date.Text = Str.longDate()
	end
	tick()
	local clockJob = Scheduler.schedule(tick, { name = "lockClock", rate = 1, priority = 5 })
	Sfx.play("lock")
	local unlock
	unlock = function()
		if not Boot.lockPanel then
			return
		end
		Boot.locked = false
		State.locked = false
		Scheduler.unschedule(clockJob)
		local us = TweenService:Create(
			surf.root:FindFirstChildOfClass("UIScale") or create("UIScale", { Parent = surf.root }),
			TweenInfo.new(0.3, Enum.EasingStyle.Quint),
			{ Scale = 1.05 }
		)
		local a = TweenService:Create(dim, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { BackgroundTransparency = 1 })
		local b =
			TweenService:Create(root, TweenInfo.new(0.34, Enum.EasingStyle.Quint), { Size = UDim2.fromScale(1, 1) })
		us:Play()
		a:Play()
		b:Play()
		task.delay(0.34, function()
			root:Destroy()
			Boot.lockPanel = nil
		end)
	end
	local globalUnlockConn
	globalUnlockConn = UserInputService.InputBegan:Connect(function(input, gpe)
		if
			Boot.locked
			and (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.KeyCode == Enum.KeyCode.Return
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			unlock()
		end
	end)
	local realUnlock = unlock
	unlock = function()
		if globalUnlockConn then
			globalUnlockConn:Disconnect()
			globalUnlockConn = nil
		end
		realUnlock()
	end
	dim.MouseButton1Click:Connect(function()
		unlock()
	end)
	Boot.lockPanel = { root = root, unlock = unlock }
end

function Boot.unlock()
	if Boot.lockPanel then
		Boot.lockPanel.unlock()
	end
end

-- Diagnostics chip ------------------------------------------------------------------
local Diagnostics = { panel = nil, visible = false }
Nocturne.Diagnostics = Diagnostics

function Diagnostics.build()
	if Diagnostics.panel then
		return Diagnostics.panel
	end
	local layer = App.layers and App.layers.chrome
	local holder = create("Frame", {
		Name = "Diagnostics",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(190, 54),
		Position = UDim2.new(0, 10, 1, -118),
		ZIndex = 5,
		Parent = layer,
		Visible = false,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = holder })
	local bg = create("Frame", {
		Name = "Bg",
		BackgroundColor3 = Color3.fromRGB(8, 10, 16),
		BackgroundTransparency = 0.35,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
		Parent = holder,
	})
	create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = bg })
	create("UIStroke", { Transparency = 0.75, Thickness = 1, Parent = holder })
	local fpsLbl = W.label(holder, {
		text = "-- fps",
		size = 15,
		weight = "display",
		color = "success",
		anchor = Vector2.new(0, 0),
		position = UDim2.new(0, 10, 0, 6),
		size2 = { 120, 20 },
		zIndex = 4,
	})
	local metaLbl = W.label(holder, {
		text = "",
		size = 9,
		color = "faint",
		anchor = Vector2.new(0, 0),
		position = UDim2.new(0, 10, 0, 28),
		size2 = { 180, 12 },
		zIndex = 4,
	})
	local graphFrame = create("Frame", {
		Name = "Graph",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(64, 40),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 6),
		ZIndex = 4,
		Parent = holder,
	})
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 1),
		Parent = graphFrame,
	})
	local gbars = {}
	for i = 1, 22 do
		local b = create("Frame", {
			BackgroundColor3 = Color3.fromRGB(74, 222, 128),
			Size = UDim2.new(1 / 22, 0, 0, 2),
			LayoutOrder = i,
			BorderSizePixel = 0,
			Parent = graphFrame,
			ZIndex = 4,
		})
		table.insert(gbars, b)
	end
	Diagnostics.panel = holder
	Diagnostics.fpsLbl = fpsLbl
	Diagnostics.metaLbl = metaLbl
	Scheduler.schedule(function()
		if not holder.Visible then
			return
		end
		local fps = State.fps
		fpsLbl.Text = string.format("%.0f fps", fps)
		local tok = Theme.tokens()
		fpsLbl.TextColor3 = fps > 55 and tok.success or (fps > 38 and tok.warning or tok.danger)
		metaLbl.Text =
			string.format("%d surfaces · %d windows · %d tasks", Glass.count(), #WM.order, Scheduler._taskCount or 0)
		local graph = Scheduler.fpsTracker.graph
		for i = 1, #gbars do
			local idx = #graph - #gbars + i
			local dt = idx > 0 and graph[idx] or 0
			local h = Math.clamp(dt * 700, 1, 40)
			gbars[i].Size = UDim2.new(1 / 22, 0, 0, h)
			gbars[i].BackgroundColor3 = dt > Config.performance.jankThreshold and tok.danger
				or (dt > 0.020 and tok.warning or tok.success)
		end
	end, { name = "diag", rate = 8, priority = 8 })
	Theme.register(function(t)
		bg.BackgroundColor3 = t.surfaceDeep
	end)
	return holder
end

function Diagnostics.setFpsVisible(v)
	Diagnostics.build()
	Diagnostics.visible = v
	if Diagnostics.panel then
		Diagnostics.panel.Visible = v
	end
end

-- Low-spec watchdog: if we keep missing frames, quietly shed decoration.
Scheduler.schedule(function(dt)
	if not Config.performance.adaptiveQuality then
		return
	end
	if dt > Config.performance.jankThreshold then
		State.jankStreak += 1
	else
		State.jankStreak = math.max(0, State.jankStreak - 2)
	end
	if State.jankStreak > 90 and State.adaptiveQuality > 0.35 then
		State.adaptiveQuality = Math.clamp(State.adaptiveQuality - 0.15, 0.35, 1)
		Config.glass.causticsCount = math.max(1, Config.glass.causticsCount - 1)
		if DebugFlags.verbose then
			logWarn(
				"jank detected — easing off decoration (quality "
					.. string.format("%.2f", State.adaptiveQuality)
					.. ")"
			)
		end
		State.jankStreak = 0
	end
end, { name = "watchdog", rate = 2, priority = 8 })
--═══════════════════════════════════════════════════════════════════════════════--
-- § 20  PERSISTENCE
--
-- Saves a small subset of Config (theme, accent, glass knobs, motion, a11y) so
-- your setup survives rejoin. Studio-only file access, everything pcall-guarded:
-- on live servers this degrades to "settings last this session" and that is fine.
--═══════════════════════════════════════════════════════════════════════════════--

local Persistence = {
	key = "NocturneUI_v1_settings.json",
	enabled = true,
}
Nocturne.Persistence = Persistence

-- Extra icon glyphs the bootstrap palette references.
IconKit.define("camera", function(c, s)
	c.squircle(0.5, 0.54, 0.76, 0.56, 0.1, 0.08, false)
	c.poly({ { 0.32, 0.26 }, { 0.4, 0.16 }, { 0.6, 0.16 }, { 0.68, 0.26 } }, false, 0.075)
	c.ring(0.5, 0.54, 0.17, 0.085)
	c.dot(0.78, 0.34, 0.035)
end)
IconKit.define("sparkles", IconKit._defs.sparkle)

-- WEATHER (uses the sun/cloud/rain glyphs; forecast is a coin flip) ----------------
Apps.weather = {
	id = "weather",
	label = "Weather",
	icon = "cloud",
}
function Apps.weather.open()
	return WM.open({
		appId = "weather",
		id = "weather",
		title = "Weather",
		subtitle = "forecast accuracy: placeholder",
		icon = "cloud",
		size = { 380, 420 },
		content = function(parent, win)
			local hero = card(parent, { order = 1, height = 190, name = "SkyHero", caustics = true })
			local hc = hero.content
			local hour = tonumber((os.date("!%H"))) or 12
			local isNight = hour < 6 or hour >= 20
			W.label(hc, {
				text = isNight and "Clear, quietly dark" or "Glass with a chance of caustics",
				size = 12,
				color = "dim",
				anchor = Vector2.new(0, 0),
				position = UDim2.new(0, 2, 0, 4),
				size2 = { 220, 30 },
				wrapped = true,
			})
			W.label(hc, {
				text = "14°",
				size = 54,
				weight = "display",
				anchor = Vector2.new(0, 0.5),
				position = UDim2.new(0, 0, 0, 116),
				size2 = { 110, 60 },
			})
			local big = IconKit.attach(hc, isNight and "moon" or "sun", { size = 56, emphasis = not isNight })
			big.frame.AnchorPoint = Vector2.new(1, 0)
			big.frame.Position = UDim2.new(1, -6, 0, 30)
			local belt = create("Frame", {
				BackgroundColor3 = Color3.fromRGB(120, 200, 255),
				BackgroundTransparency = 0.7,
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.new(1, -40, 0, 3),
				Position = UDim2.new(0, 20, 0.5, 30),
				ZIndex = 25,
				Parent = hc,
			})
			create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = belt })
			local driftJob
			driftJob = Scheduler.schedule(function()
				if not belt.Parent then
					Scheduler.unschedule(driftJob)
					return
				end
				belt.Position = UDim2.new(0, 20 + math.sin(os.clock() * 0.4) * 14, 0.5, 30)
			end, { name = "weatherDrift", rate = 20, priority = 6 })
			local strip = create("Frame", {
				Name = "Forecast",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 96),
				LayoutOrder = 2,
				Parent = parent,
			})
			create("UIGridLayout", {
				CellSize = UDim2.new(1 / 5, -8, 0, 92),
				CellPadding = UDim.new(0, 8),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = strip,
			})
			local glyphs = { "sun", "cloud", "rain", "bolt", "moon", "cloud" }
			for d = 1, 5 do
				local day = create("Frame", {
					Name = "Day" .. d,
					BackgroundColor3 = Color3.fromRGB(36, 42, 55),
					BackgroundTransparency = 0.3,
					LayoutOrder = d,
					Parent = strip,
					ZIndex = 22,
				})
				create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = day })
				W.label(day, {
					text = Str.weekday(os.time() + d * 86400),
					size = 10,
					weight = "bold",
					color = "dim",
					anchor = Vector2.new(0.5, 0),
					position = UDim2.new(0.5, 0, 0, 6),
					size2 = { 60, 14 },
					alignX = Enum.TextXAlignment.Center,
				})
				local g = IconKit.attach(day, glyphs[math.random(1, #glyphs)], { size = 22 })
				g.frame.AnchorPoint = Vector2.new(0.5, 0.5)
				g.frame.Position = UDim2.new(0.5, 0, 0.5, 2)
				W.label(day, {
					text = string.format("%d°", math.random(9, 22)),
					size = 13,
					weight = "bold",
					anchor = Vector2.new(0.5, 1),
					position = UDim2.new(0.5, 0, 1, -6),
					size2 = { 50, 16 },
					alignX = Enum.TextXAlignment.Center,
				})
			end
			local notes = card(parent, { order = 3, height = 64, name = "SkyNote" })
			W.label(notes.content, {
				text = "Today's tip: translucent UIs refract responsibility. None detected in this forecast.",
				size = 11,
				color = "faint",
				wrapped = true,
				anchor = Vector2.new(0, 0),
				position = UDim2.fromScale(0, 2),
				size2 = { 330, 40 },
			})
		end,
	})
end

local function canTouchFiles()
	if not (isfile and writefile and readfile) then
		return false
	end
	local ok = pcall(readfile, "nocturne_probe.txt")
	return true
end

function Persistence.save(silent)
	if not Persistence.enabled or not canTouchFiles() then
		return false
	end
	local payload = {
		theme = State.currentTheme,
		accent = State.currentAccent,
		glass = {
			body = Config.glass.body,
			rimLight = Config.glass.rimLight,
			caustics = Config.glass.caustics,
			wobble = Config.glass.wobble,
			grain = Config.glass.grain,
		},
		motion = {
			enableSounds = Config.motion.enableSounds,
			soundVolume = Config.motion.soundVolume,
		},
		accessibility = {
			reduceMotion = Config.accessibility.reduceMotion,
		},
		state = {
			blurStrength = State.blurStrength,
			contrastBoost = State.contrastBoost,
			dockVisible = State.dockVisible,
		},
	}
	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(payload)
	end)
	if not ok then
		return false
	end
	pcall(function()
		writefile(Persistence.key, encoded)
	end)
	if not silent then
		Notifications.push({
			title = "Saved",
			body = "Preferences written to " .. Persistence.key .. " (Studio).",
			icon = "save",
			kind = "success",
			duration = 2.5,
		})
	end
	return true
end

function Persistence.load()
	if not Persistence.enabled or not canTouchFiles() then
		return false
	end
	local okRaw, raw = pcall(readfile, Persistence.key)
	if not okRaw or not raw or raw == "" then
		return false
	end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok or typeof(data) ~= "table" then
		return false
	end
	if data.theme then
		State.pendingTheme = data.theme
	end
	if data.accent then
		State.pendingAccent = data.accent
	end
	if data.glass then
		for k, v in data.glass do
			if Config.glass[k] ~= nil then
				Config.glass[k] = v
			end
		end
	end
	if data.motion then
		for k, v in data.motion do
			Config.motion[k] = v
		end
	end
	if data.accessibility then
		Config.accessibility.reduceMotion = data.accessibility.reduceMotion == true
		State.reduceMotion = Config.accessibility.reduceMotion
	end
	if data.state then
		State.blurStrength = data.state.blurStrength or 1
		State.contrastBoost = data.state.contrastBoost == true
	end
	return true
end

function Persistence.clear()
	if canTouchFiles() then
		pcall(function()
			if isfile(Persistence.key) then
				delfile(Persistence.key)
			end
		end)
	end
end

-- "save" icon existence note: add a couple of icons the earlier sections use.
IconKit.define("save", function(c, s)
	c.squircle(0.5, 0.5, 0.68, 0.68, 0.09, 0.08, false)
	c.poly({ { 0.3, 0.16 }, { 0.3, 0.4 }, { 0.66, 0.4 }, { 0.66, 0.16 } }, false, 0.075)
	c.squircle(0.5, 0.68, 0.24, 0.18, 0.04, 0, true)
end)

--═══════════════════════════════════════════════════════════════════════════════--
-- § 21  PUBLIC API
--
-- The surface other code touches. Everything returns handles or nothing, never
-- game state, never the data model. This kit is a guest.
--═══════════════════════════════════════════════════════════════════════════════--

function Nocturne.notify(body, opts)
	if type(body) == "table" then
		return Notifications.push(body)
	end
	return Notifications.push({ body = body, title = (opts and opts.title) or "Nocturne" })
end

function Nocturne.open(appId, opts)
	local app = Apps[appId]
	if app and app.open then
		return app.open(opts and opts.size)
	end
	-- Unknown ids still open *something*: an empty labelled window. Placeholders
	-- all the way down.
	return WM.open({
		appId = appId,
		title = Str.titleCase(tostring(appId)),
		icon = "window",
		size = opts and opts.size or { 420, 320 },
		content = opts and opts.content,
	})
end

function Nocturne.setTheme(name)
	return Theme.apply(name)
end

function Nocturne.setAccent(name)
	return Theme.setAccent(name)
end

function Nocturne.glassPreset(name)
	local presets = {
		heavy = function()
			Config.glass.body = 0.72
			Config.glass.rimLight = 0.5
			Config.glass.specular = 0.3
			Config.glass.caustics = false
		end,
		airy = function()
			Config.glass.body = 0.3
			Config.glass.rimLight = 0.9
			Config.glass.specular = 0.55
			Config.glass.caustics = true
		end,
		standard = function()
			Config.glass.body = 0.55
			Config.glass.rimLight = 0.72
			Config.glass.specular = 0.42
			Config.glass.caustics = true
		end,
	}
	local p = presets[name]
	if p then
		p()
		Theme.apply(State.currentTheme, State.currentAccent, true)
		for _, surface in Glass._surfaces do
			if surface.alive then
				surface:setTint(
					Math.clamp(Config.glass.body + (surface._tokens and surface._tokens.tintBias or 0), 0.1, 0.9)
				)
			end
		end
	end
	return p ~= nil
end

function Nocturne.show(v)
	if App.rootGui then
		App.rootGui.Enabled = v ~= false
		State.hidden = not (v ~= false)
	end
end

function Nocturne.hide()
	Nocturne.show(false)
end

function Nocturne.toggleVisible()
	Nocturne.show(State.hidden)
end

function Nocturne.stats()
	return {
		surfaces = Glass.count(),
		windows = #WM.order,
		tasks = Scheduler._taskCount,
		fps = math.floor(State.fps + 0.5),
		theme = State.currentTheme,
		accent = State.currentAccent,
		version = Nocturne.VERSION,
	}
end

function Nocturne.selfTest()
	local report = { checks = {}, passed = 0, failed = 0 }
	local function check(name, fn)
		local ok, err = pcall(fn)
		table.insert(report.checks, { name = name, ok = ok, err = ok and nil or tostring(err) })
		if ok then
			report.passed += 1
		else
			report.failed += 1
		end
	end
	check("scheduler pump", function()
		assert(Scheduler._frame > 0 or not IsStudio, "pump not ticking")
	end)
	check("theme tokens", function()
		assert(Theme.tokens() and Theme.tokens().surface, "no tokens")
	end)
	check("glass surface lifecycle", function()
		local s =
			Glass.new(App.layers.overlay, { name = "SelfTest", size = UDim2.fromOffset(120, 80), caustics = false })
		local before = Glass.count()
		assert(before > 0, "surface not registered")
		s:kill()
		assert(Glass.count() == before - 1, "surface not unregistered")
	end)
	check("button lifecycle", function()
		local b = W.button(
			App.layers.overlay,
			{ label = "test", widthPx = 40, height = 24, position = UDim2.fromScale(0.5, 0.5) }
		)
		b:destroy()
	end)
	check("window open/close", function()
		local w = WM.open({ appId = "__selftest__", title = "self test", size = { 200, 140 } })
		assert(w and w.root, "window missing")
		WM.close(w)
	end)
	check("icons render", function()
		local count = 0
		for _, name in IconKit.list() do
			count += 1
		end
		assert(count >= 30, "too few icons")
	end)
	check("notifications", function()
		local card = Notifications.push({
			title = "self-test",
			body = "you will not see this one",
			icon = "check",
			duration = 0.4,
			silent = true,
		})
		assert(card or Notifications.dnd, "push returned nothing")
	end)
	return report
end

function Nocturne.destroy()
	-- Full teardown: every surface, window, and the root GUI. For hot-reload
	-- workflows and for people who are scared.
	local okCount = 0
	local ok, err = pcall(function()
		Glass.wipe()
		for _, w in table.clone(WM.order) do
			pcall(function()
				w.surface:kill()
			end)
			w.root:Destroy()
		end
		T.clear(WM.windows)
		T.clear(WM.order)
		if App.rootGui then
			App.rootGui:Destroy()
			App.rootGui = nil
			App.ready = false
			App.layers = nil
		end
		Dock.root = nil
		Dock.instances = {}
		MenuBar.root = nil
	end)
	State.booted = false
	return ok, err
end
Nocturne.Version = Nocturne.VERSION
Nocturne.Info = {
	name = "Nocturne UI",
	tagline = Config.tagline,
	license = "MIT",
	assetsUsed = 0,
	featuresImplemented = 0,
	vibes = "immaculate",
}

--═══════════════════════════════════════════════════════════════════════════════--
-- § 22  BOOTSTRAP
--
-- The assembly line. Everything above is machinery; this is the handbrake turn
-- that starts the engine, opens the first windows and gets out of the way.
--═══════════════════════════════════════════════════════════════════════════════--

local Bootstrap = {}
Nocturne.Bootstrap = Bootstrap

local function registerDockApps()
	local apps = {
		{ id = "home", label = "Home", icon = "home", color = Color3.fromRGB(72, 120, 200) },
		{ id = "settings", label = "Settings", icon = "gear", color = Color3.fromRGB(110, 115, 130) },
		{ id = "media", label = "Sound Lab", icon = "music", color = Color3.fromRGB(160, 90, 200) },
		{ id = "stats", label = "Stats", icon = "cpu", color = Color3.fromRGB(60, 160, 150) },
		{ id = "tasks", label = "Tasks", icon = "check", color = Color3.fromRGB(90, 170, 110) },
		{ id = "chat", label = "Messages", icon = "chat", color = Color3.fromRGB(80, 140, 220) },
		{ id = "terminal", label = "Terminal", icon = "terminal", color = Color3.fromRGB(40, 48, 64) },
		{ id = "files", label = "Files", icon = "folder", color = Color3.fromRGB(200, 160, 80) },
		{ id = "weather", label = "Weather", icon = "cloud", color = Color3.fromRGB(80, 140, 190) },
		{ id = "about", label = "About", icon = "info", color = Color3.fromRGB(100, 110, 140) },
	}
	return apps
end

local function registerPaletteCommands()
	local function add(label, icon, group, run, keywords, disabled)
		Spotlight.register({
			label = label,
			icon = icon,
			group = group,
			run = run,
			keywords = keywords,
			disabled = disabled,
		})
	end
	add("Open Home", "home", "Apps", function()
		Apps.home.open()
	end, "desktop dashboard widgets")
	add("Open Settings", "gear", "Apps", function()
		Apps.settings.open()
	end, "config preferences theme accent")
	add("Open Sound Lab", "music", "Apps", function()
		Apps.media.open()
	end, "player media waveform")
	add("Open Stats", "cpu", "Apps", function()
		Apps.stats.open()
	end, "fps performance diagnostics")
	add("Open Tasks", "check", "Apps", function()
		Apps.tasks.open()
	end, "todo checklist")
	add("Open Messages", "chat", "Apps", function()
		Apps.chat.open()
	end, "chat bubbles")
	add("Open Terminal", "terminal", "Apps", function()
		Apps.terminal.open()
	end, "shell console")
	add("Open Files", "folder", "Apps", function()
		Apps.files.open()
	end, "finder tree")
	add("Open Weather", "cloud", "Apps", function()
		Apps.weather.open()
	end, "forecast sun rain")
	add("About Nocturne", "info", "Apps", function()
		Apps.about.open()
	end, "license credits")
	add("Hotkey cheat sheet", "keyboard", "Apps", function()
		Apps.cheats.open()
	end, "shortcuts keys konami")
	for _, th in Theme.list() do
		add("Theme: " .. th.label, "palette", "Theme", function()
			Theme.apply(th.id)
			Persistence.save(true)
		end, th.note)
	end
	for _, a in Theme.accentList() do
		add("Accent: " .. a.label, "wand", "Theme", function()
			Theme.setAccent(a.id)
			Persistence.save(true)
		end)
	end
	add("Glass: airy", "cloud", "Glass", function()
		Nocturne.glassPreset("airy")
	end, "thin light see through")
	add("Glass: heavy", "lock", "Glass", function()
		Nocturne.glassPreset("heavy")
	end, "opaque frosted")
	add("Glass: standard", "layers", "Glass", function()
		Nocturne.glassPreset("standard")
	end, "default balanced")
	add("Toggle dock", "dock", "UI", function()
		Dock.toggle()
	end)
	add("Toggle menu bar", "panelLeft", "UI", function()
		MenuBar.toggleVisible()
	end)
	add("Toggle reduce motion", "eye", "UI", function()
		Config.accessibility.reduceMotion = not Config.accessibility.reduceMotion
		State.reduceMotion = Config.accessibility.reduceMotion
	end)
	add("Notification centre", "bell", "UI", function()
		Notifications.toggleCentre()
	end)
	add("Focus mode (DND)", "moon", "UI", function()
		Notifications.setDoNotDisturb(not Notifications.dnd)
	end)
	add("Mission control", "grid", "UI", function()
		Nocturne.MissionControl.toggle()
	end, "expose windows overview")
	add("Cascade windows", "layers", "Windows", function()
		WM.cascade()
	end)
	add("Tile windows", "grid", "Windows", function()
		WM.tile()
	end)
	add("Close all windows", "close", "Windows", function()
		for _, w in table.clone(WM.order) do
			WM.close(w)
		end
	end)
	add("Minimise focused window", "minus", "Windows", function()
		if State.focusedWindow then
			WM.minimize(State.focusedWindow)
		end
	end, nil, State.focusedWindow == nil)
	add("Shuffle wallpaper", "sparkle", "Fun", function()
		Nocturne.Wallpaper.shuffle()
	end)
	add("Wobble everything", "cloud", "Fun", function()
		Glass.wobbleAll(0.9)
	end)
	add("Screenshot flash", "camera", "Fun", function()
		Nocturne.Capture.flashScreen()
	end)
	add("Lock screen", "lock", "Fun", function()
		Boot.lock()
	end)
	add("Run self-test", "shield", "Dev", function()
		local report = Nocturne.selfTest()
		Notifications.push({
			title = "Self-test " .. (report.failed == 0 and "passed" or "FAILED"),
			body = string.format("%d passed · %d failed", report.passed, report.failed),
			icon = report.failed == 0 and "check" or "warning",
			kind = report.failed == 0 and "success" or "danger",
			duration = 5,
			force = true,
		})
	end, "diagnostics smoke")
	add("Save preferences", "save", "Dev", function()
		Persistence.save()
	end)
	add("Reset preferences", "trash", "Dev", function()
		Persistence.clear()
		Notifications.push({
			title = "Preferences cleared",
			body = "Next boot will be amnesia.",
			icon = "trash",
			kind = "warning",
		})
	end)
	add("Read the license aloud (no, just read it)", "file", "Dev", function()
		print(Nocturne.Info.tagline .. "\nMIT License — do whatever, keep the header.")
	end)
end

local function wireKeybinds()
	local map = Config.input.keybinds
	local handlers = {
		palette = function()
			Nocturne.Spotlight.toggle()
		end,
		settings = function()
			Apps.settings.open()
		end,
		dock = Dock.toggle,
		minimise = function()
			if State.focusedWindow then
				WM.minimize(State.focusedWindow)
			end
		end,
		missionControl = function()
			Nocturne.MissionControl.toggle()
		end,
		fullscreen = function()
			Nocturne.toggleVisible()
		end,
		lock = Boot.lock,
		notifications = function()
			Notifications.toggleCentre()
		end,
		capture = function()
			Nocturne.Capture.flashScreen()
		end,
		hide = function()
			Nocturne.toggleVisible()
		end,
		diagnostics = function()
			Diagnostics.setFpsVisible(not Config.diagnostics.showFps)
		end,
	}
	for id, combo in map do
		local fn = handlers[id]
		if fn then
			Keys.register(id, combo, id, fn)
		end
	end
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		-- Framework-level keys work even when a textbox has focus unless they are
		-- plain text keys; we only intercept modified chords and the listed ones.
		local isMod = Keys.ctrl or Keys.meta or Keys.alt
		if gameProcessed and not isMod then
			return
		end
		local binding = Keys.matches(input)
		if binding then
			task.spawn(function()
				local ok, err = pcall(binding.fn, input)
				if not ok then
					logWarn("keybind " .. binding.id .. " failed:", err)
				end
			end)
		end
	end)
	-- Konami & friends feed the cheat machine.
	UserInputService.KeyDown:Connect(function(keyCode)
		local name = keyCode and keyCode.Name
		if name then
			CheatCodes.feed(name)
		end
	end)
	-- Esc closes the top thing.
	UserInputService.InputBegan:Connect(function(input, gpe)
		if input.KeyCode ~= Enum.KeyCode.Escape then
			return
		end
		if Menu.anyOpen() then
			Menu.closeAll()
		elseif Spotlight.visible then
			Spotlight.toggle(false)
		elseif Nocturne.MissionControl.isActive() then
			Nocturne.MissionControl.exit()
		elseif ControlCentre.open then
			ControlCentre.toggle(false)
		elseif State.focusedWindow and State.focusedWindow.snapped then
			State.focusedWindow.snapped = nil
		end
	end)
end

local function buildWelcomeWindow()
	return WM.open({
		appId = "welcome",
		id = "welcome",
		title = "Welcome to Nocturne",
		subtitle = "100% placeholder · 0 features · infinite vibes",
		icon = "sparkle",
		size = { 470, 380 },
		content = function(parent, win)
			local hero = card(parent, { order = 1, height = 130, name = "WelcomeHero", caustics = true })
			local hc = hero.content
			W.label(hc, {
				text = "Liquid glass, delivered.",
				size = 20,
				weight = "display",
				anchor = Vector2.new(0, 0),
				position = UDim2.new(0, 2, 0, 8),
				size2 = { 420, 26 },
			})
			W.label(hc, {
				text = "Every control you see is a demonstration. Drag windows into screen edges, right-click the desktop, press Ctrl+K, hover the dock, and flip themes in Settings — the buttons do nothing to your game, by design.",
				size = 11.5,
				color = "dim",
				wrapped = true,
				anchor = Vector2.new(0, 0),
				position = UDim2.new(0, 2, 0, 38),
				size2 = { 400, 76 },
			})
			local tips = {
				"Drag a titlebar toward a screen edge for snap zones",
				"Ctrl+K for the command palette",
				"Right-click the wallpaper for the desktop menu",
				"Settings actually changes the glass (it's the one app with a job)",
				"↑↑↓↓←→←→B A if you're feeling ancient",
			}
			for i, tip in tips do
				local row = create("Frame", {
					Name = "Tip" .. i,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 26),
					LayoutOrder = 10 + i,
					Parent = parent,
					ZIndex = 21,
				})
				local bullet = create("Frame", {
					BackgroundColor3 = Color3.fromRGB(120, 200, 255),
					AnchorPoint = Vector2.new(0, 0.5),
					Size = UDim2.fromOffset(6, 6),
					Position = UDim2.new(0, 8, 0.5, 0),
					ZIndex = 22,
					Parent = row,
				})
				create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = bullet })
				W.label(row, {
					text = tip,
					size = 12,
					color = "dim",
					anchor = Vector2.new(0, 0.5),
					position = UDim2.new(0, 24, 0.5, 0),
					size2 = { 390, 16 },
					truncate = true,
				})
			end
			local actions = create("Frame", {
				Name = "Actions",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 40),
				LayoutOrder = 30,
				Parent = parent,
			})
			W.button(actions, {
				label = "Open settings",
				icon = "gear",
				variant = "primary",
				widthPx = 150,
				height = 36,
				onClicked = function()
					Apps.settings.open()
				end,
			})
			W.button(actions, {
				label = "Do absolutely nothing",
				icon = "info",
				variant = "glass",
				widthPx = 186,
				height = 36,
				position = UDim2.new(0, 158, 0, 2),
				onClicked = function()
					Sfx.play("tap")
					win.surface:wobble(0.4, 0.4)
					Notifications.push({
						title = "As requested",
						body = "Nothing was done. Nothing will ever be done. Enjoy the rim light.",
						icon = "minus",
						duration = 3,
					})
				end,
			})
		end,
	})
end

local function staggeredIntro()
	local openers = {
		function()
			return Notifications.push({
				title = "Nocturne ready",
				body = "Glass mounted. Springs tensioned. Features: none.",
				icon = "sparkle",
				kind = "success",
				duration = 4.5,
			})
		end,
		function()
			return Notifications.push({
				title = "Try the dock",
				body = "Hover it. Magnification is free here.",
				icon = "dock",
				duration = 5,
			})
		end,
		function()
			return Notifications.push({
				title = "Tip",
				body = "Ctrl+K · themes, apps and wobbles are all one keystroke away.",
				icon = "keyboard",
				duration = 5,
			})
		end,
	}
	for i, f in openers do
		task.delay(0.8 + i * 1.6, f)
	end
end

function Bootstrap.run()
	if State.booted then
		return
	end
	State.booted = true

	-- Load any saved preferences before a single pixel is painted.
	Persistence.load()
	if State.pendingTheme then
		Theme.apply(State.pendingTheme, State.pendingAccent or State.currentAccent, true)
	end

	App.init()
	Nocturne.TooltipApp = Tooltip

	-- Desktop: wallpaper, particles, glow, right-click catcher.
	Wallpaper.build()
	Particles.build()
	CursorGlow.build()

	local catcher = create("TextButton", {
		Name = "DesktopCatcher",
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 0,
		Parent = App.layers.wallpaper,
	})
	Context.attach(catcher, Context.buildDesktopMenu)
	catcher.MouseButton1Click:Connect(function()
		if Menu.anyOpen() then
			Menu.closeAll()
		end
	end)

	-- Chrome: menu bar then dock.
	MenuBar.build()
	local apps = registerDockApps()
	Dock.build(apps)
	for _, app in apps do
		Dock.setAppRunning(app.id, WM.windows[app.id] ~= nil)
	end
	WM.windowOpenedHook = function(win)
		Dock.setAppRunning(win.appId, true)
	end

	-- Palette + keys.
	registerPaletteCommands()
	wireKeybinds()

	-- Periodic autosave (Studio). Cheap insurance.
	task.spawn(function()
		while true do
			task.wait(75)
			if IsStudio then
				Persistence.save(true)
			end
		end
	end)

	-- First blood: the boot curtain, then welcome, then a demo desktop.
	local function openInitialState()
		buildWelcomeWindow()
		if not State.reduceMotion then
			task.delay(0.4, function()
				Apps.home.open()
			end)
		end
		staggeredIntro()
	end

	if Config.boot.showBootSequence then
		Boot.run(openInitialState)
	else
		openInitialState()
	end

	if Config.boot.showLockScreen then
		task.delay(0.2, Boot.lock)
	end

	State.ready = true
	Nocturne.Ready = Nocturne.Ready or Signal.new("ready")
	Nocturne.Ready:Fire(Nocturne)
	logInfo(("Nocturne %s booted (assets: 0, features: 0)"):format(Nocturne.VERSION))
end

-- Auto-boot when this file runs as a script. If someone required it as a module
-- (the README explains converting), they call Bootstrap.run() themselves.
if Config.boot.auto then
	task.defer(function()
		local ok, err = pcall(Bootstrap.run)
		if not ok then
			warn("[Nocturne] boot failed:", err)
			-- One last-ditch toast using raw engine objects so the user at least
			-- knows the glass cracked rather than silently vanished.
			pcall(function()
				local gui = Instance.new("ScreenGui")
				gui.Name = "NocturneCracked"
				gui.ResetOnSpawn = false
				gui.Parent = PlayerGui
				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.fromOffset(320, 44)
				lbl.Position = UDim2.new(0, 20, 0, 20)
				lbl.BackgroundTransparency = 0.4
				lbl.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
				lbl.TextColor3 = Color3.fromRGB(240, 160, 160)
				lbl.Font = Enum.Font.Gotham
				lbl.TextSize = 12
				lbl.Text = "Nocturne failed to boot: " .. tostring(err):sub(1, 120)
				lbl.Parent = gui
				game:GetService("Debris"):AddItem(gui, 14)
			end)
		end
	end)
end

-- One last export flourish: the banner, for anyone who pastes this into Studio
-- and stares at the output window.
if DebugFlags.verbose or IsStudio then
	print(
		string.format(
			"[Nocturne] %s · %s · MIT · surfaces will now refract light",
			Nocturne.VERSION,
			Nocturne.CODENAME
		)
	)
end

return Nocturne

-- NOCTURNE_UI_EOF · fin · the glass is always loading
