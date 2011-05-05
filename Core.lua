--
-- $Date $Revision$
--

CLT = LibStub("AceAddon-3.0"):NewAddon(
    "CombatLogTrigger",
    "AceConsole-3.0",
    "AceEvent-3.0"
)

-- interesting affiliations and triggers
local aff, aff_to_trigger

-- group size
local grouptype = 0

-- per-event variables to avoid re-allocating in-scope
local ev, sName, sFlags, dName, dFlags, spellId, spellName, espellId, espellName

-- convenience functions
local bit_band = _G.bit.band
local string_find = string.find
local string_gsub = string.gsub
local string_format = string.format

-- convenience bitmasks
local filterMine = _G.bit.bor(
    COMBATLOG_OBJECT_AFFILIATION_MINE,
	COMBATLOG_OBJECT_REACTION_FRIENDLY,
	COMBATLOG_OBJECT_CONTROL_PLAYER,
	COMBATLOG_OBJECT_TYPE_PLAYER,
	COMBATLOG_OBJECT_TYPE_PET
)
local sfilterMine = string_format("%d", filterMine)
local filterMyGuardian = _G.bit.bor(
    COMBATLOG_OBJECT_AFFILIATION_MINE,
    COMBATLOG_OBJECT_REACTION_FRIENDLY,
    COMBATLOG_OBJECT_CONTROL_PLAYER,
    COMBATLOG_OBJECT_TYPE_GUARDIAN
)
local sfilterMyGuardian = string_format("%d", filterMyGuardian)
local filterEnemy = _G.bit.bor(
    COMBATLOG_OBJECT_AFFILIATION_OUTSIDER,
    COMBATLOG_OBJECT_REACTION_HOSTILE,
    COMBATLOG_OBJECT_CONTROL_NPC,
    COMBATLOG_OBJECT_TYPE_NPC,
    COMBATLOG_OBJECT_TYPE_PET,
    COMBATLOG_OBJECT_TYPE_GUARDIAN,
    COMBATLOG_OBJECT_TYPE_OBJECT
)
local sfilterEnemy = string_format("%d", filterEnemy)

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
    self:BuildInteresting()
end

-- disable addon
function CLT:OnDisable()
    if CLT_DB.enabled then
        self:UnregisterAllEvents()
        self:Print("CombatLogTrigger deactivated")
    end
end

