--[[

	Written by MrDoubleA
	Please give credit!

    Banzai bill blaster sprites by Sednaiur
	Background banzai bill sprites by Squishy Rex

    Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local bulletBills = {}


bulletBills.globalTimer = 0


-- Blasters
do
    bulletBills.blasterSettings = {
        gfxwidth = 32,
        gfxheight = 32,
    
        gfxoffsetx = 0,
        gfxoffsety = 0,
        
        width = 32,
        height = 32,
        
        frames = 3,
        framestyle = 1,
        framespeed = 8,
        
        speed = 1,
        
        npcblock = true,
        npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
        playerblock = true,
        playerblocktop = true, --Also handles other NPCs walking atop this NPC.
    
        nohurt = true,
        nogravity = false,
        noblockcollision = false,
        nofireball = true,
        noiceball = true,
        noyoshi = true,
        nowaterphysics = false,
        
        jumphurt = false,
        spinjumpsafe = false,
        harmlessgrab = false,
        harmlessthrown = false,
    
        notcointransformable = true,
        staticdirection = true,
        luahandlesspeed = true,


        defaultProjectileID = 0,
        smokeEffectID = 10,

        projectileSpeedX = 4,
        projectileSpeedY = 0,

        coinID = 10,

        blastEffectDuration = 8,
        blastEffectScale = 1.25,

        playersCanStopFire = true,
        npcsCanStopFire = true,
        blocksCanStopFire = true,

        activeNPCLimit = 15, -- if the number of alive NPC's it's shot out is at this amount, it won't fire until one of them dies/despawns
    }

    bulletBills.blasterHarmTypes = {
        HARM_TYPE_LAVA,
    }
    bulletBills.blasterHarmEffects = {
        [HARM_TYPE_LAVA] = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
    }

    bulletBills.blasterIDList = {}
    bulletBills.blasterIDMap  = {}


    function bulletBills.registerBlaster(npcID)
        npcManager.registerEvent(npcID, bulletBills, "onTickNPC", "onTickBlaster")
        npcManager.registerEvent(npcID, bulletBills, "onDrawNPC", "onDrawBlaster")

        table.insert(bulletBills.blasterIDList,npcID)
        bulletBills.blasterIDMap[npcID] = true
    end


    local DIR_RIGHTSIDE_UP = -1
    local DIR_UPSIDE_DOWN = 1


    local function blockSolidFilter(v,npc)
        if v.isHidden or v:mem(0x5A,FIELD_BOOL) then
            return false
        end

        local config = Block.config[v.id]

        if config.passthrough or config.semisolid or config.sizeable then
            return false
        end

        if config.npcfilter < 0 or config.npcfilter == npc.id then
            return false
        end

        if npc.collisionGroup ~= "" and npc.collisionGroup == v.collisionGroup then
            return false
        end

        return true
    end

    local function npcSolidFilter(v,npc)
        if v.despawnTimer <= 0 or v.isGenerator or v.friendly then
            return false
        end

        if v:mem(0x12C,FIELD_WORD) > 0 or v:mem(0x136,FIELD_BOOL) or v:mem(0x138,FIELD_WORD) > 0 then
            return false
        end

        local config = NPC.config[v.id]

        if config.npcblock then
            return true
        end

        if npc.collisionGroup ~= "" and npc.collisionGroup == v.collisionGroup then
            return false
        end

        return false
    end
    
    local function npcBlockingFilter(v)
        if v.despawnTimer <= 0 or v.isGenerator or v.friendly then
            return false
        end

        if v:mem(0x12C,FIELD_WORD) > 0 or v:mem(0x136,FIELD_BOOL) or v:mem(0x138,FIELD_WORD) > 0 then
            return false
        end

        local config = NPC.config[v.id]

        if config.iscoin then
            return false
        end

        return true
    end



    local function getAndUpdateShotTimer(v,data,config,settings)
        if settings.useLocalTimer then
            data.localTimer = data.localTimer + 1
            return data.localTimer
        else
            return bulletBills.globalTimer
        end
    end


    local function canFire(v,data,config,settings,x,y,width,height)
        if Level.endState() > 0 then
            return false
        end

        if config.playersCanStopFire then
            -- this bit is taken from npc-21.lua
            local col = Colliders.Box(0,0,0,0)

            col.width = v.width + width*2
            col.height = height + 600
            col.x = v.x + v.width*0.5 - col.width*0.5
            
            if v.direction == DIR_RIGHTSIDE_UP then
                col.y = v.y + (config.height - col.height)*0.5
            else
                col.y = v.y + v.height - (config.height + col.height)*0.5
            end

            --col:Debug(true)


            for _,p in ipairs(Player.get()) do
                if p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL) and col:collide(p) then
                    return false
                end

                --[[if  v.x <= p.x + p.width + 32 and v.x + v.width >= p.x - 32
                and v.y <= p.y + p.height + 300 and v.y + v.height >= p.y - 300 then
                    return false
                end]]
            end
        end

        if config.blocksCanStopFire then
            for _,block in Block.iterateIntersecting(x,y,x+width,y+height) do
                if blockSolidFilter(block,v) then
                    return false
                end
            end
        end

        if config.npcsCanStopFire or config.blocksCanStopFire then
            for _,npc in NPC.iterateIntersecting(x,y,x+width,y+height) do
                if npc ~= v then
                    if config.blocksCanStopFire and npcSolidFilter(npc,v) then
                        return false
                    end

                    if config.npcsCanStopFire and npcBlockingFilter(npc) then
                        return false
                    end
                end
            end
        end

        return true
    end


    local function getFireDirection(v,data,config,settings)
        if settings.shotDirection == 0 then
            local x = v.x + v.width*0.5
            local y = v.y

            if v.direction == DIR_UPSIDE_DOWN then
                y = y + v.height
            end

            local p = Player.getNearest(x,y)

            if p.x+p.width*0.5 < x then
                return DIR_LEFT
            else
                return DIR_RIGHT
            end
        elseif settings.shotDirection == 1 then
            return DIR_LEFT
        elseif settings.shotDirection == 2 then
            return DIR_RIGHT
        end
    end


    local function tryFire(v,data,config,settings)
        -- Get ID of projectile
        local id = settings.projectileID
        local count = 1
        if id == 0 then
            id = config.defaultProjectileID
        elseif id < 0 then -- coins
            count = -id
            id = config.coinID
        end

        if id <= 0 or count <= 0 then
            return
        end

        -- Find X/Y
        local shotConfig = NPC.config[id]

        local direction = getFireDirection(v,data,config,settings)

        local width = shotConfig.width
        local height = shotConfig.height

        local x,y

        if direction == DIR_LEFT then
            x = v.x - width
        else
            x = v.x + v.width
        end

        if v.direction == DIR_RIGHTSIDE_UP then
            y = v.y + (config.height - height)*0.5
        else
            y = v.y + v.height - (config.height + height)*0.5
        end

        if bulletBills.bulletIDMap[id] then
            x = x - width*0.5*direction
        end

        if not canFire(v,data,config,settings,x,y,width,height) then
            return
        end

        -- Shoot!
        for i = 1,count do
            local npc = NPC.spawn(id,x,y,v.section,false,false)

            npc.direction = direction
            npc.spawnDirection = npc.direction

            npc.speedX = config.projectileSpeedX*direction
            npc.speedY = config.projectileSpeedY

            npc.layerName = "Spawned NPCs"
            npc.friendly = v.friendly

            if shotConfig.iscoin then
                npc.speedX = npc.speedX + RNG.random(-2,2)
                npc.speedY = npc.speedY + RNG.random(-4,1)
                npc.ai1 = 1
            elseif not bulletBills.bulletIDMap[id] then
                npc:mem(0x136,FIELD_BOOL,true)
            else
                local bulletData = npc.data

                bulletData.originBlaster = v
            end

            if config.smokeEffectID > 0 then
                local e = Effect.spawn(config.smokeEffectID,npc.x + npc.width*0.5,npc.y + npc.height*0.5)

                e.x = e.x - e.width *0.5
                e.y = e.y - e.height*0.5
            end


            if config.activeNPCLimit > 0 then
                table.insert(data.activeNPCs,npc)
            end
        end

        data.shots = data.shots + 1

        data.blastEffectTimer = config.blastEffectDuration

        SFX.play(22)
    end


    local function blockIsAbove(v,data,config,settings)
        local x1 = v.x + 4
        local x2 = v.x + v.width - 4
        local y1 = v.y - 12
        local y2 = v.y + 4

        --Colliders.Box(x1,y1,x2-x1,y2-y1):draw()

        local things = {}

        for _,block in Block.iterateIntersecting(x1,y1,x2,y2) do
            if blockSolidFilter(block,v) then
                table.insert(things,block)
            end
        end

        for _,npc in NPC.iterateIntersecting(x1,y1,x2,y2) do
            if npcSolidFilter(npc,v) then
                table.insert(things,npc)
            end
        end

        
        if things[1] == nil then -- nothing, we can end here
            return false
        end


        local leftStartPoint = vector(v.x + v.width*0.25 + 1,y2)
        local leftEndPoint = vector(leftStartPoint.x,y1)
        local rightStartPoint = vector(v.x + v.width*0.75 - 1,y2)
        local rightEndPoint = vector(rightStartPoint.x,y1)

        local leftHit,leftHitPoint,_,leftHitObj = Colliders.linecast(leftStartPoint,leftEndPoint,things)
        local rightHit,rightHitPoint,_,rightHitObj = Colliders.linecast(rightStartPoint,rightEndPoint,things)


        if not leftHit and not rightHit then
            return false
        end


        local hitY = -math.huge
        local hitObj

        if leftHit and leftHitPoint.y > hitY then
            hitObj = leftHitObj
            hitY = leftHitPoint.y
        end
        if rightHit and rightHitPoint.y > hitY then
            hitObj = rightHitObj
            hitY = rightHitPoint.y
        end

        return true,hitY,hitObj
    end

    local function updateBlockHanging(v,data,config,settings)
        if v.direction ~= DIR_UPSIDE_DOWN then
            return
        end

        local hit,hitY,hitObj = blockIsAbove(v,data,config,settings)

        if hit then
            local gravity = Defines.npc_grav
            if config.nogravity then
                gravity = 0
            elseif v.underwater and not config.nowaterphysics then
                gravity = gravity*0.2
            end

            data.hangingObj = hitObj
            v.speedX = hitObj.speedX
            v.speedY = hitObj.speedY - gravity - 2
        else
            data.hangingObj = nil
        end
    end


    local function hasReachedShotLimit(v,data,config,settings)
        if settings.maximumShots > 0 and data.shots >= settings.maximumShots then
            return false
        end

        if config.activeNPCLimit > 0 then
            local count = 0

            for i = #data.activeNPCs,1,-1 do
                local npc = data.activeNPCs[i]

                if npc.isValid and npc.despawnTimer > 0 then
                    count = count + 1
                else
                    table.remove(data.activeNPCs,i)
                end
            end

            if count >= config.activeNPCLimit then
                return false
            end
        end

        return true
    end


    local function initialisePreSpawn(v,data)
        if data.baseLength == nil then
            local settings = v.data._settings

            data.baseLength = settings.baseLength
        end

        local newSpawnHeight = v.spawnHeight + 32*data.baseLength
        local newHeight = v.height + 32*data.baseLength

        if v.spawnDirection == DIR_RIGHTSIDE_UP then
            v.spawnY = v.spawnY + v.spawnHeight - newSpawnHeight
            v.y = v.y + v.height - newHeight
        end

        v.spawnHeight = newSpawnHeight
        v.height = newHeight

        if v.section == 0 then -- might be out of bounds
            v.section = Section.getIdxFromCoords(v)
        end

        data.initialisedPreSpawnStuff = true
    end

    local function initialise(v,data,config,settings)
        if not data.initialisedPreSpawnStuff then
            initialisePreSpawn(v,data)
        end

        data.animationFrame = 0
        data.animationTimer = 0

        data.localTimer = 0

        data.activeNPCs = data.activeNPCs or {}
        data.shots = data.shots or 0

        data.blastEffectTimer = 0

        updateBlockHanging(v,data,config,settings)

        data.initialized = true
    end


    function bulletBills.onTickBlaster(v)
        if Defines.levelFreeze then return end
        
        local data = v.data

        if v.despawnTimer <= 0 then
            if not data.initialisedPreSpawnStuff then
                initialisePreSpawn(v,data)
            end

            data.initialized = false
            return
        end

        local settings = v.data._settings
        local config = NPC.config[v.id]

        if not data.initialized then
            initialise(v,data,config,settings)
        end

        local timer = getAndUpdateShotTimer(v,data,config,settings)

        if settings.delay > 0 and timer%settings.delay == math.floor(settings.delay*0.5 + 0.5) and hasReachedShotLimit(v,data,config,settings) then
            tryFire(v,data,config,settings)
        end

        if v:mem(0x12C,FIELD_WORD) == 0 and v:mem(0x138,FIELD_WORD) == 0 then
            if v.collidesBlockBottom then
                v.speedX = 0
                v:mem(0x18,FIELD_FLOAT,0)
            end

            updateBlockHanging(v,data,config,settings)
        end

        data.blastEffectTimer = math.max(0,data.blastEffectTimer - 1)

        data.animationFrame = math.floor(data.animationTimer/config.framespeed) % math.floor(config.frames/3)
        data.animationTimer = data.animationTimer + 1
    end


    local vertexCoords = {}
    local textureCoords = {}
    local drawArgs = {vertexCoords = vertexCoords,textureCoords = textureCoords,sceneCoords = true}

    local vertexCount = 0
    local previousVertexCount = 0

    local lowPriorityStates = table.map{1,3,4}


    function bulletBills.onDrawBlaster(v)
        if v.despawnTimer <= 0 then
            return
        end

        npcutils.hideNPC(v)

        local settings = v.data._settings
        local config = NPC.config[v.id]
        local data = v.data

        if not data.initialized then
            initialise(v,data,config,settings)
        end

        -- Draw!
        local segments = math.ceil(v.height/config.gfxheight)
        if segments <= 0 then
            return
        end
        
        local image = Graphics.sprites.npc[v.id].img
        if image == nil then
            return
        end

        drawArgs.texture = image

        if lowPriorityStates[v:mem(0x138,FIELD_WORD)] then
            drawArgs.priority = -75
        elseif config.foreground then
            drawArgs.priority = -15
        else
            drawArgs.priority = -55
        end


        for i = 1,segments do
            -- Per-segment drawing code
            local frame = data.animationFrame + math.min(2,i - 1)*(config.frames/3)

            local offset = (i-1)*config.gfxheight

            local sourceWidth = config.gfxwidth
            local sourceHeight = math.clamp(v.height - offset,0,config.gfxheight)

            local width,height = sourceWidth,sourceHeight

            local y

            if data.blastEffectTimer > 0 and i == 1 then
                local scale = math.lerp(1,config.blastEffectScale,data.blastEffectTimer/config.blastEffectDuration)

                width = width*scale
                height = height*scale
            end

            if v.direction == DIR_RIGHTSIDE_UP then
                y = v.y + offset + sourceHeight - height
            else
                y = v.y + v.height - offset - sourceHeight

                if config.framestyle > 0 then
                    frame = frame + config.frames
                end
            end

            if config.framestyle >= 2 and (v:mem(0x12C,FIELD_WORD) > 0 or v:mem(0x136,FIELD_BOOL)) then
                frame = frame + config.frames*2
            end

            -- Add vertex coords
            do
                local x1 = v.x + v.width*0.5 - width*0.5
                local x2 = x1 + width
                local y1 = y
                local y2 = y1 + height

                vertexCoords[vertexCount+1 ] = x1 -- top left
                vertexCoords[vertexCount+2 ] = y1
                vertexCoords[vertexCount+3 ] = x2 -- top right
                vertexCoords[vertexCount+4 ] = y1
                vertexCoords[vertexCount+5 ] = x1 -- bottom left
                vertexCoords[vertexCount+6 ] = y2
                vertexCoords[vertexCount+7 ] = x2 -- top right
                vertexCoords[vertexCount+8 ] = y1
                vertexCoords[vertexCount+9 ] = x1 -- bottom left
                vertexCoords[vertexCount+10] = y2
                vertexCoords[vertexCount+11] = x2 -- bottom right
                vertexCoords[vertexCount+12] = y2
            end

            -- Add texture coords
            do
                local sourceY = frame*config.gfxheight
                if v.direction == DIR_UPSIDE_DOWN then
                    sourceY = sourceY + (config.gfxheight - sourceHeight)
                end

                local x1 = 0
                local x2 = 1
                local y1 = sourceY/image.height
                local y2 = y1 + sourceHeight/image.height

                textureCoords[vertexCount+1 ] = x1 -- top left
                textureCoords[vertexCount+2 ] = y1
                textureCoords[vertexCount+3 ] = x2 -- top right
                textureCoords[vertexCount+4 ] = y1
                textureCoords[vertexCount+5 ] = x1 -- bottom left
                textureCoords[vertexCount+6 ] = y2
                textureCoords[vertexCount+7 ] = x2 -- top right
                textureCoords[vertexCount+8 ] = y1
                textureCoords[vertexCount+9 ] = x1 -- bottom left
                textureCoords[vertexCount+10] = y2
                textureCoords[vertexCount+11] = x2 -- bottom right
                textureCoords[vertexCount+12] = y2
            end

            vertexCount = vertexCount + 12
        end


        -- Clear out vertices from the last draw
        for i = vertexCount+1,previousVertexCount do
            vertexCoords[i] = nil
            textureCoords[i] = nil
        end

        previousVertexCount = vertexCount
        vertexCount = 0


        Graphics.glDraw(drawArgs)
    end
end


-- Bills
do
    bulletBills.bulletSettings = {
        gfxwidth = 32,
        gfxheight = 32,

        gfxoffsetx = 0,
        gfxoffsety = 4,
        
        width = 32,
        height = 24,
        
        frames = 1,
        framestyle = 1,
        framespeed = 8,
        
        speed = 4,
        
        npcblock = false,
        npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
        playerblock = false,
        playerblocktop = false, --Also handles other NPCs walking atop this NPC.

        nohurt = false,
        nogravity = true,
        noblockcollision = true,
        nofireball = true,
        noiceball = false,
        noyoshi = false,
        nowaterphysics = false,
        
        jumphurt = false,
        spinjumpsafe = false,
        harmlessgrab = false,
        harmlessthrown = false,

        luahandlesspeed = true,
        staticdirection = true,

        smokeEffectID = 10,
        smokeStartFrame = 2,
        smokeTime = 24,

        isHoming = false,
        rotationLerpFactor = 0.01,
        followTime = 384,

        destroyWhenNormal = false,
        destroyWhenRedirected = true,
        isStrong = false,
    }

    bulletBills.bulletIDList = {}
    bulletBills.bulletIDMap  = {}

    bulletBills.bulletHarmTypes = {
        HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
    }
    bulletBills.banzaiHarmTypes = {
        HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
    }
    bulletBills.bulletHarmEffects = {
        [HARM_TYPE_LAVA]     = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_SPINJUMP] = 10,
    }


    function bulletBills.registerBullet(npcID)
        npcManager.registerEvent(npcID, bulletBills, "onTickNPC", "onTickBullet")
        npcManager.registerEvent(npcID, bulletBills, "onDrawNPC", "onDrawBullet")

        table.insert(bulletBills.bulletIDList,npcID)
        bulletBills.bulletIDMap[npcID] = true
    end


    local function spawnEffects(effectID,x,y,width,height)
        local effectConfig = Effect.config[effectID][1]
    
        local effectWidth = effectConfig.width
        local effectHeight = effectConfig.height
    
        local effectCountX = math.floor(width /effectWidth  + 0.5)
        local effectCountY = math.floor(height/effectHeight + 0.5)
    
        for idxX = 1,effectCountX do
            for idxY = 1,effectCountY do
                local effectX = x - effectCountX*effectWidth *0.5 + (idxX - 1)*effectWidth
                local effectY = y - effectCountY*effectHeight*0.5 + (idxY - 1)*effectHeight
    
                Effect.spawn(effectID,effectX,effectY)
            end
        end
    end


    function bulletBills.destroyThings(v,data,config)
        if v.friendly then
            return
        end
        
        if data.redirected then
            if not config.destroyWhenRedirected then
                return
            end
        else
            if not config.destroyWhenNormal then
                return
            end
        end

        -- Blocks
        local blocks = Colliders.getColliding{a = v,btype = Colliders.BLOCK}
        local destroy = false

        for _,b in ipairs(blocks) do
            if b.id == 90 then
                b:hit()
            elseif Block.MEGA_SMASH_MAP[b.id] then
                destroy = destroy or (not config.isStrong)
                b:remove(true)
            elseif Block.MEGA_STURDY_MAP[b.id] then
                destroy = true
                b:remove(true)
            end
        end

        -- NPC's
        local npcs = Colliders.getColliding{a = v,btype = Colliders.NPC}

        for _,n in ipairs(npcs) do
            local otherConfig = NPC.config[n.id]

            if bulletBills.bulletIDMap[n.id] then
                if otherConfig.isStrong and not config.isStrong then
                    destroy = true
                else
                    destroy = destroy or (otherConfig.isStrong)
                    n:harm(HARM_TYPE_NPC)
                end
            end
        end


        if destroy then
            if config.smokeEffectID > 0 then
                spawnEffects(config.smokeEffectID,v.x + v.width*0.5,v.y + v.height*0.5,v.width,v.height)
            end

            v:kill(HARM_TYPE_VANISH)

            Defines.earthquake = 4
            SFX.play(43)
        end
    end



    local function initialise(v,data,config,settings)
        data.rotation = settings.rotation

        data.followTimer = config.followTime
        data.smokeTimer = 0

        data.redirected = false

        data.initialized = true
    end

    local function blasterIsValid(npc)
        return (npc ~= nil and npc.isValid and npc.despawnTimer > 0 and npc:mem(0x12C,FIELD_WORD) == 0 and npc:mem(0x138,FIELD_WORD) == 0)
    end


    function bulletBills.onTickBullet(v)
        if Defines.levelFreeze then return end
        
        local data = v.data

        if v.despawnTimer <= 0 then
            data.initialized = false
            return
        end

        local settings = v.data._settings
        local config = NPC.config[v.id]

        if not data.initialized then
            initialise(v,data,config,settings)
        end

        if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
        or v:mem(0x136, FIELD_BOOL)        --Thrown
        or v:mem(0x138, FIELD_WORD) > 0    --Contained within
        then return end

        -- Homing
        if config.isHoming and (data.followTimer > 0 or config.followTime == 0) then
            -- Find rotation to go towards
            local p = npcutils.getNearestPlayer(v)

            local distX = (p.x + p.width *0.5) - (v.x + v.width *0.5)
            local distY = (p.y + p.height*0.5) - (v.y + v.height*0.5)

            local targetRotation = math.deg(math.atan2(distY,distX))

            if v.direction == DIR_LEFT then
                targetRotation = targetRotation + 180
            end

            targetRotation = targetRotation % 360

            -- Interpolate to it
            data.rotation = math.anglelerp(data.rotation,targetRotation,config.rotationLerpFactor)
            data.followTimer = math.max(0,data.followTimer - 1)
        end

        -- Set speed
        local speed = vector(config.speed*v.direction,0):rotate(data.rotation)
        
        v.speedX = speed.x
        v.speedY = speed.y

        -- Spawn smoke
        data.smokeTimer = data.smokeTimer + 1

        if data.smokeTimer >= config.smokeTime and config.smokeEffectID > 0 then
            local offset = vector(v.direction*v.width*0.5,0):rotate(data.rotation)
            local speed = vector(v.speedX,v.speedY)*0.5

            local e = Effect.spawn(config.smokeEffectID,v.x + v.width*0.5 - offset.x,v.y + v.height*0.5 - offset.y)

            e.x = e.x - e.width *0.5
            e.y = e.y - e.height*0.5
            e.speedX = -speed.x*0.5
            e.speedY = -speed.y

            e.animationFrame = config.smokeStartFrame

            data.smokeTimer = 0
        end

        
        if not blasterIsValid(data.originBlaster) or not Colliders.collide(data.originBlaster,v) then
            data.originBlaster = nil
        end


        bulletBills.destroyThings(v,data,config)
    end


    local lowPriorityStates = table.map{1,3,4}

    local function getPriority(v,data,config)
        if lowPriorityStates[v:mem(0x138,FIELD_WORD)] or blasterIsValid(data.originBlaster) then
            return -75
        end

        if config.foreground then
            return -15
        end

        return -45
    end

    function bulletBills.onDrawBullet(v)
        if v.despawnTimer <= 0 then
            return
        end

        local settings = v.data._settings
        local config = NPC.config[v.id]
        local data = v.data

        if not data.initialized then
            initialise(v,data,config,settings)
        end

        if data.sprite == nil then
            data.sprite = Sprite{texture = Graphics.sprites.npc[v.id].img,frames = npcutils.getTotalFramesByFramestyle(v),pivot = Sprite.align.CENTRE}
        end

        data.sprite.x = v.x + v.width*0.5 + config.gfxoffsetx
        data.sprite.y = v.y + v.height - config.gfxheight*0.5 + config.gfxoffsety

        data.sprite.rotation = data.rotation

        data.sprite:draw{frame = v.animationFrame+1,priority = getPriority(v,data,config),sceneCoords = true}

        npcutils.hideNPC(v)
    end
