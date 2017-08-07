require "oop"
require "ui"
ssc = require("sscreader")
chartreader = require("chartreader")

local currentUI
local tempSongIndex = 1
local currentReader
SETTINGS = {
	calibration = 0.125
}

function love.load()
	math.randomseed(os.time())
	--temp
	local arrowimg = love.graphics.newImage("resources/arrow_screen_64.png")
	love.audio.setVolume(0.1)

	--LOAD THE SONGS IN
	local songtitles = love.filesystem.getDirectoryItems("songs")
	local songs = {}


	for i, title in pairs(songtitles) do
		if title == "Roar" then
			local songObject = ssc.song.new("songs/"..title)
			songObject.pathTitle = title
			table.insert(songs, songObject)
		end
	end
	--[[table.sort(songs, function(a, b)
		return a.meta.ARTIST..a.meta.TITLE < b.meta.ARTIST..b.meta.TITLE
	end)]]
	tempSongIndex = math.random(1, #songs)

	--TEMP, load single song
	local currentSong = songs[tempSongIndex]
	songs = nil
	collectgarbage()
	--currentSong.meta, currentSong.charts = ssc.song.parse(currentSong.sscFilePath)
	currentReader = chartreader.new(currentSong, "Challenge")
	currentReader:loadNotes()

	currentUI = ui.new()
	currentUI.NOTEDATA = currentReader.notes --TEMPORARY AS FUCK
	currentUI.JUDGMENTS = currentReader.judgments
	local noteContainer = ui.new(currentUI, "NoteContainer", {0,256,0,64},{0,20,0,60})
	local angles = {-math.pi/2, math.pi, 0, math.pi/2}
	local colors = {}
	colors[4] = {244, 67, 54} --#F44336
	colors[8] = {33, 150, 243} --#2196F3
	colors[12] = {76, 175, 80} --#4CAF50
	colors[16] = {255, 235, 59} --#FFEB3B
	colors[24] = {156, 39, 176} --#9C27B0
	colors[32] = {0, 150, 136} --#009688
	colors[48] = {233, 30, 99} --#E91E63






	function noteContainer:selfdraw()
	end

	for i = 1, 4 do
		local noteCol = ui.new(noteContainer, i, {.25,0,4,0},{(i-1)*.25,0,0,0})
		
		function noteCol:selfdraw(x,y,w,h)
			local currentBeat, currentSpeed, beatSmear = currentReader:getCurrentBeat()

			if i == 1 then
				love.graphics.print(currentBeat, 10,10)
				love.graphics.print(currentReader.src:tell(), 10,30)
			end

			love.graphics.setBlendMode("screen")
			--targets
			local beatAlpha = (currentBeat+beatSmear)%1
			local tcolor = 125 - beatAlpha*100
			love.graphics.setColor(tcolor,tcolor,tcolor)
			love.graphics.draw(arrowimg, x+w/2, y+w/2, angles[i], 1-beatAlpha/10,1-beatAlpha/10,32,32)
			--DRAW NOTES IN THIS COLUMN
			local notelist = self.parent.parent.NOTEDATA[i]
			for _, note in pairs(notelist) do
				if (note.beat - currentBeat) < 8 and (note.beat - currentBeat) > -2 
					or (note.length and note.beat < currentBeat and note.beat+note.length > currentBeat-2) then
					if note.ntype == "M" then
						love.graphics.setColor(25,25,25)
					else
						love.graphics.setColor(255,255,255)
						local current = 1000
						for divisor, color in pairs(colors) do
							if divisor < current and ((note.beat)*divisor/4) % (1) == 0 then
								love.graphics.setColor(color[1],color[2],color[3])
								current = divisor
							end
						end
					end

					local NOTEX = math.floor(x + w/2)
					local NOTEY_0 =  y+w/2 + (note.beat - currentBeat)*h*currentSpeed
					if not note.judged and not note.length then
						--draw a normal note
						love.graphics.draw(arrowimg, NOTEX, NOTEY_0, angles[i], w/64,w/64,32,32)
					end
					if note.length and not note.liftPercent then
						local NOTEY_1 = math.floor(NOTEY_0 + note.length*h*currentSpeed)
						if note.judged then
							NOTEY_0 = y+w/2
							if note.length + note.beat < currentBeat then
								note.liftPercent = 1
								--TODO: probably send a message to OK the judgment?
							end
						end
						if not note.liftPercent then
							love.graphics.draw(arrowimg, NOTEX, NOTEY_0, angles[i], w/64,w/64,32,32)
							
							love.graphics.line(x, NOTEY_0, x, NOTEY_1)
							love.graphics.line(x+w, NOTEY_0, x+w, NOTEY_1)
							love.graphics.line(x, NOTEY_1, NOTEX, NOTEY_1 + w/2)
							love.graphics.line(x+w, NOTEY_1, NOTEX, NOTEY_1 + w/2)
						end
					end


				end
				if note.evaltime then
					love.graphics.circle("line", x+w/2+w*6, y+w/2 + (note.evaltime - currentReader.src:tell())*h*3, w/3)
				end
			end
			love.graphics.setBlendMode("alpha")
		end
	end

	local judgeContainer = ui.new(noteContainer, "judgeContainer", {1,0,0,0},{0,0,0,256})
	function judgeContainer:selfdraw(x,y,w,h)
		local judgments = self.parent.parent.JUDGMENTS
		for i, judgment in pairs(judgments) do
			love.graphics.setColor(255,255,255)
			love.graphics.printf(judgment.text,x,y+i*20, w, "center")
		end

	end

	function currentUI:selfdraw(x,y,w,h)
		love.graphics.setColor(20,30,60,200)
		love.graphics.rectangle("fill",x,y,w,h)
	end

	currentReader:play()
	--currentReader.src:seek(60)


end


local gameTime = 0
function love.update(dt)
	gameTime = love.timer.getTime()
end

local keyTranslate = {left = 1, down = 2, up = 3, right = 4}
function love.keypressed(key)
	if currentReader then
		if keyTranslate[key] then
			currentReader:press(keyTranslate[key])
		end
	end
end

function love.keyreleased(key)
	if currentReader then
		if keyTranslate[key] then
			currentReader:release(keyTranslate[key])
		end
	end
end


function love.draw()
	local width, height = love.window.getMode()
	love.graphics.setBackgroundColor(255, 255, 255)
	love.graphics.setColor(255,255,255)
	if currentUI then
		currentUI:draw(0,0,width,height)
	end
end