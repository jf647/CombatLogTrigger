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

-- group size
local grouptype = 0

-- per-event variables to avoid re-allocating in-scope
local ev, sName, sFlags, dName, dFlags, spellId, spellName, espellId, espellName

-- convenience functions
local bit_band = _G.bit.band
local string_find = string.find
local string_gsub = string.gsub

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
function CLT:Debug(...)
    if CLT_DB.debug then
        self:Print("DEBUG: ", ...)
    end
end

-- enable addon
function CLT:OnEnable()
    if CLT_DB.enabled then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:RegisterEvent("PARTY_MEMBERS_CHANGED", "UpdateGroupType")
        self:RegisterEvent("RAID_ROSTER_UPDATE", "UpdateGroupType")
        self:UpdateGroupType()
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
    local affil = {}
    for 1, #(CLT_Triggers)
        t = CLT_Triggers[i]
        if CLTDB.debug then
            if t.spellId ~= nil then
                self:Debug("trigger ", i, ": ", t.event, ", ", t.spellId, ", ", t.channel, ", ", t.message)
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
        elseif t.affiliation = "myGuardian" then 
            if affil[filterMyGuardian] = nil then
                self:Debug("adding filterMyGuardian to interesting affiliations")
                affil[filterMyGuardian] = 1
            end
            self:Debug("adding trigger ", i, " to filterMyGuardian events")
            table.insert(aff_to_trigger[filterMyGuardian], i)
        elseif t.affiliation = "enemy" then
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

-- handle party/raid size changes
function CLT:UpdateGroupType()
    if GetNumRaidMembers > 0 then
        grouptype = 2
    elseif GetNumPartyMembers > 0 then
        grouptype = 1
    else
        grouptype = 0
    end
end

-- handle combat log event
function CLT:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
    ev, _, _, sName, sFlags, _, dName, dFlags, spellId, spellName, _, espellId, espellName = select(2, ...)
    for i, mask in ipairs(aff) do
        if bit_band(sFlags, mask) or bit_band(dFlags, mask) then
            for i, triggernum in ipairs(aff_to_trigger[aff]) do
                t = CLT_Triggers[triggernum]
                -- break out early if we have a group type constraint that doesn't match
                if t.groupType ~= nil then if t.grouptype ~= grouptype then return end
                -- does the event match?
                if t.event = ev then
                    -- does the spellId or spellName match? 
                    if t.spellId ~= nil and t.spellId = spellId
                       or
                       t.spellName ~= nil and t.spellName = spellName
                       or
                       t.anySpell ~= nil
                    then
                        self:Report(t)
                    end
                end
            end
        end
    end
end

-- report an event to a channel
function CLT:Report(t)

 
    -- format the message
    local message = string_gsub(t.message, "*ev", ev)
    message = string_gsub(message, "*src", sName)
    message = string_gsub(message, "*tgt", dName)
    message = string_gsub(message, "*sid", spellId)
    message = string_gsub(message, "*sname", spellName)
    if espellId ~= nil then
        message = string_gsub(message, "*espellId", espellId)
        message = string_gsub(message, "*espellName", espellName)
    end

   -- format the channel
    local whisper_dest
    if t.channel = "WHISPER" then
        whisper_dest = string_gsub(t.whisper_dest, "*src", sName)
        whisper_dest = string_gsub(whisper_dest, "*tgt", dName)
    end
    
    -- handle auto channel selection
    local channel = t.channel
    if channel = "AUTO" then
        if grouptype = 2 then
            channel = "RAID"
        elseif grouptype = 1 then
            channel = "PARTY"
        else
            channel = "SELF"
        end
    end
    
    -- output the message
    if channel = "WHISPER" then
        SendChatMessage(message, "WHISPER", nil, whisper_dest)
    elseif channel = "SELF" then
        self:Print(message)
    else
        SendChatMessage(message, channel)
    end
    
end

--
-- EOF
