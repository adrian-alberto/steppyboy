--[[
- Load in whole file line by line
	- Remove comments (//)
	- Remove newlines?

- gmatch with #<tag>:<stuff>;
- handle stuff by tag?

- DO NOT EVALUATE THE INDIVIDUAL #NOTES LISTS until
  track is loaded
]]

local LISTTAGS = {BPMS = 1, DELAYS = 2, STOPS = 3, WARPS = 4}

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
				local v2 = {}
				local i = 0
				for x in string.gmatch(value, "([%d%.=]+),?") do
					local t, v = string.match(x, "([%d%.]+)=([%d%.]+)")
					--v2[tonumber(t)] = tonumber(v)

					--TUPLES:  {offset, value, tag}
					table.insert(v2, {tonumber(t),tonumber(v), tag})
					i = i + 1
				end
				--[[table.sort(v2, function(a, b)
					return a[1] < b[1]
				end)]]

				--[[if i == 1 and tag == "BPMS" then
					value = v2[next(v2)]
				else
					value = v2
				end]]
				value = v2
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
				--TUPLES:  {offset, value, tag}
				if a[1] == b[1] then
					return LISTTAGS[a[3]] < LISTTAGS[b[3]]
				else
					return a[1] < b[1]
				end
			end)

			local actualOffset = 0
			local currentFileBeat = 0
			local bpm = 0
			local lastBPMchangeBeat = 0
			local lastBPMchangeTime = 0
			local totalWarpSinceBPMchange = 0
			local renderOffset = 0
			local total_delay = 0
			for _, tup in pairs(markers) do
				local beat = tup[1]
				local value = tup[2]
				local tag = tup[3]

				tup.start = beat
				tup.t_start = 0
				if bpm > 0 then
					tup.t_start = (beat - lastBPMchangeBeat - totalWarpSinceBPMchange)/(bpm/60) + lastBPMchangeTime + total_delay
				end
				if currentFileBeat > tup[1] then
					tup.start = math.huge
					tup.t_start = math.huge
				elseif tag == "BPMS" then
					bpm = value
					lastBPMchangeBeat = beat
					lastBPMchangeTime = tup.t_start
					totalWarpSinceBPMchange = 0
				elseif tag == "STOPS" then
					tup.dt = value
					tup.length = value*bpm/60
					total_delay = total_delay + value
				elseif tag == "WARPS" then
					tup.start = tup.start + value
					tup.length = value
					totalWarpSinceBPMchange = totalWarpSinceBPMchange + tup.length
				end
				tup.bpm = bpm
			end

			v.markers = markers
		end
	end

	file:close()
	return meta, charts
end

return ssc