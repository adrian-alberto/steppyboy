local arrowimg = love.graphics.newImage("resources/arrow_screen_64.png")
function buildGameUI(reader)
	local gameUI = ui.new()
	gameUI.tag = "Game"
	gameUI.NOTEDATA = reader.notes --TEMPORARY AS FUCK
	gameUI.JUDGMENTS = reader.judgments
	local noteContainer = ui.new(gameUI, "NoteContainer", {0,256,0,64},{0.5,-128,0,60})
	local angles = {-math.pi/2, math.pi, 0, math.pi/2}
	local colors = {}
	colors[4] = {244, 67, 54} --#F44336
	colors[8] = {33, 150, 243} --#2196F3
	colors[12] = {76, 175, 80} --#4CAF50
	colors[16] = {255, 235, 59} --#FFEB3B
	colors[24] = {156, 39, 176} --#9C27B0
	colors[32] = {0, 150, 136} --#009688
	colors[48] = {233, 30, 99} --#E91E63

	function noteContainer:selfdraw()
	end

	for i = 1, 4 do
		local noteCol = ui.new(noteContainer, i, {.25,0,4,0},{(i-1)*.25,0,0,0})
		
		function noteCol:selfdraw(x,y,w,h)
			local currentBeat, currentSpeed, beatSmear = reader:getCurrentBeat()

			if i == 1 then
				love.graphics.setColor(90,90,90)
				love.graphics.print(currentBeat, 10,10)
				love.graphics.print(reader.src:tell(), 10,30)
				if #reader.judgments > 0 then
					local temp = {}
					for j = 1, #reader.judgments do
						table.insert(temp, reader.judgments[j].ms)
					end
					table.sort(temp)


					love.graphics.print(temp[math.ceil(#temp/2)],200,10)
				end
			end

			love.graphics.setBlendMode("screen")
			--targets
			local beatAlpha = (currentBeat+beatSmear)%1
			local tcolor = 125 - beatAlpha*100
			love.graphics.setColor(tcolor+16,tcolor+24,tcolor+47)
			love.graphics.draw(arrowimg, x+w/2, y+w/2, angles[i], 1-beatAlpha/10,1-beatAlpha/10,32,32)
			--DRAW NOTES IN THIS COLUMN
			local notelist = self.parent.parent.NOTEDATA[i]
			for _, note in pairs(notelist) do
				if (note.beat - currentBeat) < 8 and (note.beat - currentBeat) > -2 
					or (note.length and note.beat < currentBeat and note.beat+note.length > currentBeat-2) then
					if note.ntype == "M" then
						love.graphics.setColor(25,25,25)
					else
						love.graphics.setColor(255,255,255)
						local current = 1000
						for divisor, color in pairs(colors) do
							if divisor < current and ((note.beat)*divisor/4) % (1) == 0 then
								love.graphics.setColor(color[1]+16,color[2]+24,color[3]+48)
								current = divisor
							end
						end
					end

					local NOTEX = math.floor(x + w/2)
					local NOTEY_0 =  y+w/2 + (note.beat - currentBeat)*h*currentSpeed
					if not note.judged and not note.length then
						--draw a normal note
						love.graphics.draw(arrowimg, NOTEX, NOTEY_0, angles[i], w/64,w/64,32,32)
					end
					if note.length and not note.liftPercent then
						local NOTEY_1 = math.floor(NOTEY_0 + note.length*h*currentSpeed)
						if note.judged then
							NOTEY_0 = y+w/2
							if note.length + note.beat < currentBeat then
								note.liftPercent = 1
								--TODO: probably send a message to OK the judgment?
							end
						end
						if not note.liftPercent then
							love.graphics.draw(arrowimg, NOTEX, NOTEY_0, angles[i], w/64,w/64,32,32)
							
							love.graphics.line(x, NOTEY_0, x, NOTEY_1)
							love.graphics.line(x+w, NOTEY_0, x+w, NOTEY_1)
							love.graphics.line(x, NOTEY_1, NOTEX, NOTEY_1 + w/2)
							love.graphics.line(x+w, NOTEY_1, NOTEX, NOTEY_1 + w/2)
						end
					end


				end
				--[[if note.evaltime then
					love.graphics.circle("line", x+w/2+w*6, y+w/2 + (note.evaltime - reader.src:tell())*h*3, w/3)
				end]]
			end
			love.graphics.setBlendMode("alpha")
		end
	end

	local judgeContainer = ui.new(noteContainer, "judgeContainer", {1,0,0,0},{0,0,0,256})
	function judgeContainer:selfdraw(x,y,w,h)
		local judgments = self.parent.parent.JUDGMENTS
		for i, judgment in pairs(judgments) do
			if i > 5 then
				break
			end
			
			if i == 1 then
				love.graphics.setColor(200,255,200)
				love.graphics.printf(judgment.text,x,y+i*20, w, "center")
			else
				love.graphics.setColor(255,255,255)
				love.graphics.printf(judgment.text,x,y+i*20, w, "center")
			end
		end

	end

	function gameUI:selfdraw(x,y,w,h)
		love.graphics.setColor(20,30,60,200)
		--love.graphics.setColor(30,30,30)
		love.graphics.rectangle("fill",x,y,w,h)
	end

	return gameUI
end

return {build=buildGameUI}