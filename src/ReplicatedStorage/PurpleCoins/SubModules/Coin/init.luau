--!strict

-- Coin


---------- Services ----------

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")


---------- Imports ----------

local UIUtil = require(script.Parent:WaitForChild("UIUtil"))


---------- Constants ----------

local Constants = {}

Constants.coinRemoteEvent = script:WaitForChild("CoinRemoteEvent")
Constants.remoteEventStrings = {
    spinInstancesAtVelocity = "Spin Instances At Velocity",
    updateTransparency = "Update Transparency",
    setDefaultTransparency = "Set Default Transparency",
    playSoundFromPart = "Play Sound From Part",
    playSoundFromWorkspace = "Play Sound From Workspace",
    playerConnected = "Player Connected",
}

Constants.distanceCheck_extraLength = 7

table.freeze(Constants)


---------- Globals ----------

local Globals = {}
Globals.player_connected = {} :: {[Player]: boolean?}


---------- Local functions ----------

local getDescendantParts
local onCoinServerEvent


----- Get parts -----

getDescendantParts = function(parentInstance: Instance, includeParent: boolean)
    local result = {}
    if includeParent and parentInstance:IsA("BasePart") then
        table.insert(result, parentInstance)
    end
    for _, object in parentInstance:GetDescendants() do
        if object:IsA("BasePart") then
            table.insert(result, object)
        end
    end
    return result
end


----- Coin event -----

onCoinServerEvent = function(player: Player, mode: string, ...)
    if mode == Constants.remoteEventStrings.playerConnected then
        Globals.player_connected[player] = true
    end
end


----- Main -----

local function main()
    Constants.coinRemoteEvent.OnServerEvent:Connect(onCoinServerEvent)
    Players.PlayerRemoving:Connect(function(player: Player)
        Globals.player_connected[player] = nil
    end)
end


---------- Calling function ----------

task.defer(main)


---------- Module ----------

local Coin = {}
Coin.__index = Coin


----- Module types -----

type ClassData = {
    _uniqueId: string,

    _coinInstance: BasePart | Model,
    _coinValue: number,
    _isServerSided: boolean,

    _default_isActivated: boolean,
    _server_isActivated: boolean,
    _client_player_isActivated: {[Player]: boolean?},

    _default_isVisible: boolean,
    _server_isVisible: boolean,
    _client_player_isVisible: {[Player]: boolean?},

    _coinParts: {BasePart},
    _default_claimed: boolean,
    _server_claimed: boolean,
    _client_player_claimed: {[Player]: boolean?},

    _updatePlayerVisualThread: thread?,
}

export type ClassType = ClassData & typeof(Coin)


---------- Module functions ----------

function Coin.new(coinInstance: BasePart | Model, coinValue: number, isServerSided: boolean, isActivated: boolean)
    local self = setmetatable({} :: any, Coin) :: ClassType

    self._uniqueId = HttpService:GenerateGUID()

    self._coinInstance = coinInstance
    self._coinValue = coinValue
	self._isServerSided = isServerSided

    self._default_isActivated = isActivated
    self._server_isActivated = isActivated
    self._client_player_isActivated = {}

    self._default_isVisible = true
    self._server_isVisible = true
    self._client_player_isVisible = {}

    self:getOrCreatePrimaryPart()
    self._coinParts = getDescendantParts(coinInstance, true)
    self._default_claimed = false
    self._server_claimed = false
    self._client_player_claimed = {}

    self._updatePlayerVisualThread = nil

    UIUtil.resetTransparency(self._coinInstance)

    return self
end


----- Claimed attribute -----

-- Sets claimed status on server.
function Coin.setClaimed_server(self: ClassType, isClaimed: boolean, updateVisual: boolean)
    if self._server_claimed ~= isClaimed then
        self._server_claimed = isClaimed
        if updateVisual then
            self:updateVisual_server()
        end
    end
end

-- Sets claimed status on client.
function Coin.setClaimed_player(self: ClassType, player: Player, isClaimed: boolean, updateVisual: boolean)
    if self._client_player_claimed[player] ~= isClaimed then
        self._client_player_claimed[player] = isClaimed
        if isClaimed and self._isServerSided then
            self:setClaimed_server(isClaimed, updateVisual)
        end
        if not self._isServerSided then
            if updateVisual then
                self:updateVisual_player(player)
            end
        end
    end
end

-- Checks if coin is claimed on server.
function Coin.checkClaimed_server(self: ClassType): boolean
    return self._server_claimed == true
end

-- Checks if coin is claimed by player.
function Coin.checkClaimed_player(self: ClassType, player: Player): boolean
    local result
    if self._isServerSided then
        result = self._server_claimed == true
    else
        if self._client_player_claimed[player] ~= nil then
            result = self._client_player_claimed[player] == true
        else
            result = self._default_claimed
        end
    end
	return result
end


----- Activated attribute -----

-- Sets if coin is activated on server.
function Coin.setActivated_server(self: ClassType, isActivated: boolean)
    self._server_isActivated = isActivated
end

