--[[

	Written by MrDoubleA
	Please give credit!

    Banzai bill blaster sprites by Sednaiur
	Background banzai bill sprites by Squishy Rex

    Part of MrDoubleA's NPC Pack

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local easing = require("ext/easing")
local paralx2 = require("paralx2")

local bulletBills = require("bulletBills_ai")

local backgroundBills = {}


backgroundBills.globalTimer = 0


local initialiseBullet -- reserved for later

function backgroundBills.getParallax(depth)
    -- Same calculation done by paralx2
    local parallax = depth/paralx2.focus + 1
    parallax = 1/(parallax*parallax)

    -- Parallax and scale
    return parallax,parallax
end

local function spawnNPC(v,camIdx)
    -- On camera, so activate (based on this  https://github.com/smbx/smbx-legacy-source/blob/master/modGraphics.bas#L517)
    local resetOffset = (0x126 + (camIdx - 1)*2)
    
    if v:mem(resetOffset, FIELD_BOOL) or v:mem(0x124,FIELD_BOOL) then
        if not v:mem(0x124,FIELD_BOOL) then
            v:mem(0x14C,FIELD_WORD,camIdx)
        end

        v.despawnTimer = 180
        v:mem(0x124,FIELD_BOOL,true)
    end

    v:mem(0x126,FIELD_BOOL,false)
    v:mem(0x128,FIELD_BOOL,false)
end

local function convertNPCPosToScreen(v,c,config,parallax)
    local x = v.x + v.width*0.5 + config.gfxoffsetx
    local y = v.y + v.height - config.gfxheight*0.5 + config.gfxoffsety

    x = (x - (c.x + c.width *0.5))*parallax + c.width *0.5
    y = (y - (c.y + c.height*0.5))*parallax + c.height*0.5

    return x,y
end


-- Blasters
do
    backgroundBills.blasterSettings = {
        gfxwidth = 128,
        gfxheight = 128,
    
        gfxoffsetx = 0,
        gfxoffsety = 0,
        
        width = 128,
        height = 128,
        
        frames = 1,
        framestyle = 0,
        framespeed = 8,
        
        speed = 1,
        
        npcblock = false,
        npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
        playerblock = false,
        playerblocktop = false, --Also handles other NPCs walking atop this NPC.
    
        nohurt = true,
        nogravity = true,
        noblockcollision = true,
        nofireball = true,
        noiceball = true,
        noyoshi = true,
        nowaterphysics = true,
        
        jumphurt = true,
        spinjumpsafe = false,
        harmlessgrab = true,
        harmlessthrown = true,
    
        notcointransformable = true,
        ignorethrownnpcs = true,
        staticdirection = true,
        luahandlesspeed = true,


        projectileID = 0,

        blastEffectDuration = 8,
        blastEffectScale = 1.25,

        priority = -96,
    }

    backgroundBills.blasterIDList = {}
    backgroundBills.blasterIDMap  = {}


    function backgroundBills.registerBlaster(npcID)
        npcManager.registerEvent(npcID, backgroundBills, "onTickNPC", "onTickBlaster")
        npcManager.registerEvent(npcID, backgroundBills, "onCameraDrawNPC", "onCameraDrawBlaster")

        table.insert(backgroundBills.blasterIDList,npcID)
        backgroundBills.blasterIDMap[npcID] = true
    end



    local function getAndUpdateShotTimer(v,data,config,settings)
        if settings.useLocalTimer then
            data.localTimer = data.localTimer + 1
            return data.localTimer
        else
            return backgroundBills.globalTimer
        end
    end


    local function tryFire(v,data,config,settings)
        -- Don't shoot if winning
        if Level.endState() > 0 then
            return
        end

        if config.projectileID <= 0 then
            return
        end

        -- Shoot!
        local npc = NPC.spawn(config.projectileID,v.x + v.width*0.5,v.y + v.height*0.5,v.section,false,true)

        npc.direction = v.direction
        npc.spawnDirection = npc.direction

        npc.layerName = "Spawned NPCs"
        npc.friendly = data.originalFriendly

        if backgroundBills.bulletIDMap[npc.id] then
            local bulletConfig = NPC.config[npc.id]
            local bulletData = npc.data

            initialiseBullet(npc,bulletData,bulletConfig,npc.data._settings)

            bulletData.startDepth = data.depth
            bulletData.depth = bulletData.startDepth
        end


        data.blastEffectTimer = config.blastEffectDuration

        SFX.play(22)
    end


    local function initialisePreSpawn(v,data)
        local settings = v.data._settings

        data.depth = settings.depth
        data.parallax,data.scale = backgroundBills.getParallax(data.depth)

        data.initialisedPreSpawnStuff = true
    end

    local function initialise(v,data,config,settings)
        if not data.initialisedPreSpawnStuff then
            initialisePreSpawn(v,data)
        end

        data.localTimer = 0

        data.blastEffectTimer = 0

        data.initialized = true
    end


    function backgroundBills.onTickBlaster(v)
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

        if settings.delay > 0 and timer%settings.delay == math.floor(settings.delay*0.5 + 0.5) then
            tryFire(v,data,config,settings)
        end

        v.speedX,v.speedY = npcutils.getLayerSpeed(v)

        data.blastEffectTimer = math.max(0,data.blastEffectTimer - 1)
    end



    function backgroundBills.onCameraDrawBlaster(v,camIdx)
        -- Spawning
        local c = Camera(camIdx)

        local config = NPC.config[v.id]
        local data = v.data

        local x,y = convertNPCPosToScreen(v,c,config,data.parallax)
        local width  = config.gfxwidth *data.scale*0.5
        local height = config.gfxheight*data.scale*0.5

        if (x + width) > 0 and (y + height) > 0 and c.width > (x - width) and c.height > (y - height) then
            spawnNPC(v,camIdx)
        end


        if v.despawnTimer <= 0 then
            return
        end

        local settings = v.data._settings

        if not data.initialized then
            initialise(v,data,config,settings)
        end

        if data.sprite == nil then
            data.sprite = Sprite{texture = Graphics.sprites.npc[v.id].img,frames = npcutils.getTotalFramesByFramestyle(v),pivot = Sprite.align.CENTRE}
        end

        local scale = data.scale*math.lerp(1,config.blastEffectScale,data.blastEffectTimer/config.blastEffectDuration)

        data.sprite.x = x
        data.sprite.y = y
        data.sprite.scale = vector.v2(scale)

        data.sprite:draw{frame = v.animationFrame+1,priority = config.priority}

        npcutils.hideNPC(v)
    end
end


-- Bills
do
    backgroundBills.bulletSettings = {
        gfxwidth = 128,
        gfxheight = 128,

        gfxoffsetx = 0,
        gfxoffsety = 12,
        
        width = 104,
        height = 104,
        
        frames = 1,
        framestyle = 0,
        framespeed = 8,
        
        speed = 0.75,
        
        npcblock = false,
        npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
        playerblock = false,
        playerblocktop = false, --Also handles other NPCs walking atop this NPC.

        nohurt = false,
        nogravity = true,
        noblockcollision = true,
        nofireball = true,
        noiceball = true,
        noyoshi = true,
        nowaterphysics = false,
        
        jumphurt = false,
        spinjumpsafe = false,
        harmlessgrab = false,
        harmlessthrown = false,

        luahandlesspeed = true,
        staticdirection = true,

        hitboxDepth = 20,
        disappearDepth = -20,

        fadeColor = Color.lightgrey,
        fadeDistance = 15,

        enterRotation = 360,

        destroyWhenNormal = true,
        destroyWhenRedirected = true,
        isStrong = true,
    }

    backgroundBills.bulletIDList = {}
    backgroundBills.bulletIDMap  = {}


    function backgroundBills.registerBullet(npcID)
        npcManager.registerEvent(npcID, backgroundBills, "onTickNPC", "onTickBullet")
        npcManager.registerEvent(npcID, backgroundBills, "onCameraDrawNPC", "onCameraDrawBullet")

        table.insert(backgroundBills.bulletIDList,npcID)
        backgroundBills.bulletIDMap[npcID] = true
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


    function initialiseBullet(v,data,config,settings)
        if data.originalFriendly == nil then
            data.originalFriendly = v.friendly
        end
        
        v.friendly = true

        data.startDepth = settings.depth
        data.depth = data.startDepth

        data.rotation = config.enterRotation

        data.initialized = true
    end


    function backgroundBills.onTickBullet(v)
        if Defines.levelFreeze then return end
        
        local data = v.data

        if v.despawnTimer <= 0 then
            data.initialized = false
            return
        end

        local settings = v.data._settings
        local config = NPC.config[v.id]

        if not data.initialized then
            initialiseBullet(v,data,config,settings)
        end

        if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
        or v:mem(0x136, FIELD_BOOL)        --Thrown
        or v:mem(0x138, FIELD_WORD) > 0    --Contained within
        then return end

        -- Disappear after long enough
        if data.depth < config.disappearDepth then
            if config.smokeEffectID > 0 then
                spawnEffects(config.smokeEffectID,v.x + v.width*0.5,v.y + v.height*0.5,v.width,v.height)
            end

            if v.spawnId > 0 then
                v.despawnTimer = -1
                v:mem(0x124,FIELD_BOOL,false)
            else
                v:kill(HARM_TYPE_VANISH)
            end
        end

        -- Only be tangible if in the right spot
        if math.abs(data.depth) < config.hitboxDepth*0.5 then
            v.friendly = data.originalFriendly
        else
            v.friendly = true
        end

        -- Rotation
        local offset = config.hitboxDepth*0.5
        local duration = data.startDepth - offset

        if duration > 0 then
            local change = -config.enterRotation
            local time = math.max(0,data.depth)

            data.rotation = easing.inOutElastic(time,0,change,duration,nil,duration*1.2)
        end


        v.despawnTimer = math.max(50,v.despawnTimer)

        data.depth = data.depth - config.speed

        bulletBills.destroyThings(v,data,config)
    end


    local lowPriorityStates = table.map{1,3,4}

    local function getPriority(v,data,config)
        if config.foreground then
            return -15
        end

        if data.depth > config.hitboxDepth*0.5 then
            return -96
        end

        if data.depth < 0 then
            return -15
        end

        return -45
    end

    local function getColor(v,data,config)
        local t = math.min(1,math.max(0,math.abs(data.depth) - config.hitboxDepth)/config.fadeDistance)

        return Color.white:lerp(config.fadeColor,t)
    end

    function backgroundBills.onCameraDrawBullet(v,camIdx)
        if v.despawnTimer <= 0 then
            return
        end

        local settings = v.data._settings
        local config = NPC.config[v.id]
        local data = v.data

        if not data.initialized then
            initialiseBullet(v,data,config,settings)
        end

        if data.sprite == nil then
            data.sprite = Sprite{texture = Graphics.sprites.npc[v.id].img,frames = npcutils.getTotalFramesByFramestyle(v),pivot = Sprite.align.CENTRE}
        end

        local parallax,scale = backgroundBills.getParallax(data.depth)
        local c = Camera(camIdx)

        data.sprite.x,data.sprite.y = convertNPCPosToScreen(v,c,config,parallax)
        data.sprite.scale = vector.v2(scale)

        data.sprite.rotation = data.rotation

        data.sprite:draw{frame = v.animationFrame+1,priority = getPriority(v,data,config),color = getColor(v,data,config)}

        npcutils.hideNPC(v)

        --if not v.friendly then Colliders.getHitbox(v):draw() end
    end
end


function backgroundBills.onTick()
    if not Defines.levelFreeze then
        backgroundBills.globalTimer = backgroundBills.globalTimer + 1
    end
end


function backgroundBills.onInitAPI()
    registerEvent(backgroundBills,"onTick")
end


return backgroundBills