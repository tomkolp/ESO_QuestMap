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
QuestMap.PIN_TYPE_QUEST_UNCOMPLETED    = "QuestMap_uncompleted"
QuestMap.PIN_TYPE_QUEST_COMPLETED      = "QuestMap_completed"
QuestMap.PIN_TYPE_QUEST_HIDDEN         = "QuestMap_hidden"
QuestMap.PIN_TYPE_QUEST_STARTED        = "QuestMap_started"
QuestMap.PIN_TYPE_QUEST_REPEATABLE     = "QuestMap_repeatable"
QuestMap.PIN_TYPE_QUEST_DAILY          = "QuestMap_daily"
QuestMap.PIN_TYPE_QUEST_CADWELL        = "QuestMap_cadwell"
QuestMap.PIN_TYPE_QUEST_SKILL          = "QuestMap_skill"
QuestMap.PIN_TYPE_QUEST_DUNGEON        = "QuestMap_dungeon"

QuestMap.PIN_TYPE_QUEST_UNCOMPLETED_PVP    = "QuestMap_uncompleted_pvp"
QuestMap.PIN_TYPE_QUEST_COMPLETED_PVP      = "QuestMap_completed_pvp"
QuestMap.PIN_TYPE_QUEST_HIDDEN_PVP         = "QuestMap_hidden_pvp"
QuestMap.PIN_TYPE_QUEST_STARTED_PVP        = "QuestMap_started_pvp"
QuestMap.PIN_TYPE_QUEST_REPEATABLE_PVP     = "QuestMap_repeatable_pvp"
QuestMap.PIN_TYPE_QUEST_DAILY_PVP          = "QuestMap_daily_pvp"
QuestMap.PIN_TYPE_QUEST_CADWELL_PVP        = "QuestMap_cadwell_pvp"
QuestMap.PIN_TYPE_QUEST_SKILL_PVP          = "QuestMap_skill_pvp"
QuestMap.PIN_TYPE_QUEST_DUNGEON_PVP        = "QuestMap_dungeon_pvp"

QuestMap.icon_sets = {
    QuestMap = "QuestMap/icons/pinQuestCompleted.dds",
    ESO = "QuestMap/icons/eso_completed.dds",
    ESOInverted = "QuestMap/icons/eso_inverted_completed.dds",
}

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

