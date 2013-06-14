--- Loads .tmx tilemap and runs the level designed on it.
-- Inits player, mobs and offers utilities for help spatial hashing, collision system and pathfinding.
--
--
--### Tilemap description:
-- You can design a map using a lot of layers, both *tile layer* and *object layer*. But there are two required: 
-- 
--* *Tile layer "0"*: where the entities are drawn and used for check wall collisions.  
--	-- Tiles with property `obstacle = true` works as invisible wall.
--
--* *Object layer "Events"*: used for instance objects.  
--	-- The object is instanciated where the object is placed.  
--	-- Must be defined with the `type = spawn` and had a property defined as `type` with the value that describes
--	the object. See `Level:_mobSpawn()`.  
--	-- The object spawn with property `type = player` instance the player avatar where is placed.
-- @module Level

require("lib.middleclass")
require("lib.AStar.astar")
require("entity.player")
require("entity.mob.mummy")
require("entity.mob.bat")
camera = require("lib.camera")

--- Level Class. 
-- @type Level
Level = {}
Level.__index = Level

-- Some global stuff that the examples use.
global = {}
global.limitDrawing = false		-- If true then the drawing range example is shown
global.benchmark = false		-- If true the map is drawn 20 times instead of 1
global.useBatch = false			-- If true then the layers are rendered with sprite batches
global.drawObjects = false		-- If this is true then ObjectLayers will be drawn
global.scale = 1				-- Scale of the screen
global.cameraZoom = 2 			-- zoom
global.drawPath = false
global.flattenStart, global.flattenEnd = 0, 0

local floor, abs = math.floor, math.abs


--- Create a `Level`.
-- Loads the .tmx tilemap.
--
-- Supose the files placed into "res/levels/" folder.
-- @param tmxPath the file name of .tmx
function Level.create(tmxPath) 
	lvl = {}
	setmetatable(lvl,Level)

	local loader = require("lib.AdvTiledLoader.Loader")
	local grid = require("lib.AdvTiledLoader.Grid")

	loader.path = "res/levels/" 				--Change this to wherever your .tmx files are
	lvl.map = loader.load(tmxPath) 				--Change this to the name of your mapfile
	lvl.map.drawObjects = global.drawObjects 	-- Hide ObjectLayers
	lvl.map.useSpriteBatch = global.useBatch
	lvl.buckets = grid:new()  					-- The buckets to put entities into
 	lvl.cellSize = 5         					-- The number of tiles that a bucket represents
	lvl.player = nil 							-- player entity shortcut
	lvl.entities = {}
	lvl.path = {}

	-- load Player
	lvl:_mobSpawn()

	-- initial flat map
	local exitPos = (lvl.player.tile.y * lvl.map.width) + lvl.player.tile.x
	lvl.pathMap = lvl:floodFill(lvl:flattenMap(), exitPos)

	-- create a camera
	lvl.cam = camera(0, 0, global.cameraZoom, 0)

	return lvl
end

--- Update stage.
--
-- - Calls the method `update(dt)` of all `Entity` objects.
-- - Updates the camera position, following the player.
-- @param dt delta time
function Level:update(dt)
	global.numOfEntities = 0 -- benchmark data
	-- update entities
	for entity,_ in pairs(self.entities) do 
		entity:update(dt)
		global.numOfEntities = global.numOfEntities + 1
	end

	-- Only flat the map when the player change her position
	if self.player.flagUpdateBucket==true then
		local exitPos = (self.player.tile.y * self.map.width) + self.player.tile.x
		self.pathMap = self:floodFill(self:flattenMap(), exitPos)
	end

	-- update camera
	self.cam:lookAt(self.player.x, self.player.y)
end

--- **Debug function**.
--
-- Draw for a given entity his bound box.
-- @param entity the `Entity` object
function Level:drawQuadCollider(entity)
	local colorSaved = {}
	local quadCollider = entity.quadCollider
	colorSaved.r, colorSaved.g, colorSaved.b = love.graphics.getColor()

	if quadCollider~=nil then
		love.graphics.setColor(255,0,0)
		love.graphics.quad("line", entity.x+entity.quadCollider.x1, entity.y+entity.quadCollider.y1, 
								   entity.x+entity.quadCollider.x2, entity.y+entity.quadCollider.y1,
								   entity.x+entity.quadCollider.x2, entity.y+entity.quadCollider.y2,
								   entity.x+entity.quadCollider.x1, entity.y+entity.quadCollider.y2)
	end

	love.graphics.setColor(colorSaved.r,colorSaved.g,colorSaved.b)
