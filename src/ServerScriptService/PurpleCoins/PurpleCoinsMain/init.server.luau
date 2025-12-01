--!strict

-- Purple Coins Main


---------- Services ----------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


---------- Imports ----------

local GetChallenges = require(script.Parent.GetChallenges)
local PurpleCoins = require(ReplicatedStorage.Modules.PurpleCoins)
local _Constants = require(script.Parent._Constants)


---------- Constants ----------

local Constants = {}

Constants.challengeModules = GetChallenges.challengeModules

table.freeze(Constants)


---------- Globals ----------

local Globals = {}

Globals.challengeModules = {} :: {_Constants.ChallengeModule}

Globals.challengeId_player_evaluatedScore = {} :: {[string]: {[Player]: number}}
Globals.challengeId_purpleCoins = {} :: {[string]: PurpleCoins.ClassType}


---------- Local functions ----------

local createPurpleCoinsChallenge
local event_restartChallenge
local event_setCoinsActivated
local event_setCoinsVisible
local onPurpleCoinsEvent
local onPlayerAdded
local onServerStart


----- Challenge functions -----

createPurpleCoinsChallenge = function(challengeModule: _Constants.ChallengeModule, challengeId: string)
    ----- Create purple coins challenge -----

    local challengeConfigs = challengeModule.getConfigs()
    local wegas = PurpleCoins.new()
    wegas:setDefaultInfo(1, challengeConfigs.isServerSided, challengeConfigs.defaultIsActivated)
    -- wegas:setDefaultRotationVelocity(Vector3.new(0, math.rad(540), 0))
    -- wegas:setDefaultSound(ReplicatedStorage.Modules.PurpleCoins.Sounds.CoinCollect)

    wegas:addCoinsFromContainer(challengeConfigs.coinsFolder, true)
    wegas:spinCoins()
    wegas:setCoinsCanCollide(false)

    wegas:connect()

    Globals.challengeId_purpleCoins[challengeId] = wegas

    ----- Evaluate purple coins score -----

    local totalScore = #wegas.storedCoins
    local player_evaluatedScore = {}
    Globals.challengeId_player_evaluatedScore[challengeId] = player_evaluatedScore

    local thread = task.defer(function()
        while true do
            for _, player in Players:GetPlayers() do
                local score = wegas:getScore_player(player)
                if player_evaluatedScore[player] ~= score then
                    player_evaluatedScore[player] = score
                    _Constants.purpleCoinsRemoteEvent:FireClient(player, _Constants.remoteEventStrings.onScoreChange, score, totalScore)
                    task.defer(function()
                        challengeModule.evaluatePlayerStateFromScore(player, score, totalScore)
                    end)
                end
            end
            task.wait()
        end
    end)

    return thread
end


----- Purple coins event -----

event_restartChallenge = function(challengeId: string, player: Player)
    -- Get challenge
    challengeId = tostring(challengeId)
    local purpleCoins = Globals.challengeId_purpleCoins[challengeId]

    -- Restart & show score
    if purpleCoins then
        local score = purpleCoins:getScore_player(player)
        local totalScore = #purpleCoins.storedCoins
        purpleCoins:unclaimAllCoins_player(player)
        _Constants.purpleCoinsRemoteEvent:FireClient(player, _Constants.remoteEventStrings.onScoreChange, score, totalScore)
    end
end

event_setCoinsActivated = function(challengeId: string, player: Player, isActivated: boolean)
    -- Get challenge
    challengeId = tostring(challengeId)
    local purpleCoins = Globals.challengeId_purpleCoins[challengeId]

    -- Activate coins
    if purpleCoins then
        purpleCoins:setCoinsActivated_player(player, isActivated)
    end
end

event_setCoinsVisible = function(challengeId: string, player: Player, isVisible: boolean)
    -- Get challenge
    challengeId = tostring(challengeId)
    local purpleCoins = Globals.challengeId_purpleCoins[challengeId]

    -- Set coins visible
    if purpleCoins then
        purpleCoins:setCoinsVisible_player(player, isVisible)
    end
end

onPurpleCoinsEvent = function(mode: string, ...)
    if mode == _Constants.bindableEventStrings.restartChallenge then
        event_restartChallenge(...)
    elseif mode == _Constants.bindableEventStrings.setCoinsActivated then
        event_setCoinsActivated(...)
    elseif mode == _Constants.bindableEventStrings.setCoinsVisible then
        event_setCoinsVisible(...)
    end
end


----- Player added -----

onPlayerAdded = function(player: Player)
    -- Set up reset on death
    player.CharacterRemoving:Connect(function(character: Model)
        for id, challengeModule in Constants.challengeModules do
            local challengeConfigs = challengeModule.getConfigs()
            local purpleCoins = Globals.challengeId_purpleCoins[tostring(id)]
            if purpleCoins and challengeConfigs.willResetOnDeath then
                purpleCoins:unclaimAllCoins_player(player)
            end
        end
    end)

    -- Show on char join
    local showOnJoinChallengeModule
    for _, challengeModule in Constants.challengeModules do
        local challengeConfigs = challengeModule.getConfigs()
        if challengeConfigs.showUIOnCharJoin then
            showOnJoinChallengeModule = challengeModule
        end
    end
    if showOnJoinChallengeModule then
        local _ = player.Character or player.CharacterAdded:Wait()
        _Constants.purpleCoinsRemoteEvent:FireClient(player, _Constants.remoteEventStrings.setUIEnabled, true)
    end
end


----- Main function -----

onServerStart = function()
    -- Player removing clean up
    Players.PlayerRemoving:Connect(function(player: Player)
        for id, _ in Constants.challengeModules do
            local player_evaluatedScore = Globals.challengeId_player_evaluatedScore[tostring(id)]
            if player_evaluatedScore then
                player_evaluatedScore[player] = nil
            end
        end
    end)

    -- Create challenges
    for id, challengeModule in Constants.challengeModules do
        createPurpleCoinsChallenge(challengeModule, tostring(id))
    end

    -- Purple coins event
    _Constants.purpleCoinsBindableEvent.Event:Connect(onPurpleCoinsEvent)

    -- Player added functions
    local initialPlayers = Players:GetPlayers()
    Players.PlayerAdded:Connect(onPlayerAdded)
    for _, player in initialPlayers do
        task.defer(onPlayerAdded, player)
    end
end


---------- Calling function ----------

onServerStart()
