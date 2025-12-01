--!strict

-- Purple Coins


---------- Services ----------

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")


---------- Validate environment ----------

assert(RunService:IsServer(), "PurpleCoins Module should only be used by Server scripts")


---------- Imports ----------

local Coin = require(script.SubModules.Coin)


---------- Constants ----------

local Constants = {}

Constants.default_coinValue = 1
Constants.default_isServerSided = false
Constants.default_isActivated = false
Constants.default_coinRotationalVelocity = Vector3.new(0, math.rad(540), 0)
Constants.default_coinCollectSound = script.Sounds.CoinCollect

table.freeze(Constants)


---------- Module ----------

local PurpleCoins = {}
PurpleCoins.__index = PurpleCoins


----- Module types -----

type ClassData = {
	storedCoins: {Coin.ClassType},

	default_coinValue: number,
	default_isServerSided: boolean,
	default_isActivated: boolean,
	default_coinRotationalVelocity: Vector3,
	default_coinCollectSound: Sound,

	_connections: {RBXScriptConnection},
}

export type ClassType = ClassData & typeof(PurpleCoins)


---------- Module functions ----------

--[[
Constructs a new Purple Coins challenge.
]]
function PurpleCoins.new()
	local self = setmetatable({} :: any, PurpleCoins) :: ClassType

	self.storedCoins = {}

	self.default_coinValue = Constants.default_coinValue
	self.default_isServerSided = Constants.default_isServerSided
	self.default_isActivated = Constants.default_isActivated
	self.default_coinRotationalVelocity = Constants.default_coinRotationalVelocity
	self.default_coinCollectSound = Constants.default_coinCollectSound

	self._connections = {}

	return self
end

function PurpleCoins.setDefaultInfo(self: ClassType, default_coinValue: number, default_isServerSided: boolean, default_isActivated: boolean)
	self.default_coinValue = default_coinValue
	self.default_isServerSided = default_isServerSided
	self.default_isActivated = default_isActivated
end

function PurpleCoins.setDefaultRotationVelocity(self: ClassType, default_coinRotationalVelocity: Vector3)
	self.default_coinRotationalVelocity = default_coinRotationalVelocity
end

function PurpleCoins.setDefaultSound(self: ClassType, default_coinCollectSound: Sound)
	self.default_coinCollectSound = default_coinCollectSound
end


----- Coin functions -----

-- Creates a single coin.
function PurpleCoins.addCoin(self: ClassType, object: Instance)
	local success = false
	if object:IsA("BasePart") or (object:IsA("Model") and object:FindFirstChildWhichIsA("BasePart")) then
		-- Create coin object
		local coin = Coin.new(
			object,
			tonumber(object:GetAttribute("CoinValue")) or self.default_coinValue,
			(object:GetAttribute("IsServerSided") == true) or self.default_isServerSided,
			(object:GetAttribute("Activated") == true) or self.default_isActivated
		)
		table.insert(self.storedCoins, coin)
		success = true
	end
	return success
end

-- Creates coins from a container.
function PurpleCoins.addCoinsFromContainer(self: ClassType, container: Instance, recursive: boolean)
	for _, object in container:GetChildren() do
		local success = self:addCoin(object)
		if not success and recursive then
			self:addCoinsFromContainer(object, recursive)
		end
	end
end

-- Spins all currently stored coins.
function PurpleCoins.spinCoins(self: ClassType)
	for _, coin in self.storedCoins do
		coin:spin(self.default_coinRotationalVelocity)
	end
end

-- Sets the collision of all currently stored coins.
function PurpleCoins.setCoinsCanCollide(self: ClassType, canCollide: boolean)
	for _, coin in self.storedCoins do
		for _, part in coin._coinParts do
			part.CanCollide = canCollide
		end
	end
end

-- Sets the activated state of all currently stored coins on server.
function PurpleCoins.setCoinsActivated_server(self: ClassType, isActivated: boolean)
	for _, coin in self.storedCoins do
		coin:setActivated_server(isActivated)
	end
end

-- Sets the activated state of all currently stored coins on client.
function PurpleCoins.setCoinsActivated_player(self: ClassType, player: Player, isActivated: boolean)
	for _, coin in self.storedCoins do
		coin:setActivated_player(player, isActivated)
	end
end

-- Sets the visible state of all currently stored coins on server.
function PurpleCoins.setCoinsVisible_server(self: ClassType, isVisible: boolean)
	for _, coin in self.storedCoins do
		coin:setVisible_server(isVisible)
	end
end

-- Sets the visible state of all currently stored coins on client.
function PurpleCoins.setCoinsVisible_player(self: ClassType, player: Player, isVisible: boolean)
	for _, coin in self.storedCoins do
		coin:setVisible_player(player, isVisible)
	end
end

-- Unclaims all stored coins on server.
function PurpleCoins.unclaimAllCoins_server(self: ClassType)
	for _, coin in self.storedCoins do
		coin:setClaimed_server(false)
	end
end

-- Unclaims all stored coins on client.
function PurpleCoins.unclaimAllCoins_player(self: ClassType, player: Player)
	for _, coin in self.storedCoins do
		coin:setClaimed_player(player, false)
	end
end

-- Removes all stored coins.
function PurpleCoins.clearCoins(self: ClassType)
	for _, coin in self.storedCoins do
		coin:cleanUp()
	end
	table.clear(self.storedCoins)
end


----- Score functions -----

-- Gets the score of the purple coins challenge (on server).
function PurpleCoins.getScore_server(self: ClassType): number
	local result = 0
	for _, coin in self.storedCoins do
		result += coin:getEarnedValue_server()
	end
	return result
end

-- Gets the score of the purple coins challenge (on player).
function PurpleCoins.getScore_player(self: ClassType, player: Player): number
	local result = 0
	for _, coin in self.storedCoins do
		result += coin:getEarnedValue_player(player)
	end
	return result
end


----- Connection functions -----

function PurpleCoins.connect(self: ClassType)
	-- Claim on touch
	for _, coin in self.storedCoins do
		for _, part in coin._coinParts do
			table.insert(self._connections, part.Touched:Connect(function(otherPart: BasePart)
				local character = otherPart.Parent
				local player = character and Players:GetPlayerFromCharacter(character)
				if not (character and player) then return end

				local isValid = true
				isValid = isValid and coin:checkActivated_player(player)
				isValid = isValid and not coin:checkClaimed_player(player)
				isValid = isValid and coin:checkPlayerTouched_distanceCheck(player)
				if isValid then
					coin:setClaimed_player(player, true)
					if coin._isServerSided then
						coin:playSound_server(self.default_coinCollectSound)
					else
						coin:playSound_player(player, self.default_coinCollectSound)
					end
				end
			end))
		end
	end

	-- Remove data for players that left
	table.insert(self._connections, Players.PlayerRemoving:Connect(function(player: Player)
		for _, coin in self.storedCoins do
			coin:removePlayer(player)
		end
	end))
end


----- Clean up -----

function PurpleCoins.cleanUp(self: ClassType)
	self:clearCoins()

	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)
end


---------- Return module ----------

table.freeze(PurpleCoins)
return PurpleCoins
