leaderboard = {}
leaderboard.LocalEvent = {
	OnPlayerLoad = "leaderboard.OnPlayerLoad",
	OnRefresh = "leaderboard.OnRefresh",
}

local REFRESH_INTERVAL = 10

local store = {}
local playersData = {}
local friendsData = {}
local playersList = {}
local friendList = {}
local prefix = "leaderboard."
local playersListKey = "_playersList"

local contains = function(t, v)
	for _, value in ipairs(t) do
		if value == v then
			return true
		end
	end
	return false
end

local saveFunction = function(p)
	local data = { -- Default for leaderboard_ui, replace with the data you like if you don't use leaderboard_ui
		username = p.Username,
		score = p.highScore,
	}
	return data
end

local _getFromKvs = function(userId, sendEvent)
	store:Get(userId, function(success, results)
		if not success then
			return
		end
		playersData[userId] = results[userId]
		LocalEvent:Send(leaderboard.LocalEvent.OnPlayerLoad, userId, results[userId])
		if not sendEvent then
			return
		end
		_setFriendsData()
		LocalEvent:Send(leaderboard.LocalEvent.OnRefresh, playersData, friendsData)
	end)
end

local _getAllFromKvs = function()
	store:get(playersListKey, function(success, results)
		if not success then
			return
		end
		playersList = results[playersListKey] or {}
		for k, userId in ipairs(playersList) do
			local sendEvent = k == #playersList
			_getFromKvs(userId, sendEvent)
		end
	end)
end

local _saveToKvs = function(userId, data)
	store:Set(userId, data, function(_) end)
end

local _checkAgainstPlayerList = function(userId)
	store:Get(playersListKey, function(success, results)
		if not success then
			return
		end
		playersList = results[playersListKey] or {}
		if not contains(playersList, userId) then
			table.insert(playersList, userId)
			store:Set(playersListKey, playersList, function(_) end)
		end
	end)
end

local _setFriendsData = function()
	for _, v in ipairs(friendList) do
		friendsData[v.id] = playersData[v.id]
	end
end

local _getPlayerFriends = function()
	require("api"):getFriends(function(success, friends)
		if success then
			friendList = friends
			_setFriendsData()
		end
	end)
end

leaderboard.init = function(_, dataSaveFunction)
	saveFunction = dataSaveFunction
	store = KeyValueStore(prefix)
end

leaderboard.getPlayerData = function(p)
	return playersData[p.UserID]
end

leaderboard.getGlobalLeaderboard = function()
	return playersData
end

leaderboard.getFriendsLeaderboard = function()
	return friendsData
end

leaderboard.updatePlayerData = function(_, p)
	_saveToKvs(p.UserID, saveFunction(p))
end

leaderboard.refresh = function(_)
	_getAllFromKvs()
end

_isClient = function()
	return type(Client.IsMobile) == "boolean"
end
if _isClient() then
	LocalEvent:Listen(LocalEvent.Name.OnPlayerJoin, function(p)
		_checkAgainstPlayerList(p.UserID)
		_getPlayerFriends()
		Timer(REFRESH_INTERVAL, true, function()
			leaderboard.refresh()
		end)
	end)
end

return leaderboard
