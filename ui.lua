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

	if parent and tag then
		parent.children[tag] = self
	elseif parent then
		table.insert(parent.children, self)
	end
end

function ui:draw(px, py, pw, ph)
	--Takes parent coordinates and size
	local abs_x = px + self.pos[2] + self.pos[1]*pw
	local abs_y = py + self.pos[4] + self.pos[3]*ph
	local abs_w = self.size[2] + self.size[1]*pw
	local abs_h = self.size[4] + self.size[3]*ph

	--incase selfdraw clips descendants
	local sx, sy, sw, sh = love.graphics.getScissor()

	--draw self
	if self.selfdraw then
		self:selfdraw(abs_x, abs_y, abs_w, abs_h)
	else
		debugdraw(abs_x, abs_y, abs_w, abs_h)
	end
	--draw children
	for _, childui in pairs(self.children) do
		childui:draw(abs_x, abs_y, abs_w, abs_h)
	end
	love.graphics.setScissor(sx, sy, sw, sh)
end

function debugdraw(x,y,w,h)
	love.graphics.setColor(100,200,100)
	love.graphics.rectangle("line", x,y,w,h)
	love.graphics.setColor(255,255,255)
end
