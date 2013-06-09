--- Main *superclass* for all the objects who wants to have a minimal effect or interaction with other objects inside the level map.  
--##### Example of Main Entities: 
--
-- - Player
-- - Mobs
-- - Bullets
-- - Collectable items...
-- @module Entity

require("lib.middleclass")
anim8 = require("lib.anim8")
vector = require("lib.vector")

--- Entity Class. 
-- @type Entity
Entity = class("Entity")


--- Initialize the object `Entity`.
--
-- *Never create an instance of this class!.* It's recomendable work with subclasses.
-- @param x world x coordinate
-- @param y world y coordinate
-- @param speed value px/second
-- @param state init name state of state machine
-- @param sprites `Image` object that contains SPRITES used in animations.
-- @param animations dictionary of animations created with anim8 by kikito, the key is the stateName+facingPosition
-- @tparam {x,y} anchor table that define the sprite anchor point.
-- @tparam {x1,y1,x2,y2} quadCollider table with two pair of coordinates. 
-- @param level `Level` where the object belongs
function Entity:initialize(x,y,speed,state,sprites,animations,anchor,quadCollider,level)
	-- inicialization
	self.x, self.y = x, y 				-- position
	self.state = "stop"					-- actual state of state machine
	self.speed = speed 					-- speed
	self.stuned = false					-- stuned by damage
	self.alive = true					-- alive flag
	self.enableCheckCollideEntities = true
	self.collisions = {}				-- table of entities in collision
	self.facing = nil					-- face direction
	self.action = {}					-- action dictionary order by state plus face direction

	self.sprites = sprites				-- tileset that contains the sprites
	self.animations = animations		-- animations dictionary by state plus face direction
	self.anchor = anchor 				-- offset applied to the sprite
	self.level = level 					-- level 

	if quadCollider~=nil then
		self.quadCollider = {
			x1=quadCollider.x1-anchor.x, y1=quadCollider.y1-anchor.y,
			x2=quadCollider.x2-anchor.x, y2=quadCollider.y2-anchor.y
		} -- quadCollider referenced to the top left corner of Sprite instead to de anchor
	else 
		quadCollider = nil
	end
	 
	-- add to level entities table
	level.entities[self] = true

	-- add to level bucket
	self.tile = level:coordsToTile(self.x,self.y)
	level:putIntoBucket(self,self.tile)
	self.oldTile = shallowcopy(self.tile)
end


--- Class destructor
function Entity:delete()
	self.level.entities[self] = nil
	self.level:removeFromBucket(self,self.tile)
end

function Entity:checkCollision()
	--
end


--- Update stage.
-- @param dt delta time
function Entity:update(dt)
	-- key control
	self.action[self.state](dt)

	self:checkCollision()

	-- playerAnimation update
	self.animations[self.state..self.facing]:update(dt)
end


--- Draw stage.
function Entity:draw()
	if self.stuned then
		love.graphics.setColor(175,0,0,200)
	end
	self.animations[self.state..self.facing]:draw(self.sprites, self.x-self.anchor.x, self.y-self.anchor.y)

	love.graphics.setColor(255,255,255,255)
end


--- Update tile attribute.
-- Update tile to the current isometric grid position.
function Entity:updateTile()
	tile = self.level:coordsToTile(self.x, self.y)

	if not self.level:tileIsObstacle(tile) then
		self.tile = shallowcopy(tile)
	end
end


--- Move `Entity` x and y amount of pixel.
-- @param x px to move in X coordinate
-- @param y px to move in Y coordinate
function Entity:move(x,y)
	local posx = self.x + x
	local posy = self.y + y

	self:moveAt(posx, posy)
end


--- Set `Entity` in location referenciated in world location coordinates..
-- @param x world location x coordinate
-- @param y world location y
function Entity:moveAt(x,y)
	-- check if the operation can be performed
	if not self.level:checkCollideEntities(self,x,y) then

		self.x = x
		self.y = y

		self:updateTile()

		if self.level:updateBucket(self) then
			self.flagUpdateBucket = true
		else
			self.flagUpdateBucket = false
		end
	end

end

--- Change state to a new state.
-- @param newState new state.
function Entity:_changeState(newState)
	self.state = newState
end