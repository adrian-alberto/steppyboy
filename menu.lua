	--TODO: MENU STUFF. MOVE TO DIFFERENT FILE LATER
local ssc = require("sscreader")

function buildMainMenu(songdata)
	local SONGINDEX = 1
	local difficulties = {"Beginner", "Easy", "Medium", "Hard", "Challenge"}
	local gridWidth = math.ceil(math.sqrt(#songdata))

	local mainMenu = ui.new()
	mainMenu.tag = "SongSelect"
	function mainMenu:selfdraw(x, y, w, h)
		love.graphics.setColor(30,30,30)
		love.graphics.rectangle("fill",x,y,w,h)
	end




	local songContainer = ui.new(mainMenu, "songContainer", {0,310,0,310},{0.5,-310,0.5,-155})
	
	function songContainer:selfdraw()
	end

	local menuSong, switchSong

	function mainMenu:keypressed(key)
		local gx = ((SONGINDEX-1) % gridWidth)
		local gy = math.floor((SONGINDEX-1) /gridWidth)
		if key == "right" then
			gx = (gx + 1) % gridWidth
		elseif key == "left" then
			gx = (gx - 1) % gridWidth
		elseif key == "down" then
			gy = (gy + 1) % gridWidth
		elseif key == "up" then
			gy = (gy - 1) % gridWidth
		elseif key == "return" then
			if menuSong then
				love.audio.stop(menuSong)
				loadSong(songdata[SONGINDEX])
				print("hwhat")
			end
			return
		else
			return
		end
		local newIndex = gx + gy*gridWidth + 1
		if newIndex > #songdata then
			if key == "right" then
				newIndex = gridWidth*gridWidth - gridWidth + 1
			elseif key == "left" then
				newIndex = #songdata
			elseif key == "down" then
				newIndex = gx + 1
			elseif key == "up" then
				newIndex = newIndex - gridWidth
			end
		end
		switchSong(newIndex)
	end

	for i, data in ipairs(songdata) do
		local gx = ((i-1) % gridWidth)
		local gy = math.floor((i-1) /gridWidth)
		local title = data.TITLE
		local songui = ui.new(songContainer, i, {1,-10,1,-10}, {gx,0,gy,0})
		songui.autocull = true
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


			--love.graphics.printf(songinfo, math.floor(x + 4), math.floor(y + 308), 200, "left")
		end

		local songimg
		if string.len(data.JACKET) > 0 then
			songimg = "songs/"..data.folder.."/".. data.JACKET
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
				local imgw, imgh = getImg(songimg):getDimensions()
				local scale = math.min(h/imgh, w/imgw)
				drawImg(songimg, x + w/2 - imgw*scale/2,
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

	local songInfo = ui.new(songContainer, "songInfo", {0,260, 0, 400})
	function songInfo:selfdraw(x,y,w,h)
		love.graphics.setBlendMode("multiply")
		love.graphics.setColor(100,100,100)
		love.graphics.rectangle("fill",x-2,y-2,w+4,h+4)
		love.graphics.setBlendMode("alpha")
		love.graphics.setColor(200,200,200)
		love.graphics.rectangle("fill",x,y,w,h)

		love.graphics.setColor(0,0,0)

		love.graphics.printf(self.info or "", x+4,y+4,w,"left")

	end

	function switchSong(newIndex)
		SONGINDEX = newIndex
		local gx = ((SONGINDEX-1) % gridWidth)
		local gy = math.floor((SONGINDEX-1) /gridWidth)

		songContainer:tween(songContainer.size, {0.5,-gx*310-310,0.5,-gy*310-155}, 0.2)

		songInfo.pos = {gx+1,20,gy,-50}

		local data = songdata[SONGINDEX]
		songInfo.info = data.TITLE .. "\n" .. data.ARTIST .. "\n\n" .. data.CHARTS

		local tempsong = songdata[SONGINDEX]
		if menuSong then
			love.audio.stop(menuSong)
		end
		local srcpath = "songs/"..tempsong.folder.."/"..tempsong.MUSIC
		if love.filesystem.isFile(srcpath) then
			menuSong = love.audio.newSource(srcpath, "stream")
			love.audio.play(menuSong)
			menuSong:seek(tempsong.SAMPLESTART)
		end
		tempsong = nil
	end

	switchSong(1)
	return mainMenu
end

return {build = buildMainMenu}

