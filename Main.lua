--[[

Quest Map
by CaptainBlagbird
https://github.com/CaptainBlagbird

--]]

-- Libraries
local LMP = LibMapPins
local LMW = LibMsgWin
local GPS = LibGPS2
local LQD = LibQuestData
local SDLV = DebugLogViewer

-- Constants
local PIN_PRIORITY_OFFSET = 1
-- Transfer from init
local PIN_TYPE_QUEST_UNCOMPLETED    = QuestMap.pinTypes.uncompleted
local PIN_TYPE_QUEST_COMPLETED      = QuestMap.pinTypes.completed
local PIN_TYPE_QUEST_HIDDEN         = QuestMap.pinTypes.hidden
local PIN_TYPE_QUEST_STARTED        = QuestMap.pinTypes.started
local PIN_TYPE_QUEST_REPEATABLE     = QuestMap.pinTypes.repeatable
local PIN_TYPE_QUEST_DAILY          = QuestMap.pinTypes.daily
local PIN_TYPE_QUEST_CADWELL        = QuestMap.pinTypes.cadwell
local PIN_TYPE_QUEST_SKILL          = QuestMap.pinTypes.skill

local PIN_TYPE_QUEST_UNCOMPLETED_PVP    = QuestMap.pinTypes.uncompleted_pvp
local PIN_TYPE_QUEST_COMPLETED_PVP      = QuestMap.pinTypes.completed_pvp
local PIN_TYPE_QUEST_HIDDEN_PVP         = QuestMap.pinTypes.hidden_pvp
local PIN_TYPE_QUEST_STARTED_PVP        = QuestMap.pinTypes.started_pvp
local PIN_TYPE_QUEST_REPEATABLE_PVP     = QuestMap.pinTypes.repeatable_pvp
local PIN_TYPE_QUEST_DAILY_PVP          = QuestMap.pinTypes.daily_pvp
local PIN_TYPE_QUEST_CADWELL_PVP        = QuestMap.pinTypes.cadwell_pvp
local PIN_TYPE_QUEST_SKILL_PVP          = QuestMap.pinTypes.skill_pvp

-- Local variables
local zoneQuests = {}
local last_mapid


-------------------------------------------------
----- Helpers                               -----
-------------------------------------------------

local function is_in(search_value, search_table)
    for k, v in pairs(search_table) do
        if search_value == v then return true end
        if type(search_value) == "string" then
            if string.find(string.lower(v), string.lower(search_value)) then return true end
        end
    end
    return false
end

-------------------------------------------------
----- Quest Map                             -----
-------------------------------------------------

-- UI
local ListUI
if LMW ~= nil then
    ListUI = LMW:CreateMsgWindow(QuestMap.idName.."_ListUI", " ")
    ListUI:SetAnchor(TOPLEFT, nil, nil, 50, 200)
    ListUI:SetDimensions(400, 600)
    ListUI:SetHidden(true)
    local btn = WINDOW_MANAGER:CreateControlFromVirtual(ListUI:GetName().."Close", ListUI, "ZO_CloseButton")
    btn:SetAnchor(TOPRIGHT, nil, nil, -7, 7)
    btn:SetHandler("OnClicked", function(self) self:GetParent():SetHidden(true) end)
end

-- Function to check for empty table
local function isEmpty(t)
    if next(t) == nil then
        return true
    else
        return false
    end
end

--[[
Function to print text when hiding quests to the chat window
including the addon name
]]--
local function p(s)
    if QuestMap.logger and SDLV then
        s = s:gsub("|cFFFFFF", "")
        temp_state = QuestMap.show_log
        QuestMap.show_log = true
        QuestMap.dm("Debug", s)
        QuestMap.show_log = temp_state
    else
        -- Add addon name to message
        s = "|c70C0DE["..QuestMap.displayName.."]|r "..s
        -- Replace regular color (yellow) with ESO golden in this string
        s = s:gsub("|r", "|cC5C29E")
        -- Replace newline character with newline + ESO golden (because newline resets color to default yellow)
        s = s:gsub("\n", "\n|cC5C29E")
        -- Display message
        temp_state = QuestMap.show_log
        QuestMap.show_log = true
        QuestMap.dm("Debug", s)
        QuestMap.show_log = temp_state
    end
end

-- Function to get the location/position of the player by slash command for reporting new quest givers / bugs
local function GetPlayerPos()
    -- Get location info and format coordinates
    local zone = LMP:GetZoneAndSubzone(true, false, true)
    local x, y = GetMapPlayerPosition("player")
    xpos, ypos = GPS:LocalToGlobal(x, y)
    -- x = string.format("%05.2f", x*100)
    -- y = string.format("%05.2f", y*100)
    QuestMap.dm("Debug", zone)
    QuestMap.dm("Debug", "X: "..x)
    QuestMap.dm("Debug", "Y: "..y)
    QuestMap.dm("Debug", "xpos: "..xpos)
    QuestMap.dm("Debug", "ypos: "..ypos)
    -- Add to chat input field so it's copyable
    -- StartChatInput(zone.." @ "..x.."/"..y)
    -- ZO_ChatWindowTextEntryEditBox:SelectAll();
end

