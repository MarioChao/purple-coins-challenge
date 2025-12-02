--!strict

-- Constants


---------- Services ----------

local ReplicatedStorage = game:GetService("ReplicatedStorage")


---------- Imports ----------

local _Types = require(script._Types)

local _Modules = script.Parent.Parent.Modules
local BadgeUtil = require(_Modules.BadgeUtil)


---------- Types ----------

export type ChallengeModule = _Types.ChallengeModule


---------- Module ----------

local Module = {}


----- Module fields -----

Module._Types = _Types
Module.BadgeUtil = BadgeUtil

Module.purpleCoinsRemoteEvent = ReplicatedStorage.RemoteEvents.PurpleCoinsRemoteEvent
Module.remoteEventStrings = {
    onScoreChange = "On Score Change",
    setUIEnabled = "Set UI Enabled",
}
table.freeze(Module.remoteEventStrings)

Module.purpleCoinsBindableEvent = script.Events.PurpleCoinsEvent
Module.bindableEventStrings = {
    restartChallenge = "Restart Challenge",
    setCoinsActivated = "Set Coins Activated",
    setCoinsVisible = "Set Coins Visible",
}
table.freeze(Module.bindableEventStrings)

Module.challengeStateBindableEvent = script.Events.ChallengeStateEvent
Module.challengeStateBindableEventStrings = {
    playerChallengeScoreUpdate = "Player Challenge Score Update",
}
table.freeze(Module.challengeStateBindableEventStrings)


---------- Return module ----------

table.freeze(Module)
return Module