-- Sets if coin is activated on player.
function Coin.setActivated_player(self: ClassType, player: Player, isActivated: boolean)
    self._client_player_isActivated[player] = isActivated
end

-- Checks if coin is activated on server.
function Coin.checkActivated_server(self: ClassType): boolean
    return self._server_isActivated == true
end

-- Checks if coin is activated by player.
function Coin.checkActivated_player(self: ClassType, player: Player): boolean
    local result
    if self._isServerSided then
        result = self._server_isActivated == true
    else
        if self._client_player_isActivated[player] ~= nil then
            result = self._client_player_isActivated[player] == true
        else
            result = self._default_isActivated
        end
    end
	return result
end


----- Visible attribute -----

-- Sets if coin is visible on server.
function Coin.setVisible_server(self: ClassType, isVisible: boolean, updateVisual: boolean)
    self._server_isVisible = isVisible
    if updateVisual then
        self:updateVisual_server()
    end
end

-- Sets if coin is visible on player.
function Coin.setVisible_player(self: ClassType, player: Player, isVisible: boolean, updateVisual: boolean)
    self._client_player_isVisible[player] = isVisible
    if updateVisual then
        self:updateVisual_player(player)
    end
end

-- Checks if coin is visible on server.
function Coin.checkVisible_server(self: ClassType): boolean
    return self._server_isVisible == true
end

-- Checks if coin is visible by player.
function Coin.checkVisible_player(self: ClassType, player: Player): boolean
    local result
    if self._isServerSided then
        result = self._server_isVisible == true
    else
        if self._client_player_isVisible[player] ~= nil then
            result = self._client_player_isVisible[player] == true
        else
            result = self._default_isVisible
        end
    end
	return result
end


----- Claimed status -----

-- Checks if the player picks up the coin on the server.
function Coin.checkPlayerTouched_distanceCheck(self: ClassType, player: Player)
    local character = player.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
	local result = false

    if character and humanoidRootPart and humanoidRootPart:IsA("BasePart") then
        local coinPosition
        local coinRadius
        if self._coinInstance:IsA("BasePart") then
            local size = self._coinInstance.Size
            coinPosition = self._coinInstance.Position
            coinRadius = math.max(size.X, size.Y, size.Z) // 2
        elseif self._coinInstance:IsA("Model") then
            local size = self._coinInstance:GetExtentsSize()
            coinPosition = self._coinInstance:GetPivot().Position
            coinRadius = math.max(size.X, size.Y, size.Z) // 2
        end

        result = (coinPosition - humanoidRootPart.Position).Magnitude < coinRadius + Constants.distanceCheck_extraLength
    end

    return result
end

-- Returns 0 if not claimed or the coin value if claimed (on server).
function Coin.getEarnedValue_server(self: ClassType)
    local result = 0
    if self:checkClaimed_server() then
        result = self._coinValue
    end
    return result
end

-- Returns 0 if not claimed or the coin value if claimed (on client).
function Coin.getEarnedValue_player(self: ClassType, player: Player)
    local result = 0
    if self:checkClaimed_player(player) then
        result = self._coinValue
    end
    return result
end


----- Spin -----

-- Gets the primary part of the coin.
function Coin.getOrCreatePrimaryPart(self: ClassType): BasePart
    local result
    if self._coinInstance:IsA("BasePart") then
        result = self._coinInstance
    elseif self._coinInstance:IsA("Model") then
        result = self._coinInstance.PrimaryPart or (function()
            -- Create a root part located at the center of the model
			local rootPart = Instance.new("Part")
			rootPart.Transparency = 1
			rootPart.Name = "CreatedRoot"
			rootPart.Size = Vector3.new(0.1, 0.1, 0.1)
			rootPart.Position = self._coinInstance:GetBoundingBox().Position
			rootPart.CanCollide = false
			rootPart.Anchored = true
			rootPart.Parent = self._coinInstance
            self._coinInstance.PrimaryPart = rootPart
            return rootPart
        end)()
    end
    return result
end

-- Spins the coin's root part.
function Coin.spin(self: ClassType, rotationalVelocity: Vector3)
    Constants.coinRemoteEvent:FireAllClients(Constants.remoteEventStrings.spinInstancesAtVelocity, {self._coinInstance}, rotationalVelocity)
end

-- (static) Spins multiple instances.
function Coin.static_spin(fireAllClients: boolean, player: Player?, instances: {Instance}, rotationalVelocity: Vector3)
    if fireAllClients then
        Constants.coinRemoteEvent:FireAllClients(Constants.remoteEventStrings.spinInstancesAtVelocity, instances, rotationalVelocity)
    elseif player then
        Constants.coinRemoteEvent:FireClient(player, Constants.remoteEventStrings.spinInstancesAtVelocity, instances, rotationalVelocity)
    else
        warn('[Purple Coins]: Either `fireAllClients` should be `true` or `player` should be specified.')
    end
end


----- Visual -----