-- Function for displaying window with the quest list
local function DisplayListUI(arg)
    if ListUI == nil then return end

    -- Default option
    if arg == "" or arg == nil then arg = QuestMap.settings.lastListArg end

    -- Get currently displayed zone and subzone from texture
    local zone = LMP:GetZoneAndSubzone(true, false, true)
    -- Update quest list for current zone if the zone changed
    if last_mapid and (GetCurrentMapId() ~= last_mapid) then
        zoneQuests = LQD:get_quest_list(zone)
    end

    -- Init variables and custom function that will be changed depending on input argument
    local title = GetString(QUESTMAP_QUESTS)..": "
    local list = {}
    local addQuestToList = function() end

    -- Define variables and function depending on input argument
    if arg == "uncompleted" then
        title = title..GetString(QUESTMAP_UNCOMPLETED)
        -- Check the completedQuests list and only add not matching quests
        addQuestToList = function(quest)
            local name = LQD:get_quest_name(quest[LQD.quest_map_pin_index.quest_id])
            if name ~= "" and not LQD.completed_quests[quest[LQD.quest_map_pin_index.quest_id]] then
                list[quest[LQD.quest_map_pin_index.quest_id]] = name
            end
        end

    elseif arg == "completed" then
        title = title..GetString(QUESTMAP_COMPLETED)
        -- Check the completedQuests list and only add matching quests
        addQuestToList = function(quest)
            local name = LQD:get_quest_name(quest[LQD.quest_map_pin_index.quest_id])
            if name ~= "" and LQD.completed_quests[quest[LQD.quest_map_pin_index.quest_id]] then
                list[quest[LQD.quest_map_pin_index.quest_id]] = name
            end
        end

    elseif arg == "hidden" then
        title = title..GetString(QUESTMAP_HIDDEN)
        -- Check the hiddenQuests list in the saved variables and only add matching quests
        addQuestToList = function(quest)
            local name = LQD:get_quest_name(quest[LQD.quest_map_pin_index.quest_id])
            if name ~= "" and QuestMap.settings.hiddenQuests[quest[LQD.quest_map_pin_index.quest_id]] then
                list[quest[LQD.quest_map_pin_index.quest_id]] = name
            end
        end

    elseif arg == "started" then
        title = title..GetString(QUESTMAP_STARTED)
        -- Check the startedQuests list in the saved variables and only add matching quests
        addQuestToList = function(quest)
            local name = LQD:get_quest_name(quest[LQD.quest_map_pin_index.quest_id])
            if name ~= "" and LQD.started_quests[quest[LQD.quest_map_pin_index.quest_id]] then
                list[quest[LQD.quest_map_pin_index.quest_id]] = name
            end
        end

    elseif arg == "repeatable" then
        title = title..GetString(QUESTMAP_REPEATABLE)
        -- Check the startedQuests list in the saved variables and only add matching quests
        addQuestToList = function(quest)
            local name = LQD:get_quest_name(quest[LQD.quest_map_pin_index.quest_id])
            if name ~= "" and LQD:get_quest_repeat(quest[LQD.quest_map_pin_index.quest_id]) == 1 then
                list[quest[LQD.quest_map_pin_index.quest_id]] = name
            end
        end

    elseif arg == "daily" then
        title = title..GetString(QUESTMAP_DAILY)
        -- Check the startedQuests list in the saved variables and only add matching quests
        addQuestToList = function(quest)
            local name = LQD:get_quest_name(quest[LQD.quest_map_pin_index.quest_id])
            if name ~= "" and LQD:get_quest_repeat(quest[LQD.quest_map_pin_index.quest_id]) == 2 then
                list[quest[LQD.quest_map_pin_index.quest_id]] = name
            end
        end

    elseif arg == "cadwell" then
        title = title..GetString(QUESTMAP_CADWELL)
        -- Check if quest is a cadwell's almanac quest and only add it if true
        addQuestToList = function(quest)
            local name = LQD:get_quest_name(quest[LQD.quest_map_pin_index.quest_id])
            local isCadwellQuest = LQD:get_qm_quest_type(quest[LQD.quest_map_pin_index.quest_id])
            if name ~= "" and isCadwellQuest then
                list[quest[LQD.quest_map_pin_index.quest_id]] = name
            end
        end

    elseif arg == "skill" then
        title = title..GetString(QUESTMAP_SKILL)
        -- Check if quest is a skill quest and only add it if true
        addQuestToList = function(quest)
            local name = LQD:get_quest_name(quest[LQD.quest_map_pin_index.quest_id])
            if name ~= "" and LQD.quest_rewards_skilpoint[quest[LQD.quest_map_pin_index.quest_id]] then
                list[quest[LQD.quest_map_pin_index.quest_id]] = name
            end
        end

    else
        -- Do nothing when argument invalid
        return
    end

    -- Save argument so the next time the slash command can be used without argument
    QuestMap.settings.lastListArg = arg

    -- Add quests of zone and subzone to list with the custom function
    for _, quest in ipairs(zoneQuests) do addQuestToList(quest) end

    -- Change title and add quest titles from list to window
    title = title.." ("..ZO_WorldMap_GetMapTitle()..")"
    WINDOW_MANAGER:GetControlByName(ListUI:GetName(), "Label"):SetText(title)
    ListUI:ClearText()
    for id, questName in pairs(list) do
        ListUI:AddText(questName)
    end

    ListUI:SetHidden(false)
