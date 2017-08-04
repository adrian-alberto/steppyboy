	--TODO: MENU STUFF. MOVE TO DIFFERENT FILE LATER
	local mainMenu = ui.new()
	function mainMenu:selfdraw(x, y, w, h)
		love.graphics.setColor(100,150,240)
		love.graphics.rectangle("fill",x,y,w,h)
	end

	local songContainer = ui.new(mainMenu, "songContainer", {1,0,0.5,0},{0,0,0.25,0})
	function songContainer:selfdraw()
	end




	local difficulties = {"Beginner", "Easy", "Medium", "Hard", "Challenge"}
	for i, songObject in pairs(songs) do
		local title = songObject.pathTitle
		local songui = ui.new(songContainer, i, {0,204,1,0}, {0,(i-1)*220,0,0})
		function songui:selfdraw(x,y,w,h)
			if i == tempSongIndex then
				love.graphics.setColor(230,230,250)
			else
				love.graphics.setColor(200,200,250)
			end

			
			love.graphics.rectangle("fill",x,y,w,h+4)
			love.graphics.setColor(0,0,0,30)
			love.graphics.rectangle("fill",x,y+h,w,4)

			local songinfo = songObject.meta.TITLE .. "\n"
				.. songObject.meta.ARTIST

			love.graphics.setColor(0,0,0)
			love.graphics.printf(songinfo, math.floor(x + 4), math.floor(y + 108), 200, "left")
		end

		local songimg = love.graphics.newImage("songs/"..title.."/".. songObject.meta.BANNER)
		local header = ui.new(songui, "header", {0,200,0,100},{0,2,0,2})
		function header:selfdraw(x,y,w,h)
			if songimg then
				love.graphics.setBlendMode("multiply")
				love.graphics.setColor(180,180,180)
				love.graphics.rectangle("fill", x,y,w,h)
				love.graphics.setBlendMode("alpha")
				love.graphics.setColor(255,255,255)
				local imgw, imgh = songimg:getDimensions()
				local scale = math.min(h/imgh, w/imgw)
				love.graphics.draw(songimg, x + w/2 - imgw*scale/2,
					y + h/2 - imgh*scale/2, 0, scale, scale)
			else
				love.graphics.rectangle("line", x, y, w, h)
			end
		end


	end

