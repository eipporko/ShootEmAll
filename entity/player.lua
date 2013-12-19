--- Player class, subclass of `Entity`.
--
--  ![Texto alternativo](../../res/art/player/lord_lard_sheet.png "Player Sprites")  
--
--	SPEED = 100
--	STATE = 'stop|walk'
-- @module entity.player

require("entity.entity")
require("entity.weapon")

--- Player Class, subclass of `Entity`
-- @type Player
Player = class('Player', Entity)

-- Image where are located the tileset of the player.
Player.static.SPRITES = love.graphics.newImage('res/art/player/lord_lard_sheet.png')
Player.SPRITES:setFilter("nearest","nearest")

-- Define the grid that divides the tileset.
Player.static.GRID = anim8.newGrid(32, 32, Player.SPRITES:getWidth(), Player.SPRITES:getHeight())

-- Set of animations for the player depending on the state and where is looking for.
Player.static.ANIMATIONS = {
	stop0 = anim8.newAnimation(Player.GRID(1,5), 0.1), 	-- Player is stopped looking up (0º)
	stop1 = anim8.newAnimation(Player.GRID(1,6), 0.1), 	-- Player is stopped looking right 45º 
	stop2 = anim8.newAnimation(Player.GRID(1,7), 0.1), 	-- Player is stopped looking right 90º
	stop3 = anim8.newAnimation(Player.GRID(1,8), 0.1), 	-- Player is stopped looking right 135º  
	stop4 = anim8.newAnimation(Player.GRID(1,1), 0.1), 	-- Player is stopped looking down (180º) 
	stop5 = anim8.newAnimation(Player.GRID(1,2), 0.1), 	-- Player is stopped looking left -135º
	stop6 = anim8.newAnimation(Player.GRID(1,3), 0.1), 	-- Player is stopped looking left -90º
	stop7 = anim8.newAnimation(Player.GRID(1,4), 0.1), 	-- Player is stopped looking left -45º
	walk0 = anim8.newAnimation(Player.GRID('1-6',5), 0.1),	-- Player is walking looking up (0º)
	walk1 = anim8.newAnimation(Player.GRID('1-6',6), 0.1),	-- Player is walking looking right 45º
	walk2 = anim8.newAnimation(Player.GRID('1-6',7), 0.1),	-- Player is walking looking right 90º
	walk3 = anim8.newAnimation(Player.GRID('1-6',8), 0.1),	-- Player is walking looking right 135º
	walk4 = anim8.newAnimation(Player.GRID('1-6',1), 0.1),	-- Player is walking looking down (180º)
	walk5 = anim8.newAnimation(Player.GRID('1-6',2), 0.1),	-- Player is walking looking left -135º
	walk6 = anim8.newAnimation(Player.GRID('1-6',3), 0.1),	-- Player is walking looking left -90º
	walk7 = anim8.newAnimation(Player.GRID('1-6',4), 0.1)	-- Player is walking looking left -45º
}

-- Speed value (px/sec).
Player.static.SPEED = 100

-- Sprite anchor point.
-- @field x x offset
-- @field y y offset
Player.static.ANCHOR = {x=16,y=32}

-- Bound box.
-- In function of the (0,0) coordinate of the sprite.
-- @field x1 top left x 
-- @field y1 top left y
-- @field x2 bottom right x
-- @field y2 bottom right y
Player.static.QUADCOLLIDER = {x1=9,y1=23,x2=23,y2=30}

-- mouse
love.mouse.setVisible(false) -- make default mouse invisible
imgMouse = love.graphics.newImage("res/art/player/mouse.png") -- load in a custom mouse image
imgMouse:setFilter("nearest","nearest")