end

-- Function to refresh pins
function QuestMap:RefreshPins()
    LMP:RefreshPins(PIN_TYPE_QUEST_UNCOMPLETED)
    LMP:RefreshPins(PIN_TYPE_QUEST_COMPLETED)
    LMP:RefreshPins(PIN_TYPE_QUEST_HIDDEN)
    LMP:RefreshPins(PIN_TYPE_QUEST_STARTED)
    LMP:RefreshPins(PIN_TYPE_QUEST_REPEATABLE)
    LMP:RefreshPins(PIN_TYPE_QUEST_DAILY)
    LMP:RefreshPins(PIN_TYPE_QUEST_CADWELL)
    LMP:RefreshPins(PIN_TYPE_QUEST_SKILL)
end

-- Callback function which is called every time another map is viewed, creates quest pins
--[[
ZO_NORMAL_TEXT
ZO_HIGHLIGHT_TEXT
ZO_HINT_TEXT
]]--
local QUEST_NAME_LAYOUT = {

    [PIN_TYPE_QUEST_UNCOMPLETED] =
    {
        color = ZO_NORMAL_TEXT,
        suffix = "(UN)",
    },
    [PIN_TYPE_QUEST_COMPLETED] =
    {
        color = ZO_HIGHLIGHT_TEXT,
        suffix = "(CM)",
    },
    [PIN_TYPE_QUEST_HIDDEN] =
    {
        color = ZO_HINT_TEXT,
        suffix = "(HI)",
    },
    [PIN_TYPE_QUEST_STARTED] =
    {
        color = ZO_NORMAL_TEXT,
        suffix = "(ST)",
    },
    [PIN_TYPE_QUEST_REPEATABLE] =
    {
        color = ZO_HIGHLIGHT_TEXT,
        suffix = "(RP)",
    },
    [PIN_TYPE_QUEST_DAILY] =
    {
        color = ZO_HIGHLIGHT_TEXT,
        suffix = "(DA)",
    },
    [PIN_TYPE_QUEST_SKILL] =
    {
        color = ZO_HIGHLIGHT_TEXT,
        suffix = "(SK)",
    },
    [PIN_TYPE_QUEST_CADWELL] =
    {
        color = ZO_HIGHLIGHT_TEXT,
        suffix = "(CW)",
    },
}

local function FormatQuestName(questName, questNameLayoutType)
    local layout = QUEST_NAME_LAYOUT[questNameLayoutType]
    local color = layout.color
    local suffix = layout.suffix
    return color:Colorize(string.format("%s %s", questName, suffix))
end

function check_map_state()
    QuestMap.dm("Debug", "Checking map state")
    if last_mapid and (GetCurrentMapId() ~= last_mapid) then
        QuestMap.dm("Debug", "changed")
        QuestMap.dm("Debug", GetCurrentMapId())
        if GetMapType() > MAPTYPE_ZONE then
            QuestMap.dm("Debug", "stopped")
            return
        end
        local zone = LMP:GetZoneAndSubzone(true, false, true)
        zoneQuests = LQD:get_quest_list(zone)
        QuestMap.dm("Debug", "RefreshPins")
        QuestMap:RefreshPins()
    else
        QuestMap.dm("Debug", "Did not change or not assigned")
    end
    last_mapid = GetCurrentMapId()
end

CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", function(navigateIn)
    check_map_state()
end)

WORLD_MAP_SCENE:RegisterCallback("StateChange", function(oldState, newState)
    if newState == SCENE_SHOWING then
        check_map_state()
    elseif newState == SCENE_HIDDEN then
        check_map_state()
    end
end)

