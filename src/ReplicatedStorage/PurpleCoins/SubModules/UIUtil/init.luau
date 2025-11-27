--!strict

---------- Module ----------

local module = {}


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


---------- Helper functions ----------

local getAttributeName
local getDescendantsWithContainer
local canTweenProperty
local storeTransparencyValues
local createTransparencyTweenObject

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

createTransparencyTweenObject = function(object: Instance, tweenInfo: TweenInfo, fadeIn: boolean)
    local propertyTable = {}
    local attributeName
    local targetTransparency
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
    return TweenService:Create(object, tweenInfo, propertyTable)
end


---------- Gui transparency functions ----------

local fade
local setTransparency
local resetTransparency

-- Fade the transparency of all guis in a container
fade = function(container: Instance, tweenInfo: TweenInfo, fadeIn: boolean, waitForTween: boolean)
    local tweenObjects = {}
    for _, object in getDescendantsWithContainer(container) do
        storeTransparencyValues(object)
        table.insert(tweenObjects, createTransparencyTweenObject(object, tweenInfo, fadeIn))
    end
    for _, tween in tweenObjects do
        tween:Play()
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


---------- Module fields ----------

module.fade = fade
module.setTransparency = setTransparency
module.resetTransparency = resetTransparency


---------- Return module ----------

return module
