--!strict

-- Main Server (Purple Coins)


--------- Imports ---------

local PurpleCoins = require(script.Parent)


--------- Constants ---------

local Constants = {}

Constants.mainRemoteEvent = script.Parent:WaitForChild("MainRemoteEvent")
Constants.remoteEventStrings = {
    setUpClientCoinTouched = "Set Up Client Coin Touched",
    setMultipleCoinsCanTouch = "Set Multiple Coins Can Touch",
    clientCoinTouched = "Client Coin Touched",
}
table.freeze(Constants.remoteEventStrings)

table.freeze(Constants)


---------- Local functions ----------

local onClientCoinTouched
local onMainServerEvent


----- Client coin touched -----

onClientCoinTouched = function(player: Player, purpleCoinsId: string, coinId: string)
	local purpleCoins = PurpleCoins.static_getPurpleCoinsFromId(purpleCoinsId)
	if purpleCoins and purpleCoins.useClientCollision then
		purpleCoins:_onClientCoinTouched(player, coinId)
	end
end


----- Remote event -----

onMainServerEvent = function(player: Player, mode: string, ...)
	if mode == Constants.remoteEventStrings.clientCoinTouched then
		onClientCoinTouched(player, ...)
	end
end


----- Main -----

local function main()
	Constants.mainRemoteEvent.OnServerEvent:Connect(onMainServerEvent)
end


---------- Calling function ----------

main()
