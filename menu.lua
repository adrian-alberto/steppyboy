	--TODO: MENU STUFF. MOVE TO DIFFERENT FILE LATER
function buildMainMenu(songdata)
	local SONGINDEX = 2
	local difficulties = {"Beginner", "Easy", "Medium", "Hard", "Challenge"}
	local gridWidth = math.ceil(math.sqrt(#songdata))

	local mainMenu = ui.new()
	function mainMenu:selfdraw(x, y, w, h)
		love.graphics.setColor(30,30,30)
		love.graphics.rectangle("fill",x,y,w,h)
	end

	local songContainer = ui.new(mainMenu, "songContainer", {0,210,0,210},{0.5,-210,0.5,-105})
	songContainer.autocull = true
	function songContainer:selfdraw()
	end

	for i, data in ipairs(songdata) do
		local gx = ((i-1) % gridWidth)
		local gy = math.floor((i-1) /gridWidth)
		local title = data.TITLE
		local songui = ui.new(songContainer, i, {1,-10,1,-10}, {gx,0,gy,0})
		function songui:selfdraw(x,y,w,h)
			love.graphics.setColor(0,0,0,60)
			love.graphics.rectangle("fill", x-3,y-3,w+6,h+10)

			if i == SONGINDEX then
				love.graphics.setColor(200,200,200)
			else
				love.graphics.setColor(100,100,100)
			end


			love.graphics.rectangle("fill",x,y,w,h+4)
			love.graphics.setColor(0,0,0,60)
			love.graphics.rectangle("fill",x,y+h,w,4)


			local songinfo = data.TITLE .. "\n"
				.. data.ARTIST

			love.graphics.setColor(0,0,0)

			--love.graphics.printf(songinfo, math.floor(x + 4), math.floor(y + 308), 200, "left")
		end

		local songimg
		if string.len(data.JACKET) > 0 then
			songimg = love.graphics.newImage("songs/"..data.folder.."/".. data.JACKET)
		end
		local header = ui.new(songui, "header", {1,-6,1,-6},{0,3,0,3})
		function header:selfdraw(x,y,w,h)
			local screenw, screenh = love.window.getMode()

			if songimg then



				love.graphics.setBlendMode("multiply")
				love.graphics.setColor(180,180,180)
				love.graphics.rectangle("fill", x,y,w,h)
				love.graphics.setBlendMode("alpha")
				if i == SONGINDEX then
					love.graphics.setColor(255,255,255)
				else
					love.graphics.setColor(100,100,100)
				end
				local imgw, imgh = songimg:getDimensions()
				local scale = math.min(h/imgh, w/imgw)
				love.graphics.draw(songimg, x + w/2 - imgw*scale/2,
					y + h/2 - imgh*scale/2, 0, scale, scale)
			else
				love.graphics.rectangle("line", x, y, w, h)
			end
		end
	end

	----------------------------------------------------------
	local navbar = ui.new(mainMenu, "navbar", {1,0,0,100},{0,0,1,-100})
	function navbar:selfdraw(x,y,w,h)
		love.graphics.setColor(0,0,0,200)
		love.graphics.rectangle("fill",x,y,w,h)
	end

	local navgrid = ui.new(navbar, "grid", {0,0,1,-20},{0,10,0,10})
	function navgrid:selfdraw(x,y,w,h)
		w = h
		love.graphics.setColor(200,200,200)
		love.graphics.rectangle("line", x,y,w,h)
		local gx = ((SONGINDEX-1) % gridWidth)/gridWidth
		local gy = math.floor((SONGINDEX-1) /gridWidth)/gridWidth
		love.graphics.rectangle("fill", x + gx*w, y + gy*h, w/gridWidth, w/gridWidth)
	end

	return mainMenu
end

return {build = buildMainMenu}

