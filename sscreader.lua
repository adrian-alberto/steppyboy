--[[
- Load in whole file line by line
	- Remove comments (//)
	- Remove newlines?

- gmatch with #<tag>:<stuff>;
- handle stuff by tag?

- DO NOT EVALUATE THE INDIVIDUAL #NOTES LISTS until
  track is loaded
]]

local LISTTAGS = {"BPMS","STOPS","DELAYS", "WARPS"}
for i, v in ipairs(LISTTAGS) do
LISTTAGS[v] = true
LISTTAGS[i] = nil
end

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
					v2[tonumber(t)] = tonumber(v)
					i = i + 1
				end

				if i == 1 and tag == "BPMS" then
					value = v2[next(v2)]
				else
					value = v2
				end
			end
			current[tag] = value
		end
	end

	local charts = {}
	for i, v in pairs(tempModes) do
		if v.STEPSTYPE == "dance-single" then
			charts[v.DIFFICULTY] = v
			setmetatable(charts, {__index=meta})
		end
	end

	file:close()
	return meta, charts
end

return ssc