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

-- state variables
local grouptype = 0
local spec = "spec1"
local incombat = false
local playername

-- per-event variables to avoid re-allocating in-scope
local ev, sName, sFlags, dName, dFlags, spellId, spellName, espellId, espellName, doReport

-- convenience functions
local bit_bor = _G.bit.bor
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

-- party type bitmasks
local gtSolo  = 0x01
local gtParty = 0x02
local gtRaid  = 0x04
local gtBg    = 0x08
local gtArena = 0x10

-- debug output
function CLT:Debug(...)
    if CLT_DB.debug then
        self:Print("DEBUG: ", ...)
    end
end

-- enable addon
function CLT:OnEnable()
    if CLT_DB.enabled then
	
		-- get our name
		playername = UnitName("player")

        -- register the events we're interested in
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        self:RegisterEvent("PARTY_MEMBERS_CHANGED", "UpdateGroupType")
        self:RegisterEvent("RAID_ROSTER_UPDATE", "UpdateGroupType")
        self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "UpdateSpec")
        self:RegisterEvent("PLAYER_REGEN_DISABLED", "UpdateCombat", true)
        self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateCombat", false)

        -- set up initial state
        self:UpdateGroupType()
        self:UpdateSpec()
        self:UpdateCombat(false)

        -- register slash commands
        self:RegisterChatCommand("clt", "SlashCommand")

        self:Print("CombatLogTrigger activated")

    end
end

-- disable addon
function CLT:OnDisable()
    if CLT_DB.enabled then
        self:UnregisterAllEvents()
        self:UnregisterChatCommand("clt")
        self:Print("CombatLogTrigger deactivated")
    end
end

-- handle /clt slash command
-- /clt enable
-- /clt disable
-- /clt debug (toggle)
-- /clt list [1|2]
function CLT:SlashCommand(text)
    local command, rest = text:match("^(%S*)%s*(.-)$")
    if command == "enable" then
        if not self:IsEnabled() then
			self:Print("enabling")
            self:Enable()
			CLT_DB.enabled = true
        else
            self:Print("already enabled")
        end
    elseif command == "disable" then
        if self:IsEnabled() then
			self:Print("disabling")
            self:Disable()
			CLT_DB.enabled = false
        else
            self:Print("already disabled")
        end
    elseif command == "debug" then
        CLT_DB.debug = not CLT_DB.debug
		if CLT_DB.debug then
			self:Print("debug is now on")
		else
			self:Print("debug is now off")
		end
    elseif command == "list" then
		if rest == "" then
			self:ListTriggers(spec)
        elseif rest:match("^(1|2)$") then
            if CLT_Triggers["spec"..rest] ~= nil then
                self:ListTriggers("spec"..rest)
            else
                self:Printf("no triggers for spec%s", rest)
            end
        else
			self:Print("usage: /clt list [specnum]")
        end
    else
        self:Print("usage: /clt enable")
        self:Print("       /clt disable")
        self:Print("       /clt debug")
        self:Print("       /clt list [specnum]")
    end
end

-- handle party/raid size changes
function CLT:UpdateGroupType()
    grouptype = 0;
    local inInstance, instanceType = IsInInstance()
    if inInstance then
        if instanceType == "pvp" then
            grouptype = bit_bor(grouptype, gtBg)
        elseif instanceType == "raid" then
            grouptype = bit_bor(grouptype, gtArena)
        end
    end
    if GetNumRaidMembers() > 0 then
        grouptype = bit_bor(grouptype, gtRaid)
    elseif GetNumPartyMembers() > 0 then
        grouptype = bit_bor(grouptype, gtParty)
    else
        grouptype = bit_bor(grouptype, gtSolo)
    end
end

-- handle spec changes
function CLT:UpdateSpec()
    local specnum = GetActiveTalentGroup(false, false)
	spec = "spec" .. specnum
	--self:Debug("now in", spec)
    self:BuildInteresting()
end

-- handle combat state changes
function CLT:UpdateCombat(state)
    incombat = state
end