-- build a list of interesting affiliations and events
function CLT:BuildInteresting()
    local affil = {}
	aff = {}
	aff_to_trigger = {}
    for i = 1, #(CLT_Triggers) do
        t = CLT_Triggers[i]
        if CLT_DB.debug then
            if t.spellId ~= nil then
                self:Debug("trigger ", i, ":", t.event, ",", t.spellId, ",", t.channel, ",", t.message)
            else
                self:Debug("trigger ", i, ":", t.event, ",", t.channel, ",", t.message)
            end
        end
        if t.affiliation == "mine" then
            if affil.filterMine == nil then
                self:Debug("adding filterMine to interesting affiliations")
                affil.filterMine = 1
				table.insert(aff, filterMine)
				aff_to_trigger[sfilterMine] = {}
            end
            self:Debug("adding trigger ", i, " to filterMine events")
            table.insert(aff_to_trigger[sfilterMine], i)
			self:Debug("filterEnemy now has", #(aff_to_trigger[sfilterMine]), "triggers")
        elseif t.affiliation == "myGuardian" then 
            if affil.filterMyGuardian == nil then
                self:Debug("adding filterMyGuardian to interesting affiliations")
                affil.filterMyGuardian = 1
				table.insert(aff, filterMyGuardian)
				aff_to_trigger[sfilterMyGuardian] = {}
            end
            self:Debug("adding trigger ", i, " to filterMyGuardian events")
            table.insert(aff_to_trigger[sfilterMyGuardian], i)
			self:Debug("filterEnemy now has", #(aff_to_trigger[sfilterMyGuardian]), "triggers")
        elseif t.affiliation == "enemy" then
            if affil.filterEnemy == nil then
                self:Debug("adding filterEnemy to interesting affiliations")
                affil.filterEnemy = 1
				table.insert(aff, filterEnemy)
				aff_to_trigger[sfilterEnemy] = {}
            end
            self:Debug("adding trigger ", i, " to filterEnemy events")
            table.insert(aff_to_trigger[sfilterEnemy], i)
			self:Debug("filterEnemy now has", #(aff_to_trigger[sfilterEnemy]), "triggers")
       end
    end
end

-- handle party/raid size changes
function CLT:UpdateGroupType()
    if GetNumRaidMembers() > 0 then
        grouptype = 2
    elseif GetNumPartyMembers() > 0 then
        grouptype = 1
    else
        grouptype = 0
    end
end

-- handle combat log event
function CLT:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
    ev, _, _, sName, sFlags, _, dName, dFlags, spellId, spellName, _, espellId, espellName = select(2, ...)
    for i, aff in ipairs(aff) do
        if bit_band(sFlags, aff) or bit_band(dFlags, aff) then
			saff = string_format("%d", aff)
            for i, triggernum in ipairs(aff_to_trigger[saff]) do
                t = CLT_Triggers[triggernum]
				self:Debug("considering trigger", i, t.event, t.name)
                -- break out early if we have a group type constraint that doesn't match
                if t.grouptype ~= nil then
					self:Debug("considering grouptype match between", t.grouptype, "and", grouptype)
					if t.grouptype ~= grouptype then
						self:Debug("grouptype match failed")
						return
					end
				end
                -- does the event match?
                if t.event == ev then
					-- source / dest match
					if t.src ~= nil then
						self:Debug("considering src match between", t.src, "and", sName)
						if t.src ~= sName then
							self:Debug("src match failed")
							return
						end
					end
					if t.dst ~= nil then
						self:Debug("considering dst match between", t.dst, "and", dName)
						if t.dst ~= dName then
							self:Debug("dst match failed")
							return
						end
					end
                    -- does the spellId or spellName match? 
                    if t.spellId ~= nil then
						self:Debug("considering spellid match between", t.spellId, "and", spellId)
						if t.spellId == spellId then
							self:Debug("reporting a spellid match on", spellId, "/", spellId)
							self:Report(t)
						end
					elseif t.spellName ~= nil then
						self:Debug("considering spellid match between", t.spellId, "and", spellId)
						if t.spellName == spellName then
							self:Debug("reporting a spellname match on", spellId, "/", spellId)
							self:Report(t)
						end
					elseif t.anyspell ~= nil then
						self:Debug("reporting an anyspell match on", spellId, "/", spellId)
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
    message = string_gsub(message, "*slink", GetSpellLink(spellId))
    if espellId ~= nil then
        message = string_gsub(message, "*esid", espellId)
        message = string_gsub(message, "*esname", espellName)
        message = string_gsub(message, "*eslink", GetSpellLink(espellId))
    end

    -- handle auto channel selection
    local channel = t.channel
    if channel == "AUTO" then
        if grouptype == 2 then
            channel = "RAID"
        elseif grouptype == 1 then
            channel = "PARTY"
        else
            channel = "SELF"
        end
    end
    
    -- output the message
    if channel == "WHISPER" then
        local whisper_dest
        whisper_dest = string_gsub(t.whisper_dest, "*src", sName)
        whisper_dest = string_gsub(whisper_dest, "*tgt", dName)
        SendChatMessage(message, "WHISPER", nil, whisper_dest)
    elseif channel == "SELF" then
        self:Print(message)
    else
        SendChatMessage(message, channel)
    end
	
	-- if we're doing a spellid trace, output that to the chat frame
	if t.reportspellid then
		self:Print("spellId for", GetSpellLink(spellId), "is", spellId)
		if espellId ~= nil then
			self:Print("spellId for", GetSpellLink(espellId), "is", espellId)
		end
	end
    
end

--
-- EOF
