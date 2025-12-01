--!strict

-- Get Challenges


---------- Imports ----------

local _Constants = require(script.Parent._Constants)


---------- Constants ----------

local Constants = {}
Constants.challengesStorage = script.Parent.ChallengesStorage

table.freeze(Constants)


---------- Local functions ----------

local getChallengeModules


----- Challenge modules -----

getChallengeModules = function(): {[string]: _Constants.ChallengeModule}
    local result = {}
    local challengeModule
    for _, object in Constants.challengesStorage:GetChildren() do
        local isValidModule = true
        isValidModule = isValidModule and object:GetAttribute("Ignore") ~= true
        if object:IsA("ModuleScript") and isValidModule then
            challengeModule = require(object) :: _Constants.ChallengeModule
            result[challengeModule.getConfigs()._challengeId] = challengeModule
        end
    end
    return result
end


---------- Module ----------

local Module = {}


----- Module fields -----

Module.challengeModules = getChallengeModules()
table.freeze(Module.challengeModules)


---------- Return module ----------

table.freeze(Module)
return Module
