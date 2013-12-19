---------------
-- ShootEmAll.  
-- Prototype for löve 2d 0.8.0
--
-- [Github Project](https://github.com/eipporko/ShootEmAll)
--
--	Instructions
--
--	The goal of the game is to survive as long as you can.  
--	When you kill a monster you can obtain cash and buy power ups or buildings.
--
--	Controls
--	W: Forward
--	S: Back
--	A: Left
--	D: Right
--	Left Mouse Button: Fire Weapon
--	P: Debug mode
--	1-2: Set zoom
--	Esc: Exit
--
-- @author David Antúnez González
-- @copyright 2013
-- @license GPLv3
-- @script ShootEmAll

require("table-save")
require("level")
Timer = require("lib.timer")

local fps = 0					-- Frames Per Second
local fpsCount = 0				-- FPS count of the current second
local fpsTime = 0				-- Keeps track of the elapsed time
local memory = 0				-- Memory used

function round(num, idp)
  if idp and idp>0 then
    local mult = 10^idp
    return math.floor(num * mult + 0.5) / mult
  end
  return math.floor(num + 0.5)
end

function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function love.load() 
	-- load level
	level = Level.create("lvl3.tmx")

	-- load music
	--auBGM = love.audio.newSource("res/sound/music.ogg","stream")
	--auBGM:setLooping(true)
	--auBGM:setVolume(0.2)
	--auBGM:play()
end

function love.draw()	
	-- draw level
	level:draw()

	-- Draw a box so we can see the text easier
	if global.debugMode then
		love.graphics.setColor(0,0,0,100)
		love.graphics.rectangle("fill",10,10,216,93)
		love.graphics.setColor(255,255,255,255)

		love.graphics.setColor(255,255,255,255)
		love.graphics.print("FPS: "..love.timer.getFPS(), 20, 20)
		love.graphics.print("Memory: "..memory.." Mb", 20, 40)
		love.graphics.print("Entities: "..global.numOfEntities, 20, 60)
		love.graphics.print(string.format("Time span of flatten: %g seg", (global.flattenEnd - global.flattenStart)), 20, 80)
	end
end

function love.update(dt)
	-- level update
	level:update(dt)

	Timer.update(dt)

	-- Count the frames per second
	fpsTime = fpsTime + dt
	if fpsTime >= 1 then
		fps = love.timer.getFPS()
		fpsTime = 0
		memory = round(collectgarbage("count")/1024,2) -- Kb to Mb
	end
end

function love.keypressed(key)
	if key == "1" then
		level.cam:zoomTo(1)
	end
	if key == "2" then
		level.cam:zoomTo(2)
	end
	if key == "p" then
		-- Draw path A*
		global.debugMode = not global.debugMode
	end
	if key == "escape" then
		love.event.push("quit")   -- actually causes the app to quit
	end
end