local function MapCallbackQuestPins(pinType)
    local hidden_quest
    if GetMapType() > MAPTYPE_ZONE then return end

    if last_mapid and (GetCurrentMapId() ~= last_mapid) then return end
    -- Loop over both quests and create a map pin with the quest name
    for key, quest in pairs(zoneQuests) do

        -- Get quest name and only continue if string isn't empty
        local name = LQD:get_quest_name(quest[LQD.quest_map_pin_index.quest_id])
        QuestMap.dm("Debug", name)
        if name ~= "" then
            if quest[LQD.quest_map_pin_index.global_x] ~= -10 then
                quest[LQD.quest_map_pin_index.local_x], quest[LQD.quest_map_pin_index.local_y] = GPS:GlobalToLocal(quest[LQD.quest_map_pin_index.global_x], quest[LQD.quest_map_pin_index.global_y])
            end

            -- Get quest type info
            -- local uncompleted_quest, it's just when it's not completed
            local completed_quest = LQD.completed_quests[quest[LQD.quest_map_pin_index.quest_id]] or false
             -- Quest Name when set
            if QuestMap.settings.hiddenQuests[quest[LQD.quest_map_pin_index.quest_id]] ~= nil then
                hidden_quest = true
            else
                hidden_quest = false
            end
            local started_quest = LQD.started_quests[quest[LQD.quest_map_pin_index.quest_id]] or false
            local repeatable_type = LQD:get_quest_repeat(quest[LQD.quest_map_pin_index.quest_id])
            local skill_quest = LQD.quest_rewards_skilpoint[quest[LQD.quest_map_pin_index.quest_id]] or false
            local cadwell_quest = LQD:get_qm_quest_type(quest[LQD.quest_map_pin_index.quest_id]) or false
            local pinInfo = { id = quest[LQD.quest_map_pin_index.quest_id] } -- pinName is defined later
            --QuestMap.dm("Debug", pinInfo)
            --QuestMap.dm("Debug", "Pin Type: "..pinType)
            --QuestMap.dm("Debug", completed_quest)
            --QuestMap.dm("Debug", hidden_quest)
            --QuestMap.dm("Debug", started_quest)
            --QuestMap.dm("Debug", repeatable_type)
            --QuestMap.dm("Debug", skill_quest)
            --QuestMap.dm("Debug", cadwell_quest)

            --if LQD.completed_quests[quest[LQD.quest_map_pin_index.quest_id]] then

            -- Create pins for completed quests
            if pinType == PIN_TYPE_QUEST_COMPLETED then
                -- and (not skill_quest or not cadwell_quest) when skill point and cadwell not active
                if completed_quest then
                    --QuestMap.dm("Debug", repeatable_type)
                    --QuestMap.dm("Debug", LQD.quest_data_repeat.quest_repeat_daily)
                    --QuestMap.dm("Debug", (repeatable_type == LQD.quest_data_repeat.quest_repeat_daily and not LMP:IsEnabled(PIN_TYPE_QUEST_DAILY)))
                    if (repeatable_type == LQD.quest_data_repeat.quest_repeat_repeatable and LMP:IsEnabled(PIN_TYPE_QUEST_REPEATABLE)) or
                        (repeatable_type == LQD.quest_data_repeat.quest_repeat_daily and LMP:IsEnabled(PIN_TYPE_QUEST_DAILY)) then
                        -- don't draw it
                    else
                        -- draw it
                        if LMP:IsEnabled(PIN_TYPE_QUEST_COMPLETED) then
                            --QuestMap.dm("Debug", PIN_TYPE_QUEST_COMPLETED)
                            pinInfo.pinName = FormatQuestName(name, PIN_TYPE_QUEST_COMPLETED)
                            LMP:CreatePin(PIN_TYPE_QUEST_COMPLETED, pinInfo, quest[LQD.quest_map_pin_index.local_x], quest[LQD.quest_map_pin_index.local_y])
                        end
                    end
                end
            end
                -- Create pins for hidden quests
            if pinType == PIN_TYPE_QUEST_HIDDEN then
                if hidden_quest then
                    if LMP:IsEnabled(PIN_TYPE_QUEST_HIDDEN) then
                        --QuestMap.dm("Debug", PIN_TYPE_QUEST_HIDDEN)
                        pinInfo.pinName = FormatQuestName(name, PIN_TYPE_QUEST_HIDDEN)
                        LMP:CreatePin(PIN_TYPE_QUEST_HIDDEN, pinInfo, quest[LQD.quest_map_pin_index.local_x], quest[LQD.quest_map_pin_index.local_y])
                    end
                end
            end


            if pinType == PIN_TYPE_QUEST_STARTED then
                if not completed_quest and started_quest then
                    --if started_quest and (repeatable_type == 0 or repeatable_type == -1) and not hidden_quest then
                    if LMP:IsEnabled(PIN_TYPE_QUEST_STARTED) then
                        --QuestMap.dm("Debug", PIN_TYPE_QUEST_STARTED)
                        pinInfo.pinName = FormatQuestName(name, PIN_TYPE_QUEST_STARTED)
                        LMP:CreatePin(PIN_TYPE_QUEST_STARTED, pinInfo, quest[LQD.quest_map_pin_index.local_x], quest[LQD.quest_map_pin_index.local_y])
                    end
                end
            end

            if pinType == PIN_TYPE_QUEST_REPEATABLE then
                if repeatable_type == LQD.quest_data_repeat.quest_repeat_repeatable then
                    if LMP:IsEnabled(PIN_TYPE_QUEST_REPEATABLE) then
                        --QuestMap.dm("Debug", PIN_TYPE_QUEST_REPEATABLE)
                        pinInfo.pinName = FormatQuestName(name, PIN_TYPE_QUEST_REPEATABLE)
                        LMP:CreatePin(PIN_TYPE_QUEST_REPEATABLE, pinInfo, quest[LQD.quest_map_pin_index.local_x], quest[LQD.quest_map_pin_index.local_y])
                    end
                end
            end

            if pinType == PIN_TYPE_QUEST_DAILY then
                if repeatable_type == LQD.quest_data_repeat.quest_repeat_daily then
                    if LMP:IsEnabled(PIN_TYPE_QUEST_DAILY) then
                        --QuestMap.dm("Debug", PIN_TYPE_QUEST_DAILY)
                        pinInfo.pinName = FormatQuestName(name, PIN_TYPE_QUEST_DAILY)
                        LMP:CreatePin(PIN_TYPE_QUEST_DAILY, pinInfo, quest[LQD.quest_map_pin_index.local_x], quest[LQD.quest_map_pin_index.local_y])
                    end
                end
            end

            if pinType == PIN_TYPE_QUEST_SKILL then
                if not completed_quest and skill_quest then
                    if LMP:IsEnabled(PIN_TYPE_QUEST_SKILL) then
                        --QuestMap.dm("Debug", PIN_TYPE_QUEST_SKILL)
                        pinInfo.pinName = FormatQuestName(name, PIN_TYPE_QUEST_SKILL)
                        LMP:CreatePin(PIN_TYPE_QUEST_SKILL, pinInfo, quest[LQD.quest_map_pin_index.local_x], quest[LQD.quest_map_pin_index.local_y])
                    end
                end
            end

            if pinType == PIN_TYPE_QUEST_CADWELL then
                if not completed_quest and cadwell_quest then
                    if LMP:IsEnabled(PIN_TYPE_QUEST_CADWELL) then
                        --QuestMap.dm("Debug", PIN_TYPE_QUEST_CADWELL)
                        pinInfo.pinName = FormatQuestName(name, PIN_TYPE_QUEST_CADWELL)
                        LMP:CreatePin(PIN_TYPE_QUEST_CADWELL, pinInfo, quest[LQD.quest_map_pin_index.local_x], quest[LQD.quest_map_pin_index.local_y])
                    end
                end
            end

            if pinType == PIN_TYPE_QUEST_UNCOMPLETED then
                if not completed_quest and not started_quest and not hidden_quest then
                    if (repeatable_type == LQD.quest_data_repeat.quest_repeat_repeatable and LMP:IsEnabled(PIN_TYPE_QUEST_REPEATABLE)) or
                        (repeatable_type == LQD.quest_data_repeat.quest_repeat_daily and LMP:IsEnabled(PIN_TYPE_QUEST_DAILY)) or
                        (skill_quest and LMP:IsEnabled(PIN_TYPE_QUEST_SKILL)) or
                        (cadwell_quest and LMP:IsEnabled(PIN_TYPE_QUEST_CADWELL))
                    then
                        -- do not draw it
                        QuestMap.dm("Debug", "do not draw it")
                    else
                        -- draw it
                        if LMP:IsEnabled(PIN_TYPE_QUEST_UNCOMPLETED) then
                            QuestMap.dm("Debug", "Drawing Uncompleted Pin"..name)
                            pinInfo.pinName = FormatQuestName(name, PIN_TYPE_QUEST_UNCOMPLETED)
                            LMP:CreatePin(PIN_TYPE_QUEST_UNCOMPLETED, pinInfo, quest[LQD.quest_map_pin_index.local_x], quest[LQD.quest_map_pin_index.local_y])
                        end
                    end
                end
            end
            --[[
            ]]--

            QuestMap.dm("Debug", "Next Quest")

        end
    end
    QuestMap.dm("Debug", "End --------------------")
