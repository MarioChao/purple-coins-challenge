--!strict

-- Coin Script


---------- Services ----------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


---------- Imports ----------

local PurpleCoins = require(ReplicatedStorage.Modules.PurpleCoins)


---------- Constants ----------

local Constants = {}

Constants.CoinsFolder = workspace._Workspace.CoinsFolder

table.freeze(Constants)


---------- Global variables ----------

local Globals = {}
Globals.player_evaluatedScore = {}


---------- Local functions ----------

local onServerStart
local startPurpleCoinsChallenge
local evaluatePlayerStateFromScore


----- Challenge functions -----

startPurpleCoinsChallenge = function()
    local wegas = PurpleCoins.new()
    wegas:setDefaultInfo(1, false)
    -- wegas:setDefaultRotationVelocity(Vector3.new(0, math.rad(540), 0))
    -- wegas:setDefaultSound(ReplicatedStorage.Modules.PurpleCoins.Sounds.CoinCollect)

    wegas:addCoinsFromContainer(Constants.CoinsFolder, true)
    wegas:spinCoins()
    wegas:setCoinsCanCollide(false)

    wegas:connect()

    while true do
        for _, player in Players:GetPlayers() do
            local score = wegas:getScore_player(player)
            evaluatePlayerStateFromScore(player, score, wegas)
        end
        task.wait()
    end
end

evaluatePlayerStateFromScore = function(player: Player, score: number, purpleCoins: PurpleCoins.ClassType)
    if Globals.player_evaluatedScore[player] == score then return end
    Globals.player_evaluatedScore[player] = score

    if score == 10 then
        print(`[Purple Coins Challenge]: Player {player.Name} collected 10 coins!`)
    elseif score == #purpleCoins.storedCoins then
        print(`[Purple Coins Challenge]: Player {player.Name} won!`)
        task.wait(3)
        purpleCoins:unclaimAllCoins_player(player)
    end
end


----- Main function -----

onServerStart = function()
    Players.PlayerRemoving:Connect(function(player: Player)
        Globals.player_evaluatedScore[player] = nil
    end)

    startPurpleCoinsChallenge()
end


---------- Calling function ----------

onServerStart()