-- (static) Sets multiple instances to default transparency.
function Coin.static_setDefaultTransparency(fireAllClients: boolean, player: Player?, instances: {Instance})
    if fireAllClients then
        Constants.coinRemoteEvent:FireAllClients(Constants.remoteEventStrings.setDefaultTransparency, instances)
    elseif player then
        Constants.coinRemoteEvent:FireClient(player, Constants.remoteEventStrings.setDefaultTransparency, instances)
    else
        warn('[Purple Coins]: Either `fireAllClients` should be `true` or `player` should be specified.')
    end
end

-- (static) Sets multiple instances to the specified transparency.
function Coin.static_updateTransparency(fireAllClients: boolean, player: Player?, instances: {Instance}, transparency: number)
    if fireAllClients then
        Constants.coinRemoteEvent:FireAllClients(Constants.remoteEventStrings.updateTransparency, instances, transparency)
    elseif player then
        Constants.coinRemoteEvent:FireClient(player, Constants.remoteEventStrings.updateTransparency, instances, transparency)
    else
        warn('[Purple Coins]: Either `fireAllClients` should be `true` or `player` should be specified.')
    end
end

-- Gets the coin's expected appearance (on server).
function Coin.getExpectedVisual_server(self: ClassType)
    local result
    if not self:checkVisible_server() then
        result = "Hidden"
    elseif self:checkClaimed_server() then
        result = "Hidden"
    else
        result = "Default"
    end
    return result
end

-- Gets the coin's expected appearance (on player).
function Coin.getExpectedVisual_player(self: ClassType, player: Player)
    local result
    if not self:checkVisible_player(player) then
        result = "Hidden"
    elseif self:checkClaimed_player(player) then
        result = "Hidden"
    else
        result = "Default"
    end
    return result
end

-- Updates coin's appearance based on visible and claimed value (on server).
function Coin.updateVisual_server(self: ClassType)
    if next(Players:GetPlayers()) then
        local expectedVisual = self:getExpectedVisual_server()
        if expectedVisual == "Hidden" then
            Constants.coinRemoteEvent:FireAllClients(Constants.remoteEventStrings.updateTransparency, {self._coinInstance}, 1)
        elseif expectedVisual == "Default" then
            Constants.coinRemoteEvent:FireAllClients(Constants.remoteEventStrings.setDefaultTransparency, {self._coinInstance})
        end
    end
end

-- Updates coin's appearance based on visible and claimed value (on player).
function Coin.updateVisual_player(self: ClassType, player: Player)
    if self._updatePlayerVisualThread then
        task.cancel(self._updatePlayerVisualThread)
    end
    self._updatePlayerVisualThread = task.defer(function()
        local startTime = time()
        while not Globals.player_connected[player] and time() - startTime < 5 do
            task.wait()
        end
        local expectedVisual = self:getExpectedVisual_player(player)
        if expectedVisual == "Hidden" then
            Constants.coinRemoteEvent:FireClient(player, Constants.remoteEventStrings.updateTransparency, {self._coinInstance}, 1)
        elseif expectedVisual == "Default" then
            Constants.coinRemoteEvent:FireClient(player, Constants.remoteEventStrings.setDefaultTransparency, {self._coinInstance})
        end
    end)
end


----- Sound functions -----

-- Plays a sound from the coin on server.
function Coin.playSound_server(self: ClassType, sound: Sound)
    Constants.coinRemoteEvent:FireAllClients(Constants.remoteEventStrings.playSoundFromPart, self:getOrCreatePrimaryPart(), sound)
end

-- Plays a sound from the coin on player.
function Coin.playSound_player(self: ClassType, player: Player, sound: Sound)
    -- Constants.CoinRemoteEvent:FireClient(player, Constants.remoteEventStrings.playSoundFromPart, self:getOrCreatePrimaryPart(), sound)
    Constants.coinRemoteEvent:FireClient(player, Constants.remoteEventStrings.playSoundFromWorkspace, sound)
end


----- Clean up -----

function Coin.removePlayer(self: ClassType, player: Player)
    self._client_player_isActivated[player] = nil
    self._client_player_isVisible[player] = nil
    self._client_player_claimed[player] = nil
end

function Coin.removePlayersThatLeft(self: ClassType)
    local player_inServer = {}
    local playersToRemove = {}
    for _, player in Players:GetPlayers() do
        player_inServer[player] = true
    end
    for player, _ in self._client_player_isActivated do
        if not player_inServer[player] then
            table.insert(playersToRemove, player)
        end
    end
    for player, _ in self._client_player_isVisible do
        if not player_inServer[player] then
            table.insert(playersToRemove, player)
        end
    end
    for player, _ in self._client_player_claimed do
        if not player_inServer[player] then
            table.insert(playersToRemove, player)
        end
    end
    for _, player in playersToRemove do
        self:removePlayer(player)
    end
end

function Coin.cleanUp(self: ClassType)
    if self._updatePlayerVisualThread then
        task.cancel(self._updatePlayerVisualThread)
    end
    self._updatePlayerVisualThread = nil

    table.clear(self._client_player_isActivated)
    table.clear(self._client_player_isVisible)
    table.clear(self._client_player_claimed)
end


---------- Return module ----------

table.freeze(Coin)
return Coin
