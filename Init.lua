--[[

Quest Map
by CaptainBlagbird
https://github.com/CaptainBlagbird

--]]

QuestMap = {}
QuestMap.displayName = "Quest Map"
QuestMap.idName = "QuestMap"
QuestMap.savedVars = {}

-- Constatnts
local PIN_TYPE_QUEST_UNCOMPLETED = "Quest_uncompleted"
local PIN_TYPE_QUEST_COMPLETED   = "Quest_completed"
local PIN_TYPE_QUEST_HIDDEN      = "Quest_hidden"
local PIN_TYPE_QUEST_STARTED     = "Quest_started"
local PIN_TYPE_QUEST_CADWELL     = "Quest_cadwell"
local PIN_TYPE_QUEST_SKILL       = "Quest_skill"

QuestMap.pinTypes = {
    uncompleted = PIN_TYPE_QUEST_UNCOMPLETED,
    completed   = PIN_TYPE_QUEST_COMPLETED,
    hidden      = PIN_TYPE_QUEST_HIDDEN,
    started     = PIN_TYPE_QUEST_STARTED,
    cadwell     = PIN_TYPE_QUEST_CADWELL,
    skill       = PIN_TYPE_QUEST_SKILL,
}

QuestMap.iconSets = {
    QuestMap = {"QuestMap/icons/pinQuestUncompleted.dds", "QuestMap/icons/pinQuestCompleted.dds"},
    ESO = {"/esoui/art/floatingmarkers/quest_available_icon.dds", "/esoui/art/icons/achievements_indexicon_quests_down.dds"},
}

QuestMap.settings_default = {
	["iconSet"] = "QuestMap",
	["pinSize"] = 25,
	["pinLevel"] = 40,
	["hiddenQuests"] = {},
	["pinFilters"] = {
	    [PIN_TYPE_QUEST_UNCOMPLETED]         = true,
	    [PIN_TYPE_QUEST_COMPLETED]           = false,
	    [PIN_TYPE_QUEST_HIDDEN]              = false,
	    [PIN_TYPE_QUEST_STARTED]             = false,
	    [PIN_TYPE_QUEST_UNCOMPLETED.."_pvp"] = false,
	    [PIN_TYPE_QUEST_COMPLETED.."_pvp"]   = false,
	    [PIN_TYPE_QUEST_HIDDEN.."_pvp"]      = false,
	    [PIN_TYPE_QUEST_STARTED.."_pvp"]     = false,
	    [PIN_TYPE_QUEST_CADWELL]             = false,
	    [PIN_TYPE_QUEST_SKILL]               = false,
	},
	["displayClickMsg"] = true,
	["lastListArg"] = "uncompleted",
}

QuestMap.data_default = {
data = {}
}

function QuestMap.InitSavedVariables()
    QuestMap.savedVars = {
        ["settings"]    = ZO_SavedVars:New("QuestMap_SavedVariables", 1, "settings", QuestMap.settings_default),
        ["log"]         = ZO_SavedVars:New("QuestMap_SavedVariables", 1, "log", QuestMap.data_default),
        ["scout"]       = ZO_SavedVars:New("QuestMap_SavedVariables", 1, "scout", QuestMap.data_default),
        ["npc_names"]   = ZO_SavedVars:New("QuestMap_SavedVariables", 1, "npc_names", QuestMap.data_default),
        ["quest_names"] = ZO_SavedVars:New("QuestMap_SavedVariables", 1, "quest_names", QuestMap.data_default),
        ["quest_data"]  = ZO_SavedVars:New("QuestMap_SavedVariables", 1, "quest_data", QuestMap.data_default),
    }
end