end

-- Function to refresh pin appearance (e.g. from settings menu)
function QuestMap:RefreshPinLayout()
    LMP:SetLayoutKey(PIN_TYPE_QUEST_UNCOMPLETED, "size", QuestMap.settings.pinSize)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_UNCOMPLETED, "level", QuestMap.settings.pinLevel+PIN_PRIORITY_OFFSET)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_UNCOMPLETED, "texture", QuestMap.iconSets[QuestMap.settings.iconSet][1])
    LMP:RefreshPins(PIN_TYPE_QUEST_UNCOMPLETED)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_COMPLETED, "size", QuestMap.settings.pinSize)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_COMPLETED, "level", QuestMap.settings.pinLevel)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_COMPLETED, "texture", QuestMap.iconSets[QuestMap.settings.iconSet][2])
    LMP:RefreshPins(PIN_TYPE_QUEST_COMPLETED)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_HIDDEN, "size", QuestMap.settings.pinSize)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_HIDDEN, "level", QuestMap.settings.pinLevel)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_HIDDEN, "texture", QuestMap.iconSets[QuestMap.settings.iconSet][2])
    LMP:RefreshPins(PIN_TYPE_QUEST_HIDDEN)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_STARTED, "size", QuestMap.settings.pinSize)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_STARTED, "level", QuestMap.settings.pinLevel+PIN_PRIORITY_OFFSET)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_STARTED, "texture", QuestMap.iconSets[QuestMap.settings.iconSet][1])
    LMP:RefreshPins(PIN_TYPE_QUEST_STARTED)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_REPEATABLE, "size", QuestMap.settings.pinSize)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_REPEATABLE, "level", QuestMap.settings.pinLevel)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_REPEATABLE, "texture", QuestMap.internal_icons.repeatable)
    LMP:RefreshPins(PIN_TYPE_QUEST_REPEATABLE)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_DAILY, "size", QuestMap.settings.pinSize)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_DAILY, "level", QuestMap.settings.pinLevel)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_DAILY, "texture", QuestMap.internal_icons.repeatable)
    LMP:RefreshPins(PIN_TYPE_QUEST_DAILY)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_SKILL, "size", QuestMap.settings.pinSize)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_SKILL, "level", QuestMap.settings.pinLevel)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_SKILL, "texture", QuestMap.iconSets[QuestMap.settings.iconSet][2])
    LMP:RefreshPins(PIN_TYPE_QUEST_SKILL)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_CADWELL, "size", QuestMap.settings.pinSize)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_CADWELL, "level", QuestMap.settings.pinLevel)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_CADWELL, "texture", QuestMap.iconSets[QuestMap.settings.iconSet][2])
    LMP:RefreshPins(PIN_TYPE_QUEST_CADWELL)
