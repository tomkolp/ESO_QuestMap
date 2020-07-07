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
local PIN_TYPE_QUEST_CADWELL        = "QuestMap_cadwell"
local PIN_TYPE_QUEST_SKILL          = "QuestMap_skill"

local PIN_TYPE_QUEST_UNCOMPLETED_PVP    = "QuestMap_uncompleted_pvp"
local PIN_TYPE_QUEST_COMPLETED_PVP      = "QuestMap_completed_pvp"
local PIN_TYPE_QUEST_HIDDEN_PVP         = "QuestMap_hidden_pvp"
local PIN_TYPE_QUEST_STARTED_PVP        = "QuestMap_started_pvp"
local PIN_TYPE_QUEST_REPEATABLE_PVP     = "QuestMap_repeatable_pvp"
local PIN_TYPE_QUEST_DAILY_PVP          = "QuestMap_daily_pvp"
local PIN_TYPE_QUEST_CADWELL_PVP        = "QuestMap_cadwell_pvp"
local PIN_TYPE_QUEST_SKILL_PVP          = "QuestMap_skill_pvp"

QuestMap.pinTypes = {
    uncompleted     = PIN_TYPE_QUEST_UNCOMPLETED,
    completed       = PIN_TYPE_QUEST_COMPLETED,
    hidden          = PIN_TYPE_QUEST_HIDDEN,
    started         = PIN_TYPE_QUEST_STARTED,
    repeatable      = PIN_TYPE_QUEST_REPEATABLE,
    daily           = PIN_TYPE_QUEST_DAILY,
    cadwell         = PIN_TYPE_QUEST_CADWELL,
    skill           = PIN_TYPE_QUEST_SKILL,
    uncompleted_pvp = PIN_TYPE_QUEST_UNCOMPLETED_PVP,
    completed_pvp   = PIN_TYPE_QUEST_COMPLETED_PVP,
    hidden_pvp      = PIN_TYPE_QUEST_HIDDEN_PVP,
    started_pvp     = PIN_TYPE_QUEST_STARTED_PVP,
    repeatable_pvp  = PIN_TYPE_QUEST_REPEATABLE_PVP,
    daily_pvp       = PIN_TYPE_QUEST_DAILY_PVP,
    cadwell         = PIN_TYPE_QUEST_CADWELL_PVP,
    skill           = PIN_TYPE_QUEST_SKILL_PVP,
}

QuestMap.iconSets = {
    QuestMap = {"QuestMap/icons/pinQuestUncompleted.dds", "QuestMap/icons/pinQuestCompleted.dds"},
    ESO = {"esoui/art/floatingmarkers/quest_available_icon.dds", "esoui/art/icons/achievements_indexicon_quests_down.dds"},
    ESOInverted = {"QuestMap/icons/eso_inverted_uncompleted.dds", "QuestMap/icons/eso_inverted_completed.dds"},
}

QuestMap.iconRepeatableSets = {
    QuestMap = "QuestMap/icons/pinQuestCompleted_repeatable.dds",
    ESO = "QuestMap/icons/eso_completed_repeatable.dds",
    ESOInverted = "QuestMap/icons/eso_inverted_completed_repeatable.dds",
}

function QuestMap.unpack_color_table(the_table)
    local col_r, col_g, col_b, col_a = unpack(the_table)
    return col_r, col_g, col_b, col_a
end

function QuestMap.create_color_table(r, g, b, a)
    local c = {}

    if(type(r) == "string") then
        c[4], c[1], c[2], c[3] = ConvertHTMLColorToFloatValues(r)
    elseif(type(r) == "table") then
        local otherColorDef = r
        c[1] = otherColorDef.r or 1
        c[2] = otherColorDef.g or 1
        c[3] = otherColorDef.b or 1
        c[4] = otherColorDef.a or 1
    else
        c[1] = r or 1
        c[2] = g or 1
        c[3] = b or 1
        c[4] = a or 1
    end

    return c
end

QuestMap.color_default = {
    [1] = 1,
    [2] = 1,
    [3] = 1,
    [4] = 1,
}

-- { [1] = 1, [2] = 1, [3] = 1, [4] = 1, }
-- /script QuestMap.dm("Debug", ZO_ColorDef:New(QuestMap.unpack_color_table({ [1] = 1, [2] = 1, [3] = 1, [4] = 1, })):Colorize(string.format("%s %s", "The Light Giver", "(CM)")))

