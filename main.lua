require "oop"
require "ui"
ssc = require("sscreader")

local currentUI
local tempSongIndex = 3

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
	currentUI = ui.new()
	local currentSong = songs[tempSongIndex]
	local src = love.audio.newSource("songs/"..currentSong.pathTitle.."/"..currentSong.meta.MUSIC, "stream")
	love.audio.play(src)
	src:seek(80)

	local chart = currentSong.charts.Challenge

	for i, v in pairs(chart.markers) do
		print(v[1], v.start, v.speed, v.length)
	end

	--break down the NOTES stuff
	local notes = {{},{},{},{}} --4 separate note queues

	local i = 0 --measure index
	for measure in string.gmatch(chart.NOTES, "(%w+),?") do
		local numrows = string.len(measure)/4
		local j = 0
		for rowstr in string.gmatch(measure, "%w%w%w%w") do
			local beat = 4*i + 4*j/numrows

			local col_index = 1
			for note in string.gmatch(rowstr, "%w") do
				if note == "3" then
					local prevnote = notes[col_index][#notes[col_index]]
					if prevnote and prevnote.ntype == "2" or prevnote.ntype == "4" then
						prevnote.length = beat - prevnote.beat
					end
				elseif note ~= "0" then
					local noteObj = {ntype = note, beat = beat}
					table.insert(notes[col_index], noteObj)
				end
				col_index = col_index + 1
			end
			j = j + 1
		end
		i = i + 1
	end





	currentUI.NOTEDATA = notes --TEMPORARY AS FUCK

	local noteContainer = ui.new(currentUI, "NoteContainer", {0,20,0,5},{0,20,0,200})


	function getCurrentBeat(src, chart)
		local t = src:tell() + chart.OFFSET

		local beat = 0
		local bpm = 0
		local speed = 1
		local lastSpeed = 1

		for i, marker in pairs(chart.markers) do
			if t >= marker.t_start then
				bpm = marker.bpm
				speed = marker.speed
				beat = marker.start + (t - marker.t_start)*bpm/60
				
				if marker[1] == "STOPS" and (t - marker.t_start) < marker.dt then
					beat = marker.start
				elseif marker[1] == "SPEEDS" and (beat-marker.start) < marker.length then
					local alpha = (beat-marker.start)/marker.length
					speed = alpha*(speed-lastSpeed) + lastSpeed
				end
			else
				break
			end
			lastSpeed = speed
		end

		return beat, speed
	end
	for i = 1, 4 do
		local noteCol = ui.new(noteContainer, i, {.25,0,4,0},{(i-1)*.25,0,0,0})
		
		function noteCol:selfdraw(x,y,w,h)
			local currentBeat, currentSpeed = getCurrentBeat(src, chart)

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
			end
		end
	end

	function currentUI:selfdraw(x,y,w,h)
		--[[for i, col in pairs(self.NOTEDATA) do
			for _, note in pairs(col) do
				love.graphics.circle("line", 8*i, 8*note.beat*4, 2)
			end

		end]]
	end

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