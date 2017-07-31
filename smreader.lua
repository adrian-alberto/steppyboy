sm = {}

function sm.parse(file)
	local meta = {}
	local tracks = {}
	--tracks[difficulty] = dictionary

	for line in file:lines() do
		--Remove comments
		local l2 = string.match(line, "(.-)//.*")
		if l2 then
			line = l2
		end

		--Check leading character
		local first = string.sub(line, 1, 1)
		if first == "#" then
			--Check tag
			local tag, value, semicolon = string.match(line, "#(%a+):([^:;]*)(;?)")
			if not value then
				value = ""
			end

			if not tag then
				error("Bad line: '" .. line .. "'")
			elseif semicolon ~= ";" then
				--We need to combine multiple lines until a semicolon is found.
				repeat
					local nextline = file:read("*l")
					if not nextline then break end
					local nl2 = string.match(nextline, "(.-)//.*")
					if nl2 then
						nextline = nl2
					end

					local v2
					v2, semicolon = string.match(nextline, "^([^;]*)(;?).-")
					
					if v2 and v2 ~= "" then
						value = string.gsub(value .. "\n" .. v2,"\13","")
					end
				until semicolon == ";"
			end
			
			if tag == "NOTES" then
				local track, difficulty, tracktype = readNotes(value)

				tracks[tracktype .. "[" .. difficulty .. "]"] = track
			else
				meta[tag] = value
			end
		end
	end
	meta.TRACKS = tracks
	return meta
end

function readNotes(notedata)
	notedata = notedata .. "\n,;"
	local track = {}
	local difficulty = 0
	local tracktype = ""

	local i = 0
	local m = 1 -- measure index
	local measures = {{}} --list of measures

	--Load all notes into memory, also grab difficulty level
	for line in string.gmatch(notedata, "([^\n]-)[%s\n]+") do
		i = i + 1
		if i > 6 then
			if line == "," then
				--print("measure precision: " .. #measures[m])
				m = m + 1
				measures[m] = {}
			else
				local beat = {}
				for note in string.gmatch(line, "%d") do
					table.insert(beat, tonumber(note))
				end
				table.insert(measures[m], beat)
			end
		elseif i == 2 then
			tracktype = string.match(line, "%s*([%a%-]+):")
		elseif i == 5 then
			difficulty = tonumber(string.match(line, "%s*(%d+):"))
		end
	end
	
	--Convert into stream of notes (track)
	local lastLongNote = {} --references to last long note in a given direction
	                        --used to set the length of a note
	local beat = 0
	for m, measure in ipairs(measures) do
		local beatsize = 4 / #measure
		for _, bdata in ipairs(measure) do
			for dir, note in ipairs(bdata) do
				if note ~= 0 then
					if lastLongNote[dir] then
						lastLongNote[dir].length = beat - lastLongNote[dir].beat
						lastLongNote[dir] = nil
					else
						NOTE = {
							dir = dir,
							ntype = note,
							beat = beat,
						}
						if note ~= 1 then
							lastLongNote[dir] = NOTE
						end
						table.insert(track, NOTE)
					end
				end
			end
			beat = beat + beatsize
		end

	end

	track.noteindex = 1
	
	return track, difficulty, tracktype
end


return sm