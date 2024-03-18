playerData = {}
playerData.LocalEvent = {
	OnDataSave = "playerData.OnDataSave",
	OnDataLoad = "playerData.OnDataLoad",
	OnDataReset = "playerData.OnDataReset",
	OnNoDataFound = "playerData.OnNoDataFound",
	OnRequestTimeout = "playerData.OnRequestTimeout",
}

local REQUEST_FAIL_RETRY_DELAY = 5
local REQUEST_FAIL_MAX = 3
local loadRetries = 0
local saveRetries = 0
local resetRetries = 0

local dataKeys = {
	"example",
	"data",
	"fields",
}

loadData = function(p)
	local kvs = KeyValueStore(p.UserID)
	kvs:Get("data", function(success, results)
		if not success and loadRetries < REQUEST_FAIL_MAX then
			loadRetries = loadRetries + 1
			Timer(REQUEST_FAIL_RETRY_DELAY, function()
				loadData(p)
			end)
		else
			loadRetries = 0
			if results.data then
				for _, dataKey in ipairs(dataKeys) do
					p[dataKey] = results.data[dataKey]
				end
				LocalEvent:Send(playerData.LocalEvent.OnDataLoad)
			else
				LocalEvent:Send(playerData.LocalEvent.OnNoDataFound)
			end
		end
	end)
end

saveData = function(p)
	local kvs = KeyValueStore(p.UserID)
	local data = {}
	for _, dataKey in ipairs(dataKeys) do
		data[dataKey] = p[dataKey]
	end
	kvs:Set("data", data, function(success)
		if not success and saveRetries < REQUEST_FAIL_MAX then
			saveRetries = saveRetries + 1
			Timer(REQUEST_FAIL_RETRY_DELAY, function()
				saveData(p)
			end)
		else
			if saveRetries <= REQUEST_FAIL_MAX then
				LocalEvent:Send(playerData.LocalEvent.OnDataSave)
			else
				LocalEvent:Send(playerData.LocalEvent.OnRequestTimeout)
			end
			saveRetries = 0
		end
	end)
end

resetData = function(p)
	local kvs = KeyValueStore(p.UserID)
	kvs:remove("data", function(success)
		if not success and resetRetries < REQUEST_FAIL_MAX then
			resetRetries = resetRetries + 1
			Timer(REQUEST_FAIL_RETRY_DELAY, function()
				resetData(p)
			end)
		else
			if resetRetries <= REQUEST_FAIL_MAX then
				LocalEvent:Send(playerData.LocalEvent.OnDataReset)
			else
				LocalEvent:Send(playerData.LocalEvent.OnRequestTimeout)
			end
			resetRetries = 0
		end
	end)
end

playerData.init = function(_, pDataKeys)
	dataKeys = pDataKeys
end

playerData.save = function(_, p)
	saveData(p)
end

playerData.load = function(_, p)
	loadData(p)
end

playerData.reset = function(_, p)
	resetData(p)
end

return playerData
