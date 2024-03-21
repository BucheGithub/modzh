leaderboard_ui = {}

local uikit = require("uikit")
local conf = require("config")

local defaultConfig = {
	type = "friends", -- or "global"
	pos = "topRight",
	widgetWidth = 128,
	widgetHeight = 58,
}

local _createUI = function()
	local deviceMargin = Client.IsMobile and 0 or 16

	widgetContainer = uikit:createFrame(Color(0, 0, 0, 0.7))
	widgetContainer.parentDidResize = function(self)
		if _config.pos == "topRight" then
			self.Width = _config.widgetWidth
			self.Height = _config.widgetHeight
			self.pos.Y = Screen.Height * pos.Y - Screen.SafeArea.Top - self.Height - 4
			self.pos.X = Screen.Width * pos.X - Screen.SafeArea.Right - self.Width - deviceMargin
		end
	end

	lbTexts = {}
	for i = 1, LB_ENTRIES do
		lbTexts[i] = uikit:createText("#" .. i .. " ??? --", Color.White)
		lbTexts[i].object.Anchor = { 0, 1 }
		lbTexts[i].object.FontSize = 24
		lbTexts[i].parentDidResize = function(self)
			self.pos.X = UI_MARGIN_SMALL
			self.pos.Y = widgetContainer.Height - UI_MARGIN_SMALL - self.Height * (i - 1)
		end
		lbTexts[i]:setParent(widgetContainer)
	end
end

leaderboard_ui.init = function(config)
	_config = conf:merge(config, defaultConfig)
	_createUI()
end

leaderboard_ui.toggleWidget = function(_)
	widgetContainer:toggle()
end

LocalEvent:Listen("leaderboard.OnRefresh", function(pGlobalData, pFriendsData)
	local globalData = pGlobalData
	local friendsData = pFriendsData

	local orderedData = {}
	if _config.type == "friends" then
		table.insert(orderedData, { username = Player.Username, score = Player.highScore })
		for _, v in pairs(friendsData) do
			table.insert(orderedData, v)
		end
	else
		for _, v in pairs(globalData) do
			table.insert(orderedData, v)
		end
	end

	table.sort(orderedData, function(a, b)
		return a.highScore > b.highScore
	end)

	for i = 1, LB_ENTRIES do
		local hs = orderedData[i].highScore or "--"
		local username = orderedData[i].username or "???"
		local color = orderedData[i].username == Player.Username and Color.LightBlue or Color.White
		lbTexts[i].Text = "#" .. i .. " " .. username .. " " .. hs
		lbTexts[i].Color = color
	end
end)

return leaderboard_ui
