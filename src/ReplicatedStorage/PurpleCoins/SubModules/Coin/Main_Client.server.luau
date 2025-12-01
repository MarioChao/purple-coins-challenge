--!strict

-- Main Client


---------- Imports ----------

local UIUtil = require(script.Parent.Parent:WaitForChild("UIUtil"))


--------- Constants ---------

local Constants = {}

Constants.CoinRemoteEvent = script.Parent:WaitForChild("CoinRemoteEvent")
Constants.remoteEventStrings = {
    updateTransparency = "Update Transparency",
    setDefaultTransparency = "Set Default Transparency",
    playSoundFromPart = "Play Sound From Part",
    playSoundFromWorkspace = "Play Sound From Workspace",
}

Constants.fadeTweenInfo = TweenInfo.new(0.2)

table.freeze(Constants)


--------- Local functions ---------

local onClientStart
local onCoinClientEvent
local updateTransparency
local setDefaultTransparency
local playSoundFromPart
local playSoundFromWorkspace


----- Visual functions -----

updateTransparency = function(container: Instance, transparency: number)
    if transparency == 1 then
        UIUtil.fade(container, Constants.fadeTweenInfo, false, true)
    else
        UIUtil.setTransparency(container, transparency)
    end
end

setDefaultTransparency = function(container: Instance)
    UIUtil.fade(container, Constants.fadeTweenInfo, true, true)
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
    if mode == Constants.remoteEventStrings.updateTransparency then
        updateTransparency(...)
    elseif mode == Constants.remoteEventStrings.setDefaultTransparency then
        setDefaultTransparency(...)
    elseif mode == Constants.remoteEventStrings.playSoundFromPart then
        playSoundFromPart(...)
    elseif mode == Constants.remoteEventStrings.playSoundFromWorkspace then
        playSoundFromWorkspace(...)
    end
end


----- Main function -----

onClientStart = function()
    Constants.CoinRemoteEvent.OnClientEvent:Connect(onCoinClientEvent)
end


--------- Calling function ---------

onClientStart()
