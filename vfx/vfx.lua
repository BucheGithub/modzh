vfx = {}

vfxQueue = {}
objToRotate = {}

conf = require("config")
ease = require("ease")

LocalEvent:Listen(LocalEvent.Name.Tick, function(dt)
	if #vfxQueue < 1 and #objToRotate < 1 then
		return
	end

	for i = #vfxQueue, 0, -1 do
		if vfxQueue[i](dt) then
			table.remove(vfxQueue, i)
		end
	end

	for _, obj in ipairs(objToRotate) do
		if obj and obj.pivot then
			obj.pivot:RotateLocal(0, dt, 0)
		else
			obj:RotateLocal(0, dt, 0)
		end
	end
end)

vfx.shake = function(shapeOrObj, config)
	local defaultConfig = {
		axis = "Z",
		duration = 0.3,
		range = 0.5,
		intensity = 100,
	}
	local _config = conf:merge(defaultConfig, config)

	local initiaAxisPos = shapeOrObj.Position[_config.axis]
	local t = 0

	local vfxTick = function(dt)
		t = t + dt * _config.intensity
		shapeOrObj.Position[_config.axis] = shapeOrObj.Position[_config.axis] + (math.sin(t) * _config.range)
		if t > _config.duration * _config.intensity then
			shapeOrObj.Position[_config.axis] = initiaAxisPos
			return true
		end
		return false
	end

	table.insert(vfxQueue, vfxTick)
end

vfx.scaleBounce = function(shape, config)
	local defaultConfig = {
		duration = 0.2,
		range = 0.25,
	}
	local _config = conf:merge(defaultConfig, config)

	local initialScale = shape.Scale:Copy()
	ease:outElastic(shape, _config.duration * 0.5, {
		onDone = function()
			ease:outElastic(shape, _config.duration).Scale = initialScale
		end,
	}).Scale = initialScale
		* (1 + _config.range)
end

vfx.registerTickRotation = function(obj)
	table.insert(objToRotate, obj)
end

vfx.unregisterTickRotation = function(obj)
	for i = #objToRotate, 1, -1 do
		if objToRotate[i] == obj then
			table.remove(objToRotate, i)
			break
		end
	end
end

return vfx
