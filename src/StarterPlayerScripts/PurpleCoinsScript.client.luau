--!strict

-- Purple Coins Script (client)


---------- Services ----------

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


---------- Constants ----------

local Constants = {}

Constants.CoinsFolder = workspace._Workspace.CoinsFolder

Constants.purpleCoinsRemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("PurpleCoinsRemoteEvent")
Constants.onScoreChangeModeString = "On Score Change"
Constants.setUIEnabledModeString = "Set UI Enabled"

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
    if mode == Constants.onScoreChangeModeString then
        onScoreChange(...)
    elseif mode == Constants.setUIEnabledModeString then
        setUIEnabled(...)
    end
end


----- Main function -----

onClientStart = function()
    Constants.purpleCoinsRemoteEvent.OnClientEvent:Connect(onPurpleCoinsClientEvent)
end


---------- Calling function ----------

onClientStart()


