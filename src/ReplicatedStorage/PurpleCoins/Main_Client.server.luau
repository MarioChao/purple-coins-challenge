--!strict

-- Main Client (Purple Coins)


--------- Services ---------

local Players = game:GetService("Players")


--------- Imports ---------

local _SubModules = script.Parent:WaitForChild("SubModules")
local _Coins = _SubModules:WaitForChild("Coin")
local _Events = script.Parent:WaitForChild("Events")


--------- Types ---------

type SetUpParams = {
    coinInstance: Instance,
    coinParts: {BasePart},
    coinCollectSound: Sound,
    coinValue: number,
    totalScore: number,
}


--------- Constants ---------

local Constants = {}

Constants.mainRemoteEvent = script.Parent:WaitForChild("MainRemoteEvent")
Constants.remoteEventStrings = {
    setUpClientCoinTouched = "Set Up Client Coin Touched",
    setMultipleCoinsCanTouch = "Set Multiple Coins Can Touch",
    scoreUpdated = "Score Updated",
    clientCoinTouched = "Client Coin Touched",
    playerConnected = "Player Connected",
}
table.freeze(Constants.remoteEventStrings)

Constants.coinBindableEvent = _Coins:WaitForChild("CoinBindableEvent")
Constants.coinBindableEventStrings = {
    updateTransparency = "Update Transparency",
    setDefaultTransparency = "Set Default Transparency",
    playSoundFromPart = "Play Sound From Part",
    playSoundFromWorkspace = "Play Sound From Workspace",
}
table.freeze(Constants.coinBindableEventStrings)

Constants.purpleCoinsBindableEvent = _Events.PurpleCoinsBindableEvent
Constants.purpleCoinsBindableEventStrings = {
    playerScoreUpdated = "Player Score Updated"
}
table.freeze(Constants.purpleCoinsBindableEventStrings)

table.freeze(Constants)


--------- Globals ---------

local Globals = {}
Globals.purpleCoinsId_coinId_canTouch = {} :: {[string]: {[string]: boolean}}
Globals.purpleCoinsId_coinId_touchedConnections = {} :: {[string]: {[string]: {RBXScriptConnection}}}
Globals.purpleCoinsId_score = {} :: {[string]: number}
Globals.purpleCoinsId_totalScore = {} :: {[string]: number}


--------- Local functions ---------

local setUpClientCoinTouched
local getCoinCanTouch
local setCoinCanTouch
local setMultipleCoinsCanTouch
local cleanUpPurpleCoinsTouched
local fireScoreUpdateEvent
local onScoreUpdated
local onMainClientEvent


----- Touched -----

setUpClientCoinTouched = function(purpleCoinsId: string, coinId: string, setUpParams: SetUpParams)
    if not Globals.purpleCoinsId_coinId_touchedConnections[purpleCoinsId] then
        Globals.purpleCoinsId_coinId_touchedConnections[purpleCoinsId] = {}
    end
    local coinId_touchedConnections = Globals.purpleCoinsId_coinId_touchedConnections[purpleCoinsId]

    if not coinId_touchedConnections[coinId] then
        coinId_touchedConnections[coinId] = {}
    end
    local touchedConnections = coinId_touchedConnections[coinId]

    for _, part in setUpParams.coinParts do
        table.insert(touchedConnections, part.Touched:Connect(function(otherPart: BasePart)
            -- Validate local player
            local character = otherPart.Parent
            local player = character and Players:GetPlayerFromCharacter(character)
            if not (character and player) then return end
            if player ~= Players.LocalPlayer then return end

            if getCoinCanTouch(purpleCoinsId, coinId) then
                -- Disable can touch
                setCoinCanTouch(purpleCoinsId, coinId, false)

                -- Remote
                Constants.mainRemoteEvent:FireServer(Constants.remoteEventStrings.clientCoinTouched, purpleCoinsId, coinId)
    
                -- Effects
                Constants.coinBindableEvent:Fire(Constants.coinBindableEventStrings.updateTransparency, {setUpParams.coinInstance}, 1)
                Constants.coinBindableEvent:Fire(Constants.coinBindableEventStrings.playSoundFromWorkspace, setUpParams.coinCollectSound)

                -- Score update
                Globals.purpleCoinsId_score[purpleCoinsId] = Globals.purpleCoinsId_score[purpleCoinsId] or 0
                Globals.purpleCoinsId_score[purpleCoinsId] += setUpParams.coinValue
                Globals.purpleCoinsId_totalScore[purpleCoinsId] = Globals.purpleCoinsId_totalScore[purpleCoinsId] or setUpParams.totalScore
                fireScoreUpdateEvent(purpleCoinsId)
            end
        end))
    end