QuestMap.settings_default = {
    ["iconSet"] = "QuestMap",
    ["iconRepeatableSet"] = "QuestMap",
    ["pinSize"] = 25,
    ["pinLevel"] = 40,
    ["hiddenQuests"] = {},
    ["pinFilters"] = {
        [QuestMap.PIN_TYPE_QUEST_UNCOMPLETED]            = true,
        [QuestMap.PIN_TYPE_QUEST_COMPLETED]              = false,
        [QuestMap.PIN_TYPE_QUEST_HIDDEN]                 = false,
        [QuestMap.PIN_TYPE_QUEST_STARTED]                = false,
        [QuestMap.PIN_TYPE_QUEST_REPEATABLE]             = false,
        [QuestMap.PIN_TYPE_QUEST_DAILY]                  = false,
        [QuestMap.PIN_TYPE_QUEST_CADWELL]                = false,
        [QuestMap.PIN_TYPE_QUEST_SKILL]                  = false,
        [QuestMap.PIN_TYPE_QUEST_DUNGEON]                = false,
        [QuestMap.PIN_TYPE_QUEST_UNCOMPLETED_PVP]    = true,
        [QuestMap.PIN_TYPE_QUEST_COMPLETED_PVP]      = false,
        [QuestMap.PIN_TYPE_QUEST_HIDDEN_PVP]         = false,
        [QuestMap.PIN_TYPE_QUEST_STARTED_PVP]        = false,
        [QuestMap.PIN_TYPE_QUEST_REPEATABLE_PVP]     = false,
        [QuestMap.PIN_TYPE_QUEST_DAILY_PVP]          = false,
        [QuestMap.PIN_TYPE_QUEST_CADWELL_PVP]        = false,
        [QuestMap.PIN_TYPE_QUEST_SKILL_PVP]          = false,
        [QuestMap.PIN_TYPE_QUEST_DUNGEON_PVP]        = false,
    },
    ["displayClickMsg"] = true,
    ["displayHideQuest"] = true,
    ["displayQuestList"] = true,
    ["lastListArg"] = "uncompleted",
    ["pin_colors"] = {
        [QuestMap.PIN_TYPE_QUEST_UNCOMPLETED]    = QuestMap.color_default,
        [QuestMap.PIN_TYPE_QUEST_COMPLETED]      = QuestMap.color_default,
        [QuestMap.PIN_TYPE_QUEST_HIDDEN]         = QuestMap.color_default,
        [QuestMap.PIN_TYPE_QUEST_STARTED]        = QuestMap.color_default,
        [QuestMap.PIN_TYPE_QUEST_REPEATABLE]     = QuestMap.color_default,
        [QuestMap.PIN_TYPE_QUEST_DAILY]          = QuestMap.color_default,
        [QuestMap.PIN_TYPE_QUEST_CADWELL]        = QuestMap.color_default,
        [QuestMap.PIN_TYPE_QUEST_SKILL]          = QuestMap.color_default,
        [QuestMap.PIN_TYPE_QUEST_DUNGEON]        = QuestMap.color_default,
    },
    ["pin_tooltip_colors"] = {
        [QuestMap.PIN_TYPE_QUEST_UNCOMPLETED]    = QuestMap.color_default,
        [QuestMap.PIN_TYPE_QUEST_COMPLETED]      = QuestMap.color_default,
        [QuestMap.PIN_TYPE_QUEST_HIDDEN]         = QuestMap.color_default,
        [QuestMap.PIN_TYPE_QUEST_STARTED]        = QuestMap.color_default,
        [QuestMap.PIN_TYPE_QUEST_REPEATABLE]     = QuestMap.color_default,
        [QuestMap.PIN_TYPE_QUEST_DAILY]          = QuestMap.color_default,
        [QuestMap.PIN_TYPE_QUEST_CADWELL]        = QuestMap.color_default,
        [QuestMap.PIN_TYPE_QUEST_SKILL]          = QuestMap.color_default,
        [QuestMap.PIN_TYPE_QUEST_DUNGEON]        = QuestMap.color_default,
    },
}
QuestMap.pin_color = {}
QuestMap.pin_color[QuestMap.PIN_TYPE_QUEST_UNCOMPLETED] = ZO_ColorDef:New(unpack(QuestMap.color_default))
QuestMap.pin_color[QuestMap.PIN_TYPE_QUEST_COMPLETED]   = ZO_ColorDef:New(unpack(QuestMap.color_default))
QuestMap.pin_color[QuestMap.PIN_TYPE_QUEST_HIDDEN]      = ZO_ColorDef:New(unpack(QuestMap.color_default))
QuestMap.pin_color[QuestMap.PIN_TYPE_QUEST_STARTED]     = ZO_ColorDef:New(unpack(QuestMap.color_default))
QuestMap.pin_color[QuestMap.PIN_TYPE_QUEST_REPEATABLE]  = ZO_ColorDef:New(unpack(QuestMap.color_default))
QuestMap.pin_color[QuestMap.PIN_TYPE_QUEST_DAILY]       = ZO_ColorDef:New(unpack(QuestMap.color_default))
QuestMap.pin_color[QuestMap.PIN_TYPE_QUEST_CADWELL]     = ZO_ColorDef:New(unpack(QuestMap.color_default))
QuestMap.pin_color[QuestMap.PIN_TYPE_QUEST_SKILL]       = ZO_ColorDef:New(unpack(QuestMap.color_default))
QuestMap.pin_color[QuestMap.PIN_TYPE_QUEST_DUNGEON]     = ZO_ColorDef:New(unpack(QuestMap.color_default))

