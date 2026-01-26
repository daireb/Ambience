--!strict
--[[
	Ambience Test Client
	
	A simple testing UI for the Ambience library.
	Provides buttons to switch between lighting scenes and soundscapes,
	with sliders to control transition times.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ambience = require(ReplicatedStorage.Package)

-- Register all presets
Ambience.Lighting.RegisterFromFolder(script.presets.lighting)
Ambience.Sound.RegisterFromFolder(script.presets.soundscapes)

-- UI Constants
local PANEL_WIDTH = 220
local PANEL_PADDING = 12
local BUTTON_HEIGHT = 32
local SLIDER_HEIGHT = 24
local LABEL_HEIGHT = 20
local SPACING = 8

local COLORS = {
	background = Color3.fromRGB(30, 30, 35),
	button = Color3.fromRGB(50, 50, 60),
	buttonHover = Color3.fromRGB(70, 70, 85),
	buttonActive = Color3.fromRGB(80, 120, 180),
	text = Color3.fromRGB(240, 240, 240),
	textDim = Color3.fromRGB(180, 180, 180),
	slider = Color3.fromRGB(60, 60, 70),
	sliderFill = Color3.fromRGB(100, 150, 220),
	stopButton = Color3.fromRGB(120, 50, 50),
	stopButtonHover = Color3.fromRGB(150, 60, 60),
}

-- State
local currentTweenTime = 1
local currentFadeTime = 1
local currentLightingLabel: TextLabel? = nil
local currentSoundLabel: TextLabel? = nil

-- UI Helpers
local function createFrame(props: {
	name: string,
	size: UDim2,
	position: UDim2?,
	color: Color3?,
	parent: GuiObject?,
}): Frame
	local frame = Instance.new("Frame")
	frame.Name = props.name
	frame.Size = props.size
	frame.Position = props.position or UDim2.new(0, 0, 0, 0)
	frame.BackgroundColor3 = props.color or COLORS.background
	frame.BorderSizePixel = 0
	frame.Parent = props.parent
	return frame
end

local function createLabel(props: {
	name: string,
	text: string,
	size: UDim2,
	position: UDim2?,
	color: Color3?,
	parent: GuiObject?,
}): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = props.name
	label.Text = props.text
	label.Size = props.size
	label.Position = props.position or UDim2.new(0, 0, 0, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = props.color or COLORS.text
	label.TextSize = 14
	label.Font = Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = props.parent
	return label
end

local function createButton(props: {
	name: string,
	text: string,
	size: UDim2,
	position: UDim2?,
	color: Color3?,
	hoverColor: Color3?,
	parent: GuiObject?,
	onClick: () -> (),
}): TextButton
	local button = Instance.new("TextButton")
	button.Name = props.name
	button.Text = props.text
	button.Size = props.size
	button.Position = props.position or UDim2.new(0, 0, 0, 0)
	button.BackgroundColor3 = props.color or COLORS.button
	button.BorderSizePixel = 0
	button.TextColor3 = COLORS.text
	button.TextSize = 14
	button.Font = Enum.Font.GothamMedium
	button.AutoButtonColor = false
	button.Parent = props.parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	local baseColor = props.color or COLORS.button
	local hoverColor = props.hoverColor or COLORS.buttonHover

	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = hoverColor
	end)

	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = baseColor
	end)

	button.MouseButton1Click:Connect(props.onClick)

	return button
end

local function createSlider(props: {
	name: string,
	label: string,
	min: number,
	max: number,
	default: number,
	size: UDim2,
	position: UDim2?,
	parent: GuiObject?,
	onChanged: (value: number) -> (),
}): Frame
	local container = createFrame({
		name = props.name,
		size = props.size,
		position = props.position,
		color = Color3.fromRGB(0, 0, 0),
		parent = props.parent,
	})
	container.BackgroundTransparency = 1

	local labelText = createLabel({
		name = "Label",
		text = `{props.label}: {props.default}s`,
		size = UDim2.new(1, 0, 0, LABEL_HEIGHT),
		color = COLORS.textDim,
		parent = container,
	})
	labelText.TextSize = 12

	local sliderBg = createFrame({
		name = "SliderBg",
		size = UDim2.new(1, 0, 0, 8),
		position = UDim2.new(0, 0, 0, LABEL_HEIGHT + 4),
		color = COLORS.slider,
		parent = container,
	})

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = sliderBg

	local sliderFill = createFrame({
		name = "Fill",
		size = UDim2.new((props.default - props.min) / (props.max - props.min), 0, 1, 0),
		color = COLORS.sliderFill,
		parent = sliderBg,
	})

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = sliderFill

	-- Slider interaction
	local dragging = false

	local function updateSlider(inputX: number)
		local relativeX = math.clamp((inputX - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
		local value = props.min + relativeX * (props.max - props.min)
		value = math.floor(value * 10) / 10 -- Round to 1 decimal

		sliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
		labelText.Text = `{props.label}: {value}s`
		props.onChanged(value)
	end

	sliderBg.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			updateSlider(input.Position.X)
		end
	end)

	sliderBg.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)

	sliderBg.InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			updateSlider(input.Position.X)
		end
	end)

	return container