end

-- Function to refresh pin filters (e.g. from settings menu)
function QuestMap:RefreshPinFilters()
    LMP:SetEnabled(PIN_TYPE_QUEST_UNCOMPLETED,  QuestMap.settings.pinFilters[PIN_TYPE_QUEST_UNCOMPLETED])
    LMP:SetEnabled(PIN_TYPE_QUEST_COMPLETED,    QuestMap.settings.pinFilters[PIN_TYPE_QUEST_COMPLETED])
    LMP:SetEnabled(PIN_TYPE_QUEST_HIDDEN,       QuestMap.settings.pinFilters[PIN_TYPE_QUEST_HIDDEN])
    LMP:SetEnabled(PIN_TYPE_QUEST_STARTED,      QuestMap.settings.pinFilters[PIN_TYPE_QUEST_STARTED])
    LMP:SetEnabled(PIN_TYPE_QUEST_REPEATABLE,   QuestMap.settings.pinFilters[PIN_TYPE_QUEST_REPEATABLE])
    LMP:SetEnabled(PIN_TYPE_QUEST_DAILY,        QuestMap.settings.pinFilters[PIN_TYPE_QUEST_DAILY])
    LMP:SetEnabled(PIN_TYPE_QUEST_SKILL,        QuestMap.settings.pinFilters[PIN_TYPE_QUEST_SKILL])
    LMP:SetEnabled(PIN_TYPE_QUEST_CADWELL,      QuestMap.settings.pinFilters[PIN_TYPE_QUEST_CADWELL])
end

-- Function to (un)hide all quests on the currently displayed map
local function SetQuestsInZoneHidden(str)
    usage = GetString(QUESTMAP_SLASH_USAGE)
    if type(str) ~= "string" then return end
    if ZO_WorldMap:IsHidden() then p(GetString(QUESTMAP_SLASH_MAPINFO)); return end
    local map = LMP:GetZoneAndSubzone(true, false, true)

    -- Trim whitespaces from input string
    argument = str:gsub("^%s*(.-)%s*$", "%1")
    -- Convert string to lower case
    argument = str:lower()

    if str ~= "unhide" and str ~= "hide" then p(usage); return end

    -- Get quest list for that zone from database
    local questlist = LQD:get_quest_list(map)

    if str == "unhide" then
        for _, quest in ipairs(questlist) do
            -- Remove from list that holds hidden quests
            QuestMap.settings.hiddenQuests[quest[LQD.quest_map_pin_index.quest_id]] = nil
        end
        if QuestMap.settings.displayClickMsg then p(GetString(QUESTMAP_MSG_UNHIDDEN_P).." @ |cFFFFFF"..LMP:GetZoneAndSubzone(true, false, true)) end
    elseif str == "hide" then
        for _, quest in ipairs(questlist) do
            -- Hiding only necessary for uncompleted quests
            if not LQD.completed_quests[quest[LQD.quest_map_pin_index.quest_id]] then
                -- Add to list that holds hidden quests
                QuestMap.settings.hiddenQuests[quest[LQD.quest_map_pin_index.quest_id]] = LQD:get_quest_name(quest.id)
            end
        end
        if QuestMap.settings.displayClickMsg then p(GetString(QUESTMAP_MSG_HIDDEN_P).." @ |cFFFFFF"..LMP:GetZoneAndSubzone(true, false, true)) end
    else
        p(usage)
        return
    end
end