end

getCoinCanTouch = function(purpleCoinsId: string, coinId: string)
    if not Globals.purpleCoinsId_coinId_canTouch[purpleCoinsId] then
        Globals.purpleCoinsId_coinId_canTouch[purpleCoinsId] = {}
    end
    local coinId_canTouch = Globals.purpleCoinsId_coinId_canTouch[purpleCoinsId]
    local result = coinId_canTouch[coinId] or false
    return result
end

setCoinCanTouch = function(purpleCoinsId: string, coinId: string, canTouch: boolean)
     if not Globals.purpleCoinsId_coinId_canTouch[purpleCoinsId] then
        Globals.purpleCoinsId_coinId_canTouch[purpleCoinsId] = {}
    end
    local coinId_canTouch = Globals.purpleCoinsId_coinId_canTouch[purpleCoinsId]
    coinId_canTouch[coinId] = canTouch
end

setMultipleCoinsCanTouch = function(purpleCoinsId: string, coinIds: {string}, canTouch: boolean)
    for _, coinId in coinIds do
        setCoinCanTouch(purpleCoinsId, coinId, canTouch)
    end
end

cleanUpPurpleCoinsTouched = function(purpleCoinsId: string)
    for _, touchedConnections in Globals.purpleCoinsId_coinId_touchedConnections[purpleCoinsId] do
        for _, connection in touchedConnections do
            connection:Disconnect()
        end
        table.clear(touchedConnections)
    end
    table.clear(Globals.purpleCoinsId_coinId_touchedConnections[purpleCoinsId])
    table.clear(Globals.purpleCoinsId_coinId_canTouch)
end


----- Score -----

fireScoreUpdateEvent = function(purpleCoinsId: string)
    local score = Globals.purpleCoinsId_score[purpleCoinsId]
    local totalScore = Globals.purpleCoinsId_totalScore[purpleCoinsId]
    Constants.purpleCoinsBindableEvent:Fire(Constants.purpleCoinsBindableEventStrings.playerScoreUpdated, score, totalScore)
end

onScoreUpdated = function(purpleCoinsId: string, score: number, totalScore: number)
    Globals.purpleCoinsId_score[purpleCoinsId] = score
    Globals.purpleCoinsId_totalScore[purpleCoinsId] = totalScore
    fireScoreUpdateEvent(purpleCoinsId)
end


----- Event functions -----

onMainClientEvent = function(mode: string, ...)
    if mode == Constants.remoteEventStrings.setUpClientCoinTouched then
        setUpClientCoinTouched(...)
    elseif mode == Constants.remoteEventStrings.setMultipleCoinsCanTouch then
        setMultipleCoinsCanTouch(...)
    elseif mode == Constants.remoteEventStrings.scoreUpdated then
        onScoreUpdated(...)
    end
end


----- Main -----

local function main()
    Constants.mainRemoteEvent.OnClientEvent:Connect(onMainClientEvent)
    Constants.mainRemoteEvent:FireServer(Constants.remoteEventStrings.playerConnected)
end


--------- Calling function ---------

main()