-- build a list of interesting affiliations and events
function CLT:BuildInteresting()
    local affil = {}
	aff = {}
	aff_to_trigger = {}
    for i = 1, #(CLT_Triggers[spec]) do
        t = CLT_Triggers[spec][i]
        if t.affiliation == "mine" then
            if affil.filterMine == nil then
                --self:Debug("adding filterMine to interesting affiliations")
                affil.filterMine = 1
				table.insert(aff, filterMine)
				aff_to_trigger[sfilterMine] = {}
            end
            --self:Debug("adding trigger ", i, " to filterMine events")
            table.insert(aff_to_trigger[sfilterMine], i)
        elseif t.affiliation == "myGuardian" then 
            if affil.filterMyGuardian == nil then
                --self:Debug("adding filterMyGuardian to interesting affiliations")
                affil.filterMyGuardian = 1
				table.insert(aff, filterMyGuardian)
				aff_to_trigger[sfilterMyGuardian] = {}
            end
            --self:Debug("adding trigger ", i, " to filterMyGuardian events")
            table.insert(aff_to_trigger[sfilterMyGuardian], i)
        elseif t.affiliation == "enemy" then
            if affil.filterEnemy == nil then
                --self:Debug("adding filterEnemy to interesting affiliations")
                affil.filterEnemy = 1
				table.insert(aff, filterEnemy)
				aff_to_trigger[sfilterEnemy] = {}
            end
            --self:Debug("adding trigger ", i, " to filterEnemy events")
            table.insert(aff_to_trigger[sfilterEnemy], i)
       end
    end
end


