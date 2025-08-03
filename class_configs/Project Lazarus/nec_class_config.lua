-- [ README: Customization ] --
-- If you want to make customizations to this file, please put it
-- into your: MacroQuest/configs/rgmercs/class_configs/ directory
-- so it is not patched over.

-- [ NOTE ON ORDERING ] --
-- Order matters! Lua will implicitly iterate everything in an array
-- in order by default so always put the first thing you want checked
-- towards the top of the list.

local mq           = require('mq')
local Config       = require('utils.config')
local Comms        = require("utils.comms")
local Core         = require("utils.core")
local Targeting    = require("utils.targeting")
local Casting      = require("utils.casting")

local _ClassConfig = {
    _version            = "1.0 - Project Lazarus",
    _author             = "Derple, Grimmier",
    ['Modes']           = {
        'DPS',
    },
    ['ModeChecks']      = {
        -- necro can AA Rez
        IsRezing   = function() return Config:GetSetting('BattleRez') or Targeting.GetXTHaterCount() == 0 end,
        CanCharm   = function() return true end,
        IsCharming = function() return (Config:GetSetting('CharmOn') and mq.TLO.Pet.ID() == 0) end,
    },
    ['Themes']          = {
        ['DPS'] = {
            { element = ImGuiCol.TitleBgActive,    color = { r = 0.5, g = 0.05, b = 1.0, a = .8, }, },
            { element = ImGuiCol.TableHeaderBg,    color = { r = 0.4, g = 0.05, b = 0.8, a = .8, }, },
            { element = ImGuiCol.Tab,              color = { r = 0.2, g = 0.05, b = 0.6, a = .8, }, },
            { element = ImGuiCol.TabActive,        color = { r = 0.2, g = 0.05, b = 0.6, a = .8, }, },
            { element = ImGuiCol.TabHovered,       color = { r = 0.2, g = 0.05, b = 0.6, a = 1.0, }, },
            { element = ImGuiCol.Header,           color = { r = 0.1, g = 0.05, b = 0.5, a = .8, }, },
            { element = ImGuiCol.HeaderActive,     color = { r = 0.2, g = 0.05, b = 0.6, a = .8, }, },
            { element = ImGuiCol.HeaderHovered,    color = { r = 0.2, g = 0.05, b = 0.6, a = 1.0, }, },
            { element = ImGuiCol.FrameBgHovered,   color = { r = 0.2, g = 0.05, b = 0.6, a = 0.7, }, },
            { element = ImGuiCol.Button,           color = { r = 0.1, g = 0.05, b = 0.5, a = .8, }, },
            { element = ImGuiCol.ButtonActive,     color = { r = 0.2, g = 0.05, b = 0.6, a = .8, }, },
            { element = ImGuiCol.ButtonHovered,    color = { r = 0.2, g = 0.05, b = 0.6, a = 1.0, }, },
            { element = ImGuiCol.TextSelectedBg,   color = { r = 0.1, g = 0.05, b = 0.5, a = .1, }, },
            { element = ImGuiCol.FrameBg,          color = { r = 0.1, g = 0.05, b = 0.5, a = .8, }, },
            { element = ImGuiCol.SliderGrab,       color = { r = 0.5, g = 0.05, b = 1.0, a = .8, }, },
            { element = ImGuiCol.SliderGrabActive, color = { r = 0.5, g = 0.05, b = 1.0, a = .9, }, },
            { element = ImGuiCol.FrameBgActive,    color = { r = 0.2, g = 0.05, b = 0.6, a = 1.0, }, },
        },
    },
    ['CommandHandlers'] = {
        startlich = {
            usage = "/rgl startlich",
            about = "Start your Lich Spell [Note: This will enabled DoLich if it is not already].",
            handler =
                function(self)
                    Config:SetSetting('DoLich', true)
                    Core.SafeCallFunc("Start Necro Lich", self.ClassConfig.HelperFunctions.StartLich, self)

                    return true
                end,
        },
        stoplich = {
            usage = "/rgl stoplich",
            about = "Stop your Lich Spell [Note: This will NOT disable DoLich].",
            handler =
                function(self)
                    Core.SafeCallFunc("Stop Necro Lich", self.ClassConfig.HelperFunctions.CancelLich, self)

                    return true
                end,
        },
    },
    ['ItemSets']        = {
        ['Epic'] = {
            "Deathwhisper",
            "Soulwhisper",
        },
        ['OoW_Chest'] = {
            "Blightbringer's Tunic of the Grave",
            "Deathcaller's Robe",
        },
    },
    ['AbilitySets']     = {
        ['SelfHPBuff'] = {
            "Shadow Guard",
            "Shield of Maelin",
            "Shield of the Arcane",
            "Shield of the Magi",
            "Arch Shielding",
            "Greater Shielding",
            "Major Shielding",
            "Shielding",
            "Lesser Shielding",
            "Minor Shielding",
        },
        ['SelfRune'] = {
            "Dull Pain",
            "Force Shield",
            "Manaskin",
            "Diamondskin",
            "Steelskin",
            "Leatherskin",
            "Shieldskin",
        },
        ['CharmSpell'] = {
            "Word of Chaos",
            "Word of Terris",
            "Enslave Death",
            "Thrall of Bones",
            "Cajole Undead",
            "Beguile Undead",
            "Dominate Undead",
        },
        ['LifeTap'] = {
            "Ancient: Touch of Orshilak",
            "Soulspike",
            "Touch of Mujaki",
            -- "Gangrenous Touch of Zum`uul",
            "Touch of Night",
            "Deflux",
            "Drain Soul",
            "Drain Spirit",
            "Spirit Tap",
            "Siphon Life",
            "Lifedraw",
            "Lifespike",
            "Lifetap",
        },
        ['DurationTap'] = {
            "Fang of Death",
            "Night's Beckon",
            "Saryrn's Kiss",
            "Vexing Replenishment",
            "Auspice",
            "Bond of Death",
            "Vampiric Curse",
            "Shadow Compact",
            "Leech",
        },
        ['PoisonNuke'] = {
            "Acikin",
            "Neurotoxin",
            "Ancient: Lifebane",
            "Torbas' Venom Blast",
            "Torbas' Poison Blast",
            "Torbas' Acid Blast",
            "Shock of Poison",
        },
        ['FireDot'] = {
            "Dread Pyre",
            "Pyre of Mori",
            "Night Fire",
            "Funeral Pyre of Kelador",
            "Pyrocruor",
            "Ignite Blood",
            "Boil Blood",
            "Heat Blood",
        },
        ['FireDot2'] = {
            "Dread Pyre",
            "Pyre of Mori",
            "Night Fire",
            "Funeral Pyre of Kelador",
            "Pyrocruor",
            "Ignite Blood",
            "Boil Blood",
            "Heat Blood",
        },
        ['Magic1'] = {
            "Splort",
            "Splurt",
        },
        ['Magic2'] = {
            "Ancient: Curse of Mori",
            "Dark Nightmare",
            "Horror",
            "Imprecation",
            "Dark Soul",
        },
        ['Magic2_2'] = {
            "Ancient: Curse of Mori",
            "Dark Nightmare",
            "Horror",
            "Imprecation",
            "Dark Soul",
        },
        ['Disease1'] = {
            "Chaos Plague",
            "Dark Plague",
            "Cessation of Cor",
        },
        ['Disease2'] = {
            "Grip of Mori",
            "Plague",
            "Asystole",
            "Scourge",
            "Heart Flutter",
            "Infectious Cloud",
            "Disease Cloud",
        },
        ['Poison3'] = {
            "Venom of Anguish",
        },
        ['Poison2'] = {
            "Chaos Venom",
            "Blood of Thule",
            "Envenomed Bolt",
            "Chilling Embrace",
            "Venom of the Snake",
            "Poison Bolt",
        },
        ['SnareDot'] = {
            "Desecrating Darkness",
            "Embracing Darkness",
            "Devouring Darkness",
            "Cascading Darkness",
            "Scent of Darkness",
            "Dooming Darkness",
            "Engulfing Darkness",
            "Clinging Darkness",
        },
        ['ScentDebuff'] = {
            "Scent of Midnight",
            "Scent of Terris",
            "Scent of Darkness",
            "Scent of Shadow",
            "Scent of Dusk",
        },
        ['LichSpell'] = {
            "Ancient: Allure of Extinction",
            -- "Dark Possession", -- Listed in spell file, does not appear to be in game?
            "Grave Pact",
            "Ancient: Seduction of Chaos",
            "Seduction of Saryrn",
            "Ancient: Master of Death",
            "Arch Lich",
            "Demi Lich",
            "Lich",
            "Call of Bones",
            "Allure of Death",
            "Dark Pact",
        },
        ['PetSpellRog'] = {
            "Dark Assassin",
            "Child of Bertoxxulous",
            "Saryrn's Companion",
            "Minion of Shadows",
        },
        ['PetSpellWar'] = {
            "Lost Soul",
            "Child of Bertoxxulous",
            "Legacy of Zek",
            "Emissary of Thule",
            "Servant of Bones",
            "Invoke Death",
            "Cackling Bones",
            "Malignant Dead",
            "Invoke Shadow",
            "Summon Dead",
            "Haunting Corpse",
            "Animate Dead",
            "Restless Bones",
            "Convoke Shadow",
            "Bone Walk",
            "Leering Corpse",
            "Cavorting Bones",
        },
        ['PetHaste'] = {
            "Glyph of Darkness",
            "Rune of Death",
            "Augmentation of Death",
            "Augment Death",
            "Intensify Death",
            "Focus Death",
        },
        ['UndeadNuke'] = {
            "Desolate Undead",
            "Destroy Undead",
            "Exile Undead",
            "Banish Undead",
            "Expel Undead",
            "Dismiss Undead",
            "Expulse Undead",
            "Ward Undead",
        },
        ['HealOrb'] = {
            "Shadow Orb",
            "Soul Orb",
        },
        ['Calliav'] = {
            "Bulwark of Calliav",
            "Protection of Calliav",
            "Guard of Calliav",
            "Ward of Calliav",
        },
        ['PetHealCure'] = {
            "Dark Salve",
            "Touch of Death",
            "Renew Bones",
            "Mend Bones",
        },
        ['CallNuke'] = {
            "Call for Blood",
        },
        ['Pustules'] = {
            "Necrotic Pustules",
        },
        -- ['GroupLeech'] = {
        --     "Night Stalker",
        --     "Zevfeer's Theft of Vitae",
        -- },
        ['FeignSpell'] = {
            "Death Peace",
            "Comatose",
            "Feign Death",
        },
        ['HarmshieldSpell'] = {
            "Quivering Veil of Xarn",
            "Harmshield",
        },
        ['UndeadConvert'] = {
            "Chill Bones",
            "Ignite Bones",
        },
    },
    ['RotationOrder']   = {
        -- Downtime doesn't have state because we run the whole rotation at once.
        {
            name = 'Downtime',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and
                    Casting.OkayToBuff() and Casting.AmIBuffable()
            end,
        },
        { --Summon pet even when buffs are off on emu
            name = 'PetSummon',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and Casting.OkayToPetBuff() and not Core.IsCharming() and Casting.AmIBuffable()
            end,
        },
        { --Pet Buffs if we have one, timer because we don't need to constantly check this
            name = 'PetBuff',
            timer = 30,
            targetId = function(self) return mq.TLO.Me.Pet.ID() > 0 and { mq.TLO.Me.Pet.ID(), } or {} end,
            cond = function(self, combat_state)
                return combat_state == "Downtime" and mq.TLO.Me.Pet.ID() > 0 and Casting.OkayToPetBuff()
            end,
        },
        {
            name = 'Lich Management',
            timer = 10,
            state = 1,
            steps = 1,
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return true
            end,
        },
        {
            -- this will always run first in combat to check for things like FD or stand up
            -- if you add to it make sure it remains pretty short because everythign will be
            -- evalutated before we move to combat.
            name = 'Safety',
            targetId = function(self) return { mq.TLO.Me.ID(), } end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and (Targeting.IHaveAggro(Config:GetSetting('StartFDPct')) or Casting.IAmFeigning())
            end,
        },
        {
            name = 'Burn',
            state = 1,
            steps = 4,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and
                    Casting.BurnCheck() and not Casting.IAmFeigning()
            end,
        },
        {
            name = 'Scent',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoScentDebuff') end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Casting.IAmFeigning() and Casting.OkayToDebuff()
            end,
        },
        {
            name = 'DPS',
            state = 1,
            steps = 1,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Casting.IAmFeigning()
            end,
        },
        {
            name = 'ArcanumWeave',
            state = 1,
            steps = 1,
            load_cond = function() return Config:GetSetting('DoArcanumWeave') and Casting.CanUseAA("Acute Focus of Arcanum") end,
            targetId = function(self) return Targeting.CheckForAutoTargetID() end,
            cond = function(self, combat_state)
                return combat_state == "Combat" and not Casting.IAmFeigning() and not mq.TLO.Me.Buff("Focus of Arcanum")()
            end,
        },
    },
    ['Rotations']       = {
        ['Lich Management'] = {
            {
                name = "LichSpell",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell)
                    return Config:GetSetting('DoLich') and Casting.SelfBuffCheck(spell) and
                        (not Config:GetSetting('DoUnity') or not Casting.AAReady("Mortifier's Unity")) and
                        mq.TLO.Me.PctHPs() > Config:GetSetting('StopLichHP') and mq.TLO.Me.PctMana() < Config:GetSetting('StopLichMana')
                end,
            },
            {
                name = "LichControl",
                type = "CustomFunc",
                active_cond = function(self, spell) return true end,
                cond = function(self, _)
                    local lichSpell = Core.GetResolvedActionMapItem('LichSpell')

                    return lichSpell and lichSpell() and Casting.IHaveBuff(lichSpell) and
                        (mq.TLO.Me.PctHPs() <= Config:GetSetting('StopLichHP') or mq.TLO.Me.PctMana() >= Config:GetSetting('StopLichMana'))
                end,
                custom_func = function(self)
                    Core.SafeCallFunc("Stop Necro Lich", self.ClassConfig.HelperFunctions.CancelLich, self)
                end,
            },
        },
        ['Safety'] = {
            {
                name = "Death Peace",
                type = "AA",
                cond = function(self, aaName)
                    return not Casting.IAmFeigning() and mq.TLO.Me.PctHPs() < 75
                end,
            },
            {
                name = "Harm Shield",
                type = "AA",
                cond = function(self, aaName)
                    return not Casting.IAmFeigning() and mq.TLO.Me.PctHPs() >= 75
                end,
            },
            {
                name = "Stand Back Up",
                type = "CustomFunc",
                cond = function(self)
                    return Casting.IAmFeigning() and Targeting.GetHighestAggroPct() <= Config:GetSetting('StopFDPct')
                end,
                custom_func = function(_)
                    Core.DoCmd("/stand")
                    return true
                end,
            },
        },
        ['Scent'] = {
            {
                name = "Scent of Terris",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.DetAACheck(aaName)
                end,
            },
            {
                name = "ScentDebuff",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DetSpellCheck(spell)
                end,
            },
        },
        ['NewDPS'] = {
            {
                name = "Wake the Dead",
                type = "AA",
                cond = function(self, aaName)
                    return mq.TLO.SpawnCount("corpse radius 100")() >= Config:GetSetting('WakeDeadCorpseCnt')
                end,
            },
            {
                name = "Poison3",
                type = "Spell",
                cond = function(self, spell)
                    return Casting.DotSpellCheck(spell)
                end,
            },
            {
                name = "Poison2",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.IsNamed(target) and Casting.DotSpellCheck(spell)
                end,
            },
            {
                name = "FireDot",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.IsNamed(target) and Casting.DotSpellCheck(spell)
                end,
            },
            {
                name = "Magic2",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.IsNamed(target) and Casting.DotSpellCheck(spell)
                end,
            },
            {
                name = "Disease1",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.DotSpellCheck(spell)
                end,
            },
            {
                name = "FireDot2",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.IsNamed(target) and Casting.DotSpellCheck(spell)
                end,
            },
            {
                name = "Magic2_2",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.IsNamed(target) and Casting.DotSpellCheck(spell)
                end,
            },
            {
                name = "Scythe of the Shadowed Soul",
                type = "Item",
                cond = function(self, itemName, target)
                    return Targeting.IsNamed(target) and Targeting.MobNotLowHP(target) and Casting.DetItemCheck(itemName, target)
                end,
            },
            {
                name = "CallNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return Targeting.MobHasLowHP(target) and Casting.OkayToNuke()
                end,
            },
            {
                name = "PoisonNuke",
                type = "Spell",
                cond = function(self, spell, target)
                    return Casting.OkayToNuke()
                end,
            },
            {
                name = "LifeTap",
                type = "Spell",
                -- TO DO
            },
        },
        ['DPS'] = {
            {
                name = "Wake the Dead",
                type = "AA",
                cond = function(self, aaName)
                    return mq.TLO.SpawnCount("corpse radius 100")() >= Config:GetSetting('WakeDeadCorpseCnt')
                end,
            },
            {
                name = "Death Bloom",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName) and mq.TLO.Me.PctMana() < Config:GetSetting('DeathBloomPercent') and mq.TLO.Me.PctHPs() > 50
                end,
            },
            {
                name = "Encroaching Darkness",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName) and Targeting.GetTargetPctHPs() < 50
                end,
            },
            {
                name = "Silent Casting",
                type = "AA",
                cond = function(self, aaName, target)
                    return Targeting.IsNamed(target) and mq.TLO.Me.PctAggro() > 60
                end,
            },
            {
                name = "Life Burn",
                type = "AA",
                cond = function(self, aaName)
                    return Config:GetSetting('DoLifeBurn') and mq.TLO.Me.PctAggro() <= 25
                end,
            },
            {
                name = "SnareDot",
                type = "Spell",
                cond = function(self, spell) return Casting.DotSpellCheck(spell) and Config:GetSetting('DoSnare') end,
            },
            {
                name = "Poison3",
                type = "Spell",
                cond = function(self, spell) return Casting.DotSpellCheck(spell) end,
            },
            {
                name = "Disease2",
                type = "Spell",
                cond = function(self, spell) return Casting.DotSpellCheck(spell) end,
            },
            {
                name = "Poison2",
                type = "Spell",
                cond = function(self, spell) return Casting.DotSpellCheck(spell) end,
            },
            {
                name = "Disease1",
                type = "Spell",
                cond = function(self, spell) return Casting.DotSpellCheck(spell) end,
            },
            {
                name = "Magic2",
                type = "Spell",
                cond = function(self, spell) return Casting.DotSpellCheck(spell) end,
            },
            {
                name = "Magic1",
                type = "Spell",
                cond = function(self, spell) return Casting.DotSpellCheck(spell) end,
            },
            {
                name = "PoisonNuke",
                type = "Spell",
                cond = function(self, _) return Casting.OkayToNuke() end,
            },
            {
                name = "LifeTap",
                type = "Spell",
                cond = function(self, spell) return Casting.DotSpellCheck(spell) end,
            },
            {
                name = "FireDot",
                type = "Spell",
                cond = function(self, spell) return Casting.DotSpellCheck(spell) end,
            },
            {
                name = "GroupLeech",
                type = "Spell",
                cond = function(self, spell) return Casting.DotSpellCheck(spell) end,
            },
            {
                name = "DurationTap",
                type = "Spell",
                cond = function(self, spell) return Casting.DotSpellCheck(spell) end,
            },
            {
                name = "Dagger of Death",
                type = "Item",
            },
        },
        ['Burn'] = {
            {
                name = "OoW_Chest",
                type = "Item",
            },
            {
                name = "Gathering Dusk",
                type = "AA",
                cond = function(self, aaName, target) return Targeting.IsNamed(target) end,
            },
            {
                name = "Swarm of Decay",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Rise of Bones",
                type = "AA",
            },
            {
                name = "Focus of Arcanum",
                type = "AA",
                cond = function(self, aaName, target)
                    return Casting.SelfBuffAACheck(aaName) and Targeting.IsNamed(target)
                end,
            },
            {
                name = "Forceful Rejuvenation",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            { -- Spire, the SpireChoice setting will determine which ability is displayed/used.
                name_func = function(self)
                    local spireAbil = string.format("Fundament: %s Spire of Necromancy", Config.Constants.SpireChoices[Config:GetSetting('SpireChoice') or 4])
                    return Casting.CanUseAA(spireAbil) and spireAbil or "Spire Not Purchased/Selected"
                end,
                type = "AA",
            },
        },
        ['ArcanumWeave'] = {
            {
                name = "Empowered Focus of Arcanum",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Enlightened Focus of Arcanum",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
            {
                name = "Acute Focus of Arcanum",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.SelfBuffAACheck(aaName)
                end,
            },
        },
        ['Downtime'] = {
            {
                name = "Stand Back Up",
                type = "CustomFunc",
                cond = function(self)
                    return mq.TLO.Me.State():lower() == "feign" and (mq.TLO.Me.PctAggro() < 90 or mq.TLO.Me.TargetOfTarget.ID() ~= mq.TLO.Me.ID())
                end,
                custom_func = function(_)
                    Core.DoCmd("/stand")
                    return true
                end,
            },
            {
                name = "SelfHPBuff",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "SelfRune",
                type = "Spell",
                active_cond = function(self, spell) return Casting.IHaveBuff(spell) end,
                cond = function(self, spell) return Casting.SelfBuffCheck(spell) end,
            },
            {
                name = "Death Bloom",
                type = "AA",
                active_cond = function(self, aaName) return Casting.IHaveBuff(mq.TLO.AltAbility(aaName).Spell.RankName()) end,
                cond = function(self, aaName) return mq.TLO.Me.PctMana() < Config:GetSetting('DeathBloomPercent') end,
            },
        },
        ['PetSummon'] = { --TODO: Double check these lists to ensure someone leveling doesn't have to change options to keep pets current at lower levels
            {
                name = "PetSpellWar",
                type = "Spell",
                active_cond = function(self, _) return mq.TLO.Me.Pet.ID() ~= 0 and mq.TLO.Me.Pet.Class.ShortName():lower() == ("war" or "mnk") end,
                cond = function(self, spell)
                    return Config:GetSetting('PetType') == 1 and mq.TLO.Me.Pet.ID() == 0 and Casting.ReagentCheck(spell)
                end,
                post_activate = function(self, spell, success)
                    local pet = mq.TLO.Me.Pet
                    if success and pet.ID() > 0 then
                        Comms.PrintGroupMessage("Summoned a new %d %s pet named %s using '%s'!", pet.Level(), pet.Class.Name(), pet.CleanName(), spell.RankName())
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
            {
                name = "PetSpellRog",
                type = "Spell",
                active_cond = function(self, _) return mq.TLO.Me.Pet.ID() ~= 0 and mq.TLO.Me.Pet.Class.ShortName():lower() == "rog" end,
                cond = function(self, spell)
                    return Config:GetSetting('PetType') == 2 and mq.TLO.Me.Pet.ID() == 0 and Casting.ReagentCheck(spell)
                end,
                post_activate = function(self, spell, success)
                    local pet = mq.TLO.Me.Pet
                    if success and pet.ID() > 0 then
                        Comms.PrintGroupMessage("Summoned a new %d %s pet named %s using '%s'!", pet.Level(), pet.Class.Name(), pet.CleanName(), spell.RankName())
                        mq.delay(50) -- slight delay to prevent chat bug with command issue
                        self:SetPetHold()
                    end
                end,
            },
        },
        ['PetBuff'] = {
            {
                name = "PetHaste",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.PetBuff(spell.RankName())() ~= nil end,
                cond = function(self, spell) return Casting.PetBuffCheck(spell) end,
            },
            {
                name = "PetBuff",
                type = "Spell",
                active_cond = function(self, spell) return mq.TLO.Me.PetBuff(spell.RankName())() ~= nil end,
                cond = function(self, spell) return Casting.PetBuffCheck(spell) end,
            },
            {
                name = "Aegis of Kildrukaun",
                type = "AA",
                cond = function(self, aaName)
                    return Casting.PetBuffAACheck(aaName)
                end,
            },
        },
    },
    ['HelperFunctions'] = {
        CancelLich = function(self)
            -- detspa means detremental spell affect
            -- spa is positive spell affect
            local lichName = mq.TLO.Me.FindBuff("detspa hp and spa mana")()
            Core.DoCmd("/removebuff %s", lichName)
        end,

        StartLich = function(self)
            local lichSpell = Core.GetResolvedActionMapItem('LichSpell')

            if lichSpell and lichSpell() then
                Casting.UseSpell(lichSpell.RankName.Name(), mq.TLO.Me.ID(), false)
            end
        end,

        DoRez = function(self, corpseId)
            if Config:GetSetting('DoBattleRez') or mq.TLO.Me.CombatState():lower() ~= "combat" then
                if Casting.AAReady("Convergence") and Casting.ReagentCheck(mq.TLO.Me.AltAbility("Convergence").Spell) then
                    return Casting.OkayToRez(corpseId) and Casting.UseAA("Convergence", corpseId, true, 1)
                end
            end
        end,
    },
    ['Spells']          = {
        {
            gem = 1,
            spells = {
                { name = "Disease2", },
                { name = "Poison3", },
            },
        },
        {
            gem = 2,
            spells = {
                { name = "Poison2", cond = function(self) return mq.TLO.Me.Level() < 86 end, },
            },
        },
        {
            gem = 3,
            spells = {
                { name = "FireDot",    cond = function(self) return mq.TLO.Me.Level() < 51 end, },
                { name = "Magic1", },
                { name = "GroupLeech", },
            },
        },
        {
            gem = 4,
            spells = {
                { name = "PoisonNuke", cond = function(self) return mq.TLO.Me.Level() < 75 end, },
            },
        },
        {
            gem = 5,
            spells = {
                { name = "HealthTaps", },
                { name = "Poison2", },
            },
        },
        {
            gem = 6,
            spells = {
                { name = "DurationTap", },
                { name = "Magic2", },
                { name = "LichSpell", },
            },
        },
        {
            gem = 7,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "CharmSpell",  cond = function(self) return Config:GetSetting('CharmOn') end, },
                { name = "ScentDebuff", cond = function(self) return Config:GetSetting('DoScentDebuff') and not Casting.CanUseAA("Scent of Thule") end, },
                { name = "Disease1", },
                { name = "Disease2", },
            },
        },
        {
            gem = 8,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "SnareDot",   cond = function(self) return Config:GetSetting('DoSnare') end, },
                { name = "Magic1",     cond = function(self) return mq.TLO.Me.Level() > 70 and mq.TLO.Me.Level() < 87 end, },
                { name = "HealthTaps", },
            },
        },
        {
            gem = 9,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "FireDot", cond = function(self) return mq.TLO.Me.Level() < 89 end, },
                { name = "FDSpell", },
            },
        },
        {
            gem = 10,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "Poison3",  cond = function(self) return mq.TLO.Me.Level() < 85 end, },
                { name = "SwarmPet", },
            },
        },
        {
            gem = 11,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "Poison3",       cond = function(self) return mq.TLO.Me.Level() < 93 end, },
                { name = "ChaoticDebuff", },
            },
        },
        {
            gem = 12,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "DichoSpell", },
            },
        },
        {
            gem = 13,
            cond = function(self, gem) return mq.TLO.Me.NumGems() >= gem end,
            spells = {
                { name = "AllianceSpell", cond = function(self) return Config:GetSetting('DoAlliance') end, },
            },
        },
    },
    ['DefaultConfig']   = {
        ['Mode']              = {
            DisplayName = "Mode",
            Category = "Combat",
            Tooltip = "Select the Combat Mode for this Toon",
            Type = "Custom",
            RequiresLoadoutChange = true,
            Default = 1,
            Min = 1,
            Max = 1,
            FAQ = "What do the different Modes Do?",
            Answer = "Currently Necros only have one mode, which is DPS. This mode will focus on DPS and some utility.",
        },
        ['PetType']           = {
            DisplayName = "Pet Class",
            Category = "Combat",
            Tooltip = "1 = War, 2 = Rog",
            Type = "Combo",
            ComboOptions = { 'War', 'Rog', },
            Default = 1,
            Min = 1,
            Max = 2,
            FAQ = "I want to only use a Rogue Pet for the Backstabs, how do I do that?",
            Answer = "Set the [PetType] setting to Rog and the Necro will only summon Rogue pets.",
        },
        ['BattleRez']         = {
            DisplayName = "Battle Rez",
            Category = "Spells and Abilities",
            Tooltip = "Do Rezes during combat.",
            RequiresLoadoutChange = true,
            Default = true,
            FAQ = "I want to use my Battle Rez, how do I do that?",
            Answer = "Set the [BattleRez] setting to true and the Necro will use their Battle Rez during combat.",
        },
        ['DoLifeBurn']        = {
            DisplayName = "Use Life Burn",
            Category = "Spells and Abilities",
            Tooltip = "Use Life Burn AA if your aggro is below 25%.",
            Default = true,
            Index = 2,
            FAQ = "I want to use my Life Burn AA, how do I do that?",
            Answer = "Set the [DoLifeBurn] setting to true and the Necro will use Life Burn AA if their aggro is below 25%.",
        },
        ['DoUnity']           = {
            DisplayName = "Cast Unity",
            Category = "Spells and Abilities",
            Tooltip = "Enable casting Mortifiers Unity.",
            Default = true,
            Index = 1,
            FAQ = "I want to use my Unity AA, how do I do that?",
            Answer = "Set the [DoUnity] setting to true and the Necro will use Mortifiers Unity when it is available.",
        },
        ['DeathBloomPercent'] = {
            DisplayName = "Death Bloom %",
            Category = "Spells and Abilities",
            Tooltip = "Mana % at which to cast Death Bloom",
            Default = 40,
            Min = 1,
            Max = 100,
            FAQ = "I am using Death Bloom to early or late, how do I adjust it?",
            Answer = "Set the [DeathBloomPercent] setting to the desired % of mana you want to cast Death Bloom at.",
        },
        ['DoSnare']           = {
            DisplayName = "Cast Snares",
            Category = "Spells and Abilities",
            Tooltip = "Enable casting Snare spells.",
            Default = true,
            FAQ = "I want to use my Snare spells, how do I do that?",
            Answer = "Set the [DoSnare] setting to true and the Necro will use Snare spells.",
        },
        ['StartFDPct']        = {
            DisplayName = "FD Aggro Pct",
            Category = "Aggro Management",
            Tooltip = "Aggro % at which to FD",
            Default = 90,
            Min = 1,
            Max = 99,
            FAQ = "How do I manage my aggro with Feign Death?",
            Answer = "Set the [StartFDPct] setting to the desired % of aggro you want to FD at.",
        },
        ['StopFDPct']         = {
            DisplayName = "Stand Aggro Pct",
            Category = "Aggro Management",
            Tooltip = "Aggro % at which to Stand up from FD",
            Default = 80,
            Min = 1,
            Max = 99,
            FAQ = "How do I manage my aggro with Feign Death?",
            Answer = "Set the [StopFDPct] setting to the desired % of aggro you want to Stand up from FD at.",
        },
        ['WakeDeadCorpseCnt'] = {
            DisplayName = "WtD Corpse Count",
            Category = "Spells and Abilities",
            Tooltip = "Number of Corpses before we cast Wake the Dead",
            Default = 5,
            Min = 1,
            Max = 20,
            FAQ = "I want to use Wake the Dead when I have X corpses nearby, how do I do that?",
            Answer = "Set the [WakeDeadCorpseCnt] setting to the desired number of corpses you want to cast Wake the Dead at.",
        },
        ['DoLich']            = {
            DisplayName = "Cast Lich",
            Category = "Lich",
            Tooltip = "Enable casting Lich spells.",
            RequiresLoadoutChange = true,
            Default = true,
            FAQ = "I want to use my Lich spells, how do I do that?",
            Answer = "Set the [DoLich] setting to true and the Necro will use Lich spells.\n" ..
                "You will also want to set your [StopLichHP] and [StopLichMana] settings to the desired values so you do not Lich to Death.",
        },
        ['StopLichHP']        = {
            DisplayName = "Stop Lich HP",
            Category = "Lich",
            Tooltip = "Cancel Lich at HP Pct [x]",
            RequiresLoadoutChange = false,
            Default = 25,
            Min = 1,
            Max = 99,
            FAQ = "I want to stop Liching at a certain HP %, how do I do that?",
            Answer = "Set the [StopLichHP] setting to the desired % of HP you want to stop Liching at.",
        },
        ['StopLichMana']      = {
            DisplayName = "Stop Lich Mana",
            Category = "Lich",
            Tooltip = "Cancel Lich at Mana Pct [x]",
            RequiresLoadoutChange = false,
            Default = 100,
            Min = 1,
            Max = 100,
            FAQ = "I want to stop Liching at a certain Mana %, how do I do that?",
            Answer = "Set the [StopLichMana] setting to the desired % of Mana you want to stop Liching at.",
        },
        ['DoArcanumWeave']    = {
            DisplayName = "Weave Arcanums",
            Category = "Spells and Abilities",
            Tooltip = "Weave Empowered/Enlighted/Acute Focus of Arcanum into your standard combat routine (Focus of Arcanum is saved for burns).",
            RequiresLoadoutChange = true, --this setting is used as a load condition
            Default = true,
            FAQ = "What is an Arcanum and why would I want to weave them?",
            Answer =
            "The Focus of Arcanum series of AA decreases your spell resist rates.\nIf you have purchased all four, you can likely easily weave them to keep 100% uptime on one.",
        },
        ['DoScentDebuff']     = {
            DisplayName = "Use Scent Debuff",
            Category = "Spells and Abilities",
            Tooltip = "Use your Scent debuff spells or AA.",
            RequiresLoadoutChange = true, --this setting is used as a load condition
            Default = false,
            FAQ = "Why am I not using a Scent debuff?",
            Answer = "You can enable Scent use on the Spells and Abilities tab.",
        },
        ['SpireChoice']       = {
            DisplayName = "Spire Choice:",
            Category = "Buffs",
            Index = 6,
            Tooltip = "Choose which Fundament you would like to use during burns:\n" ..
                "First Spire: DoT Crit Chance Buff.\n" ..
                "Second Spire: Pet Damage Proc Buff.\n" ..
                "Third Spire: DoT Crit Damage Buff.",
            Type = "Combo",
            ComboOptions = Config.Constants.SpireChoices,
            Default = 3,
            Min = 1,
            Max = #Config.Constants.SpireChoices,
            FAQ = "Why am I using the wrong spire?",
            Answer = "You can choose which spire you prefer in the Class Options.",
        },
    },

}

return _ClassConfig
