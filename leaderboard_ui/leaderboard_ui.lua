leaderboard_ui = {}

local uikit = require("uikit")
local conf = require("config")

local defaultConfig = {
	type = "friends", -- or "global"
	pos = "topRight", -- "topLeft", "bottomLeft", "bottomRight"
	offset = Number2(0, -64),
	widgetWidth = 128,
	widgetHeight = 58,
	entries = 4,
}

local _createUI = function()
	local deviceMargin = Client.IsMobile and 0 or 16
	local margin = 4

	widgetContainer = uikit:createFrame(Color(0, 0, 0, 0.7))
	widgetContainer.parentDidResize = function(self)
		self.Width = _config.widgetWidth
		self.Height = _config.widgetHeight
		if _config.pos == "topRight" then
			self.pos.Y = Screen.Height - Screen.SafeArea.Top - self.Height - margin + _config.offset.Y
			self.pos.X = Screen.Width - Screen.SafeArea.Right - self.Width - deviceMargin + _config.offset.X
        elseif _config.pos = "topLeft" then
            self.pos.Y = Screen.Height - Screen.SafeArea.Top - self.Height - margin + _config.offset.Y
            self.pos.X = Screen.SafeArea.Left + deviceMargin
        elseif _config.pos = "bottomLeft" then
            self.pos.Y = Screen.SafeArea.bottomLeft + deviceMargin
            self.pos.X = Screen.SafeArea.Left + deviceMargin
        elseif _config.pos = "bottomRight" then
            self.pos.Y = Screen.SafeArea.bottomLeft + deviceMargin
            self.pos.X = Screen.Width - Screen.SafeArea.Right - self.Width - deviceMargin + _config.offset.X
        end
		
	end

	lbTexts = {}
	for i = 1, _config.entries do
		lbTexts[i] = uikit:createText("#" .. i .. " ??? --", Color.White)
		lbTexts[i].object.FontSize = 24
		lbTexts[i].parentDidResize = function(self)
            if _config.pos = "bottomRight" or "topRight" then 
                self.object.Anchor = { 0, 1 }
            elseif _config.pos = "bottomLeft" or "topLeft" then
                self.object.Anchor = { 1, 0 }
            end
			self.pos.X = margin
			self.pos.Y = widgetContainer.Height - self.Height * (i - 1) - margin
		end
		lbTexts[i]:setParent(widgetContainer)
	end
end

leaderboard_ui.init = function(_, config)
	_config = conf:merge(defaultConfig, config)
	_createUI()

	LocalEvent:Listen("leaderboard.OnRefresh", function(pGlobalData, pFriendsData)
		local globalData = pGlobalData
		local friendsData = pFriendsData

		local orderedData = {}
		if _config.type == "friends" then
			table.insert(
				orderedData,
				{ username = Player.Username, score = Player.highScore and Player.highScore or 0 }
			)
			for _, v in pairs(friendsData) do
				table.insert(orderedData, v)
			end
		else
			for _, v in pairs(globalData) do
				table.insert(orderedData, v)
			end
		end

		table.sort(orderedData, function(a, b)
			a.score = a.score and a.score or 0
			b.score = b.score and b.score or 0
			return a.score > b.score
		end)

		for i = 1, _config.entries do
			local hs = orderedData[i].score or "--"
			local username = orderedData[i].username or "???"
			local color = orderedData[i].username == Player.Username and Color.LightBlue or Color.White
			lbTexts[i].Text = "#" .. i .. " " .. username .. " " .. hs
			lbTexts[i].Color = color
		end
	end)
end

leaderboard_ui.toggleWidget = function(_)
	widgetContainer:toggle()
end

return leaderboard_ui
