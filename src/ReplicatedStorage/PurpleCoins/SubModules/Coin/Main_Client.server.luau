--!strict

-- Main Client (Coin)


---------- Imports ----------

local UIUtil = require(script.Parent.Parent:WaitForChild("UIUtil"))


--------- Constants ---------

local Constants = {}

Constants.coinRemoteEvent = script.Parent:WaitForChild("CoinRemoteEvent")
Constants.remoteEventStrings = {
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


--------- Local functions ---------

local updateTransparency
local setDefaultTransparency
local playSoundFromPart
local playSoundFromWorkspace
local onCoinClientEvent
local onCoinEvent
local onClientStart


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
