--!strict

-- Example Challenge


---------- Imports ----------

local _Constants = require(script.Parent.Parent._Constants)


---------- Constants ----------

local Constants = {}

Constants.CoinsFolder = workspace._Workspace.CoinsFolder


----- TODO: configurations -----
Constants.configurations = {
    _challengeId = "Example",
    showUIOnCharJoin = true,
    coinsFolder = Constants.CoinsFolder,
    isServerSided = false,
    defaultIsActivated = true,
    willResetOnDeath = true,
}
----- TODO end -----

table.freeze(Constants)
table.freeze(Constants.configurations)


---------- Globals ----------

local Globals = {}
Globals.player_evaluatedScore = {}


---------- Local functions ----------

local onPlayerWin


----- Reached score functions -----

----- TODO: win function -----
onPlayerWin = function(player: Player)
    _Constants.BadgeUtil.awardBadgeLoop(player, 2144442058, "Purple Coins around Twelfth Mansion")
    -- Award badge, etc...
end
----- TODO end -----


---------- Module ----------

local Module = {}


----- Purple coins functions -----

function Module.getConfigs()
    return Constants.configurations
end

----- TODO: score evaluations -----
function Module.evaluatePlayerStateFromScore(player: Player, score: number, totalScore: number)
    if score == 0 then
        -- Initialize, etc.
        -- _Constants.purpleCoinsBindableEvent:Fire(_Constants.bindableEventStrings.setCoinsActivated, "Example", player, false)
	    -- _Constants.purpleCoinsBindableEvent:Fire(_Constants.bindableEventStrings.setCoinsVisible, "Example", player, false)
    elseif score == totalScore then
        print(`[Purple Coins Challenge]: Player {player.Name} won!`)
        task.defer(onPlayerWin, player)
        task.wait(1)
        -- _Constants.purpleCoinsBindableEvent:Fire(_Constants.bindableEventStrings.setCoinsActivated, "Example", player, true)
        -- _Constants.purpleCoinsBindableEvent:Fire(_Constants.bindableEventStrings.setCoinsVisible, "Example", player, true)
        -- _Constants.purpleCoinsBindableEvent:Fire(_Constants.bindableEventStrings.restartChallenge, "Example", player)
    end
end
----- TODO end -----


---------- Return module -----

table.freeze(Module)
return Module :: _Constants.ChallengeModule