QuestMap.settings_default = {
    ["iconSet"] = "QuestMap",
    ["iconRepeatableSet"] = "QuestMap",
    ["pinSize"] = 25,
    ["pinLevel"] = 40,
    ["hiddenQuests"] = {},
    ["pinFilters"] = {
        [PIN_TYPE_QUEST_UNCOMPLETED]            = true,
        [PIN_TYPE_QUEST_COMPLETED]              = false,
        [PIN_TYPE_QUEST_HIDDEN]                 = false,
        [PIN_TYPE_QUEST_STARTED]                = false,
        [PIN_TYPE_QUEST_REPEATABLE]             = false,
        [PIN_TYPE_QUEST_DAILY]                  = false,
        [PIN_TYPE_QUEST_CADWELL]                = false,
        [PIN_TYPE_QUEST_SKILL]                  = false,
        [PIN_TYPE_QUEST_UNCOMPLETED.."_pvp"]    = true,
        [PIN_TYPE_QUEST_COMPLETED.."_pvp"]      = false,
        [PIN_TYPE_QUEST_HIDDEN.."_pvp"]         = false,
        [PIN_TYPE_QUEST_STARTED.."_pvp"]        = false,
        [PIN_TYPE_QUEST_REPEATABLE.."_pvp"]     = false,
        [PIN_TYPE_QUEST_DAILY.."_pvp"]          = false,
        [PIN_TYPE_QUEST_CADWELL.."_pvp"]        = false,
        [PIN_TYPE_QUEST_SKILL.."_pvp"]          = false,
    },
    ["displayClickMsg"] = true,
    ["displayHideQuest"] = true,
    ["displayQuestList"] = true,
    ["lastListArg"] = "uncompleted",
    ["pin_colors"] = {
        [PIN_TYPE_QUEST_UNCOMPLETED]    = QuestMap.color_default,
        [PIN_TYPE_QUEST_COMPLETED]      = QuestMap.color_default,
        [PIN_TYPE_QUEST_HIDDEN]         = QuestMap.color_default,
        [PIN_TYPE_QUEST_STARTED]        = QuestMap.color_default,
        [PIN_TYPE_QUEST_REPEATABLE]     = QuestMap.color_default,
        [PIN_TYPE_QUEST_DAILY]          = QuestMap.color_default,
        [PIN_TYPE_QUEST_CADWELL]        = QuestMap.color_default,
        [PIN_TYPE_QUEST_SKILL]          = QuestMap.color_default,
    },
    ["pin_tooltip_colors"] = {
        [PIN_TYPE_QUEST_UNCOMPLETED]    = QuestMap.color_default,
        [PIN_TYPE_QUEST_COMPLETED]      = QuestMap.color_default,
        [PIN_TYPE_QUEST_HIDDEN]         = QuestMap.color_default,
        [PIN_TYPE_QUEST_STARTED]        = QuestMap.color_default,
        [PIN_TYPE_QUEST_REPEATABLE]     = QuestMap.color_default,
        [PIN_TYPE_QUEST_DAILY]          = QuestMap.color_default,
        [PIN_TYPE_QUEST_CADWELL]        = QuestMap.color_default,
        [PIN_TYPE_QUEST_SKILL]          = QuestMap.color_default,
    },
}

--[[
Unfortunatly when QuestMap loads it sets some constants
that are not availabe yet. This will make sure nil values
are not referenced.

I would prefer to let ZO_SavedVars set these to defaults
but it is called too late.
]]--
if QuestMap.settings == nil then QuestMap.settings = {} end
if QuestMap.settings.pin_tooltip_colors == nil then QuestMap.settings.pin_tooltip_colors = {} end
if QuestMap.settings.pin_tooltip_colors[PIN_TYPE_QUEST_UNCOMPLETED] == nil then QuestMap.settings.pin_tooltip_colors[PIN_TYPE_QUEST_UNCOMPLETED] = QuestMap.color_default end
if QuestMap.settings.pin_tooltip_colors[PIN_TYPE_QUEST_COMPLETED] == nil then QuestMap.settings.pin_tooltip_colors[PIN_TYPE_QUEST_COMPLETED] = QuestMap.color_default end
if QuestMap.settings.pin_tooltip_colors[PIN_TYPE_QUEST_HIDDEN] == nil then QuestMap.settings.pin_tooltip_colors[PIN_TYPE_QUEST_HIDDEN] = QuestMap.color_default end
if QuestMap.settings.pin_tooltip_colors[PIN_TYPE_QUEST_STARTED] == nil then QuestMap.settings.pin_tooltip_colors[PIN_TYPE_QUEST_STARTED] = QuestMap.color_default end
if QuestMap.settings.pin_tooltip_colors[PIN_TYPE_QUEST_REPEATABLE] == nil then QuestMap.settings.pin_tooltip_colors[PIN_TYPE_QUEST_REPEATABLE] = QuestMap.color_default end
if QuestMap.settings.pin_tooltip_colors[PIN_TYPE_QUEST_DAILY] == nil then QuestMap.settings.pin_tooltip_colors[PIN_TYPE_QUEST_DAILY] = QuestMap.color_default end
if QuestMap.settings.pin_tooltip_colors[PIN_TYPE_QUEST_CADWELL] == nil then QuestMap.settings.pin_tooltip_colors[PIN_TYPE_QUEST_CADWELL] = QuestMap.color_default end
if QuestMap.settings.pin_tooltip_colors[PIN_TYPE_QUEST_SKILL] == nil then QuestMap.settings.pin_tooltip_colors[PIN_TYPE_QUEST_SKILL] = QuestMap.color_default end

QuestMap.QUEST_NAME_LAYOUT = {

    [PIN_TYPE_QUEST_UNCOMPLETED] =
    {
        suffix = "(UN)",
    },
    [PIN_TYPE_QUEST_COMPLETED] =
    {
        suffix = "(CM)",
    },
    [PIN_TYPE_QUEST_HIDDEN] =
    {
        suffix = "(HI)",
    },
    [PIN_TYPE_QUEST_STARTED] =
    {
        suffix = "(ST)",
    },
    [PIN_TYPE_QUEST_REPEATABLE] =
    {
        suffix = "(RP)",
    },
    [PIN_TYPE_QUEST_DAILY] =
    {
        suffix = "(DA)",
    },
    [PIN_TYPE_QUEST_SKILL] =
    {
        suffix = "(SK)",
    },
    [PIN_TYPE_QUEST_CADWELL] =
    {
        suffix = "(CW)",
    },
}

QuestMap.dm("Debug", "Finished Init")
QuestMap.dm("Debug", QuestMap.settings.pin_tooltip_colors)