end


--- **Debug function**.
--
-- Draw for a given entity the path that is walking. 
-- @param entity the `Entity` object
function Level:drawPath(entity)
	local colorSaved = {}
	local dest = entity.dest
	colorSaved.r, colorSaved.g, colorSaved.b = love.graphics.getColor()

	love.graphics.setLineWidth(1)

	local x1, y1 = dest.x, dest.y
	local x2, y2 = entity.x,  entity.y
	love.graphics.setColor(255,255,0)
	love.graphics.line(x1,y1,x2,y2)
	love.graphics.setColor(255,0,0)
	love.graphics.circle("fill",x1,y1,2)
	love.graphics.circle("fill",x2,y2,2)

	love.graphics.setColor(colorSaved.r,colorSaved.g,colorSaved.b)
end

--- Draw the entities of a tile. 
--
-- Draw all the entities which are on a specific tile of the .tmx map, sorted by depth.
--
-- This function will be called by `TileLayer:setAfterTileFunction()` from AdvTileLoader library
-- and was made following her documentation.
-- @param tilePositionX tile X position 
-- @param tilePositionY tile Y position
-- @param tileDrawX unused
-- @param tileDrawY unused
-- @param self unused
function Level:drawEntities(tilePositionX, tilePositionY, tileDrawX, tileDrawY, self)
	
	local function drawSort(a,b) return a.y < b.y end
	local listOfEntities = {}

	-- dictionary to table
	for entity,_ in pairs(self:getBucket({x=tilePositionX, y=tilePositionY})) do 
		if tilePositionX==entity.tile.x and tilePositionY==entity.tile.y then
			table.insert(listOfEntities,entity)
		end
	end

	-- sort the table by depth
	table.sort(listOfEntities, drawSort)

	-- draw the entities
	for _,entity in ipairs(listOfEntities) do 
		entity:draw()
	end
end


--- Draw stage.
--
-- Represent the actual level state. 
-- Draw the map, the entities and the mouse.
function Level:draw()
	self.cam:attach()

	local camX, camY = self.cam:pos()

	-- scale and translate the game screen for map drawing
	love.graphics.push()
	love.graphics.scale(global.scale)
	
	-- limit the draw range ARREGLAR!!
	self.map:autoDrawRange((love.graphics.getWidth()/2)-camX, (love.graphics.getHeight()/2)-camY, global.scale, padding)

	self.map.layers["0"]:setAfterTileFunction(self.drawEntities, self)

  	-- draw map
  	self.map:draw()

  	-- draw Path
  	if global.debugMode then
  		for entity,_ in pairs(self.entities) do 
			if instanceOf(Mob,entity) and entity.dest.fScore ~= nil then
				self:drawPath(entity)
			end
			self:drawQuadCollider(entity)
		end
  	end
  	
	love.graphics.pop()

	self.cam:detach()

	-- draw mouse
	if self.player ~= nil then
		love.graphics.push()
		love.graphics.scale(self.cam.scale)
    	self.player:drawMouse()
    	love.graphics.pop()
    end

end


--- Shake cam effect. 
--
-- Effect that fake an earthquake
function Level:shake()

	Timer.do_for(1, 
		function()
    		self.cam:lookAt(self.player.x + math.random(-2,2), self.player.y + math.random(-2,2))
		end,
		function()
		end
	)
end


