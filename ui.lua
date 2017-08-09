--[[
UI framework
- Draw call arguments use absolute pixel values: x, y, w, h
- Size and Pos tuples use ScaleX, ScaleY, AbsX, AbsY
]]

ui = class()

function ui:init(parent, tag, size, pos)
	self.parent = parent
	self.tag = tag
	self.size = size or {1,0,1,0}
	self.pos = pos or {0,0,0,0}
	self.children = {}
	self.autocull = false

	local root = self
	while root.parent do
		root = root.parent
	end
	self.root = root

	if parent and tag then
		parent.children[tag] = self
	elseif parent then
		table.insert(parent.children, self)
	end
end

function ui:draw(px, py, pw, ph, t)
	t = t or love.timer.getTime()
	if self.currentTween then
		self:updateTween(t)
	end

	--Takes parent coordinates and size
	local abs_x = math.floor(0.5 + px + self.pos[2] + self.pos[1]*pw)
	local abs_y = math.floor(0.5 + py + self.pos[4] + self.pos[3]*ph)
	local abs_w = math.floor(0.5 + self.size[2] + self.size[1]*pw)
	local abs_h = math.floor(0.5 + self.size[4] + self.size[3]*ph)

	--incase selfdraw clips descendants
	local sx, sy, sw, sh = love.graphics.getScissor()

	if self.autocull then
		local w, h = love.window.getMode()
		if abs_x < -abs_w or abs_y < -abs_h or abs_x > w or abs_y > h then
			return
		end
	end

	--draw self
	if self.selfdraw then
		self:selfdraw(abs_x, abs_y, abs_w, abs_h)
	else
		debugdraw(abs_x, abs_y, abs_w, abs_h)
	end
	--draw children
	for _, childui in pairs(self.children) do
		childui:draw(abs_x, abs_y, abs_w, abs_h, t)
	end
	love.graphics.setScissor(sx, sy, sw, sh)
end

function ui:tween(newSize, newPos, dt, style)
	local t0 = love.timer.getTime()
	local t1 = t0 + dt
	local s0 = {unpack(self.size)}
	local p0 = {unpack(self.pos)}
	self.currentTween = {t0, t1, s0, newSize, p0, newPos, style or "linear"}
end

function ui:updateTween(t)
	local tween = self.currentTween
	if t >= tween[2] then
		self.size = tween[4]
		self.pos = tween[6]
		self.currentTween = nil
	end
	--alpha = (t - t0) / (t1 - t0)
	local a = math.min(1,(t - tween[1])/(tween[2] - tween[1]))
	a = 1 - ((1-a)*(1-a))
	local s0 = tween[3]
	local s1 = tween[4]
	local p0 = tween[5]
	local p1 = tween[6]
	self.size = {
		s0[1]+(s1[1]-s0[1])*a,
		s0[2]+(s1[2]-s0[2])*a,
		s0[3]+(s1[3]-s0[3])*a,
		s0[4]+(s1[4]-s0[4])*a,
	}
	self.pos = {
		p0[1]+(p1[1]-p0[1])*a,
		p0[2]+(p1[2]-p0[2])*a,
		p0[3]+(p1[3]-p0[3])*a,
		p0[4]+(p1[4]-p0[4])*a,
	}
end

function debugdraw(x,y,w,h)
	love.graphics.setColor(100,200,100)
	love.graphics.rectangle("line", x,y,w,h)
	love.graphics.setColor(255,255,255)
end

local imgsrcs = {}
function drawImg(path, ...)
	if not imgsrcs[path] then
		imgsrcs[path] = love.graphics.newImage(path)
		if not imgsrcs[path] then
			print("WARNING: NO IMAGE AT " .. path)
			return
		end
	end
	love.graphics.draw(imgsrcs[path], ...)
end
function getImg(path)
	if not imgsrcs[path] then
		imgsrcs[path] = love.graphics.newImage(path)
		if not imgsrcs[path] then
			print("WARNING: NO IMAGE AT " .. path)
			return
		end
	end
	return imgsrcs[path]
end

