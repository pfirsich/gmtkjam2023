local gltf = require "gltf"

local causticsTexture = womf.Texture("assets/Caustic_Free.jpg")

local shader = womf.Shader("assets/default.vert", "assets/default.frag")

local seafloor = gltf.load("assets/seafloor.gltf")

local fish = gltf.load("assets/Goldfish.gltf")
local fishTrafo = womf.Transform()
fishTrafo:setScale(0.5, 0.5, 0.5)
local fishPos = vec3(0, 3, 0)
local fishVel = vec3(0, 0, 1)
fishTrafo:setPosition(fishPos:unpack())

fish:walk(function(node)
    local factor = 3.0
    if node.mesh then
        for _, prim in ipairs(node.mesh.primitives) do
            local r, g, b, a = unpack(prim.material.color)
            prim.material.color = {r * factor, g * factor, b * factor, a}
        end
    end
end)

local xRes, yRes = womf.getWindowSize()
womf.setProjectionMatrix(45, xRes/yRes, 0.1, 100.0)

local floorTrafo = womf.Transform()
floorTrafo:setScale(5.0, 2.0, 5.0)

local camTrafo = womf.Transform()
camTrafo:setPosition((fishPos + vec3(0, 0, -5)):unpack())

local function update(dt)
    -- friction
    local minSpeed = 0.5
    if fishVel:len() > minSpeed then
        fishVel = fishVel - fishVel * math.min(1.0 * dt, fishVel:len() - minSpeed)
    end

    -- acceleration
    local maxSpeed = 2.0
    if womf.isDown(32) and fishVel:len() < maxSpeed then
        fishVel = fishVel + fishVel:normalize() * math.min(2.5 * dt, maxSpeed - fishVel:len())
    end

    local pitchDir = (womf.isDown(119) and 1 or 0) - (womf.isDown(115) and 1 or 0)
    local pitchAxis = fishVel:normalize():cross(vec3(0, 1, 0))
    local yDot = fishVel:normalize():dot(vec3(0, 1, 0))
    local maxPitch = 0.25
    local canMoveUp = pitchDir > 0 and yDot < math.cos(math.pi * maxPitch)
    local canMoveDown = pitchDir < 0 and yDot > -math.cos(math.pi * maxPitch)
    if canMoveUp or canMoveDown then
        local rot = quat.from_angle_axis(math.pi * 0.1 * pitchDir * dt, pitchAxis)
        fishVel = rot * fishVel
    end

    local yawDir = (womf.isDown(100) and 1 or 0) - (womf.isDown(97) and 1 or 0)
    if math.abs(yawDir) > 0 then
        local rot = quat.from_angle_axis(math.pi * 0.1 * -yawDir * dt, 0, 1, 0)
        fishVel = rot * fishVel
    end


    fishPos = fishPos + fishVel * dt
    fishTrafo:setPosition(fishPos:unpack())
    fishTrafo:lookAt((fishPos - fishVel):unpack())

    local camPos = vec3(camTrafo:getPosition())
    local delta = fishPos - camPos
    local dist = delta:len()
    local targetDist = 5.0
    if dist > targetDist then
        local len = dist - targetDist
        camTrafo:setPosition((camPos + delta:normalize() * len):unpack())
    end
    camTrafo:lookAt(fishTrafo:getPosition())
    womf.setViewMatrix(camTrafo)
end

local function drawScene(scene, shader, sceneTransform)
    sceneTransform = sceneTransform and mat4(sceneTransform:getMatrix()) or mat4()
    scene:walk(function(node)
        if node.mesh then
            local parentTrafo = node.parent and node.parent.fullTransform or sceneTransform
            node.fullTransform = parentTrafo * mat4(node.transform:getMatrix())
            womf.setModelMatrix(node.fullTransform:unpack())

            for _, prim in ipairs(node.mesh.primitives) do
                womf.draw(shader, prim.geometry, {
                    texture = prim.material.albedo or pixelTexture,
                    caustics = causticsTexture,
                    color = prim.material.color,
                    time = womf.getTime(),
                })
            end
        end
    end)
end

local function draw()
    womf.clear(0.15, 0.55, 0.84, 0, 1)
    drawScene(seafloor, shader, floorTrafo)
    drawScene(fish, shader, fishTrafo)
    womf.present()
end

local function main()
    local time = womf.getTime()
    while true do
        for event in womf.pollEvent() do
            print("event", inspect(event))
            if event.type == "quit" then
                return
            elseif event.type == "keydown" and event.symbol == 27 then
                return
            elseif event.type == "windowresized" then
                print("window resized", event.width, event.height)
            end
        end

        local now = womf.getTime()
        local dt = now - time
        time = now

        update(dt)
        draw()
    end
end

return main