-- Event handler function for EVENT_PLAYER_ACTIVATED
local function OnPlayerActivated(eventCode)
    QuestMap.dm("Debug", "Starting QuestMap")
    -- Set up SavedVariables table
    QuestMap.settings = ZO_SavedVars:NewAccountWide("QuestMap_SavedVariables", 3, nil, QuestMap.settings_default)

    -- Get saved variables table for current user/char directly (without metatable), so it is possible to use pairs()
    local sv = QuestMap_SavedVariables.Default[GetDisplayName()]["$AccountWide"]
    -- Clean up saved variables (from previous versions)
    for key, val in pairs(sv) do
        -- Delete key-value pair if the key can't also be found in the default settings (except for version)
        if key ~= "version" and QuestMap.settings_default[key] == nil then
            sv[key] = nil
        end
    end

    for key, val in pairs(QuestMap_SavedVariables.Default[GetDisplayName()]) do
        if key ~= "$AccountWide" then
            --d(key)
            --d(QuestMap_SavedVariables.Default[GetDisplayName()][key])
            if QuestMap_SavedVariables.Default[GetDisplayName()][key] ~= nil then QuestMap_SavedVariables.Default[GetDisplayName()][key] = nil end
        end
    end

    local zone = LMP:GetZoneAndSubzone(true, false, true)
    QuestMap.dm("Debug", zone)
    zoneQuests = LQD:get_quest_list(zone)

    -- Get tootip of each individual pin
    local pinTooltipCreator = {
        creator = function(pin)
            local pinTag = select(2, pin:GetPinTypeAndTag())
            if IsInGamepadPreferredMode() then
                local InformationTooltip = ZO_MapLocationTooltip_Gamepad
                local baseSection = InformationTooltip.tooltip
                InformationTooltip:LayoutIconStringLine(baseSection, nil, QuestMap.idName, baseSection:GetStyle("mapLocationTooltipContentHeader"))
                InformationTooltip:LayoutIconStringLine(baseSection, nil, pinTag.pinName, baseSection:GetStyle("mapLocationTooltipContentName"))
            else
                SetTooltipText(InformationTooltip, pinTag.pinName)
            end
        end,
    }

    -- first pinLayout, uncompleted, started
    local pinLayout_1 = {level = QuestMap.settings.pinLevel+PIN_PRIORITY_OFFSET, texture = QuestMap.iconSets[QuestMap.settings.iconSet][1], size = QuestMap.settings.pinSize}
    -- second pinLayout for completed, hidden
    local pinLayout_2 = {level = QuestMap.settings.pinLevel, texture = QuestMap.iconSets[QuestMap.settings.iconSet][2], size = QuestMap.settings.pinSize}
    -- third pinLayout for repeatable and daily
    local pinLayout_3 = {level = QuestMap.settings.pinLevel, texture = QuestMap.internal_icons.repeatable, size = QuestMap.settings.pinSize}

    -- Add new pin types for quests
    LMP:AddPinType(PIN_TYPE_QUEST_UNCOMPLETED, function() MapCallbackQuestPins(PIN_TYPE_QUEST_UNCOMPLETED) end, nil, pinLayout_1, pinTooltipCreator)
    LMP:AddPinType(PIN_TYPE_QUEST_COMPLETED, function() MapCallbackQuestPins(PIN_TYPE_QUEST_COMPLETED) end, nil, pinLayout_2, pinTooltipCreator)
    LMP:AddPinType(PIN_TYPE_QUEST_HIDDEN, function() MapCallbackQuestPins(PIN_TYPE_QUEST_HIDDEN) end, nil, pinLayout_2, pinTooltipCreator)
    LMP:AddPinType(PIN_TYPE_QUEST_STARTED, function() MapCallbackQuestPins(PIN_TYPE_QUEST_STARTED) end, nil, pinLayout_1, pinTooltipCreator)
    LMP:AddPinType(PIN_TYPE_QUEST_REPEATABLE, function() MapCallbackQuestPins(PIN_TYPE_QUEST_REPEATABLE) end, nil, pinLayout_3, pinTooltipCreator)
    LMP:AddPinType(PIN_TYPE_QUEST_DAILY, function() MapCallbackQuestPins(PIN_TYPE_QUEST_DAILY) end, nil, pinLayout_3, pinTooltipCreator)

    LMP:AddPinType(PIN_TYPE_QUEST_CADWELL, function() MapCallbackQuestPins(PIN_TYPE_QUEST_CADWELL) end, nil, pinLayout_2, pinTooltipCreator)
    LMP:AddPinType(PIN_TYPE_QUEST_SKILL, function() MapCallbackQuestPins(PIN_TYPE_QUEST_SKILL) end, nil, pinLayout_2, pinTooltipCreator)

    -- Add map filters
    LMP:AddPinFilter(PIN_TYPE_QUEST_UNCOMPLETED, GetString(QUESTMAP_QUESTS).." ("..GetString(QUESTMAP_UNCOMPLETED)..")", true, QuestMap.settings.pinFilters, PIN_TYPE_QUEST_UNCOMPLETED, PIN_TYPE_QUEST_UNCOMPLETED_PVP)
    LMP:AddPinFilter(PIN_TYPE_QUEST_COMPLETED, GetString(QUESTMAP_QUESTS).." ("..GetString(QUESTMAP_COMPLETED)..")", true, QuestMap.settings.pinFilters, PIN_TYPE_QUEST_COMPLETED, PIN_TYPE_QUEST_COMPLETED_PVP)
    LMP:AddPinFilter(PIN_TYPE_QUEST_HIDDEN, GetString(QUESTMAP_QUESTS).." ("..GetString(QUESTMAP_HIDDEN)..")", true, QuestMap.settings.pinFilters, PIN_TYPE_QUEST_HIDDEN, PIN_TYPE_QUEST_HIDDEN_PVP)
    LMP:AddPinFilter(PIN_TYPE_QUEST_STARTED, GetString(QUESTMAP_QUESTS).." ("..GetString(QUESTMAP_STARTED)..")", true, QuestMap.settings.pinFilters, PIN_TYPE_QUEST_STARTED, PIN_TYPE_QUEST_STARTED_PVP)
    LMP:AddPinFilter(PIN_TYPE_QUEST_REPEATABLE, GetString(QUESTMAP_QUESTS).." ("..GetString(QUESTMAP_REPEATABLE)..")", true, QuestMap.settings.pinFilters, PIN_TYPE_QUEST_REPEATABLE, PIN_TYPE_QUEST_REPEATABLE_PVP)
    LMP:AddPinFilter(PIN_TYPE_QUEST_DAILY, GetString(QUESTMAP_QUESTS).." ("..GetString(QUESTMAP_DAILY)..")", true, QuestMap.settings.pinFilters, PIN_TYPE_QUEST_DAILY, PIN_TYPE_QUEST_DAILY_PVP)
    LMP:AddPinFilter(PIN_TYPE_QUEST_CADWELL, GetString(QUESTMAP_QUEST_SUBFILTER).." ("..GetString(QUESTMAP_CADWELL)..")", true, QuestMap.settings.pinFilters, PIN_TYPE_QUEST_CADWELL, PIN_TYPE_QUEST_CADWELL_PVP)
    LMP:AddPinFilter(PIN_TYPE_QUEST_SKILL, GetString(QUESTMAP_QUEST_SUBFILTER).." ("..GetString(QUESTMAP_SKILL)..")", true, QuestMap.settings.pinFilters, PIN_TYPE_QUEST_SKILL, PIN_TYPE_QUEST_SKILL_PVP)

    LMP:SetPinFilterHidden(PIN_TYPE_QUEST_CADWELL, "pvp", true)
    LMP:SetPinFilterHidden(PIN_TYPE_QUEST_CADWELL, "imperialPvP", true)
    LMP:SetPinFilterHidden(PIN_TYPE_QUEST_CADWELL, "battleground", true)
    LMP:SetPinFilterHidden(PIN_TYPE_QUEST_SKILL, "pvp", true)
    LMP:SetPinFilterHidden(PIN_TYPE_QUEST_SKILL, "imperialPvP", true)
    LMP:SetPinFilterHidden(PIN_TYPE_QUEST_SKILL, "battleground", true)

    QuestMap:RefreshPinFilters()
    QuestMap:RefreshPinLayout()

    -- Add click action for pins
    LMP:SetClickHandlers(PIN_TYPE_QUEST_UNCOMPLETED, {[1] = {name = function(pin) return zo_strformat(GetString(QUESTMAP_HIDE).." |cFFFFFF<<1>>|r", LQD:get_quest_name(pin.m_PinTag.id)) end,
        show = function(pin) return true end,
        duplicates = function(pin1, pin2) return pin1.m_PinTag.id == pin2.m_PinTag.id end,
        callback = function(pin)
            -- Add to table which holds all the hidden quests
            QuestMap.settings.hiddenQuests[pin.m_PinTag.id] = LQD:get_quest_name(pin.m_PinTag.id)
            if QuestMap.settings.displayClickMsg then p(GetString(QUESTMAP_MSG_HIDDEN)..": |cFFFFFF"..LQD:get_quest_name(pin.m_PinTag.id)) end
            QuestMap:RefreshPins()
        end}})
    LMP:SetClickHandlers(PIN_TYPE_QUEST_COMPLETED, {[1] = {name = function(pin) return zo_strformat("Quest |cFFFFFF<<1>>|r", LQD:get_quest_name(pin.m_PinTag.id)) end,
        show = function(pin) return true end,
        duplicates = function(pin1, pin2) return pin1.m_PinTag.id == pin2.m_PinTag.id end,
        callback = function(pin)
        -- Do nothing
        end}})
    LMP:SetClickHandlers(PIN_TYPE_QUEST_HIDDEN, {[1] = {name = function(pin) return zo_strformat(GetString(QUESTMAP_UNHIDE).." |cFFFFFF<<1>>|r", LQD:get_quest_name(pin.m_PinTag.id)) end,
        show = function(pin) return true end,
        duplicates = function(pin1, pin2) return pin1.m_PinTag.id == pin2.m_PinTag.id end,
        callback = function(pin)
            -- Remove from table which holds all the hidden quests
            QuestMap.settings.hiddenQuests[pin.m_PinTag.id] = nil
            if QuestMap.settings.displayClickMsg then p(GetString(QUESTMAP_MSG_UNHIDDEN)..": |cFFFFFF"..LQD:get_quest_name(pin.m_PinTag.id)) end
            QuestMap:RefreshPins()
        end}})

    -- Register slash commands and link function
    SLASH_COMMANDS["/qm"] = function(str)
        SetQuestsInZoneHidden(str)
        QuestMap:RefreshPins()
        -- If the list window was open, update it too by running the function again without argument
        if ListUI ~= nil and not ListUI:IsHidden() then
            DisplayListUI()
        end
    end
    if LMW == nil then
        SLASH_COMMANDS["/qmlist"] = function()
            p("LibMsgWin-1.0 "..GetString(QUESTMAP_LIB_REQUIRED))
        end
    else
        SLASH_COMMANDS["/qmlist"] = DisplayListUI
    end
    SLASH_COMMANDS["/qmgetpos"] = GetPlayerPos

    EVENT_MANAGER:UnregisterForEvent(QuestMap.idName, EVENT_PLAYER_ACTIVATED)
end
EVENT_MANAGER:RegisterForEvent(QuestMap.idName, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

-- Event handler function for EVENT_QUEST_REMOVED and EVENT_QUEST_ADDED
local function OnQuestRemovedOrAdded(eventCode)
    QuestMap:RefreshPins()
end
EVENT_MANAGER:RegisterForEvent(QuestMap.idName, EVENT_QUEST_ADDED,      OnQuestRemovedOrAdded)
EVENT_MANAGER:RegisterForEvent(QuestMap.idName, EVENT_QUEST_REMOVED,    OnQuestRemovedOrAdded)
