--!strict

-- Coin


---------- Services ----------

local Players = game:GetService("Players")


---------- Constants ----------

local Constants = {}

Constants.CoinRemoteEvent = script:WaitForChild("CoinRemoteEvent")
Constants.initialTransparencyString = "CoinInitialTransparency"

Constants.updateTransparencyModeString = "Update Transparency"
Constants.setDefaultTransparencyModeString = "Set Default Transparency"
Constants.playSoundFromPartModeString = "Play Sound From Part"

Constants.distanceCheck_extraLength = 5

table.freeze(Constants)


---------- Local functions ----------

local getDescendantParts
local storePartInitialTransparency
local getPartInitialTransparency


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


----- Visual functions -----

storePartInitialTransparency = function(part: BasePart)
    if not part:GetAttribute(Constants.initialTransparencyString) then
        part:SetAttribute(Constants.initialTransparencyString, part.Transparency)
    end
end

getPartInitialTransparency = function(part: BasePart): number
    return tonumber(part:GetAttribute(Constants.initialTransparencyString)) or part.Transparency
end


---------- Module ----------

local Coin = {}
Coin.__index = Coin


----- Module types -----

type ClassData = {
    _coinInstance: BasePart | Model,
    _coinValue: number,
    _isServerSided: boolean,
    _isActivated: boolean,

    _coinParts: {BasePart},
    _server_claimed: boolean,
    _client_player_claimed: {[Player]: boolean?},

    _spinThread: thread?,
}

export type ClassType = ClassData & typeof(Coin)


---------- Module functions ----------

function Coin.new(coinInstance: BasePart | Model, coinValue: number, isServerSided: boolean, isActivated: boolean)
    local self = setmetatable({} :: any, Coin) :: ClassType

    self._coinInstance = coinInstance
    self._coinValue = coinValue
	self._isServerSided = isServerSided
    self._isActivated = isActivated

    self:getOrCreatePrimaryPart()
    self._coinParts = getDescendantParts(coinInstance, true)
    self._server_claimed = false
    self._client_player_claimed = {}

    self._spinThread = nil

    for _, part in self._coinParts do
        storePartInitialTransparency(part)
    end

    return self
end


----- Claimed status -----

-- Sets claimed status on server.
function Coin.setClaimed_server(self: ClassType, isClaimed: boolean)
    if self._server_claimed ~= isClaimed then
        self._server_claimed = isClaimed
        self:updateVisual_server()
    end
end

-- Sets claimed status on client.
function Coin.setClaimed_player(self: ClassType, player: Player, isClaimed: boolean)
    if self._client_player_claimed[player] ~= isClaimed then
        self._client_player_claimed[player] = isClaimed
        if isClaimed and self._isServerSided then
            self:setClaimed_server(isClaimed)
        end
        if not self._isServerSided then
            self:updateVisual_player(player)
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
        result = self._server_claimed
    end
    if not result then
        result = self._client_player_claimed[player] == true
    end
	return result
end

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


----- Visual functions -----

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
    if self._spinThread then
        task.cancel(self._spinThread)
    end
	self._spinThread = task.defer(function()
        local primaryPart = self:getOrCreatePrimaryPart()
        while true do
            -- Get primary part position (similar to :GetPivot() but better for type checking)
            local position = primaryPart.Position

            -- Set rotation
            local rotationVector = rotationalVelocity * time()
            local targetCFrame = CFrame.Angles(rotationVector.X, rotationVector.Y, rotationVector.Z) + position
            if self._coinInstance:IsA("BasePart") then
                self._coinInstance:PivotTo(targetCFrame)
            elseif self._coinInstance:IsA("Model") then
                self._coinInstance:PivotTo(targetCFrame)
                self._coinInstance:GetPivot()
            end

            -- Small delay (equivalent to RunService.Heartbeat:Wait())
            task.wait()
        end
    end)
end

-- Updates coin's appearance based on claimed value (on server).
function Coin.updateVisual_server(self: ClassType)
    if self:checkClaimed_server() then
        Constants.CoinRemoteEvent:FireAllClients(Constants.updateTransparencyModeString, self._coinParts, 1)
    else
        Constants.CoinRemoteEvent:FireAllClients(Constants.setDefaultTransparencyModeString, self._coinParts)
    end
end

-- Updates coin's appearance based on claimed value (on player).
function Coin.updateVisual_player(self: ClassType, player: Player)
    if self:checkClaimed_player(player) then
        Constants.CoinRemoteEvent:FireClient(player, Constants.updateTransparencyModeString, self._coinParts, 1)
    else
        Constants.CoinRemoteEvent:FireClient(player, Constants.setDefaultTransparencyModeString, self._coinParts)
    end
end


----- Sound functions -----

-- Plays a sound from the coin on server.
function Coin.playSound_server(self: ClassType, sound: Sound)
    Constants.CoinRemoteEvent:FireAllClients(Constants.playSoundFromPartModeString, self:getOrCreatePrimaryPart(), sound)
end

-- Plays a sound from the coin on player.
function Coin.playSound_player(self: ClassType, player: Player, sound: Sound)
    Constants.CoinRemoteEvent:FireClient(player, Constants.playSoundFromPartModeString, self:getOrCreatePrimaryPart(), sound)
end


----- Clean up -----

function Coin.removePlayer(self: ClassType, player: Player)
    self._client_player_claimed[player] = nil
end

function Coin.removePlayersThatLeft(self: ClassType)
    local player_inServer = {}
    local playersToRemove = {}
    for _, player in Players:GetPlayers() do
        player_inServer[player] = true
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
    if self._spinThread then
        task.cancel(self._spinThread)
    end
    self._spinThread = nil

    table.clear(self._client_player_claimed)
end


---------- Return module ----------

table.freeze(Coin)
return Coin
