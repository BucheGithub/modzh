device_orientation = {}
device_orientation.LocalEvent = {
	OnOrientationChange = "device_orientation.OnOrientationChange",
}

local defaultConfig = {
	forcedOrientation = "landscape", -- "portrait"
}

local conf = require("config")

local _config
local _eventSent = false

local _isLandscape = function()
	return Screen.Width > Screen.Height
end

local _isPortrait = function()
	return Screen.Width > Screen.Height
end

local createFrame = function()
	rotateFrame = uikit:createFrame(Color.Black)
	rotateFrame.parentDidResize = function(self)
		self.Width = Screen.Width
		self.Height = Screen.Height
	end
	rotateFrame:hide()

	rotateText = uikit:createText("Please rotate your device to Landscape Mode", Color.White, "big")
	rotateText.object.Anchor = { 0.5, 0.5 }
	rotateText.parentDidResize = function(self)
		self.object.MaxWidth = Screen.Width * 0.8
		self.pos.X = Screen.Width * 0.5
		self.pos.Y = Screen.Height * 0.5
	end
	rotateText:setParent(rotateFrame)
end

local show = function(bool)
	if bool then
		rotateFrame:show()
	else
		rotateFrame:hide()
	end
end

device_orientation.init = function(_, config)
	_config = conf:merge(defaultConfig, config)
	isOrientationOk = _config.orientation == "landscape" and _isLandscape or _isPortrait
	createFrame()
end

LocalEvent:Listen(LocalEvent.Name.Tick, function(dt)
	if not _eventSent and Client.IsMobile and not isOrientationOk() then
		LocalEvent:Send(device_orientation.LocalEvent.OnOrientationChange, _eventSent)
		_eventSent = true
		show(_eventSent)
	elseif _eventSent and Client.IsMobile and isOrientationOk() then
		LocalEvent:Send(device_orientation.LocalEvent.OnOrientationChange, _eventSent)
		_eventSent = false
		show(_eventSent)
	end
end)

return device_orientation