end


local bulletEffectHarmTypes = table.map{HARM_TYPE_JUMP,HARM_TYPE_FROMBELOW,HARM_TYPE_NPC,HARM_TYPE_PROJECTILE_USED,HARM_TYPE_HELD,HARM_TYPE_TAIL}

function bulletBills.onPostNPCKill(v,reason)
    if not bulletBills.bulletIDMap[v.id] or not bulletEffectHarmTypes[reason] then
        return
    end

    local config = NPC.config[v.id]
    local data = v.data

    if config.deathEffectID == nil or config.deathEffectID <= 0 then
        return
    end

    local e = Effect.spawn(config.deathEffectID,v.x + v.width*0.5,v.y + v.height*0.5)

    e.direction = v.direction
    e.angle = data.rotation or 0

    if not config.isHoming and e.angle%360 == 0 then
        e.direction = -e.direction
        e.angle = e.angle + 180
    end
end

function bulletBills.onNPCHarm(eventObj,v,reason,culprit)
    if not bulletBills.bulletIDMap[v.id] then
        return
    end

    local data = v.data

    if reason == HARM_TYPE_TAIL then
        if v:mem(0x26,FIELD_WORD) > 0 then
            eventObj.cancelled = true
            return
        end

        if type(culprit) == "Player" then
            if (v.x + v.width*0.5) > (culprit.x + culprit.width*0.5) then
                v.direction = DIR_RIGHT
            else
                v.direction = DIR_LEFT
            end
        else
            v.direction = -v.direction
        end

        data.redirected = true
        data.rotation = 0

        -- Effects
        local e = Effect.spawn(73,v.x + v.width*0.5,v.y + v.height*0.5)

        e.x = e.x - e.width *0.5
        e.y = e.y - e.height*0.5

        SFX.play(9)

        eventObj.cancelled = true
    end
end


function bulletBills.onTick()
    if not Defines.levelFreeze then
        bulletBills.globalTimer = bulletBills.globalTimer + 1
    end
end


function bulletBills.onInitAPI()
    registerEvent(bulletBills,"onPostNPCKill")
    registerEvent(bulletBills,"onNPCHarm")
    registerEvent(bulletBills,"onTick")
end


return bulletBills