end

local function createSection(props: {
	name: string,
	title: string,
	yOffset: number,
	parent: GuiObject?,
}): (Frame, number)
	local section = createFrame({
		name = props.name,
		size = UDim2.new(1, -PANEL_PADDING * 2, 0, 0), -- Height set dynamically
		position = UDim2.new(0, PANEL_PADDING, 0, props.yOffset),
		color = Color3.fromRGB(0, 0, 0),
		parent = props.parent,
	})
	section.BackgroundTransparency = 1

	createLabel({
		name = "Title",
		text = props.title,
		size = UDim2.new(1, 0, 0, LABEL_HEIGHT),
		color = COLORS.text,
		parent = section,
	})

	return section, LABEL_HEIGHT + SPACING
end

-- Create the main UI
local function createUI()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AmbienceTest"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Main panel
	local panel = createFrame({
		name = "Panel",
		size = UDim2.new(0, PANEL_WIDTH, 0, 400),
		position = UDim2.new(0, 20, 0.5, -200),
		color = COLORS.background,
		parent = screenGui,
	})

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 10)
	panelCorner.Parent = panel

	-- Header
	local header = createLabel({
		name = "Header",
		text = "Ambience Test",
		size = UDim2.new(1, -PANEL_PADDING * 2, 0, 30),
		position = UDim2.new(0, PANEL_PADDING, 0, PANEL_PADDING),
		color = COLORS.text,
		parent = panel,
	})
	header.TextSize = 18
	header.Font = Enum.Font.GothamBold
	header.TextXAlignment = Enum.TextXAlignment.Center

	local yOffset = PANEL_PADDING + 30 + SPACING

	-- Lighting Section
	local lightingSection, lightingOffset = createSection({
		name = "LightingSection",
		title = "Lighting",
		yOffset = yOffset,
		parent = panel,
	})

	currentLightingLabel = createLabel({
		name = "CurrentLabel",
		text = "Current: None",
		size = UDim2.new(1, 0, 0, LABEL_HEIGHT),
		position = UDim2.new(0, 0, 0, lightingOffset),
		color = COLORS.textDim,
		parent = lightingSection,
	})
	currentLightingLabel.TextSize = 12
	lightingOffset += LABEL_HEIGHT + SPACING

	-- Lighting buttons
	local lightingPresets = { "day", "sunset", "night" }
	for i, preset in ipairs(lightingPresets) do
		createButton({
			name = preset .. "Button",
			text = preset:sub(1, 1):upper() .. preset:sub(2),
			size = UDim2.new(1, 0, 0, BUTTON_HEIGHT),
			position = UDim2.new(0, 0, 0, lightingOffset),
			parent = lightingSection,
			onClick = function()
				Ambience.Lighting.SetActive(preset, { tweenTime = currentTweenTime })
				if currentLightingLabel then
					currentLightingLabel.Text = `Current: {preset:sub(1, 1):upper()}{preset:sub(2)}`
				end
			end,
		})
		lightingOffset += BUTTON_HEIGHT + SPACING
	end

	-- Tween time slider
	createSlider({
		name = "TweenSlider",
		label = "Tween Time",
		min = 0,
		max = 5,
		default = currentTweenTime,
		size = UDim2.new(1, 0, 0, SLIDER_HEIGHT + LABEL_HEIGHT),
		position = UDim2.new(0, 0, 0, lightingOffset),
		parent = lightingSection,
		onChanged = function(value)
			currentTweenTime = value
		end,
	})
	lightingOffset += SLIDER_HEIGHT + LABEL_HEIGHT + SPACING

	-- Stop lighting button
	createButton({
		name = "StopLightingButton",
		text = "Stop Lighting",
		size = UDim2.new(1, 0, 0, BUTTON_HEIGHT),
		position = UDim2.new(0, 0, 0, lightingOffset),
		color = COLORS.stopButton,
		hoverColor = COLORS.stopButtonHover,
		parent = lightingSection,
		onClick = function()
			Ambience.Lighting.SetActive(nil)
			if currentLightingLabel then
				currentLightingLabel.Text = "Current: None"
			end
		end,
	})
	lightingOffset += BUTTON_HEIGHT + SPACING

	lightingSection.Size = UDim2.new(1, -PANEL_PADDING * 2, 0, lightingOffset)
	yOffset += lightingOffset + SPACING * 2

	-- Sound Section
	local soundSection, soundOffset = createSection({
		name = "SoundSection",
		title = "Sound",
		yOffset = yOffset,
		parent = panel,
	})

	currentSoundLabel = createLabel({
		name = "CurrentLabel",
		text = "Current: None",
		size = UDim2.new(1, 0, 0, LABEL_HEIGHT),
		position = UDim2.new(0, 0, 0, soundOffset),
		color = COLORS.textDim,
		parent = soundSection,
	})
	currentSoundLabel.TextSize = 12
	soundOffset += LABEL_HEIGHT + SPACING

	-- Sound buttons
	local soundPresets = { "forest", "rain", "wind" }
	for i, preset in ipairs(soundPresets) do
		createButton({
			name = preset .. "Button",
			text = preset:sub(1, 1):upper() .. preset:sub(2),
			size = UDim2.new(1, 0, 0, BUTTON_HEIGHT),
			position = UDim2.new(0, 0, 0, soundOffset),
			parent = soundSection,
			onClick = function()
				Ambience.Sound.SetActive(preset, { fadeTime = currentFadeTime })
				if currentSoundLabel then
					currentSoundLabel.Text = `Current: {preset:sub(1, 1):upper()}{preset:sub(2)}`
				end
			end,
		})
		soundOffset += BUTTON_HEIGHT + SPACING
	end

	-- Fade time slider
	createSlider({
		name = "FadeSlider",
		label = "Fade Time",
		min = 0,
		max = 5,
		default = currentFadeTime,
		size = UDim2.new(1, 0, 0, SLIDER_HEIGHT + LABEL_HEIGHT),
		position = UDim2.new(0, 0, 0, soundOffset),
		parent = soundSection,
		onChanged = function(value)
			currentFadeTime = value
		end,
	})
	soundOffset += SLIDER_HEIGHT + LABEL_HEIGHT + SPACING

	-- Stop sound button
	createButton({
		name = "StopSoundButton",
		text = "Stop Sound",
		size = UDim2.new(1, 0, 0, BUTTON_HEIGHT),
		position = UDim2.new(0, 0, 0, soundOffset),
		color = COLORS.stopButton,
		hoverColor = COLORS.stopButtonHover,
		parent = soundSection,
		onClick = function()
			Ambience.Sound.SetActive(nil)
			if currentSoundLabel then
				currentSoundLabel.Text = "Current: None"
			end
		end,
	})
	soundOffset += BUTTON_HEIGHT

	soundSection.Size = UDim2.new(1, -PANEL_PADDING * 2, 0, soundOffset)
	yOffset += soundOffset + PANEL_PADDING

	-- Adjust panel height
	panel.Size = UDim2.new(0, PANEL_WIDTH, 0, yOffset)
	panel.Position = UDim2.new(0, 20, 0.5, -yOffset / 2)

	return screenGui
end

-- Initialize
createUI()
print("[AmbienceTest] Test UI initialized")
