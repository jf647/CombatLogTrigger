--
-- $Date $Revision$
--

CLT = LibStub("AceAddon-3.0"):NewAddon(
    "CombatLogTrigger",
    "AceConsole-3.0",
    "AceEvent-3.0",
)

-- interesting affiliations and triggers
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

-- handlers
local handlers = {
    "SPELL_CAST_SUCCESS" = CLT:Handle_SPELL_CAST_SUCCESS,
    "SPELL_AURA_APPLIED" = CLT:Handle_SPELL_AURA_APPLIED,
    "SPELL_AURA_REMOVED" = CLT:Handle_SPELL_AURA_REMOVED,
    "SPELL_INTERRUPT" = CLT:Handle_SPELL_INTERRUPT,
    "SPELL_MISSED" = CLT:Handle_SPELL_MISSED,
    "SPELL_SUMMON" = CLT:Handle_SPELL_SUMMON,
    "SPELL_DISPEL" = CLT:Handle_SPELL_DISPEL,
    "UNIT_DESTROYED" = CLT:Handle_UNIT_DESTROYED,
}

-- debug output
function CLT:Debug(...)
    if CLT_DB.debug then
        self:Print("DEBUG: ", ...)
    end
end

-- enable addon
function CLT:OnEnable()
    if CLT_DB.enabled then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:Print("CombatLogTrigger activated with " .. #(CLT_Triggers) .. " triggers")
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
        t = CLT_Triggers[i]
        if CLTDB.debug then
            if t.spellid ~= nil then
                self:Debug("trigger ", i, ": ", t.event, ", ", t.spellid, ", ", t.channel, ", ", t.message)
            else
                self:Debug("trigger ", i, ": ", t.event, ", ", t.channel, ", ", t.message)
            end
        end
        if t.affiliation = "mine" then
            if affil[filterMine] = nil then
                self:Debug("adding filterMine to interesting affiliations")
                affil[filterMine] = 1
            end
            self:Debug("adding trigger ", i, " to filterMine events")
            table.insert(aff_to_trigger[filterMine], i)
        else if t.affiliation = "myGuardian" then 
            if affil[filterMyGuardian] = nil then
                self:Debug("adding filterMyGuardian to interesting affiliations")
                affil[filterMyGuardian] = 1
            end
            self:Debug("adding trigger ", i, " to filterMyGuardian events")
            table.insert(aff_to_trigger[filterMyGuardian], i)
        else if t.affiliation = "enemy" then
            if affil[filterEnemy] = nil then
                self:Debug("adding filterEnemy to interesting affiliations")
                affil[filterEnemy] = 1
            end
            self:Debug("adding trigger ", i, " to filterEnemy events")
            table.insert(aff_to_trigger[filterEnemy], i)
       end
    end
    for k, v in affil do
        table.insert(aff, k)
    end
end

-- handle combat log event
function CLT:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
    local ev, _, _, sName, sFlags, _, dName, dFlags = select(2, ...)
    for i, mask in ipairs(aff) do
        if bit_band(sFlags, mask) or bit_band(dFlags, mask) then
            for i, triggernum in ipairs(aff_to_trigger[aff]) do
                t = CLT_Triggers[triggernum]
                if string_find(ev, t.event) ~= nil then
                    handlers[ev](ev, ...)
                end
            end
        end
    end
end

-- SPELL_CAST_SUCCESS  spellId, spellName, spellSchool
function CLT:Handle_SPELL_CAST_SUCCESS(ev, ...)
    
end

-- SPELL_AURA_APPLIED  spellId, spellName, spellSchool, auraType
function CLT:Handle_SPELL_AURA_APPLIED(ev, ...)
    
end

-- SPELL_AURA_REMOVED  spellId, spellName, spellSchool, auraType
function CLT:Handle_SPELL_AURA_REMOVED(ev, ...)
    
end

-- SPELL_INTERRUPT     spellId, spellName, spellSchool, extraSpellId, extraSpellName, extraSchool
function CLT:Handle_SPELL_INTERRUPT(ev, ...)
    
end

-- SPELL_MISSED        spellId, spellName, spellSchool, missType, amountMissed
function CLT:Handle_SPELL_MISSED(ev, ...)
    
end

-- SPELL_SUMMON        spellId, spellName, spellSchool
function CLT:Handle_SPELL_SUMMON(ev, ...)
    
end

-- SPELL_DISPEL        spellId, spellName, spellSchool, extraSpellId, extraSpellName, extraSchool, auraType
function CLT:Handle_SPELL_DISPEL_SPELL_STOLEN(ev, ...)
    
end

-- UNIT_DESTROYED
function CLT:Handle_UNIT_DESTROYED(ev, ...)
    
end

--
-- EOF
