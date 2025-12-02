--!strict


---------- Services ----------

local TweenService = game:GetService("TweenService")


---------- Imports ----------

local InstanceProperty = require(script:WaitForChild("InstanceProperty"))


---------- Constants ----------

local Constants = {}

Constants.transparencyPropertyNames = {
    "Transparency",
    "BackgroundTransparency",
    "TextTransparency",
    "TextStrokeTransparency",
    "ImageTransparency",
}
Constants.attributePrefix = "Coin_" .. "UIUtil_"

table.freeze(Constants)


---------- Local functions ----------

local getAttributeName
local getDescendantsWithContainer
local canTweenProperty
local storeTransparencyValues
local getTransparencyTweenObject

local fade
local setTransparency
local resetTransparency


----- Helper functions -----

getAttributeName = function(str: string)
    return Constants.attributePrefix .. str
end

getDescendantsWithContainer = function(container: Instance)
    local result = container:GetDescendants()
    table.insert(result, container)
    return result
end

canTweenProperty = function(object: Instance, property: string)
    local isPropertyANumber = InstanceProperty.getPropertyType(object, property) == "number"
    local isDeprecatedTransparency = (property == "Transparency" and object:IsA("GuiObject"))
    return isPropertyANumber and not isDeprecatedTransparency
end

storeTransparencyValues = function(object: Instance)
    local attributeName
    for _, property in Constants.transparencyPropertyNames do
        if canTweenProperty(object, property) then
            attributeName = getAttributeName(property)
            if not object:GetAttribute(attributeName) then
                object:SetAttribute(attributeName, InstanceProperty.getProperty(object, property))
            end
        end
    end
end

getTransparencyTweenObject = function(object: Instance, tweenInfo: TweenInfo, fadeIn: boolean): Tween?
    local propertyTable = {}
    local attributeName
    local targetTransparency
    local result
    for _, property in Constants.transparencyPropertyNames do
        if canTweenProperty(object, property) then
            targetTransparency = 1
            if fadeIn then
                attributeName = getAttributeName(property)
                targetTransparency = tonumber(object:GetAttribute(attributeName)) or 1
            end
            propertyTable[property] = targetTransparency
        end
    end
    if next(propertyTable) then
        result = TweenService:Create(object, tweenInfo, propertyTable)
    end
    return result
end


----- Gui transparency functions -----

-- Fade the transparency of all guis in a container
fade = function(container: Instance, tweenInfo: TweenInfo, fadeIn: boolean, waitForTween: boolean)
    local tweenObjects = {}
    local createdTween
    for _, object in getDescendantsWithContainer(container) do
        storeTransparencyValues(object)
        createdTween = getTransparencyTweenObject(object, tweenInfo, fadeIn)
        if createdTween then
            table.insert(tweenObjects, createdTween)
        end
    end
    for _, tween in tweenObjects do
        task.defer(function()
            tween:Play()
        end)
    end
    if waitForTween and next(tweenObjects) ~= nil then
        tweenObjects[1].Completed:Wait()
    end
end

-- Set the transparency of all guis in a container
setTransparency = function(container: Instance, transparency: number)
    for _, object in getDescendantsWithContainer(container) do
        storeTransparencyValues(object)
        for _, property in Constants.transparencyPropertyNames do
            if canTweenProperty(object, property) then
                InstanceProperty.setProperty(object, property, transparency)
            end
        end
    end
end

-- Reset the transparency of all guis in a container
resetTransparency = function(container: Instance)
    local targetTransparency
    for _, object in getDescendantsWithContainer(container) do
        storeTransparencyValues(object)
        for _, property in Constants.transparencyPropertyNames do
            if canTweenProperty(object, property) then
                targetTransparency = object:GetAttribute(getAttributeName(property))
                InstanceProperty.setProperty(object, property, targetTransparency)
            end
        end
    end
end


---------- Module ----------

local module = {}


----- Module fields -----

module.fade = fade
module.setTransparency = setTransparency
module.resetTransparency = resetTransparency


---------- Return module ----------

table.freeze(module)
return module
