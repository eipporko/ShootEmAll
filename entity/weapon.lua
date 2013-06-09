--- 'Bullet' entities generator.
--
--	SHOT DELAY = 8
--	ACCURACY   = 8
-- @module Weapon

require("entity.bullet")

--- Weapon class
-- @type Weapon
Weapon = {}
Weapon.__index = Weapon


--- Create a `Weapon`.
-- @param owner `Entity` who own this weapon
function Weapon.create(owner)
	wpn = {}
	wpn.owner = owner			-- owner's weapon
	wpn.readyToShoot = true		-- flag
	wpn.shootDelay = 8			-- number of shoots per second
	wpn.currentShootDelay = 1
	wpn.accuracy = 8			-- FIX! Apply accuracy when fire

	setmetatable(wpn,Weapon)
	return wpn
end

function Weapon:update(dt)
	-- body
end

function Weapon:draw()
	-- body
end


--- Shoot with primary Fire.
-- This method generate `Bullet` objects.
-- @param dt delta time
-- @param aimVector vector where the owner is firing.
function Weapon:primaryFire(dt, aimVector)
	local lvl = self.owner.level
	if self.readyToShoot then
		self.currentShootDelay = self.currentShootDelay + self.shootDelay*dt
		if self.currentShootDelay>=1 then
			for i = 1, self.currentShootDelay, 1 do
				Bullet:new(self, aimVector)
			end
			self.currentShootDelay = self.currentShootDelay - math.floor(self.currentShootDelay)
		end
	end
end


--- Release currentShootDelay.
-- This attribute is reseted to fabric values.
-- @param dt delta time.
function Weapon:releaseFire(dt)
	self.currentShootDelay = 1
end