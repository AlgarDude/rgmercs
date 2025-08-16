local mq        = require('mq')
local Combat    = require('utils.combat')
local Config    = require('utils.config')
local Core      = require("utils.core")
local Targeting = require("utils.targeting")
local Casting   = require("utils.casting")
local Logger    = require("utils.logger")

return {
    _version              = "2.0 - Project Lazarus",
    _author               = "Algar",
    ['Modes']             = {
        'DPS',
    },
    ['ModeChecks']        = {
        IsHealing = function() return Config:GetSetting('DoHeals') end,
    },
    ['ItemSets']          = {
        ['Epic'] = {
            "Aurora, the Heartwood Blade",
            "Heartwood Blade",
        },
        ['OoW_Chest'] = {
            "Sunrider's Vest",
            "Bladewhipser Chain Vest of Journeys",
        },
    },
    ['AbilitySets']       = {
        ['PredatorBuff'] = { -- Groupv2 Atk Buff
            "Howl of the Predator",
            "Spirit of the Predator",
            "Call of the Predator",
            "Mark of the Predator",
        },
        ['StrengthHPBuff'] = { -- Groupv2 HP Type 2, Atk
            "Strength of the Hunter",
            "Strength of Tunare",
            "Strength of Nature", -- Single Target
        },
        ['SkinBuff'] = {          -- ST HP Type 1, small regen
            "Onyx Skin",
            "Natureskin",
            "Skin like Nature",
            "Skin like Diamond",
            "Skin like Steel",
            "Skin like Rock",
            "Skin like Wood",
        },
        ['EyeBuff'] = { -- Self Archery Buff
            "Eyes of the Hawk",
            "Eyes of the Owl",
            "Eyes of the Eagle",
            "Eagle Eye",
            "Falcon Eye",
            "Hawk Eye",
        },
        ['FireNukeT1'] = { -- ST Fire DD, Timer 1, 30s Recast
            "Hearth Embers",
            "Sylvan Burn",
            "Call of Flame",
            "Flaming Arrow",
        },
        ['ColdNukeT2'] = { -- ST Cold DD, Timer 2, 30s Recast
            "Frost Wind",
            "Icewind",
        },
        ['ColdNukeT3'] = { -- ST Cold DD, Timer 3, 30s Recast
            "Ancient: North Wind",
            "Frozen Wind",
        },
        ['FireNukeT4'] = { -- ST Fire DD, Timer 4, 30s Recast
            "Scorched Earth",
            "Ancient: Burning Chaos",
            "Brushfire",
            "Burning Arrow",
        },
        ["DDProc"] = {
            "Call of Lightning", --Double damage against humanoids on Laz
            "Cry of Thunder",
            "Call of Ice",
            "Call of Fire",
            "Call of Sky",
        },
        -- ["SummonedProc"] = {
        --     "Nature's Denial",
        --     "Nature's Rebuke",
        -- },
        ['SelfBuff'] = {
            "Ward of the Hunter",
            "Protection of the Wild",
            "Warder's Protection",
            "Nature's Precision", --Self ATK Buff, filler
            "Firefist",           --Self ATK Buff, filler
        },
        ['ArrowHail'] = {         -- DirAE multihit archery attack
            "Hail of Arrows",
        },
        ['FocusedHail'] = { -- ST multihit archery attack
            "Focused Hail of Arrows",
        },
        ['Dispel'] = {
            "Nature's Balance",
            "Annul Magic",
            "Nullify Magic",
            "Cancel Magic",
        },
        ['Heart'] = {
            "Heartslit",
            "Heartshot",
        },
        ['RegenBuff'] = {
            "Hunter's Vigor",
            "Regrowth",
            "Chloroplast",
        },
        ['CoatBuff'] = { -- Self DS
            "Briarcoat",
            "Bladecoat",
            "Thorncoat",
            "Spikecoat",
            "Bramblecoat",
            "Barbcoat",
            "Thistlecoat",
        },
        ['GuardBuff'] = { -- ST AC DS Buff
            "Guard of the Earth",
            "Call of the Rathe",
            "Call of Earth",
            "Riftwind's Protection",
        },
        ['HealSpell'] = {
            "Sylvan Water",
            "Sylvan Light",
            "Chloroblast",
            "Greater Healing",
            "Healing",
            "Light Healing",
            "Minor Healing",
            "Salve",
        },
        ['SwarmDot'] = {
            "Locust Swarm",
            "Drifting Death",
            "Fire Swarm",
            "Drones of Doom",
            "Swarm of Pain",
            "Stinging Swarm",
        },
        ['Snapkick'] = { -- 2-hit kick attack
            "Jolting Snapkicks",
        },
        ['Bullseye'] = {
            "Bullseye Discipline",
            "Trueshot Discipline",
        },
        ['ShieldDS'] = { -- ST Slot 1 DS
            "Shield of Briar",
            "Shield of Thorns",
            "Shield of Spikes",
            "Shield of Brambles",
            "Shield of Thistles",
        },
        ['FlameSnap'] = {
            "Flame Snap",
        },
        ['NatureProc'] = { -- ST Hade reduction defensive proc buff
            "Nature Veil",
        },
        -- ['DDStunProcBuff'] = {
        --     "Sylvan Call",
        -- },
        -- ['MaskBuff'] = { -- no stack with eyes of the hawk
        --     "Mask of the Stalker",
        -- },
        ['MoveBuff'] = {
            "Spirit of Eagle",
        },
        -- ['SelfWolfBuff'] = {
        --     "Feral Form",
        --     "Greater Wolf Form",
        --     "Wolf Form",
        -- },
        ['ColdResistBuff'] = {
            "Circle of Summer",
        },
        ['FireResistBuff'] = {
            "Circle of Winter",
        },
        ['SnareSpell'] = {
            "Earthen Shackles",
            "Earthen Embrace",
            "Ensnare",
            "Tangle",
            "Snare",
            "Tangling Weeds",
        },
        ['WeaponShield'] = {
            "Weapon Shield Discipline",
        },
        ['JoltSpell'] = {
            "Cinder Jolt",
            "Jolt",
        },
        -- ['JoltProcBuff'] = {
        --     "Jolting Blades",
        -- },
        -- ['ResistDisc'] = {
        --     "Resistant Discipline",
        -- },
    },
    ['HealRotationOrder'] = {
        { -- configured as a backup healer, will not cast in the mainpoint
            name = 'BigHealPoint',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoHeals') end,
            cond = function(self, target) return Targeting.BigHealsNeeded(target) end,
        },
    },
    ['HealRotations']     = {
        ['BigHealPoint'] = {
            {
                name = "HealSpell",
                type = "Spell",
            },
        },
    },
    ['RotationOrder']     = {
        {
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff() and Casting.AmIBuffable()
            end,
        },
        {
            name = 'GroupBuff',
            timer = 60,
            targetId = function(self)
                return Casting.GetBuffableGroupIDs()
            end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToBuff()
            end,
        },
        {
            name = 'Emergency',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return Targeting.GetXTHaterCount() > 0 and
                    (mq.TLO.Me.PctHPs() <= Config:GetSetting('EmergencyStart') or (Targeting.IsNamed(Targeting.GetAutoTarget()) and mq.TLO.Me.PctAggro() > 99))
            end,
        },
        { --Keep things from running
            name = 'Snare',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoSnare') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Core.OkayToNotHeal() and not Targeting.IsNamed(Targeting.GetAutoTarget()) and
                    Targeting.GetXTHaterCount() <= Config:GetSetting('SnareCount')
            end,
        },
        {
            name = 'Burn',
            state = 1,
            steps = 4,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Casting.BurnCheck()
            end,
        },
        {
            name = 'DPS',
            state = 1,
            steps = 1,
            doFullRotation = true,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat"
            end,
        },
        {
            name = 'Weaves',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and Targeting.AggroCheckOkay()
            end,
        },
    },
    ['HelperFunctions']   = {
        combatNav = function(forceMove)
            if not Config:GetSetting('DoMelee') and not mq.TLO.Me.AutoFire() then
                Core.DoCmd('/squelch face')
                Core.DoCmd('/autofire on')
            end

            if not Config:GetSetting('NavCircle') and Targeting.GetTargetDistance() <= 30 then
                Core.DoCmd("/stick %d moveback", Config:GetSetting('NavCircleDist'))
            end

            if not Config:GetSetting('NavCircle') and (Targeting.GetTargetDistance() >= 75 or forceMove) then
                Core.DoCmd("/squelch /nav id %d facing=backward distance=%d lineofsight=on", Config.Globals.AutoTargetID, Config:GetSetting('NavCircleDist'))
            end
        end,
        --function to make sure we don't have non-hostiles in range before we use AE damage or non-taunt AE hate abilities
        AETargetCheck = function(printDebug)
            local haters = mq.TLO.SpawnCount("NPC xtarhater radius 80 zradius 50")()
            local haterPets = mq.TLO.SpawnCount("NPCpet xtarhater radius 80 zradius 50")()
            local totalHaters = haters + haterPets
            if totalHaters < Config:GetSetting('AETargetCnt') or totalHaters > Config:GetSetting('MaxAETargetCnt') then return false end

            if Config:GetSetting('SafeAEDamage') then
                local npcs = mq.TLO.SpawnCount("NPC radius 80 zradius 50")()
                local npcPets = mq.TLO.SpawnCount("NPCpet radius 80 zradius 50")()
                if totalHaters < (npcs + npcPets) then
                    if printDebug then
                        Logger.log_verbose("AETargetCheck(): %d mobs in range but only %d xtarget haters, blocking AE damage actions.", npcs + npcPets, haters + haterPets)
                    end
                    return false
                end
            end

            return true
        end,
    },
    ['Rotations']         = {
        ['Burn']      = {
            {
                name = "Auspice of the Hunter",
                type = "AA",
            },
            {
                name = "Fundament: Third Spire of the Pathfinder",
                type = "AA",
            },
            {
                name = "Group Guardian of the Forest",
                type = "AA",
                cond = function(self, aaName, target)
                    return not mq.TLO.Me.Buff("Guardian of the Forest")()
                end,
            },
            {
                name = "Guardian of the Forest",
                type = "AA",
                cond = function(self, aaName, target)
                    return not mq.TLO.Me.Buff("Guardian of the Forest")()
                end,
            },
            { -- tuned on laz to be ranged exclusive
                name = "Outrider's Accuracy",
                type = "AA",
                cond = function(self, aaName, target)
                    return not Config:GetSetting('DoMelee')
                end,
            },
            {
                name = "Outrider's Attack",
                type = "AA",
            },
            { -- increases melee proc chance, but hate reduction applies to all spells
                name = "Imbued Ferocity",
                type = "AA",
                cond = function(self, aaName, target)
                    return Config:GetSetting('DoMelee') or mq.TLO.Me.PctAggro() >= 60
                end,
            },
            {
                name = "Intensity of the Resolute",
                type = "AA",
                cond = function(self, aaName)
                    return Config:GetSetting('DoVetAA')
                end,
            },
            {
                name = "Poison Arrows",
                type = "AA",
            },
            {
                name = "Bullseye",
                type = "Disc",
            },
            {
                name_func = function(self) return Config:GetSetting('ArrowBuffChoice') == 1 and "Scout's Mastery of Fire" or "Scout's Mastery of Ice" end,
                type = "AA",
            },
            {
                name_func = function(self) return Config:GetSetting('ArrowBuffChoice') == 1 and "Flaming Arrows" or "Frost Arrows" end,
                type = "AA",
                cond = function(self, aaName, target)
                    if mq.TLO.Me.Buff("Poison Arrows")() then return false end
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "JoltSpell",
                type = "Spell",
                load_cond = function(self) return Config:GetSetting('DoJoltSpell') end,
                cond = function(self, spell, target)
                    return Targeting.IsNamed(target) and mq.TLO.Me.PctAggro() > 80
                end,
            },
            {
                name = "Forceful Rejuvenation",
                type = "AA",
            },
        },
        ['Snare']     = {
            {
                name = "Entrap",
                type = "AA",
                load_cond = function() return Casting.CanUseAA("Entrap") end,
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName) and Targeting.MobHasLowHP(target)
                end,
            },
            {
                name = "SnareSpell",
                type = "Spell",
                load_cond = function() return not Casting.CanUseAA("Entrap") end,
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell) and Targeting.MobHasLowHP(target)
                end,
            },
        },
        ['Emergency'] = {
            {
                name = "Armor of Experience",
                type = "AA",
                cond = function(self, aaName)
                    if not Config:GetSetting('DoVetAA') then return false end
                    return mq.TLO.Me.PctHPs() < 35 and Targeting.IHaveAggro(100)
                end,
            },
            {
                name = "Protection of the Spirit Wolf",
                type = "AA",
            },
            {
                name = "Outrider's Evasion",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.IHaveAggro(100) and not mq.TLO.Me.ActiveDisc() == "Weapon Shield Discipline"
                end,
            },
            {
                name = "WeaponShield",
                type = "Discipline",
                cond = function(self, discName, target)
                    return Targeting.IHaveAggro(100) and not mq.TLO.Me.Song("Outrider's Evasion")
                end,
            },
            {
                name = "Blood Drinker's Coating",
                type = "Item",
                cond = function(self, itemName, target)
                    if not Config:GetSetting('DoCoating') then return false end
                    return Casting.SelfBuffItemCheck(itemName)
                end,
            },
        },
        ['DPS']       = {
            {
                name = "SwarmDot",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoSwarmDot') or (Config:GetSetting('DotNamedOnly') and not Targeting.IsNamed(target)) then return false end
                    return Casting.DotSpellCheck(spell) and Casting.HaveManaToDot()
                end,
            },
            {
                name = "Cold Snap",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "FireNukeT4",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "FireNukeT1",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "FlameSnap",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "ColdNukeT3",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "ColdNukeT2",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "ArrowHail",
                type = "Spell",
                cond = function(self, spell, target)
                    return self.ClassConfig.HelperFunctions.AETargetCheck(true)
                end,
            },
            {
                name = "FocusedHail",
                type = "Spell",
            },
            {
                name = "Heart",
                type = "Spell",
            },
        },
        ['Weaves']    = {
            {
                name = "Kick",
                type = "Ability",
            },
            {
                name = "Snapkick",
                type = "Disc",
            },
        },
        ['GroupBuff'] = {

            {
                name = "PredatorBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target) and not (Targeting.TargetIsMyself(target) and mq.TLO.Me.Buff("Ward of the Hunter")())
                end,
            },
            {
                name = "StrengthHPBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoStrengthBuff') then return false end
                    return Casting.GroupBuffCheck(spell, target) and not (Targeting.TargetIsMyself(target) and mq.TLO.Me.Buff("Ward of the Hunter")())
                end,
            },
            {
                name = "GuardBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.GroupBuffCheck(spell, target) and not (Targeting.TargetIsMyself(target) and mq.TLO.Me.Buff("Ward of the Hunter")())
                end,
            },
            {
                name = "RegenBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoRegenBuff') then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "ShieldDS",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoShieldDS') then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "ColdResistBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoColdResist') then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
            {
                name = "FireResistBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    if not Config:GetSetting('DoFireResist') then return false end
                    return Casting.GroupBuffCheck(spell, target)
                end,
            },
        },
        ['Downtime']  = {
            {
                name = "SelfBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "EyeBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "SkinBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "CoatBuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "DDProc",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name = "NatureProc",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.SelfBuffCheck(spell)
                end,
            },
            {
                name_func = function(self) return Config:GetSetting('ArrowBuffChoice') == 1 and "Flaming Arrows" or "Frost Arrows" end,
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
        },
    },
    ['SpellList']         = { -- New style spell list, gemless, priority-based. Will use the first set whose conditions are met.
        {
            name = "Default Mode",
            -- cond = function(self) return true end, --Code kept here for illustration, if there is no condition to check, this line is not required
            spells = {
                { name = "HealSpell",   cond = function(self) return Config:GetSetting('DoHeals') end, },
                { name = "SnareSpell",  cond = function(self) return Config:GetSetting('DoSnare') and not Casting.CanUseAA('Entrap') end, },
                { name = "SwarmDot",    cond = function(self) return Config:GetSetting('DoSwarmDot') end, },
                { name = "FireNukeT1", },
                { name = "FireNukeT4", },
                { name = "ColdNukeT2", },
                { name = "ColdNukeT3", },
                { name = "FlameSnap", },
                { name = "Heart", },
                { name = "ArrowHail", },
                { name = "FocusedHail", },
                { name = "JoltSpell",   cond = function(self) return Config:GetSetting('DoJoltSpell') end, },
                { name = "MoveBuff",    cond = function(self) return Config:GetSetting('DoMoveBuffs') end, },
            },
        },
    },
    ['PullAbilities']     = {
        -- {
        --     id = 'SlowSpell',
        --     Type = "Spell",
        --     DisplayName = function() return Core.GetResolvedActionMapItem('SlowSpell')() or "" end,
        --     AbilityName = function() return Core.GetResolvedActionMapItem('SlowSpell')() or "" end,
        --     AbilityRange = 150,
        --     cond = function(self)
        --         local resolvedSpell = Core.GetResolvedActionMapItem('SlowSpell')
        --         if not resolvedSpell then return false end
        --         return mq.TLO.Me.Gem(resolvedSpell.RankName.Name() or "")() ~= nil
        --     end,
        -- },
    },
    ['DefaultConfig']     = { --TODO: Condense pet proc options into a combo box and update entry conditions appropriately
        ['Mode']            = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 1,
            FAQ = "What is the difference between the modes?",
            Answer = "Rangers currently only have one Mode. This may change in the future.",
        },

        ['DoEpic']          = {
            DisplayName = "Do Epic",
            Category = "Pet Mgmt.",
            Index = 8,
            Tooltip = "Click your Epic Weapon.",
            Default = false,
            FAQ = "How do I use my Epic Weapon?",
            Answer = "Enable Do Epic to click your Epic Weapon.",
        },
        --Spells/Abilities
        ['DoHeals']         = {
            DisplayName = "Do Heals",
            Category = "Spells and Abilities",
            Index = 1,
            Tooltip = "Mem and cast your Mending spell.",
            Default = true,
            RequiresLoadoutChange = true,
            FAQ = "I want to help with healing, what can I do?",
            Answer = "Make sure you have [DoHeals] enabled.\n" ..
                "If you want to help with pet healing, enable [DoPetHealSpell].",
        },
        ['DoSwarmDot']      = {
            DisplayName = "Magic Dot",
            Category = "Damage",
            Index = 7,
            Tooltip = "Use your Swarm line of dots (magic damage, 54s duration).",
            Default = false,
            RequiresLoadoutChange = true,
            FAQ = "Why am I not using my magic (Swarm) dot?",
            Answer = "Make sure the dot is enabled in your class settings.",
        },
        ['DotNamedOnly']    = {
            DisplayName = "Only Dot Named",
            Category = "Spells and Abilities",
            Index = 4,
            Tooltip = "Any selected dot above will only be used on a named mob.",
            Default = true,
            FAQ = "Why am I not using my dots?",
            Answer = "Make sure the dot is enabled in your class settings and make sure that the mob is named if that option is selected.\n" ..
                "You can read more about named mobs on the RGMercs named tab (and learn how to add one on your own!)",
        },
        ['DoMoveBuffs']     = {
            DisplayName = "Do Movement Buffs",
            Category = "Spells and Abilities",
            Tooltip = "Cast Movement Spells/AA.",
            Default = false,
            FAQ = "Why am I spamming movement buffs?",
            Answer = "Some move spells freely overwrite those of other classes, so if multiple movebuffs are being used, a buff loop may occur.\n" ..
                "Simply turn off movement buffs for the undesired class in their class options.",
        },
        ['DoVetAA']         = {
            DisplayName = "Use Vet AA",
            Category = "Spells and Abilities",
            Index = 7,
            Tooltip = "Use Veteran AA's in emergencies or during Burn. (See FAQ)",
            Default = true,
            FAQ = "What Vet AA's does SHD use?",
            Answer = "If Use Vet AA is enabled, Intensity of the Resolute will be used on burns and Armor of Experience will be used in emergencies.",
        },
        --Combat
        ['DoAEDamage']      = {
            DisplayName = "Do AE Damage",
            Category = "Combat",
            Index = 1,
            Tooltip = "**WILL BREAK MEZ** Use AE damage Spells and AA. **WILL BREAK MEZ**\n" ..
                "This is a top-level setting that governs all AE damage, and can be used as a quick-toggle to enable/disable abilities without reloading spells.",
            Default = false,
            FAQ = "Why am I using AE damage when there are mezzed mobs around?",
            Answer = "It is not currently possible to properly determine Mez status without direct Targeting. If you are mezzing, consider turning this option off.",
        },
        ['AETargetCnt']     = {
            DisplayName = "AE Target Count",
            Category = "Combat",
            Index = 3,
            Tooltip = "Minimum number of valid targets before using AE Disciplines or AA.",
            Default = 2,
            Min = 1,
            Max = 10,
            FAQ = "Why am I using AE abilities on only a couple of targets?",
            Answer =
            "You can adjust the AE Target Count to control when you will use actions with AE damage attached.",
        },
        ['MaxAETargetCnt']  = {
            DisplayName = "Max AE Targets",
            Category = "Combat",
            Index = 4,
            Tooltip =
            "Maximum number of valid targets before using AE Spells, Disciplines or AA.\nUseful for setting up AE Mez at a higher threshold on another character in case you are overwhelmed.",
            Default = 5,
            Min = 2,
            Max = 30,
            FAQ = "How do I take advantage of the Max AE Targets setting?",
            Answer =
            "By limiting your max AE targets, you can set an AE Mez count that is slightly higher, to allow for the possiblity of mezzing if you are being overwhelmed.",
        },
        ['SafeAEDamage']    = {
            DisplayName = "AE Proximity Check",
            Category = "Combat",
            Index = 5,
            Tooltip = "Check to ensure there aren't neutral mobs in range we could aggro if AE damage is used. May result in non-use due to false positives.",
            Default = false,
            FAQ = "Can you better explain the AE Proximity Check?",
            Answer = "If the option is enabled, the script will use various checks to determine if a non-hostile or not-aggroed NPC is present and avoid use of the AE action.\n" ..
                "Unfortunately, the script currently does not discern whether an NPC is (un)attackable, so at times this may lead to the action not being used when it is safe to do so.\n" ..
                "PLEASE NOTE THAT THIS OPTION HAS NOTHING TO DO WITH MEZ!",
        },
        ['EmergencyStart']  = {
            DisplayName = "Emergency HP%",
            Category = "Combat",
            Index = 6,
            Tooltip = "Your HP % before we begin to use emergency mitigation abilities.",
            Default = 50,
            Min = 1,
            Max = 100,
            ConfigType = "Advanced",
            FAQ = "How do I use my Emergency Mitigation Abilities?",
            Answer = "Make sure you have [EmergencyStart] set to the HP % before we begin to use emergency mitigation abilities.",
        },
        ['DoCoating']       = {
            DisplayName = "Use Coating",
            Category = "Combat",
            Index = 8,
            Tooltip = "Click your Blood/Spirit Drinker's Coating in an emergency.",
            Default = false,
            FAQ = "What is a Coating?",
            Answer = "Blood Drinker's Coating is a clickable lifesteal effect added in CotF. Spirit Drinker's Coating is an upgrade added in NoS.",
        },
        --Debuffs
        ['DoSnare']         = {
            DisplayName = "Use Snares",
            Category = "Debuffs",
            Index = 1,
            Tooltip = "Use Snare(Snare Dot used until AA is available).",
            Default = false,
            RequiresLoadoutChange = true,
            FAQ = "Why is my Shadow Knight not snaring?",
            Answer = "Make sure Use Snares is enabled in your class settings.",
        },
        ['SnareCount']      = {
            DisplayName = "Snare Max Mob Count",
            Category = "Debuffs",
            Index = 2,
            Tooltip = "Only use snare if there are [x] or fewer mobs on aggro. Helpful for AoE groups.",
            Default = 3,
            Min = 1,
            Max = 99,
            FAQ = "Why is my Shadow Knight Not snaring?",
            Answer = "Make sure you have [DoSnare] enabled in your class settings.\n" ..
                "Double check the Snare Max Mob Count setting, it will prevent snare from being used if there are more than [x] mobs on aggro.",
        },

        ['DoRegenBuff']     = {
            DisplayName = "Regen Buff",
            Category = "Combat",
            Index = 8,
            Tooltip = "Click your Blood/Spirit Drinker's Coating in an emergency.",
            Default = false,
            FAQ = "What is a Coating?",
            Answer = "Blood Drinker's Coating is a clickable lifesteal effect added in CotF. Spirit Drinker's Coating is an upgrade added in NoS.",
        },
        ['DoJoltSpell']     = {
            DisplayName = "Do Jolt Spell",
            Category = "Combat",
            Index = 8,
            Tooltip = "Click your Blood/Spirit Drinker's Coating in an emergency.",
            Default = true,
            FAQ = "What is a Coating?",
            Answer = "Blood Drinker's Coating is a clickable lifesteal effect added in CotF. Spirit Drinker's Coating is an upgrade added in NoS.",
        },
        ['DoShieldDS']      = {
            DisplayName = "Do Shield DS",
            Category = "Combat",
            Index = 8,
            Tooltip = "Click your Blood/Spirit Drinker's Coating in an emergency.",
            Default = true,
            FAQ = "What is a Coating?",
            Answer = "Blood Drinker's Coating is a clickable lifesteal effect added in CotF. Spirit Drinker's Coating is an upgrade added in NoS.",
        },
        ['DoColdResist']    = {
            DisplayName = "Do Cold Resist",
            Category = "Combat",
            Index = 8,
            Tooltip = "Click your Blood/Spirit Drinker's Coating in an emergency.",
            Default = false,
            FAQ = "What is a Coating?",
            Answer = "Blood Drinker's Coating is a clickable lifesteal effect added in CotF. Spirit Drinker's Coating is an upgrade added in NoS.",
        },
        ['DoFireResist']    = {
            DisplayName = "Do Fire Resist",
            Category = "Combat",
            Index = 8,
            Tooltip = "Click your Blood/Spirit Drinker's Coating in an emergency.",
            Default = false,
            FAQ = "What is a Coating?",
            Answer = "Blood Drinker's Coating is a clickable lifesteal effect added in CotF. Spirit Drinker's Coating is an upgrade added in NoS.",
        },
        ['ArrowBuffChoice'] = {
            DisplayName = "Pet Class",
            Category = "Combat",
            Tooltip = "Choose which element you would like to focus on with Arrow buffs and Scout's Mastery",
            Type = "Combo",
            ComboOptions = { 'Fire', 'Cold', },
            Default = 1,
            Min = 1,
            Max = 2,
            FAQ = "I want to only use a Rogue Pet for the Backstabs, how do I do that?",
            Answer = "Set the [PetType] setting to Rog and the Necro will only summon Rogue pets.",
        },
        ['DoStrengthBuff']  = {
            DisplayName = "Strength HP Buff",
            Category = "Combat",
            Index = 8,
            Tooltip = "Click your Blood/Spirit Drinker's Coating in an emergency.",
            Default = true,
            FAQ = "What is a Coating?",
            Answer = "Blood Drinker's Coating is a clickable lifesteal effect added in CotF. Spirit Drinker's Coating is an upgrade added in NoS.",
        },
    },
}
