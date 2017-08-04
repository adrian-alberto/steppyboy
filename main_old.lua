local smreader = require("smreader")
local testtrack
local src
local arrowimg
local beatOffset = -0.0

function love.load()
	local GAMEDIR = love.filesystem.getWorkingDirectory( )
	arrowimg = love.graphics.newImage("resources/arrow_screen_64.png")

	src = love.audio.newSource("songs/Black Magic/Black Magic.ogg", "stream")
	x = io.open(GAMEDIR .. "/songs/Black Magic/Black Magic.sm")
	local smdata = smreader.parse(x)

	--[[for i, v in pairs(smdata) do
		if i ~= "TRACKS" then
			print(i .. ": " .. string.format("%q", v))
		end
	end]]

	testtrack = smdata.TRACKS["dance-single[9]"]
	love.audio.play(src)
	--src:seek(20)
	--love.event.quit()
end



local heldNotes = {}
local lastTap = {0,0,0,0,0,0,0,0}
function love.update(dt)
	if src and testtrack then
		local bpm = 112
		local trackTime = src:tell()
		local currentBeat = trackTime*bpm/60 - 0.032 + beatOffset
		--clear finished held notes
		for i, note in ipairs(heldNotes) do
			if note.beat + note.length < currentBeat then
				note.holding = false
				heldNotes[i] = nil
			end
		end

		--miss notes
		for i = testtrack.noteindex, #testtrack do
			local note = testtrack[i]
			if note.beat > currentBeat - 0.3 then
				break
			end
			if not note.status then
				hitNote(note, "miss")
				testtrack.noteindex = i
			end
		end
	end
end

local testcolors = {{200,100,100},{100,100,200},{200,200,100},{100,200,100}}
local rotations = {-math.pi/2, math.pi, 0, math.pi/2, -math.pi/2, math.pi, 0, math.pi/2, }
function love.draw()
	if not src then return end
	love.graphics.setBackgroundColor(30,30,30)
	love.graphics.setBlendMode("screen")
	local bpm = 112
	local trackTime = src:tell()
	local currentBeat = trackTime*bpm/60 - 0.032 + beatOffset
	local w, h = love.window.getMode()
	local cellheight = 256
	local cellwidth = 64
	local pad = 6

	local x0 = 64
	local y0 = 64
	for i = 0, 3 do
		local bright = 100 * (1 - (currentBeat % 1)) + 50
		bright = bright + math.max(0,200 * (0.5 - (currentBeat - lastTap[i+1])))
		bright = math.min(255,bright)
		love.graphics.setColor(bright, bright, bright)
		love.graphics.circle("line", x0 + i*(cellwidth+pad), y0, cellwidth/2)
	end


	

	--NOTES
	local notecount = 0
	for i, note in ipairs(testtrack) do
		local x = x0 + (note.dir-1) * (cellwidth + pad)
		local y = y0 + note.beat * cellheight - currentBeat*cellheight
		if y > 2*h then
			--off screen
			break
		elseif y + (note.length or 0)*cellheight < -h then
			--off screen
		else
			notecount = notecount + 1
			--color pick
			love.graphics.setColor(200,200,200)
			for j = 1, #testcolors do
				if (note.beat) % (2^(1-j)) <= 0.000001 then
					love.graphics.setColor(unpack(testcolors[j]))
					break
				end
			end
			if note.status == "miss" then
				local r,g,b = love.graphics.getColor()
				love.graphics.setColor(r/2,g/2,b/2)
			elseif note.status and not note.holding then
				love.graphics.setColor(0,0,0)
			end


	
			if note.ntype ~= 1 then
				--Draw the trails
				if note.holding and note.beat+note.length > currentBeat then
					love.graphics.circle("line", x, y0, cellwidth/2)
					love.graphics.draw( arrowimg, x, y0, rotations[note.dir], 1, 1, cellwidth/2, cellwidth/2)
					love.graphics.line(x-cellwidth/2, y0, x-cellwidth/2, y + note.length*cellheight)
					love.graphics.line(x+cellwidth/2, y0, x+cellwidth/2, y + note.length*cellheight)
					love.graphics.arc("line","open", x, y + note.length*cellheight, cellwidth/2, 0, math.pi)
				else
					love.graphics.circle("line", x, y, cellwidth/2)
					love.graphics.draw( arrowimg, x, y, rotations[note.dir], 1, 1, cellwidth/2, cellwidth/2)
					love.graphics.line(x-cellwidth/2, y, x-cellwidth/2, y + note.length*cellheight)
					love.graphics.line(x+cellwidth/2, y, x+cellwidth/2, y + note.length*cellheight)
					love.graphics.arc("line","open", x, y + note.length*cellheight, cellwidth/2, 0, math.pi)
				end
				
			else
				--Draw just a standard note
				love.graphics.circle("line", x, y, cellwidth/2)
				love.graphics.draw( arrowimg, x, y, rotations[note.dir], 1, 1, cellwidth/2, cellwidth/2)
			end
		end
	end
	love.graphics.print(notecount .. " notes", 10, 10)
end

function hitNote(note, status)
	if note then
		note.status = status
	else

	end
end

function pressNote(dir, track, trackTime)
	local bpm = 112
	local currentBeat = trackTime*bpm/60 - 0.032 + beatOffset
	local didhit = false
	lastTap[dir] = currentBeat
	for i = track.noteindex, #track do
		local note = track[i]
		local diff = math.abs(currentBeat - note.beat)
		if note.beat < currentBeat - 0.3 then
			hitNote(note, "miss")
			track.noteindex = i
		elseif diff <= 0.6 then
			if note.dir == dir and not note.status then
				if note.ntype ~= 1 then
					note.holding = true
					heldNotes[dir] = note
				end
				if diff < 0.3 then
					hitNote(note, "perfect")
				elseif diff < 0.4 then
					hitNote(note, "good")
				else
					hitNote(note, "ok")
				end
				didhit = true
				break
			end
		else
			break
		end
	end
	if not didhit then
		hitNote(nil, "bad")
	end
end

function releaseNote(dir, track, trackTime)
	local bpm = 118
	local currentBeat = trackTime*bpm/60 - 0.032 + beatOffset
	if heldNotes[dir] then
		local note = heldNotes[dir]
		if currentBeat - (note.length + note.beat) - currentBeat > -0.6 then
			hitNote(note, "miss")
		end
		note.holding = false
		heldNotes[dir] = nil
	end
end

local keytranslate = {left = 1, down = 2, up = 3, right = 4}
function love.keypressed(key)
	if keytranslate[key] then pressNote(keytranslate[key], testtrack, src:tell()) end
end

function love.keyreleased(key)
	if keytranslate[key] then releaseNote(keytranslate[key], testtrack, src:tell()) end
end
