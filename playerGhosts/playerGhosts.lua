playerGhosts = {}

local avatar = require("avatar")
local hierarchyactions = require("hierarchyactions")

local TIMEOUT = 300

_ghostObjects = {}
_serverGhosts = {}

playerGhosts.handleServerEvents = function(e)
	if e.name == "AddServerGhost" then
		_serverGhosts[e.userid] = {
			username = e.username,
			pos = e.pos,
			forward = e.forward,
			text = e.text,
		}
	elseif e.name == "RequestServerGhosts" then
		local answer = Event()
		answer.name = "ReceiveServerGhost"
		answer.ghosts = _serverGhosts
		answer:SendTo(e.Sender)
	end
end

local requestServerGhosts = function()
	local e = Event()
	e.name = "RequestServerGhosts"
	e:SendTo(Server)
end

local addServerGhost = function(userid, username, pos, forward, text)
	local e = Event()
	e.name = "AddServerGhost"
	e.userid = userid
	e.username = username
	e.pos = pos
	e.forward = forward
	e.text = text
	e:SendTo(Server)
end

local createGhost = function(userId, username, callback)
	local obj = Object()
	avatarObj = avatar:get(username, nil, function()
		obj.avatar = avatarObj
		avatarObj.Scale = 0.5
		avatarObj:SetParent(obj)

		local t = Text()
		t.Type = TextType.Screen
		t.FontSize = Text.FontSizeSmall
		t.Color = Color.Grey
		t.BackgroundColor = Color(0, 0, 0, 0)
		t.IsUnlit = true
		t.Physics = PhysicsMode.Disabled
		t.CollisionGroups = {}
		t.CollidesWithGroups = {}
		t.MaxDistance = Camera.Far * 0.2
		t.Anchor = { 0.5, 0.5 }
		t.LocalPosition = { 0, avatarObj.Height + 12, 0 }
		t:SetParent(obj)

		obj.text = t

		if callback then
			callback()
		end
	end)

	_ghostObjects[userId] = obj
end

local placeGhost = function(ghost, pos, forward, text)
	ghost:SetParent(World)
	ghost.Position = pos - { 0, 6, 0 }
	ghost.Forward = forward
	ghost.text.Text = text
	hierarchyactions:applyToDescendants(ghost, function(o)
		if o == ghost.text then
			return
		end
		o.PrivateDrawMode = 1
	end)
	Timer(TIMEOUT, function()
		ghost:RemoveFromParent()
	end)
end

if type(Client.IsMobile) == "boolean" then
	LocalEvent:Listen(LocalEvent.Name.DidReceiveEvent, function(e)
		if e.name == "ReceiveServerGhost" then
			for userid, ghostData in pairs(e.ghosts) do
				createGhost(userid, ghostData.username, function()
					placeGhost(_ghostObjects[userid], ghostData.pos, ghostData.forward, ghostData.text)
				end)
			end
		end
	end)

	LocalEvent:Listen(LocalEvent.Name.OnPlayerJoin, function(p)
		if p == Player then
			requestServerGhosts()
		end

		local ghost = _ghostObjects[p.UserID]
		if ghost then
			ghost:RemoveFromParent()
			return
		end

		createGhost(p.UserID, p.Username)
	end)

	LocalEvent:Listen(LocalEvent.Name.OnPlayerLeave, function(p)
		--local gameName = "[Hub]" --TODO:: Add game name from real data
		--print(p.Username .. " joined " .. gameName)

		local text = p.Username .. " (in another world)" -- .. gameName .. ")"

		local ghost = _ghostObjects[p.UserID]
		if ghost then
			placeGhost(ghost, p.Position, p.Forward, text)
			addServerGhost(p.UserID, p.Username, p.Position, p.Forward, text)
		end
	end)
end

return playerGhosts
