--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Ambience = require(ReplicatedStorage.Package)
Ambience.registerFromFolder(script.presets)

local PANEL_WIDTH = 260
local PANEL_PADDING = 12
local BUTTON_HEIGHT = 30
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

local transitionTime = 1
local activeLabel: TextLabel? = nil
local presetButtons: { [string]: TextButton } = {}

local PRESETS = { "Day", "Night", "Sunset", "Forest", "Rain", "Wind", "Fog", "Sandstorm" }
local SET_PRESETS = { "Day", "Night", "Sunset" }

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
	frame.Position = props.position or UDim2.new()
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
	label.Position = props.position or UDim2.new()
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
	button.Position = props.position or UDim2.new()
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
	size: UDim2,
	position: UDim2,
	parent: GuiObject,
}): Frame
	local container = createFrame({
		name = "TransitionSlider",
		size = props.size,
		position = props.position,
		color = Color3.new(),
		parent = props.parent,
	})
	container.BackgroundTransparency = 1

	local textLabel = createLabel({
		name = "Label",
		text = `Transition: {transitionTime}s`,
		size = UDim2.new(1, 0, 0, LABEL_HEIGHT),
		color = COLORS.textDim,
		parent = container,
	})

	local sliderBg = createFrame({
		name = "SliderBg",
		size = UDim2.new(1, 0, 0, 8),
		position = UDim2.new(0, 0, 0, LABEL_HEIGHT + 4),
		color = COLORS.slider,
		parent = container,
	})

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 4)
	bgCorner.Parent = sliderBg

	local fill = createFrame({
		name = "Fill",
		size = UDim2.new(transitionTime / 5, 0, 1, 0),
		position = UDim2.new(),
		color = COLORS.sliderFill,
		parent = sliderBg,
	})

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fill

	local dragging = false

	local function updateSlider(inputX: number)
		local relativeX = math.clamp((inputX - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
		transitionTime = math.floor((relativeX * 5) * 10) / 10
		fill.Size = UDim2.new(relativeX, 0, 1, 0)
		textLabel.Text = `Transition: {transitionTime}s`
	end

	sliderBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			updateSlider(input.Position.X)
		end
	end)

	sliderBg.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	sliderBg.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSlider(input.Position.X)
		end
	end)

	return container
end

local function contains(list: { string }, value: string): boolean
	return table.find(list, value) ~= nil
end

local function refreshActiveLabel()
	local ids = Ambience.getActive()
	if activeLabel then
		activeLabel.Text = if #ids == 0 then "Active: None" else `Active: {table.concat(ids, ", ")}`
	end
	for id, button in pairs(presetButtons) do
		button.BackgroundColor3 = if contains(ids, id) then COLORS.buttonActive else COLORS.button
	end
end

local function createUI()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AmbienceV2Test"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local panel = createFrame({
		name = "Panel",
		size = UDim2.new(0, PANEL_WIDTH, 0, 610),
		position = UDim2.new(0, 20, 0.5, -305),
		color = COLORS.background,
		parent = screenGui,
	})

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 10)
	panelCorner.Parent = panel

	local y = PANEL_PADDING

	local header = createLabel({
		name = "Header",
		text = "Ambience v2 Test",
		size = UDim2.new(1, -PANEL_PADDING * 2, 0, 28),
		position = UDim2.new(0, PANEL_PADDING, 0, y),
		parent = panel,
	})
	header.Font = Enum.Font.GothamBold
	header.TextSize = 18
	header.TextXAlignment = Enum.TextXAlignment.Center
	y += 28 + SPACING

	activeLabel = createLabel({
		name = "ActiveLabel",
		text = "Active: None",
		size = UDim2.new(1, -PANEL_PADDING * 2, 0, LABEL_HEIGHT),
		position = UDim2.new(0, PANEL_PADDING, 0, y),
		color = COLORS.textDim,
		parent = panel,
	})
	activeLabel.TextSize = 12
	y += LABEL_HEIGHT + SPACING

	createSlider({
		size = UDim2.new(1, -PANEL_PADDING * 2, 0, LABEL_HEIGHT + 16),
		position = UDim2.new(0, PANEL_PADDING, 0, y),
		parent = panel,
	})
	y += LABEL_HEIGHT + 16 + SPACING * 2

	createLabel({
		name = "SetLabel",
		text = "Set (single active preset)",
		size = UDim2.new(1, -PANEL_PADDING * 2, 0, LABEL_HEIGHT),
		position = UDim2.new(0, PANEL_PADDING, 0, y),
		parent = panel,
	})
	y += LABEL_HEIGHT + SPACING

	for _, id in ipairs(SET_PRESETS) do
		createButton({
			name = `Set{id}`,
			text = `Set {id}`,
			size = UDim2.new(1, -PANEL_PADDING * 2, 0, BUTTON_HEIGHT),
			position = UDim2.new(0, PANEL_PADDING, 0, y),
			parent = panel,
			onClick = function()
				Ambience.set(id, { transition = transitionTime })
				refreshActiveLabel()
			end,
		})
		y += BUTTON_HEIGHT + SPACING
	end

	createLabel({
		name = "PushPopLabel",
		text = "Push/Pop Layers",
		size = UDim2.new(1, -PANEL_PADDING * 2, 0, LABEL_HEIGHT),
		position = UDim2.new(0, PANEL_PADDING, 0, y),
		parent = panel,
	})
	y += LABEL_HEIGHT + SPACING

	for _, id in ipairs(PRESETS) do
		local button = createButton({
			name = `Toggle{id}`,
			text = id,
			size = UDim2.new(1, -PANEL_PADDING * 2, 0, BUTTON_HEIGHT),
			position = UDim2.new(0, PANEL_PADDING, 0, y),
			parent = panel,
			onClick = function()
				local isActive = contains(Ambience.getActive(), id)
				if isActive then
					Ambience.pop(id, { transition = transitionTime })
				else
					Ambience.push(id, { transition = transitionTime })
				end
				refreshActiveLabel()
			end,
		})
		presetButtons[id] = button
		y += BUTTON_HEIGHT + SPACING
	end

	createButton({
		name = "ClearAll",
		text = "Clear All",
		size = UDim2.new(1, -PANEL_PADDING * 2, 0, BUTTON_HEIGHT),
		position = UDim2.new(0, PANEL_PADDING, 0, y),
		color = COLORS.stopButton,
		hoverColor = COLORS.stopButtonHover,
		parent = panel,
		onClick = function()
			Ambience.clear({ transition = transitionTime })
			refreshActiveLabel()
		end,
	})

	RunService.Heartbeat:Connect(refreshActiveLabel)
	refreshActiveLabel()
end

createUI()