--- Initialize the object `Player`.
--
-- Don't call this method directly!, this method is called automatically when 
-- the class is instanciated using the method new.
-- @usage 
-- Player:new(x,y,level)
-- @param x world x coordinate
-- @param y world y coordinate
-- @param level `Level` where the object belongs
function Player:initialize(x,y,level)
	Entity.initialize(self,x,y,Player.SPEED,"stop",Player.SPRITES,Player.ANIMATIONS,Player.ANCHOR,Player.QUADCOLLIDER,level)

	self.facing = nil
	self.aimVector = nil
	self.weapon = Weapon.create(self)

	-- state machine functions
	self.action = {
		["stop"] = function(dt) self:_stopState(dt) end,
		["walk"] = function(dt) self:_walkState(dt) end,
	}
end


--- Update stage.
-- @param dt delta time
function Player:update(dt)
	self:_aiming()

	self:_handleWeapon(dt, self.aimVector )

	-- state machine
	self.action[self.state](dt)

	-- 
	self:checkCollision()

	-- playerAnimation update
	self.animations[self.state..self.facing]:update(dt)


end

--- Draw in canvas the player spotlight.
function Player:drawMouse()
	local x, y = love.mouse.getPosition() -- get the position of the mouse
	love.graphics.draw(imgMouse, x-7, y-7) -- draw the custom mouse image
end


--- Calculates the zone where the player is aiming.
function Player:_aiming()
	-- variables
	local cam = self.level.cam
	local camScale = cam.scale
	local mouseWindowCoords, mouseWorldCoords, vectMouse, vectReference = {}, {}, {}

	-- get normalized vector player-mouse
	mouseWindowCoords.x, mouseWindowCoords.y = love.mouse.getPosition()
	mouseWorldCoords.x, mouseWorldCoords.y = cam:worldCoords(mouseWindowCoords.x*camScale, mouseWindowCoords.y*camScale)
	vectMouse.x = math.floor(mouseWorldCoords.x) - math.floor(self.x)
	vectMouse.y = math.floor(self.y) - math.floor(mouseWorldCoords.y) 
	vectMouse = vector.new(vectMouse.x,vectMouse.y):normalized()
	self.aimVector = vectMouse

	--get facing
	local angle = math.atan2(vectMouse:unpack())
	if angle<0 then
		angle = angle + 2*math.pi
	end
	angle = math.deg(angle)
	self.facing = math.floor((angle+22.5)/45)%8
end

--- Handle weapong function, fire it's neccesary.
-- @param dt delta time
-- @param aimVector direction vector
function Player:_handleWeapon(dt, aimVector)
	if love.mouse.isDown("l") then self.weapon:primaryFire(dt, aimVector) end
	if not love.mouse.isDown("l") then self.weapon:releaseFire() end
end


--- State machine.
-- @section stateMachine

--- "stop" state of the state machine. The player is stoped.
-- @param dt delta time
function Player:_stopState(dt)
	-- change to walk state
	if love.keyboard.isDown("w", "s", "a", "d" ) then
		self:_changeState("walk")
	end
end



--- "walk" state of the state machine. The player is walking.
-- @param dt delta time
function Player:_walkState(dt)
	
	local vectUp, vectDown, vectLeft, vectRight = 0, 0, 0, 0
	if love.keyboard.isDown("w") then vectUp = -1 end
	if love.keyboard.isDown("s") then vectDown = 1 end
	if love.keyboard.isDown("a") then vectLeft = -1 end
	if love.keyboard.isDown("d") then vectRight = 1 end
	if not love.keyboard.isDown("w", "s", "a", "d" ) then
		self:_changeState("stop")
		return
	end	
	
	-- calculate vector facing
	vectY = vectUp + vectDown
	vectX = vectLeft + vectRight
	if math.abs(vectX) + math.abs(vectY) > 1 then
		vectX = vectX*0.8944	
		vectY = vectY*0.4472	
	end

	-- calculate new position
	newX = self.x + (vectX*self.speed*dt)
	newY = self.y + (vectY*self.speed*dt)
	
	-- check collision
	if not self.level:checkWallCollision(self,newX, newY) then
		self:moveAt(newX,newY)
	end

end
