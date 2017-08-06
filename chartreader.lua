require "oop"
local LISTTAGS = {BPMS = 1, SPEEDS = 2, DELAYS = 3, STOPS = 5, WARPS = 6}
local ChartReader = class()

function ChartReader:init(songObj, difficulty)
	self.src = love.audio.newSource("songs/"..songObj.pathTitle.."/"..songObj.meta.MUSIC, "stream")
	self.chart = songObj.charts[difficulty] or error("No chart at this difficulty")
	--self.src:seek(60)

end


--[[
	- Compute markers
	- Load notes, store render beat & evaluation time
]]
function ChartReader:loadNotes()
	--compute timing markers
	local markers = {}
	for mtype, _ in pairs(LISTTAGS) do
		if self.chart[mtype] then
			for _, tup in pairs(self.chart[mtype]) do
				table.insert(markers, tup)
			end
		end
	end
	table.sort(markers, function(a, b)
		--TUPLES:  {tag, offset, value, ...}
		if a[2] == b[2] then
			return LISTTAGS[a[1]] < LISTTAGS[b[1]]
		else
			return a[2] < b[2]
		end
	end)

	local bpm = 0
	local speed = 1
	local lastBPMchangeBeat = 0
	local lastBPMchangeTime = 0
	local totalWarpSinceBPMchange = 0
	local totalDelay = 0
	for _, tup in pairs(markers) do
		local beat = tup[2]
		local value = tup[3]
		local tag = tup[1]

		tup.start = beat
		tup.t_start = 0
		if bpm > 0 then
			tup.t_start = (beat - lastBPMchangeBeat - totalWarpSinceBPMchange)/(bpm/60) + lastBPMchangeTime + totalDelay
		end
		if tag == "BPMS" then
			bpm = value
			lastBPMchangeBeat = beat
			lastBPMchangeTime = tup.t_start
			totalWarpSinceBPMchange = 0
		elseif tag == "SPEEDS" then
			speed = value
			local boolConvertToTime = (tup[5] == 1)
			local rampUp = tup[4] or 0
			tup.length = boolConvertToTime and rampUp/(bpm/60) or rampUp
		elseif tag == "STOPS" then
			tup.dt = value
			tup.length = value*bpm/60
			totalDelay = totalDelay + value
		elseif tag == "DELAYS" then
			tup.dt = value
			tup.length = value*bpm/60
			totalDelay = totalDelay + value
		elseif tag == "WARPS" then
			tup.start = tup.start + value
			tup.length = value
			totalWarpSinceBPMchange = totalWarpSinceBPMchange + tup.length
		end
		tup.bpm = bpm
		tup.speed = speed
	end

	self.markers = markers


	---------------------------------------------------------------------------
	--break down the NOTES stuff
	local notes = {{},{},{},{}} --4 separate note queues

	local i = 0 --measure index
	for measure in string.gmatch(self.chart.NOTES, "(%w+),?") do
		local numrows = string.len(measure)/4
		local j = 0
		for rowstr in string.gmatch(measure, "%w%w%w%w") do
			local beat = 4*i + 4*j/numrows
			local evaltime
			--Try and figure out when this thing is actually supposed to be played
			--TODO: move this portion later
			for _, marker in pairs(markers) do
				if marker[1] == "WARPS" and marker.start-marker.length < beat  and marker.start > beat then
					evaltime = nil
					break
					--we had a warp skip over this note
				elseif marker.start <= beat then
					evaltime = -self.chart.OFFSET + marker.t_start + (beat-marker.start)/(marker.bpm/60)
					if marker[1] == "DELAYS" or marker[1] == "STOPS" and marker.start < beat then
						evaltime = evaltime + marker.dt
					end
				else
					break
				end
			end


			--AAAAAAAAAAAA


			local col_index = 1
			for note in string.gmatch(rowstr, "%w") do
				if note == "3" then
					local prevnote = notes[col_index][#notes[col_index]]
					if prevnote and prevnote.ntype == "2" or prevnote.ntype == "4" then
						prevnote.length = beat - prevnote.beat
						prevnote.endevaltime = evaltime
					end
				elseif note ~= "0" then
					local noteObj = {ntype = note, beat = beat, evaltime = evaltime}
					table.insert(notes[col_index], noteObj)
				end
				col_index = col_index + 1
			end
			j = j + 1
		end
		i = i + 1
	end

	self.notes = notes
end

function ChartReader:getCurrentBeat()
	local t = self.src:tell() + self.chart.OFFSET

	local beat = 0
	local bpm = 0
	local speed = 1
	local lastSpeed = 1
	local beatSmear = 0 --How many beats held in a stop or delay (used for rendering during stop)

	for i, marker in pairs(self.markers) do
		if t >= marker.t_start then
			bpm = marker.bpm
			speed = marker.speed
			beat = marker.start + (t - marker.t_start)*bpm/60
			
			if marker[1] == "STOPS" or marker[1] == "DELAYS" then
				if (t - marker.t_start) < marker.dt then
					beatSmear = beat - marker.start
					beat = marker.start
				else
					beat = beat - marker.length
				end
			elseif marker[1] == "SPEEDS" and (beat-marker.start) < marker.length then
				local alpha = (beat-marker.start)/marker.length
				speed = alpha*(speed-lastSpeed) + lastSpeed
			end
		else
			break
		end
		lastSpeed = speed
	end

	return beat, speed, beatSmear
end

function ChartReader:play()
	love.audio.play(self.src)
end



return ChartReader