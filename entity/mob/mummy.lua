--- Mummy class, subclass of `Mob`. 
-- A creepy ancient mummy!
--
--  ![Texto alternativo](../../res/art/mob/enemy_mummy_anim_48.png "Mummy Sprites")  
--
--	LIFE  = 200
--	SPEED = 25
--	STATE = 'stop|walk'
-- @module mob.mummy

require("entity.mob.mob")

--- Mummy Class, subclass of `Mob`
-- @type Mummy
Mummy = class('Mummy', Mob)

-- Image where are located the tileset of the mummy.
Mummy.static.SPRITES = love.graphics.newImage('res/art/mob/enemy_mummy_anim_48.png')
Mummy.SPRITES:setFilter("nearest","nearest")

-- Define the grid that divides the tileset.
Mummy.static.GRID = anim8.newGrid(48, 48, Mummy.SPRITES:getWidth(), Mummy.SPRITES:getHeight())

-- Amount of life.
Mummy.static.LIFE = 200

-- Speed value (px/sec).
Mummy.static.SPEED = 25

-- Sprite anchor point.
-- In function of the sprite origin.
-- @field x x offset
-- @field y y offset
Mummy.static.ANCHOR = {x=24,y=39}

-- Bound box.
-- In function of the sprite origin.
-- @field x1 top left x 
-- @field y1 top left y
-- @field x2 bottom right x
-- @field y2 bottom right y
Mummy.static.BOXCOLLIDER = {x1=16,y1=31,x2=32,y2=39}

--- Initialize the object `Mummy`.
--
-- Don't call this method directly!, this method is called automatically when 
-- the class is instanciated using the method new.
-- @usage 
-- Mummy:new(x,y,level)
-- @param x world x coordinate
-- @param y world y coordinate
-- @param level `Level` where the object belongs
function Mummy:initialize(x,y,level)
	local animations = {
		-- stop
		stop0 = anim8.newAnimation(Mummy.GRID(1,4), 0.1),
		stop1 = anim8.newAnimation(Mummy.GRID(1,3), 0.1),  
		stop2 = anim8.newAnimation(Mummy.GRID(1,2), 0.1), 
		stop3 = anim8.newAnimation(Mummy.GRID(1,1), 0.1),   
		-- walk
		walk0 = anim8.newAnimation(Mummy.GRID('1-4',4), 0.2),
		walk1 = anim8.newAnimation(Mummy.GRID('1-4',3), 0.2),
		walk2 = anim8.newAnimation(Mummy.GRID('1-4',2), 0.2),
		walk3 = anim8.newAnimation(Mummy.GRID('1-4',1), 0.2)
	}
	
	Mob.initialize(self,x,y,Mummy.SPEED,Mummy.LIFE,"stop",Mummy.SPRITES,animations,Mummy.ANCHOR,Mummy.BOXCOLLIDER,level)

	self.facing = 2
	self.action = {
		["stop"] = function(dt) self:_stopState(dt) end,
		["walk"] = function(dt) self:_walkState(dt) end,
	}
end

--- State machine.
-- @section stateMachine

--- "stop" state of the state machine. The Mummy is stoped.
-- @param dt delta time
function Mummy:_stopState(dt)
	if self.x ~= self.dest.x or self.y ~= self.dest.y then
		self:_changeState("walk")
	end

	self.level:checkCollideEntities(self)
end


--- "walk" state of the state machine. The mummy is walking.
-- @param dt delta time
function Mummy:_walkState(dt)

	if self:isInDest() then
		self:_changeState("stop")
		return
	end

	self:moveToDest(dt)

	-- Get facing direction
	local angle = math.atan2(newPosition:unpack())
	if angle<0 then
		angle = angle + 2*math.pi
	end
	angle = math.deg(angle)
	self.facing = math.floor((angle)/90)%4

end