--!strict

-- Purple Coins Script (client)


---------- Services ----------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


---------- Imports ----------

local _SharedModules = ReplicatedStorage:WaitForChild("Modules")
local _PurpleCoins = _SharedModules:WaitForChild("PurpleCoins")
local _PurpleCoins_Events = _PurpleCoins:WaitForChild("Events")


---------- Constants ----------

local Constants = {}

Constants.CoinsFolder = workspace._Workspace.CoinsFolder

Constants.purpleCoinsRemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("PurpleCoinsRemoteEvent")
Constants.remoteEventStrings = {
    onScoreChange = "On Score Change",
    setUIEnabled = "Set UI Enabled",
}
table.freeze(Constants.remoteEventStrings)

Constants.purpleCoinsBindableEvent = _PurpleCoins_Events:WaitForChild("PurpleCoinsBindableEvent")
Constants.purpleCoinsBindableEventStrings = {
    playerScoreUpdated = "Player Score Updated"
}
table.freeze(Constants.purpleCoinsBindableEventStrings)

Constants.defaultScreenGui = script.Parent:WaitForChild("PurpleCoins_ScreenGui")

Constants.localPlayer = Players.LocalPlayer
Constants.playerGui = Constants.localPlayer.PlayerGui

table.freeze(Constants)


----- Purple coins -----

local PurpleCoinsGuis = {}

PurpleCoinsGuis.ScreenGui = Constants.defaultScreenGui:Clone()
PurpleCoinsGuis.ScreenGui.Parent = Constants.playerGui
PurpleCoinsGuis.ScreenGui.ResetOnSpawn = false
PurpleCoinsGuis.ScreenGui.Enabled = false

PurpleCoinsGuis.MainFrame = PurpleCoinsGuis.ScreenGui:WaitForChild("MainFrame")
PurpleCoinsGuis.Score_TextLabel = PurpleCoinsGuis.MainFrame:WaitForChild("Score_TextLabel")
PurpleCoinsGuis.TargetScore_TextLabel = PurpleCoinsGuis.MainFrame:WaitForChild("TargetScore_TextLabel")

PurpleCoinsGuis.Score_TextLabel.Text = "000"
PurpleCoinsGuis.TargetScore_TextLabel.Text = "/000"

table.freeze(PurpleCoinsGuis)


---------- Local functions ----------

local onScoreChange
local setUIEnabled
local onPurpleCoinsClientEvent
local onPurpleCoinsEvent
local onClientStart


----- Score functions -----

onScoreChange = function(score: number, targetScore: number)
    local targetScoreLength = string.len(tostring(targetScore))
    local formatString = `%0{string.format("%d", targetScoreLength)}d`

    PurpleCoinsGuis.Score_TextLabel.Text = string.format(formatString, score)
    PurpleCoinsGuis.TargetScore_TextLabel.Text = `/{targetScore}`
end


----- UI functions -----

setUIEnabled = function(enabled: number)
    PurpleCoinsGuis.ScreenGui.Enabled = enabled
end


----- Event functions -----

onPurpleCoinsClientEvent = function(mode: string, ...)
    if mode == Constants.remoteEventStrings.onScoreChange then
        onScoreChange(...)
    elseif mode == Constants.remoteEventStrings.setUIEnabled then
        setUIEnabled(...)
    end
end

onPurpleCoinsEvent = function(mode: string, ...)
    if mode == Constants.purpleCoinsBindableEventStrings.playerScoreUpdated then
        onScoreChange(...)
    end
end


----- Main function -----

onClientStart = function()
    Constants.purpleCoinsRemoteEvent.OnClientEvent:Connect(onPurpleCoinsClientEvent)
    Constants.purpleCoinsBindableEvent.Event:Connect(onPurpleCoinsEvent)
end


---------- Calling function ----------

onClientStart()


