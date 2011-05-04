--
-- $Date $Revision$
--

CLT = LibStub("AceAddon-3.0"):NewAddon(
    "CombatLogTrigger",
    "AceConsole-3.0",
    "AceEvent-3.0",
)

local aff, aff_to_triggers

-- convenience functions
local bit_band = _G.bit.band
local string_find = string.find

-- convenience bitmasks
local filterMine = _G.bit.bor(
    COMBATLOG_OBJECT_AFFILIATION_MINE,
	COMBATLOG_OBJECT_REACTION_FRIENDLY,
	COMBATLOG_OBJECT_CONTROL_PLAYER,
	COMBATLOG_OBJECT_TYPE_PLAYER,
	COMBATLOG_OBJECT_TYPE_PET,
)
local filterMyGuardian = _G.bit.bor(
    COMBATLOG_OBJECT_AFFILIATION_MINE,
    COMBATLOG_OBJECT_REACTION_FRIENDLY,
    COMBATLOG_OBJECT_CONTROL_PLAYER,
    COMBATLOG_OBJECT_TYPE_GUARDIAN,
)
local filterEnemy = _G.bit.bor(
    COMBATLOG_OBJECT_AFFILIATION_OUTSIDER,
    COMBATLOG_OBJECT_REACTION_HOSTILE,
    COMBATLOG_OBJECT_CONTROL_NPC,
    COMBATLOG_OBJECT_TYPE_NPC,
    COMBATLOG_OBJECT_TYPE_PET,
    COMBATLOG_OBJECT_TYPE_GUARDIAN,
    COMBATLOG_OBJECT_TYPE_OBJECT,
)

-- debug output
function CLT:Debug(text)

end

-- enable addon
function CLT:OnEnable()
    if CLT_DB.enabled then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:Print("CombatLogTrigger activated with " .. #(CLT_Triggers) .. " rules")
    end
    aff = {}
    aff_to_triggers = {
        filterMine = {},
        filterMyGuardian = {},
        enemy = {},
    }
    self:BuildInteresting()
end

-- disable addon
function CLT:OnDisable()
    if CLT_DB.enabled then
        self:UnregisterAllEvents()
        self:Print("CombatLogTrigger deactivated")
    end
    aff = {}
    aff_to_triggers = {
        filterMine = {},
        filterMyGuardian = {},
        enemy = {},
    }
end

-- build a list of interesting affiliations and events
function CLT:BuildInteresting()
    local numTriggers = #(CLT_Triggers)
    local affil = {}
    for 1, numTriggers do
        if CLT_Triggers[i].affiliation = "mine" then
            affil[filterMine] = 1
            table.insert(aff_to_trigger[filterMine], i)
        else if CLT_Triggers[i].affiliation = "myGuardian" then 
            affil[filterMyGuardian] = 1
            table.insert(aff_to_trigger[myGuardian], i)
        else if CLT_Triggers[i].affiliation = "enemy" then
            affil[enemy] = 1
            table.insert(aff_to_trigger[enemy], i)
       end
    end
    for k, v in affil do
        table.insert(aff, k)
    end
end

-- handle combat log event
function CLT:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
    local ev, _, sGUID, sName, sFlags, dGUID, dName, dFlags = select(2, ...)
    for i, mask in ipairs(aff) do
        if bit_band(sFlags, mask) or bit_band(dFlags, mask) then
            for i, rulenum in ipairs(aff_to_trigger[aff]) do
                rule = CLT_Triggers[rulenum]
                if string_find(rule.event) ~= nil then
                    
                end
            end
        end
    end
end

--
-- EOF
