--- Main superclass for design enemies, subclass of `Entity`.
-- 
-- In this case, all the mobs die with the same explosion.
--
--  ![Texto alternativo](../../res/art/effects/fx_enemydie_64.png "Explosion")  
-- @module Mob
require("entity.entity")


--- Mob Class, subclass of `Entity`
-- @type Mob
Mob = class('Mob', Entity)

-- Static variables.
-- This set of variables are defined static for avoid unnecessary memory loads.
-- @section variables

-- Image where are located the tileset of the sprites for the animation of enemy die. (The same die animation for all the mobs)
Mob.static.DIE_SPRITES = love.graphics.newImage('res/art/effects/fx_enemydie_64.png')
Mob.DIE_SPRITES:setFilter("nearest","nearest")

-- Define the grid that divides the tileset of die.
Mob.static.DIE_GRID = anim8.newGrid(64, 64, Mob.DIE_SPRITES:getWidth(), Mob.DIE_SPRITES:getHeight())

-- Sprite anchor point for die sprites.
-- @field x x offset
-- @field y y offset
Mob.static.DIE_ANCHOR = {x=32,y=50}

local floor = math.floor

--- Initialize the object `Mob`.
--
-- Never create an instance of this class. It's recomendable work with subclasses.
-- @param x world x coordinate
-- @param y world y coordinate
-- @param speed value px/second
-- @param life amount of life
-- @param state init name state of state machine
-- @param sprites `Image` object that contains SPRITES used in animations.
-- @param animations dictionary of animations created with anim8 by kikito, the key is the stateName+facingPosition
-- @tparam {x,y} anchor table that define the sprite anchor point.
-- @tparam {x1,y1,x2,y2} quadCollider table with two pair of coordinates. 
-- @param level `Level` where the object belongs
function Mob:initialize(x,y,speed,life,state,sprites,animations,anchor,quadCollider,level)
	Entity.initialize(self,x,y,speed,state,sprites,animations,anchor,quadCollider,level)

	self.dieAnimation = anim8.newAnimation('once', Mob.DIE_GRID('1-11,1','1-6,2'), 0.1)

	self.life = life						-- Amount of live
	self.dest = {x=nil,y=nil,fScore=nil}
end



--- Update stage.
-- 
-- @param dt delta time
function Mob:update(dt)

	if self.dest.fScore == nil or self:isInDest() then
		self:updateDest()
	end

	-- Mob is dead
	if self.alive == false then
		self.animations[self.state..self.facing]:update(dt)
		if self.dieAnimation.status == "finished" then
			self:delete()
		end

	-- Mob is alive
	else	
		-- key control
		self.action[self.state](dt)

		self:checkCollision()
		
		self.animations[self.state..self.facing]:update(dt)
	end
end


--- Checks collisions with the bullets running on the level and manage the damage that inflicts on the mob.
function Mob:checkCollision()

	for i,ent in ipairs(self.collisions) do

		if (ent.class.name=="Bullet") then
			if not self.stuned then
				self.life = self.life - ent.damage
				Timer.do_for(0.5, 
					function()
	    				if self.alive and not self.stuned then self.stuned = true end
					end,
					function()
						self.stuned = false
					end
					)
				end

				if self.life <= 0 then
					self:kill()
				end
			ent:delete()
		end
	end

	-- delete table
	self.collisions = {}

end


--- Kill state. 
-- The mob is dead and it's doing things like "ARGHHH, I'M DYING!!" before being destroyed. 
function Mob:kill()
	self.alive = false
	self.stuned = false
	self.quadCollider = nil
	self:_changeState("stop")
	self.animations[self.state..self.facing] = self.dieAnimation
	self.sprites = Mob.DIE_SPRITES
	self.anchor = Mob.DIE_ANCHOR
	self.level:shake()
end


--- Updates the attribute self.dest to next closed point
function Mob:updateDest()

   		local startPos = (self.tile.y * self.level.map.width) + self.tile.x

		local pathMap = self.level.pathMap
   		local fScore = pathMap[startPos].fScore
   		local neighbors = pathMap[startPos].neighbors
   		local distances = pathMap[startPos].distance

   		local neighborsCpy = shallowcopy(neighbors)

   		for _,v in pairs(neighborsCpy) do
   			pathMap[v].fScore = pathMap[v].fScore + self.level:numOfMobsInTile({x=pathMap[v].col,y=pathMap[v].row})
   		end

		local function neighborsSort(a,b) return pathMap[a].fScore < pathMap[b].fScore end
   		table.sort(neighborsCpy, neighborsSort) 

		for _,v in pairs(neighborsCpy) do
			if pathMap[v].fScore < fScore then
				self.dest.x, self.dest.y = level:tileToCoords(pathMap[v].col, 
															  pathMap[v].row)
				self.dest.fScore = pathMap[v].fScore
				break
			end
		end
end


--- Checks if the `Mob` is in dest
-- @return true if is in dest, false otherwise
function Mob:isInDest()
	if (self.x == self.dest.x) and (self.y == self.dest.y) then
		return true
	else
		return false
	end
end


--- Moves the mob to dest coords
-- @param dt delta time
function Mob:moveToDest(dt)
	local vectToDest = {} -- vector player-destiny

	vectToDest.x = self.dest.x - self.x
	vectToDest.y = self.dest.y - self.y 
	vectToDest = vector.new(vectToDest.x,vectToDest.y)
	newPosition = vectToDest:normalized()*self.speed*dt

	if (newPosition:len()<vectToDest:len()) then
		local newX, newY = self.x + newPosition.x, self.y + newPosition.y
		self:moveAt(newX,newY)
	else
		self:moveAt(self.dest.x,self.dest.y)
	end

	self.level:updateBucket(self)

	return false
end