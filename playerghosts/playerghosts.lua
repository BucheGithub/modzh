playerGhosts = {}

local avatar = require("avatar")
local hierarchyactions = require("hierarchyactions")

local TIMEOUT = 300

local _serverGhosts = {}

playerGhosts.handleServerEvents = function(e)
	if e.name == "addGhostToServer" then
		if not _serverGhosts[e.userid] then
			_serverGhosts[e.userid] = {
				userid = e.userid,
				username = e.username,
				position = e.position,
				forward = e.forward,
				text = e.text,
			}
		end
	end
end

if type(Client.IsMobile) ~= "boolean" then
	local ghostExists = function(userid)
		return _serverGhosts[userid] ~= nil
	end

	local removeGhostFromServer = function(userid)
		_serverGhosts[userid] = nil
	end

	local removeGhostFromAllClients = function(userid)
		local e = Event()
		e.name = "RemoveGhost"
		e.ghost = _serverGhosts[userid]
		e:SendTo(Players)
	end

	local addGhostToClient = function(p, userid)
		local e = Event()
		e.name = "AddGhost"
		e.ghost = _serverGhosts[userid]
		e:SendTo(p)
	end

	LocalEvent:Listen(LocalEvent.Name.OnPlayerJoin, function(p)
		if ghostExists(p.UserID) then
			removeGhostFromAllClients(p.UserID)
			removeGhostFromServer(p.UserID)
		end
		for userid, _ in pairs(_serverGhosts) do
			addGhostToClient(p, userid)
		end
	end)
end

if type(Client.IsMobile) == "boolean" then
	_clientGhosts = {}

	local createGhost = function(userid, username, callback)
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

		_clientGhosts[userid] = obj
	end

	local placeGhost = function(userid, pos, forward, text)
		local ghost = _clientGhosts[userid]
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

	local removeGhost = function(userid)
		_clientGhosts[userid]:RemoveFromParent()
	end

	local addGhostToServer = function(p, text)
		local e = Event()
		e.name = "addGhostToServer"
		e.userid = p.UserID
		e.username = p.Username
		e.position = p.Position
		e.forward = p.Forward
		e.text = text
		e:SendTo(Server)
	end

	LocalEvent:Listen(LocalEvent.Name.OnPlayerLeave, function(p)
		local text = p.Username .. " (in another World)"
		addGhostToServer(p, text)
		createGhost(p.UserID, p.Username, function()
			placeGhost(p.UserID, p.Position, p.Forward, text)
		end)
	end)

	LocalEvent:Listen(LocalEvent.Name.DidReceiveEvent, function(e)
		if e.name == "AddGhost" then
			createGhost(e.ghost.userid, e.ghost.username, function()
				placeGhost(e.ghost.userid, e.ghost.position, e.ghost.forward, e.ghost.text)
			end)
		elseif e.name == "RemoveGhost" then
			if _clientGhosts[e.ghost.userid] then
				removeGhost(e.ghost.userid)
			end
		end
	end)
end

return playerGhosts