--- Spawn player and mobs on the map. 
--
-- From the layer "Events" on the map, load the objects defined like "spawn" 
-- and depending on his property "type" make an instance.
function Level:_mobSpawn()
	local entityConstructor = {
			["player"] = function(x,y) self.player = Player:new(x, y+16, self) end,
			["mummy"] = function(x,y)  Mummy:new(x, y+16, self) end,
			["bat"] = function(x,y)  Bat:new(x, y+16, self) end
	}
	for i, obj in pairs( self.map("Events").objects ) do
		local mob = {}
        if obj.type == "spawn" then
        	mob.worldX, mob.worldY = obj.x, obj.y
        	mob.x, mob.y = self.map:fromIso(mob.worldX,mob.worldY)
        	entityConstructor[obj.properties["type"]](mob.x,mob.y)
        end

    end
end


--- Turns an isometric grid tile number to world location. 
-- @param tileX tile x position 
-- @param tileY tile y position
-- @return x x world coordination
-- @return y y world coordination
function Level:tileToCoords(tileX,tileY)
	local worldX, worldY = tileX*self.map.tileHeight, tileY*self.map.tileHeight
	local x, y = self.map:fromIso(worldX, worldY)
	return x, y+16
end


--- Turns a world location into an isometric grid tile number. 
-- @param x x world coordination
-- @param y y world coordination
-- @treturn {x,y} a table with an isometric grid tile position
function Level:coordsToTile(x,y)
	local tile, _ = {}, {}
		_.worldX, _.worldY = self.map:toIso(x,y)
		tile.x = floor(_.worldX/self.map.tileHeight)
		tile.y = floor(_.worldY/self.map.tileHeight)
	return tile
end


-- Unificar con checkWallCOllision
function Level:tileIsObstacle(tile)

	-- Grab the tile
	local tileToCheck = self.map.layers["0"](tile.x, tile.y)
	
	if tileToCheck~=nil and not tileToCheck.properties.obstacle then 
		return false
	else
		return true
	end
end

function Level:checkWallCollision(entity,destX,destY)
	local map = self.map

	tile = self:coordsToTile(destX, destY)

	return self:tileIsObstacle(tile)
end

--- Buckets functions.
-- Useful utilities for spatial hashing.
-- @section hashing

--- Gets the bucket that make reference to the location specified.
-- @tparam {x,y} tile a table with an isometric grid tile position
-- @return Gets bucket. Returns nil if the bucket does not exist.
function Level:getBucket(tile)
	local cellX, cellY
	cellX, cellY = floor(tile.x / self.cellSize), floor(tile.y / self.cellSize)
	if not self.buckets(cellX, cellY) then self.buckets:set(cellX, cellY, {}) end
	return self.buckets(cellX, cellY)
end

--- Puts an entity into a bucket. 
--
-- If the entity has moved then provide his old tile location for remove it from there.
-- @param entity the `Entity` that wants to insert in the bucket.
-- @tparam {x,y} tile a table with an isometric grid tile position  
-- @tparam {x,y} oldTile (optional) a table with an isometric grid tile position 
function Level:putIntoBucket(entity, tile, oldTile)
	local oldTile = oldTile or nil
	if oldTile ~= nil then
		self:getBucket(oldTile)[ entity ] = nil
	end
	self:getBucket(tile)[ entity ] = true
end


--- Remove an entity from his bucket.
-- @param entity the `Entity` to be removed
-- @tparam {x,y} tile a table with an isometric grid tile position  
function Level:removeFromBucket(entity, tile)
	self:getBucket(tile)[ entity ] = nil
end

--- Clears all the buckets.
-- @param buckets ¿?¿??¿ <- this param no make sense.
function Level:clearBuckets(buckets)
	self.buckets:clear()
end


--- Update the position in the bucket if it's necessary.
--
-- If the `Entity` is on the same tile that the last time, this function no makes nothing.
-- @param entity the `Entity` to be updated.
function Level:updateBucket(entity)
	if 	entity.tile.x~=entity.oldTile.x or entity.tile.y~=entity.oldTile.y then
		self:putIntoBucket(entity,entity.tile,entity.oldTile)
		entity.oldTile = shallowcopy(entity.tile)
		return true
	end

	return false	
end


--- Collision functions.
-- Useful utilities for cheks collitions between `Entity` objects.
-- @section collision


