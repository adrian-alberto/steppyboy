require "oop"
require "ui"
local ssc = require("sscreader")
local chartreader = require("chartreader")
local gameui = require("gameui")

SETTINGS = {
	calibration = 0.125
}

local currentUI
local currentReader



function love.load()
	math.randomseed(os.time())
	--temp

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
	currentReader = chartreader.new(currentSong, "Challenge")
	currentReader:loadNotes()
	currentUI = gameui.build(currentReader)
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

