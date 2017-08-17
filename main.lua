require "oop"
require "ui"
local ssc = require("sscreader")
local chartreader = require("chartreader")
local gameui = require("gameui")
local menuui = require("menu")

SETTINGS = {
	calibration = 0.125, -- 0.125 + or - 13
	mastervolume = 0.1,
}

local currentUI
local currentReader



function love.load()
	math.randomseed(os.time())

	love.audio.setVolume(SETTINGS.mastervolume)

	--LOAD THE SONGS IN
	local songtitles = love.filesystem.getDirectoryItems("songs")
	for _, title in ipairs(songtitles) do
		songtitles[title] = true
	end


	local songfastdata = {}

	local function combineStr(tab)
		local line = ""
		for i, v in pairs(tab) do
			if i ~= #tab then
				line = line .. v .. "\t"
			else
				line = line .. v .. "\n"
			end
		end
		return line
	end

	do --Read the song cache, rewrite if necessary
		local cacheTemplate = {"folder","gamefile","updated","TITLE","SUBTITLE","ARTIST","BANNER","JACKET","MUSIC","SAMPLESTART", "CHARTS"}
		local headerStr = combineStr(cacheTemplate)
		local tempFileStr = headerStr
		local requireWrite = false --Flag, must overwrite cache file.
		local cacheFile, err = love.filesystem.newFile("songcache.txt", "r")

		if not err then
			--get indices for the template
			for i, v in ipairs(cacheTemplate) do
				cacheTemplate[v] = i
			end

			local function get(tab, label)
				return tab[cacheTemplate[label]]
			end

			--validate cache first
			for line in cacheFile:lines() do
				if line.."\n" == headerStr then
					--header, do nothing
				else
					local songRemoved = false
					--break down into categories
					local lsplit = {}
					for x in string.gmatch(line, "([^\t]*)\t?") do
						table.insert(lsplit, x)
					end
					local songtitle = get(lsplit, "folder")
					local gamefile = get(lsplit, "gamefile")

					if not songtitles[songtitle] then
						requireWrite = true
						songRemoved = true
					elseif not love.filesystem.exists(gamefile) then
						requireWrite = true
						songRemoved = true
					elseif false then
						--file is mis-dated
					end

					if not songRemoved then
						--Copy to other file in case we have to rewrite
						tempFileStr = tempFileStr..line
						local data = {}
						for i, label in pairs(cacheTemplate) do
							data[label] = lsplit[i]
						end
						songfastdata[songtitle] = data
					end
				end
			end

			--add new songs (found in directory but not in the cache)
			for _, title in ipairs(songtitles) do
				if not songfastdata[title] then
					print("Adding " .. title .. "...")
					local song = ssc.song.new("songs/"..title)

					--{"folder","gamefile","updated","TITLE","SUBTITLE","ARTIST","BANNER","JACKET", "CHARTS"}
					local chartTxt = ""

					for difficulty, chart in pairs(song.charts) do
						chartTxt = chartTxt .. difficulty .. ":" .. chart.METER .. ":" .. (chart.CREDIT or "") .. ";"
					end

					local lsplit = {
						title,
						song.sscFilePath,
						love.filesystem.getLastModified(song.sscFilePath),
						song.meta.TITLE or "",
						song.meta.SUBTITLE or "",
						song.meta.ARTIST or "",
						song.meta.BANNER or "",
						song.meta.JACKET or "",
						song.meta.MUSIC,
						song.meta.SAMPLESTART or "0",
						chartTxt,
					}
					local line = ""
					for i, v in pairs(lsplit) do
						if i == #lsplit then
							line = line .. tostring(v) .. "\n"
						else
							line = line .. tostring(v) .. "\t"
						end
					end
					tempFileStr = tempFileStr..line
					song = nil
					requireWrite = true

					--Don't forget to add it to the data lol
					local data = {}
					for i, label in pairs(cacheTemplate) do
						data[label] = lsplit[i]
					end
					songfastdata[title] = data
				end
			end
		else
			requireWrite = true
		end

		if requireWrite then
			cacheFile:close()
			local newFile, err = love.filesystem.newFile("songcache.txt","w")
			newFile:write(tempFileStr)
			newFile:close()
		end
	end

	local sfdata2 = {}
	for title, data in pairs(songfastdata) do
		table.insert(sfdata2, data)
		if #sfdata2 >= 80 then
			break
		end
	end
	table.sort(sfdata2, function(a, b)
		return a.ARTIST..a.TITLE < b.ARTIST..b.TITLE
		--return a.TITLE..a.ARTIST < b.TITLE..b.ARTIST
	end)
	
	--load main menu
	local MAINMENU = menuui.build(sfdata2)
	currentUI = MAINMENU
	--TEMP, load single song
	--

	--]]
	--currentReader.src:seek(60)


end

function loadSong(data)
--local data = songfastdata["Marvin Gaye"]
--local data = sfdata2[math.random(1,#sfdata2)]
	local currentSong = ssc.song.new("songs/"..data.folder)
	currentReader = chartreader.new(currentSong, "Challenge")
	currentReader:loadNotes()
	currentUI = gameui.build(currentReader)
	currentReader:play()
	print("???")
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
	elseif currentUI.tag == "SongSelect" then
		currentUI:keypressed(key)
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
	--love.graphics.setBackgroundColor(255, 255, 255)
	love.graphics.setColor(255,255,255)
	if currentUI then
		currentUI:draw(0,0,width,height)
	end
end