--- Gets a list of buckets that are contained by a quad collider.
-- @tparam {x1,y1,x2,y2} quadCollider table with two pair of coordinates in world location. 
function Level:bucketsInsideCollider(quadCollider)
	-- quadCollider {x1,y2,x2,y2}
	local topLeftTile, topRightTile, bottomLeftTile, bottomRightTile
	topLeftTile = self:coordsToTile(quadCollider.x1,quadCollider.y1)
	topRightTile = self:coordsToTile(quadCollider.x2,quadCollider.y1)
	bottomLeftTile = self:coordsToTile(quadCollider.x1,quadCollider.y2)
	bottomRightTile = self:coordsToTile(quadCollider.x2,quadCollider.y2)

	local listOfBuckets = {}
	for j = topRightTile.y-1, bottomLeftTile.y+1 do
		for i = topLeftTile.x-1, bottomRightTile.x+1 do
			tile = {x=i, y=j}
			listOfBuckets[self:getBucket(tile)] = true
		end
	end

	return listOfBuckets
end

--- Checks if an `Entity` is colliding with another one.   
-- Saves on `entity.collision` a table with `Entity` objects with which collided.
-- 
-- If x and y params are passed, this function works like the `Entity` was there, as forecast. 
-- @param entity the `Entity` to be checked
-- @param x (optional) world location x coordinate. 
-- @param y (optional) world location y coordinate.
-- @return Returns True if the `Entity` is colliding with another `Entity`.
function Level:checkCollideEntities(entity,x,y)
	
	local isColliding = false

	if entity.enableCheckCollideEntities and entity.alive then
		x = x or entity.x
		y = y or entity.y

		local quadCollider = {
			x1=x+entity.quadCollider.x1, y1=y+entity.quadCollider.y1,
			x2=x+entity.quadCollider.x2, y2=y+entity.quadCollider.y2
		}

		local listOfBuckets = self:bucketsInsideCollider(quadCollider)

		for bucket,_ in pairs(listOfBuckets) do 
			for ent,__ in pairs(bucket) do 
				-- check collision
				if ent~=entity and ent.quadCollider~=nil then
					local entCollision = true

					if (quadCollider.x2 < ent.quadCollider.x1+ent.x) then
						entCollision = false
					end
					if (quadCollider.x1 > ent.quadCollider.x2+ent.x) then
						entCollision = false
					end
					if (quadCollider.y2 < ent.quadCollider.y1+ent.y) then
						entCollision = false
					end 
					if (quadCollider.y1 > ent.quadCollider.y2+ent.y) then
						entCollision = false
					end

					if entCollision == true then
						table.insert(entity.collisions,ent)
						isColliding = true
					end
					
				end
			end
		end
	end
	
	return isColliding

end


--- Returns the number of mobs in a tile
-- @param tile
-- @return number of entities
function Level:numOfMobsInTile(tile)
	local numOfMobs = 0
	local bucket = self:getBucket(tile)

	for ent,_ in pairs(bucket) do
		if ent.class.super.name == "Mob" and ent.tile.x == tile.x and ent.tile.y == tile.y then
			numOfMobs = numOfMobs+25 -- 70 is the weight that supose 1 entity in the same tile
		end
	end

	return numOfMobs
end


--- A* functions.
-- Useful utilities for pathfinding, needed for AStar library.
-- @section collision

--- For an row and column given, returns a list of walkable neighbors and distances to them.
-- @param row isometric grid tile y position
-- @param col isometric grid tile x position
-- @return table with positions of neighbors in flatten array.
-- @return table with distances to reach the neighbor at the same position in neighbors table returned.
function Level:findNeighbors(row, col)
	local skipList = {}
	local rmin = -1
	local rmax = 1
	local cmin = -1
	local cmax = 1
	-- This trims the search area if the current temp node is located
	-- on the boundary of a square map (will only work if correctly if
	-- all of the rows and columns are of the same length)
	if row == 0 then
		rmin = 0
	elseif row == self.map.height-1 then
		rmax = 0
	end
	if col == 0 then
		cmin = 0
	elseif col == self.map.width-1 then
		cmax = 0
	end
	local neighbors = {}
	local distance = {}
	for i = rmin, rmax do
		for j = cmin, cmax do

			local actualTile = vector.new(self:tileToCoords(col,row))

			-- As long as a neighbor isn't a wall (or itself)
			local tile = self.map.layers["0"](col+j, row+i)
			if 	not tile.properties.obstacle and not (i == 0 and j == 0) then		
				local neighborTile = vector.new(self:tileToCoords(col+j,row+i))
				local distanceToTile = neighborTile - actualTile
				table.insert(distance, distanceToTile:len())
				table.insert(neighbors, ((row + i) * self.map.width) + (col + j))
			end
		end
	end
	return neighbors, distance
