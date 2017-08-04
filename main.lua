require "oop"
require "ui"
ssc = require("sscreader")

local currentUI
local tempSongIndex = 5

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

	local chart = currentSong.charts.Challenge

	--break down the NOTES stuff
	local notes = {{},{},{},{}} --4 separate note queues

	local i = 0 --measure index
	for measure in string.gmatch(chart.NOTES, "(%d+),?") do
		local numrows = string.len(measure)/4
		local j = 0
		for rowstr in string.gmatch(measure, "%d%d%d%d") do
			local beat = 4*i + 4*j/numrows

			local col_index = 1
			for note in string.gmatch(rowstr, "%d") do
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

	local noteContainer = ui.new(currentUI, "NoteContainer", {0,40,0,10},{0,20,0,200})
	local bpm = 128--currentSong.meta.BPMS
	local offset = tonumber(currentSong.meta.OFFSET)
	local bps = bpm/60

	function getCurrentBeat(src, chart)
		local t = src:tell()
		local beat, currentBPM


		if type(chart.BPMS) == "table" then
			local latest = 0
			local latestbpm
			for offset, bpm in pairs(chart.BPMS) do
				if offset <= t and offset >= latest then
					latest = offset
					latestbpm = bpm
				end
			end
			bpm = latestbpm
			beat = (src:tell()-latest + chart.OFFSET)*latestbpm/60
		else
			bpm = chart.BPMS
			beat = (src:tell() + chart.OFFSET)*(bpm)/60
		end



		--[[local tempbeat = beat
		for offset, db in pairs(chart.WARPS) do
			if tempbeat > offset then
				tempbeat = tempbeat - db
			end
		end]]
		--beat = tempbeat

		local tempbeat = beat
		for offset, sec in pairs(chart.STOPS) do
			if beat > offset + sec*bpm/60 then
				beat = beat - sec*bpm/60
			elseif beat > offset then
				beat = offset
			end
		end
		--beat = tempbeat
		return beat
	end
	for i = 1, 4 do
		local noteCol = ui.new(noteContainer, i, {.25,0,4,0},{(i-1)*.25,0,0,0})
		
		function noteCol:selfdraw(x,y,w,h)
			local bOffset = -offset*bps
			local currentBeat = getCurrentBeat(src, chart)
			if i == 1 then
				love.graphics.print(currentBeat, 10,10)
			end

			local notelist = self.parent.parent.NOTEDATA[i]
			for _, note in pairs(notelist) do
				love.graphics.circle("line", x+w/2, y+w/2 + (note.beat - currentBeat)*h, w/3)
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