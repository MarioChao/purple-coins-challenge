--!strict

-- Main Client


--------- Constants ---------

local Constants = {}

Constants.CoinRemoteEvent = script.Parent:WaitForChild("CoinRemoteEvent")
Constants.initialTransparencyString = "CoinInitialTransparency"

table.freeze(Constants)


--------- Local functions ---------

local onClientStart
local onCoinClientEvent
local getPartInitialTransparency
local updateTransparency
local setDefaultTransparency
local playSoundFromPart


----- Visual functions -----

getPartInitialTransparency = function(part: BasePart): number
    return tonumber(part:GetAttribute(Constants.initialTransparencyString)) or part.Transparency
end

updateTransparency = function(partsTable: {BasePart}, transparency: number)
    for _, part in partsTable do
        part.Transparency = transparency
    end
end

setDefaultTransparency = function(partsTable: {BasePart})
    for _, part in partsTable do
        part.Transparency = getPartInitialTransparency(part)
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


----- Event functions -----

onCoinClientEvent = function(mode: string, ...)
    if mode == "Update Transparency" then
        updateTransparency(...)
    elseif mode == "Set Default Transparency" then
        setDefaultTransparency(...)
    elseif mode == "Play Sound From Part" then
        playSoundFromPart(...)
    end
end


----- Main function -----

onClientStart = function()
    Constants.CoinRemoteEvent.OnClientEvent:Connect(onCoinClientEvent)
end


--------- Calling function ---------

onClientStart()
