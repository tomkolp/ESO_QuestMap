--[[

Quest Map
by CaptainBlagbird
https://github.com/CaptainBlagbird

--]]

QuestMap = {}
QuestMap.displayName = "Quest Map"
QuestMap.idName = "QuestMap"
local logger = LibDebugLogger.Create(QuestMap.idName)
QuestMap.logger = logger
QuestMap.show_log = false
local SDLV = DebugLogViewer

local function create_log(log_type, log_content)
    if QuestMap.show_log and QuestMap.logger and SDLV then
        if log_type == "Debug" then
            QuestMap.logger:Debug(log_content)
        end
        if log_type == "Verbose" then
            QuestMap.logger:Verbose(log_content)
        end
    elseif QuestMap.show_log or not SDLV then
        d(log_content)
    end
end

local function emit_message(log_type, text)
    if(text == "") then
        text = "[Empty String]"
    end
    create_log(log_type, text)
end

local function emit_table(log_type, t, indent, table_history)
    indent          = indent or "."
    table_history    = table_history or {}

    for k, v in pairs(t) do
        local vType = type(v)

        emit_message(log_type, indent.."("..vType.."): "..tostring(k).." = "..tostring(v))

        if(vType == "table") then
            if(table_history[v]) then
                emit_message(log_type, indent.."Avoiding cycle on table...")
            else
                table_history[v] = true
                emit_table(log_type, v, indent.."  ", table_history)
            end
        end
    end
end

function QuestMap.dm(log_type, ...)
    if not QuestMap.show_log then return end
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if(type(value) == "table") then
            emit_table(log_type, value)
        else
            emit_message(log_type, tostring(value))
        end
    end
end

-------------------------------------------------
----- Logger Function                       -----
-------------------------------------------------

-- Constatnts
local PIN_TYPE_QUEST_UNCOMPLETED    = "QuestMap_uncompleted"
local PIN_TYPE_QUEST_COMPLETED      = "QuestMap_completed"
local PIN_TYPE_QUEST_HIDDEN         = "QuestMap_hidden"
local PIN_TYPE_QUEST_STARTED        = "QuestMap_started"
local PIN_TYPE_QUEST_REPEATABLE     = "QuestMap_repeatable"
local PIN_TYPE_QUEST_DAILY          = "QuestMap_daily"

local PIN_TYPE_QUEST_UNCOMPLETED_PVP    = "QuestMap_uncompleted_pvp"
local PIN_TYPE_QUEST_COMPLETED_PVP      = "QuestMap_completed_pvp"
local PIN_TYPE_QUEST_HIDDEN_PVP         = "QuestMap_hidden_pvp"
local PIN_TYPE_QUEST_STARTED_PVP        = "QuestMap_started_pvp"
local PIN_TYPE_QUEST_REPEATABLE_PVP     = "QuestMap_repeatable_pvp"
local PIN_TYPE_QUEST_DAILY_PVP          = "QuestMap_daily_pvp"

local PIN_TYPE_QUEST_CADWELL        = "QuestMap_cadwell"
local PIN_TYPE_QUEST_SKILL          = "QuestMap_skill"

QuestMap.pinTypes = {
    uncompleted = PIN_TYPE_QUEST_UNCOMPLETED,
    completed   = PIN_TYPE_QUEST_COMPLETED,
    hidden      = PIN_TYPE_QUEST_HIDDEN,
    started     = PIN_TYPE_QUEST_STARTED,
    repeatable  = PIN_TYPE_QUEST_REPEATABLE,
    daily       = PIN_TYPE_QUEST_DAILY,
    uncompleted_pvp = PIN_TYPE_QUEST_UNCOMPLETED_PVP,
    completed_pvp   = PIN_TYPE_QUEST_COMPLETED_PVP,
    hidden_pvp      = PIN_TYPE_QUEST_HIDDEN_PVP,
    started_pvp     = PIN_TYPE_QUEST_STARTED_PVP,
    repeatable_pvp  = PIN_TYPE_QUEST_REPEATABLE_PVP,
    daily_pvp       = PIN_TYPE_QUEST_DAILY_PVP,
    cadwell     = PIN_TYPE_QUEST_CADWELL,
    skill       = PIN_TYPE_QUEST_SKILL,
}

QuestMap.iconSets = {
    QuestMap = {"QuestMap/icons/pinQuestUncompleted.dds", "QuestMap/icons/pinQuestCompleted.dds"},
    ESO = {"esoui/art/floatingmarkers/quest_available_icon.dds", "esoui/art/icons/achievements_indexicon_quests_down.dds"},
    ESOInverted = {"QuestMap/icons/eso_inverted_uncompleted.dds", "QuestMap/icons/eso_inverted_completed.dds"},
}

QuestMap.settings_default = {
    ["iconSet"] = "QuestMap",
    ["pinSize"] = 25,
    ["pinLevel"] = 40,
    ["hiddenQuests"] = {},
    ["pinFilters"] = {
        [PIN_TYPE_QUEST_UNCOMPLETED]            = true,
        [PIN_TYPE_QUEST_COMPLETED]              = false,
        [PIN_TYPE_QUEST_HIDDEN]                 = false,
        [PIN_TYPE_QUEST_STARTED]                = false,
        [PIN_TYPE_QUEST_REPEATABLE]             = true,
        [PIN_TYPE_QUEST_DAILY]                  = true,
        [PIN_TYPE_QUEST_UNCOMPLETED.."_pvp"]    = false,
        [PIN_TYPE_QUEST_COMPLETED.."_pvp"]      = false,
        [PIN_TYPE_QUEST_HIDDEN.."_pvp"]         = false,
        [PIN_TYPE_QUEST_STARTED.."_pvp"]        = false,
        [PIN_TYPE_QUEST_REPEATABLE.."_pvp"]     = false,
        [PIN_TYPE_QUEST_DAILY.."_pvp"]          = true,
        [PIN_TYPE_QUEST_CADWELL]                = true,
        [PIN_TYPE_QUEST_SKILL]                  = true,
    },
    ["displayClickMsg"] = true,
    ["lastListArg"] = "uncompleted",
}