end


--- Flat the bidimensional array of the map. 
-- @return table with nodes created with newNode (AStar lib).  
function Level:flattenMap()
	global.flattenStart = love.timer.getTime()
	local mapFlat = {}
	local exitPos = self.player
	for row = 0, self.map.height-1 do
		for col = 0, self.map.width-1 do
			local tile = self.map.layers["0"](col, row)
			if not tile.properties.obstacle then
				local pathLoc = (row * self.map.width) + col
	
				-- My hScore is built using taxicab geometry. Sum the
				-- vertical and horizontal distances, and multiply that
				-- by 10.
				local hScore = (abs(col - exitPos.tile.x) + abs(row - exitPos.tile.y)) * 10

				local neighbors, distance = self:findNeighbors(row, col)
				--local neighbors, distance = {0},{0}
				local tempNode = newNode(pathLoc, hScore, neighbors, distance)
				tempNode.row = row
				tempNode.col = col
				mapFlat[pathLoc] = tempNode
			end
		end
	end
	global.flattenEnd = love.timer.getTime()

	return mapFlat
end

--- Uses flood fill algorithm to create a navigation graph.
-- startPos will be the "seed" of the algorithm. 
-- @param pathMap the flattened path map
-- @param startPos the start node's position, relative to the pathMap
-- @return pathMap a navigation graph
function Level:floodFill(pathMap, startPos)
	pathMap[startPos].parent = pathMap[startPos]
	-- Initialize the gScore and fScore of the start node
	pathMap[startPos].gScore = 0
	pathMap[startPos].fScore =
		pathMap[startPos].gScore + pathMap[startPos].hScore
	-- Toggle the open trigger on pathMap for the start node
	pathMap[startPos].open = true
	-- Initialize the openSet and add the start node to it
	local openSet = binary_heap:new()
	openSet:insert(pathMap[startPos].fScore, pathMap[startPos])
	-- Initialize the closedSet and the testNode
	local closedSet = {}
	local testNode = {}
	
	-- The main loop for the algorithm. Will continue to check as long as
	-- there are open nodes that haven't been checked.
	while #openSet > 0 do
		-- Find the next node with the best fScore
		_, testNode = openSet:pop()
		pathMap[testNode.pathLoc].open = false
		-- Add that node to the closed set
		pathMap[testNode.pathLoc].closed = true
		table.insert(closedSet, testNode)
		
		-- Check all the (pre-assigned) neighbors. If they are not closed 
		-- already, then check to see if they are either not on the open
		-- or if they are on the open list, but their currently assigned
		-- distance score (either given to them when they were first added
		-- or reassigned earlier) is greater than the distance score that
		-- goes through the current test node. If either is true, then
		-- calculate their fScore and assign the current test node as their
		-- parent
		for k,v in pairs(testNode.neighbors) do
			if not pathMap[v].closed then
				local tempGScore = testNode.gScore + testNode.distance[k]
				if not pathMap[v].open then
					pathMap[v].open = true
					pathMap[v].parent = testNode
					pathMap[v].pCloseLoc = #closedSet
					pathMap[v].gScore = tempGScore
					pathMap[v].fScore = 
						pathMap[v].hScore + tempGScore
					openSet:insert(pathMap[v].fScore, pathMap[v])
				elseif tempGScore < pathMap[v].gScore then
					pathMap[v].parent = testNode
					pathMap[v].gScore = tempGScore
					pathMap[v].fScore = 
						pathMap[v].hScore + tempGScore
				end
			end
		end
	end
	-- Returns an empty table if it failed to find any path to the exit node
	return pathMap
end