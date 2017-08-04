--[[
- Load in whole file line by line
	- Remove comments (//)
	- Remove newlines?

- gmatch with #<tag>:<stuff>;
- handle stuff by tag?

- DO NOT EVALUATE THE INDIVIDUAL #NOTES LISTS until
  track is loaded
]]

local LISTTAGS = {BPMS = 1, SPEEDS = 2, DELAYS = 3, STOPS = 5, WARPS = 6}

---------------------------
local ssc = {}
song = class()
ssc.song = song
function song:init(dir)
	if not love.filesystem.isDirectory(dir) then
		error("Song directory not found: " .. dir)
	end

	local dirContents = love.filesystem.getDirectoryItems(dir)
	--Find the .ssc file
	local sscFilePath
	for i, v in pairs(dirContents) do
		if string.match(v, ".-%.ssc$") then
			sscFilePath = dir .. "/" .. v
		end
	end
	if not sscFilePath then error("Missing .ssc: " .. dir) end

	--Read and parse file
	local meta, charts = song.parse(sscFilePath)
	self.meta = meta
	self.charts = charts
end

function song.parse(filepath)
	local file, err = love.filesystem.newFile(filepath, "r")

	--Squish contents together
	local contents = ""
	for line in file:lines() do
		--Remove comments
		local comment = string.find(line, "%s*//")
		if comment then
			line = string.sub(line, 1, comment-1)
		end
		contents = contents .. line
	end
	
	local meta = {}
	local tempModes = {}
	local current = meta

	for tag, value in string.gmatch(contents, "#(%w+):(.-);") do
		if tag == "NOTEDATA" then
			current = {}
			table.insert(tempModes, current)
		elseif value ~= "" then
			if LISTTAGS[tag] then
				local arrVal = {}
				local i = 0
				for tup in string.gmatch(value, "([%d%.=]+),?") do
					local nextTup = {}
					nextTup[1] = tag --First element of tuple is the tag
					for element in string.gmatch(tup, "([%d%.]+)=?") do
						--Append elements of the tuple to the nextTup array
						table.insert(nextTup, tonumber(element))
					end
					table.insert(arrVal, nextTup)
				end

				value = arrVal
			end
			current[tag] = value
		end
	end

	local charts = {}
	for i, v in pairs(tempModes) do
		if v.STEPSTYPE == "dance-single" then
			charts[v.DIFFICULTY] = v
			setmetatable(v, {__index=meta})

			--compute timing markers
			local markers = {}
			for mtype, _ in pairs(LISTTAGS) do
				if v[mtype] then
					for _, tup in pairs(v[mtype]) do
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

			v.markers = markers
		end
	end

	file:close()
	return meta, charts
end

return ssc