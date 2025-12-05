--!strict

-- Main Client (Coin)


---------- Imports ----------

local UIUtil = require(script.Parent.Parent:WaitForChild("UIUtil"))


--------- Constants ---------

local Constants = {}

Constants.coinRemoteEvent = script.Parent:WaitForChild("CoinRemoteEvent")
Constants.remoteEventStrings = {
    spinInstancesAtVelocity = "Spin Instances At Velocity",
    updateTransparency = "Update Transparency",
    setDefaultTransparency = "Set Default Transparency",
    playSoundFromPart = "Play Sound From Part",
    playSoundFromWorkspace = "Play Sound From Workspace",
    playerConnected = "Player Connected",
}
table.freeze(Constants.remoteEventStrings)

Constants.coinBindableEvent = script.Parent:WaitForChild("CoinBindableEvent")
Constants.bindableEventStrings = {
    updateTransparency = "Update Transparency",
    setDefaultTransparency = "Set Default Transparency",
    playSoundFromPart = "Play Sound From Part",
    playSoundFromWorkspace = "Play Sound From Workspace",
}
table.freeze(Constants.bindableEventStrings)

Constants.fadeTweenInfo = TweenInfo.new(0.2)

table.freeze(Constants)


--------- Globals ---------

local Globals = {}
Globals.instance_spinThread = {} :: {[Instance]: thread}


--------- Local functions ---------

local getOrCreatePrimaryPrat
local spinInstancesAtVelocity
local updateTransparency
local setDefaultTransparency
local playSoundFromPart
local playSoundFromWorkspace
local onCoinClientEvent
local onCoinEvent
local onClientStart


----- Spin -----

getOrCreatePrimaryPrat = function(instance: Instance): BasePart
    local result
    if instance:IsA("BasePart") then
        result = instance
    elseif instance:IsA("Model") then
        result = instance.PrimaryPart or (function()
            -- Create a root part located at the center of the model
			local rootPart = Instance.new("Part")
			rootPart.Transparency = 1
			rootPart.Name = "CreatedRoot"
			rootPart.Size = Vector3.new(0.1, 0.1, 0.1)
			rootPart.Position = instance:GetBoundingBox().Position
			rootPart.CanCollide = false
			rootPart.Anchored = true
			rootPart.Parent = instance
            instance.PrimaryPart = rootPart
            return rootPart
        end)()
    end
    return result
end

spinInstancesAtVelocity = function(instances: {Instance}, rotationalVelocity: Vector3)
    for _, object in instances do
        if Globals.instance_spinThread[object] then
            task.cancel(Globals.instance_spinThread[object])
        end
        Globals.instance_spinThread[object] = task.defer(function()
            local primaryPart = getOrCreatePrimaryPrat(object)
            while true do
                -- Get primary part position (similar to :GetPivot() but better for type checking)
                local position = primaryPart.Position

                -- Set rotation
                local rotationVector = rotationalVelocity * time()
                local targetCFrame = CFrame.Angles(rotationVector.X, rotationVector.Y, rotationVector.Z) + position
                if object:IsA("BasePart") then
                    object:PivotTo(targetCFrame)
                elseif object:IsA("Model") then
                    local pivotCFrame = object:GetPivot()
                    local targetPivotCFrame = targetCFrame + (pivotCFrame.Position - position)
                    object:PivotTo(targetPivotCFrame)
                end

                -- Small delay (equivalent to RunService.Heartbeat:Wait())
                task.wait()
            end
        end)
    end
end


----- Visual functions -----

updateTransparency = function(containers: {Instance}, transparency: number)
    for _, object in containers do
        if transparency == 1 then
            UIUtil.fade(object, Constants.fadeTweenInfo, false, false)
        else
            UIUtil.setTransparency(object, transparency)
        end
    end
end

setDefaultTransparency = function(containers: {Instance})
    for _, object in containers do
        UIUtil.fade(object, Constants.fadeTweenInfo, true, false)
    end
end


----- Sound functions -----

playSoundFromPart = function(part: BasePart, sound: Sound)
    local newSound = sound:Clone()
    newSound.Parent = part
    newSound.TimePosition = 0
    newSound.Ended:Connect(function()
        newSound:Destroy()
    end)
    newSound:Play()
end

playSoundFromWorkspace = function(sound: Sound)
    local newSound = sound:Clone()
    newSound.Parent = workspace
    newSound.TimePosition = 0
    newSound.Ended:Connect(function()
        newSound:Destroy()
    end)
    newSound:Play()
end


----- Event functions -----

onCoinClientEvent = function(mode: string, ...)
    if mode == Constants.remoteEventStrings.spinInstancesAtVelocity then
        spinInstancesAtVelocity(...)
    elseif mode == Constants.remoteEventStrings.updateTransparency then
        updateTransparency(...)
    elseif mode == Constants.remoteEventStrings.setDefaultTransparency then
        setDefaultTransparency(...)
    elseif mode == Constants.remoteEventStrings.playSoundFromPart then
        playSoundFromPart(...)
    elseif mode == Constants.remoteEventStrings.playSoundFromWorkspace then
        playSoundFromWorkspace(...)
    end
end

onCoinEvent = function(mode: string, ...)
    if mode == Constants.bindableEventStrings.updateTransparency then
        updateTransparency(...)
    elseif mode == Constants.bindableEventStrings.setDefaultTransparency then
        setDefaultTransparency(...)
    elseif mode == Constants.bindableEventStrings.playSoundFromPart then
        playSoundFromPart(...)
    elseif mode == Constants.bindableEventStrings.playSoundFromWorkspace then
        playSoundFromWorkspace(...)
    end
end


----- Main function -----

onClientStart = function()
    Constants.coinRemoteEvent.OnClientEvent:Connect(onCoinClientEvent)
    Constants.coinRemoteEvent:FireServer(Constants.remoteEventStrings.playerConnected)
    Constants.coinBindableEvent.Event:Connect(onCoinEvent)
end


--------- Calling function ---------

onClientStart()
