--- Bat class, subclass of `Mob`. 
-- A bat monster!
--
--  ![Texto alternativo](../../res/art/mob/enemy_bat_32.png "Bat Sprites")  
--
--	LIFE  = 50
--	SPEED = 50
--	STATE = 'stop|walk'
-- @module mob.bat

require("entity.mob.mob")


--- Bat Class, subclass of `Mob`
-- @type Bat
Bat = class('Bat', Mob)

-- Image where are located the tileset of the bat.
Bat.static.SPRITES = love.graphics.newImage('res/art/mob/enemy_bat_32.png')
Bat.SPRITES:setFilter("nearest","nearest")

-- Define the grid that divides the tileset.
Bat.static.GRID = anim8.newGrid(32, 32, Bat.SPRITES:getWidth(), Bat.SPRITES:getHeight())

-- Amount of life.
Bat.static.LIFE = 50

-- Speed value (px/sec).
Bat.static.SPEED = 50

-- Sprite anchor point.
-- In function of the sprite origin.
-- @field x x offset
-- @field y y offset
Bat.static.ANCHOR = {x=15,y=32}

-- Bound box.
-- In function of the sprite origin.
-- @field x1 top left x 
-- @field y1 top left y
-- @field x2 bottom right x
-- @field y2 bottom right y
Bat.static.BOXCOLLIDER = {x1=8,y1=24,x2=24,y2=32}


--- Initialize the object `Bat`.
--
-- Don't call this method directly!, this method is called automatically when 
-- the class is instanciated using the method new.
-- @usage 
-- Bat:new(x,y,level)
-- @param x world x coordinate
-- @param y world y coordinate
-- @param level `Level` where the object belongs
function Bat:initialize(x,y,level)
	local animations = {
		-- stop
		stop0 = anim8.newAnimation('loop', Bat.GRID('1-4,1'), 0.1),
		-- walk
		walk0 = anim8.newAnimation('loop', Bat.GRID('1-4,1'), 0.1)

	}

	Mob.initialize(self,x,y,Bat.SPEED,Bat.LIFE,"stop",Bat.SPRITES,animations,Bat.ANCHOR,Bat.BOXCOLLIDER,level)

	self.facing = 0
	self.action = {
		["stop"] = function(dt) self:_stopState(dt) end,
		["walk"] = function(dt) self:_walkState(dt) end,
	}
end


--- State machine.
-- @section stateMachine

--- "stop" state of the state machine. The bat is stoped.
-- @param dt delta time
function Bat:_stopState(dt)
	if self.x ~= self.dest.x or self.y ~= self.dest.y then
		self:_changeState("walk")
	end

	self.level:checkCollideEntities(self)
end


--- "walk" state of the state machine. The bat is flying.
-- @param dt delta time
function Bat:_walkState(dt)
	
	if self:isInDest() then
		self:_changeState("stop")
		return
	end

	self:moveToDest(dt)

end