-- handle combat log event
function CLT:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
    ev, _, _, sName, sFlags, _, dName, dFlags, spellId, spellName, _, espellId, espellName = select(2, ...)
    for i, aff in ipairs(aff) do
        if bit_band(sFlags, aff) or bit_band(dFlags, aff) then
			saff = string_format("%d", aff)
            for i, triggernum in ipairs(aff_to_trigger[saff]) do
                t = CLT_Triggers[spec][triggernum]
				--self:Debug("considering trigger", i, t.event, t.name)
				-- assume we're going to report this event
				doReport = true
                -- break out early if we have a group mask constraint that doesn't match
                if t.groupmask ~= nil then
					--self:Debug("considering groupmask match between", t.groupmask, "and", grouptype)
					if bit_band(t.groupmask, grouptype) == t.groupmask then
						--self:Debug("groupmask match failed")
						doReport = false
					end
				end
				-- break out if we have a combat restriction and we're not in combat
				if doReport and t.incombat ~= nil then
				    --self:Debug("considering incombat match between", t.incombat, "and", incombat)
				    if t.incombat ~= incombat then
    				    --self:Debug("incombat match failed")
                        doReport = false
                    end
				end
                -- does the event match?
				--self:Debug("considering event match between", t.event, "and", ev)
                if doReport and t.event == ev then
					-- source / dest match
					if t.src ~= nil then
						--self:Debug("considering src match between", t.src, "and", sName)
						if doReport and t.src ~= sName then
							--self:Debug("src match failed")
							doReport = false
						end
					end
					if doReport and t.dst ~= nil then
						if t.notonself ~= nil then
							if t.dst == playername then
								--self:Debug("skipping report; dest is self and notonself flag is set")
								doReport = false
							end
						end
						--self:Debug("considering dst match between", t.dst, "and", dName)
						if doReport and t.dst ~= dName then
							--self:Debug("dst match failed")
							doReport = false
						end
					end
                    -- does the spellId or spellName match? 
                    if doReport then
                        if t.spellId ~= nil then
	    					--self:Debug("considering spellid match between", t.spellId, "and", spellId)
        						if t.spellId == spellId then
    							--self:Debug("reporting a spellid match on", spellName, "/", spellId)
    							self:Report(t)
    						end
    					elseif t.spellName ~= nil then
    						--self:Debug("considering spellname match between", t.spellName, "and", spellName)
    						if t.spellName == spellName then
    							--self:Debug("reporting a spellname match on", spellName, "/", spellId)
    							self:Report(t)
    						end
    					elseif t.spellApprox ~= nil then
    						--self:Debug("considering spellapprox match between", t.spellApprox, "and", spellName)
    						if string_find(t.spellApprox, spellName) then
    							--self:Debug("reporting a spellapprox match on", spellName, "/", spellId)
    							self:Report(t)
    						end
						elseif t.anyspell ~= nil then
    						--self:Debug("reporting an anyspell match on", spellName, "/", spellId)
    						self:Report(t)
	    				end
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

    -- general replacements
	message = string_gsub(message, "*src", sName)
    message = string_gsub(message, "*tgt", dName)
    message = string_gsub(message, "*sid", spellId)
    message = string_gsub(message, "*sname", spellName)
    message = string_gsub(message, "*slink", GetSpellLink(spellId))
	
	-- extra spell id
    if t.hasespellid ~= nil then
        message = string_gsub(message, "*esid", espellId)
        message = string_gsub(message, "*esname", espellName)
        message = string_gsub(message, "*eslink", GetSpellLink(espellId))
    end

	-- raid target replacement
	if t.replacert ~= nil then
		--self:Debug("trying to append raid marker")
		if bit_band(dFlags, COMBATLOG_OBJECT_SPECIAL_MASK) > 0 then
			--self:Debug("unit has raid marker")
			local rtid
			if bit_band(dFlags, COMBATLOG_OBJECT_RAIDTARGET1) > 0 then rtid = 1
			elseif bit_band(dFlags, COMBATLOG_OBJECT_RAIDTARGET2) > 0 then rtid = 2
			elseif bit_band(dFlags, COMBATLOG_OBJECT_RAIDTARGET3) > 0 then rtid = 3
			elseif bit_band(dFlags, COMBATLOG_OBJECT_RAIDTARGET4) > 0 then rtid = 4
			elseif bit_band(dFlags, COMBATLOG_OBJECT_RAIDTARGET5) > 0 then rtid = 5
			elseif bit_band(dFlags, COMBATLOG_OBJECT_RAIDTARGET6) > 0 then rtid = 6
			elseif bit_band(dFlags, COMBATLOG_OBJECT_RAIDTARGET7) > 0 then rdid = 7
			elseif bit_band(dFlags, COMBATLOG_OBJECT_RAIDTARGET8) > 0 then rtid = 8 end
			if rtid ~= nil then
				--self:Debug("raid marker number is", rtid)
				message = string_gsub(message, "*rtls", string_format(" {rt%d}", rtid))
				message = string_gsub(message, "*rtp", string_format("({rt%d})", rtid))
				--message = string_gsub(message, "*rt", string_format("{rt%d}", rtid))
			end
		end
	end
	
    -- auto channel selection
    local channel = t.channel
    if channel == "AUTO" then
		----self:Debug("bit_band(gtRaid, grouptype)", bit_band(gtRaid, grouptype))
        if bit_band(gtRaid, grouptype) == gtRaid then
			----self:Debug("selecting RAID")
            channel = "RAID"
        elseif bit_band(gtParty, grouptype) == gtParty then
			----self:Debug("selecting PARTY")
            channel = "PARTY"
        elseif bit_band(gtSolo, grouptype) == gtSolo then
			----self:Debug("selecting SELF")
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
		if t.hasespellid ~= nil then
			self:Print("spellId for", GetSpellLink(espellId), "is", espellId)
		end
	end
    
end

function CLT:ListTriggers(spec)
    self:Print("dumping triggers for", spec)
    for i = 1, #(CLT_Triggers[spec]) do
        t = CLT_Triggers[spec][i]
        self:Printf("Trigger %d: %s", i, t.name)
        for _, key in ipairs( { "event", "affiliation", "spellName", "spellApprox", "spellId", "src", "dst", "channel", "groupmask", "message" } ) do
            if t[key] ~= nil then
                self:Printf("  %s: %s", key, t[key])
            end
        end
        for _, key in ipairs( { "anyspell", "incombat", "notonself", "replacert", "hasespellid" } ) do
            if t[key] ~= nil then
				if t[key] then
					self:Printf("  %s: true", key)
				else
					self:Printf("  %s: false", key)
				end
            end
        end
        self:Print()
    end
end

--
-- EOF
