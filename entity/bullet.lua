--- Object fired by `Weapon` objects, subclass of `Entity`. 
--
--  ![Texto alternativo](../../res/art/effects/bullet.png "Bullet Sprites")  
--
--	SPEED  = 250
--	DAMAGE = 25
--	STATE  = 'bullet'
-- @module entity.bullet

require("entity.entity")

--- Bullet Class, subclass of `Entity`
-- @type Bullet
Bullet = class("Bullet", Entity)

-- Image where are located the tileset of the bullets.
Bullet.static.SPRITES = love.graphics.newImage('res/art/effects/bullet.png')
Bullet.SPRITES:setFilter("nearest","nearest")

-- Define the grid that divides the tileset.
Bullet.static.GRID = anim8.newGrid(16, 16, Bullet.SPRITES:getWidth(), Bullet.SPRITES:getHeight())

-- Set of animations for the bullets depending on the state and where is .
Bullet.static.ANIMATIONS = {
	bullet0 = anim8.newAnimation(Bullet.GRID(5,1), 0.1), -- 0º
	bullet1 = anim8.newAnimation(Bullet.GRID(6,1), 0.1), -- 45º 
	bullet2 = anim8.newAnimation(Bullet.GRID(7,1), 0.1), -- 90º
	bullet3 = anim8.newAnimation(Bullet.GRID(8,1), 0.1), -- 135º  
	bullet4 = anim8.newAnimation(Bullet.GRID(1,1), 0.1), -- 180º
	bullet5 = anim8.newAnimation(Bullet.GRID(2,1), 0.1), -- -135º
	bullet6 = anim8.newAnimation(Bullet.GRID(3,1), 0.1), -- -90º
	bullet7 = anim8.newAnimation(Bullet.GRID(4,1), 0.1)  -- -45º
}

-- Speed value (px/sec).
Bullet.static.SPEED = 250

-- Sprite anchor point.
-- In function of the sprite origin.
-- @field x x offset
-- @field y y offset
Bullet.static.ANCHOR = {x=8,y=16}

-- Bound box.
-- In function of the sprite origin.
-- @field x1 top left x 
-- @field y1 top left y
-- @field x2 bottom right x
-- @field y2 bottom right y
Bullet.static.QUADCOLLIDER = {x1=4,y1=4,x2=12,y2=12}

--- Initialize the object `Bullet`.
--
-- Don't call this method directly!, this method is called automatically when 
-- the class is instanciated using the method new.
-- @usage 
-- Bullet:new(weapon,aimVector)
-- @field weapon laksjdñlaksjd
-- @param weapon `Weapon` object who fire this bullet
-- @param aimVector direction vector
function Bullet:initialize(weapon, aimVector)
	local level = weapon.owner.level
	Entity.initialize(self,x,y,Bullet.SPEED,"bullet",Bullet.SPRITES,Bullet.ANIMATIONS,Bullet.ANCHOR,Bullet.QUADCOLLIDER,level)

	self.weapon = weapon
	self.enableCheckCollideEntities = false
	self.x, self.y = weapon.owner.x + aimVector.x*20 , weapon.owner.y - aimVector.y*20
	self.vector = aimVector:rotated(math.rad((math.random()-math.random()))*self.weapon.accuracy)
	self.alive = true
	self.damage = 25

	-- calculate facing direction
	local angle = math.atan2(self.vector:unpack())
	if angle<0 then
		angle = angle + 2*math.pi
	end
	angle = math.deg(angle)
	self.facing = math.floor((angle+22.5)/45)%8

end


--- Update stage.
-- @param dt delta time
function Bullet:update(dt)
	self:move(self.vector.x*self.speed*dt, -(self.vector.y*self.speed*dt))

	self.level:updateBucket(self)

	if self.level:checkWallCollision(self, self.x, self.y) then
		self:delete()
	end
end


--- Draw stage.
function Bullet:draw()
	if self.alive == true then
		Bullet.ANIMATIONS["bullet"..self.facing]:draw(Bullet.SPRITES, self.x-8, self.y-16)
	end
end