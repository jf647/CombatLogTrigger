--
-- $Date $Revision$
--

CLT = LibStub("AceAddon-3.0"):NewAddon(
    "CombatLogTrigger",
    "AceConsole-3.0",
    "AceEvent-3.0",
)

local aff = {}
local aff_to_triggers = {}

-- convenience bitmasks
local filterMe = _G.bit.bor(
    COMBATLOG_OBJECT_AFFILIATION_MINE,
	COMBATLOG_OBJECT_REACTION_FRIENDLY,
	COMBATLOG_OBJECT_CONTROL_PLAYER,
	COMBATLOG_OBJECT_TYPE_PLAYER,
)
local filterMyPet = _G.bit.bor(
    COMBATLOG_OBJECT_AFFILIATION_MINE,
	COMBATLOG_OBJECT_REACTION_FRIENDLY,
	COMBATLOG_OBJECT_CONTROL_PLAYER,
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

-- enable addon
function CLT:OnEnable()
    if CLT_DB.enabled then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:Print("CombatLogTrigger activated with " .. #(CLT_Triggers) .. " rules")
    end
    self:BuildInteresting()
end

-- disable addon
function CLT:OnDisable()
    if CLT_DB.enabled then
        self:UnregisterAllEvents()
        self:Print("CombatLogTrigger deactivated")
    end
    aff = {}
    aff_to_triggers = {}
end

-- handle combat log event
function CLT:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
    local ev, _, sGUID, sName, sFlags, dGUID, dName, dFlags = select(2, ...)
    
end

-- build a list of interesting 
function CLT:BuildInteresting()
    
end

--
-- EOF
