require "oop"
require "ui"
ssc = require("sscreader")
chartreader = require("chartreader")

local currentUI
local tempSongIndex = 4
local currentReader

function love.load()
	--temp
	love.audio.setVolume(0.1)

	--LOAD THE SONGS IN
	local songtitles = love.filesystem.getDirectoryItems("songs")
	local songs = {}


	for i, title in pairs(songtitles) do
		local songObject = ssc.song.new("songs/"..title)
		songObject.pathTitle = title
		table.insert(songs, songObject)
	end
	table.sort(songs, function(a, b)
		return a.meta.ARTIST..a.meta.TITLE < b.meta.ARTIST..b.meta.TITLE
	end)

	--TEMP, load single song
	local currentSong = songs[tempSongIndex]
	currentReader = chartreader.new(currentSong, "Challenge")
	currentReader:loadNotes()

	currentUI = ui.new()
	currentUI.NOTEDATA = currentReader.notes --TEMPORARY AS FUCK

	local noteContainer = ui.new(currentUI, "NoteContainer", {0,100,0,25},{0,20,0,200})

	for i = 1, 4 do
		local noteCol = ui.new(noteContainer, i, {.25,0,4,0},{(i-1)*.25,0,0,0})
		
		function noteCol:selfdraw(x,y,w,h)
			local currentBeat, currentSpeed = currentReader:getCurrentBeat()

			if i == 1 then
				love.graphics.print(currentBeat, 10,10)
			end

			--DRAW NOTES IN THIS COLUMN
			local notelist = self.parent.parent.NOTEDATA[i]
			for _, note in pairs(notelist) do
				if (note.beat - currentBeat) < 8 and (note.beat - currentBeat) > -2 
					or (note.length and note.beat < currentBeat and note.beat+note.length > currentBeat-2) then
					if note.ntype == "M" then
						love.graphics.setColor(255,0,0)
					else
						love.graphics.setColor(255,255,255)
					end
					love.graphics.circle("line", x+w/2, y+w/2 + (note.beat - currentBeat)*h*currentSpeed, w/3)
					if note.length then
						love.graphics.line(x+w/2, y+w/2 + (note.beat - currentBeat)*h*currentSpeed, x+w/2, y+w/2 + (note.beat - currentBeat + note.length)*h)
					end


				end
				if note.evaltime then
					love.graphics.circle("line", x+w/2+w*6, y+w/2 + (note.evaltime - currentReader.src:tell())*h*2, w/3)
				end
			end
		end
	end

	function currentUI:selfdraw(x,y,w,h)
	end

	currentReader:play()
	currentReader.src:seek(80)

end


 
function love.update(dt)


end

function love.draw()
	local width, height = love.window.getMode()
	love.graphics.setBackgroundColor(20,20,20)
	love.graphics.setColor(255,255,255)
	if currentUI then
		currentUI:draw(0,0,width,height)
	end
end