QuestMap.tooltip_color = {}
QuestMap.tooltip_color[QuestMap.PIN_TYPE_QUEST_UNCOMPLETED] = ZO_ColorDef:New(unpack(QuestMap.color_default))
QuestMap.tooltip_color[QuestMap.PIN_TYPE_QUEST_COMPLETED]   = ZO_ColorDef:New(unpack(QuestMap.color_default))
QuestMap.tooltip_color[QuestMap.PIN_TYPE_QUEST_HIDDEN]      = ZO_ColorDef:New(unpack(QuestMap.color_default))
QuestMap.tooltip_color[QuestMap.PIN_TYPE_QUEST_STARTED]     = ZO_ColorDef:New(unpack(QuestMap.color_default))
QuestMap.tooltip_color[QuestMap.PIN_TYPE_QUEST_REPEATABLE]  = ZO_ColorDef:New(unpack(QuestMap.color_default))
QuestMap.tooltip_color[QuestMap.PIN_TYPE_QUEST_DAILY]       = ZO_ColorDef:New(unpack(QuestMap.color_default))
QuestMap.tooltip_color[QuestMap.PIN_TYPE_QUEST_CADWELL]     = ZO_ColorDef:New(unpack(QuestMap.color_default))
QuestMap.tooltip_color[QuestMap.PIN_TYPE_QUEST_SKILL]       = ZO_ColorDef:New(unpack(QuestMap.color_default))
QuestMap.tooltip_color[QuestMap.PIN_TYPE_QUEST_DUNGEON]     = ZO_ColorDef:New(unpack(QuestMap.color_default))

QuestMap.QUEST_NAME_LAYOUT = {

    [QuestMap.PIN_TYPE_QUEST_UNCOMPLETED] =
    {
        color = QuestMap.tooltip_color[QuestMap.PIN_TYPE_QUEST_UNCOMPLETED],
        suffix = "(UN)",
    },
    [QuestMap.PIN_TYPE_QUEST_COMPLETED] =
    {
        color = QuestMap.tooltip_color[QuestMap.PIN_TYPE_QUEST_COMPLETED],
        suffix = "(CM)",
    },
    [QuestMap.PIN_TYPE_QUEST_HIDDEN] =
    {
        color = QuestMap.tooltip_color[QuestMap.PIN_TYPE_QUEST_HIDDEN],
        suffix = "(HI)",
    },
    [QuestMap.PIN_TYPE_QUEST_STARTED] =
    {
        color = QuestMap.tooltip_color[QuestMap.PIN_TYPE_QUEST_UNCOMPLETED],
        suffix = "(ST)",
    },
    [QuestMap.PIN_TYPE_QUEST_REPEATABLE] =
    {
        color = QuestMap.tooltip_color[QuestMap.PIN_TYPE_QUEST_UNCOMPLETED],
        suffix = "(RP)",
    },
    [QuestMap.PIN_TYPE_QUEST_DAILY] =
    {
        color = QuestMap.tooltip_color[QuestMap.PIN_TYPE_QUEST_UNCOMPLETED],
        suffix = "(DA)",
    },
    [QuestMap.PIN_TYPE_QUEST_CADWELL] =
    {
        color = QuestMap.tooltip_color[QuestMap.PIN_TYPE_QUEST_UNCOMPLETED],
        suffix = "(CW)",
    },
    [QuestMap.PIN_TYPE_QUEST_SKILL] =
    {
        color = QuestMap.tooltip_color[QuestMap.PIN_TYPE_QUEST_UNCOMPLETED],
        suffix = "(SK)",
    },
    [QuestMap.PIN_TYPE_QUEST_DUNGEON] =
    {
        color = QuestMap.tooltip_color[QuestMap.PIN_TYPE_QUEST_DUNGEON],
        suffix = "(DN)",
    },
}

QuestMap.dm("Debug", "Finished Init")
