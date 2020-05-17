--[[

Quest Map
by CaptainBlagbird
https://github.com/CaptainBlagbird

--]]

-- Libraries
local LMP = LibMapPins
local LMW = LibMsgWin
local GPS = LibGPS2
local LQI = LibQuestInfo

-- Constants
local PIN_PRIORITY_OFFSET = 1
-- Transfer from init
local PIN_TYPE_QUEST_UNCOMPLETED = QuestMap.pinTypes.uncompleted
local PIN_TYPE_QUEST_COMPLETED   = QuestMap.pinTypes.completed
local PIN_TYPE_QUEST_HIDDEN      = QuestMap.pinTypes.hidden
local PIN_TYPE_QUEST_STARTED     = QuestMap.pinTypes.started
local PIN_TYPE_QUEST_CADWELL     = QuestMap.pinTypes.cadwell
local PIN_TYPE_QUEST_SKILL       = QuestMap.pinTypes.skill
-- Local variables
local completedQuests = {}
local startedQuests = {}
local lastZone = ""
local zoneQuests = {}
local subzoneQuests = {}
local all_scout_quests

-------------------------------------------------
----- Rebuild Quest Names for "ids" Table    ----
-------------------------------------------------

local function build_names_id_table()
    --[[
    Manually set until I find a better way.

    Also this requires you to manually wdit the manifent,
    and the alternate language files. If you do not do that
    it won't work. So this is a complete hack that requires
    knowledge of how to use it.
    ]]--
    lang = "en"

    local built_table = {}
    local all_quests_to_parse = {}

    if lang == "en" then
        all_quests_to_parse = QuestMap:GetAllQuests_en()
    end
    if lang == "de" then
        all_quests_to_parse = QuestMap:GetAllQuests_de()
    end
    if lang == "fr" then
        all_quests_to_parse = QuestMap:GetAllQuests_fr()
    end
    if lang == "jp" then
        all_quests_to_parse = QuestMap:GetAllQuests_jp()
    end

    local function contains_id(quent_ids, id_to_find)
        local found_id = false
        for questname, quest_ids in pairs(quent_ids) do
            -- print(questname)
            for _, quest_id in pairs(quest_ids) do
                -- print(quest_id)
                if quest_id == id_to_find then
                    found_id = true
                end
            end
        end
        return found_id
    end

    for var1, var2 in pairs(all_quests_to_parse) do
        -- print(var2)
        -- print(var2)
        if built_table[var2] == nil then built_table[var2] = {} end
        if contains_id(built_table, var1) then
            -- print("Var 1 is in ids")
        else
            -- print("Var 1 is not in ids")
            table.insert(built_table[var2], var1)
        end
    end

    -- Debug(built_table)

    local quest_names_table = {}

    for var1, var2 in pairs(built_table) do
        -- print(var1)
        local output_string = "\\dq"..var1.."\\dq = \\dq"
        for var_1, var_2 in pairs(var2) do
            -- print(var_1)
            -- print(var_2)
            output_string = output_string..tostring(var_2)..", "
        end
        output_string = output_string.."\\dq "
        table.insert(quest_names_table, output_string)
    end

    QuestMap.savedVars["quest_names"].data = quest_names_table
end

-------------------------------------------------
----- Import Quest Map Log Data             -----
-------------------------------------------------

local function QML_ImportData()
    local quest_table = {
        ["en"] = {},
        ["de"] = {},
        ["fr"] = {},
    }

    if QuestMapLog then
        for account, savedvars_key in pairs(QuestMapLog_SavedVariables.Default) do
            for data_key, table_data in pairs(QuestMapLog_SavedVariables.Default[account]) do
                if data_key ~= "$AccountWide" then
                    for var1, var2 in pairs(QuestMapLog_SavedVariables.Default[account][data_key]["log"]["data"]) do
                        temp_string = tostring(var1).."\\dq"..var2.name.."\\dq"
                        if not quest_table[var2.lang][var1] then
                            quest_table[var2.lang][var1] = temp_string
                        end
                    end
                end
            end
        end
        QuestMap.savedVars["quest_names"].data = quest_table
    end
end

-------------------------------------------------
----- Quest Map Log                         -----
-------------------------------------------------

local function QML_GetData()
    completedQuests = {}
    -- Saved variables table
    QM_Log = {}

    local id
    -- There currently are < 7000 quests, but some can be completed multiple times.
    -- 10000 should be more than enough to get all completed quests and still avoid an endless loop.
    for i=0, 10000 do
        -- Get next completed quest. If it was the last, break loop
        id = GetNextCompletedQuestId(i)
        if id == nil then break end
        -- Add the quest to the list
        completedQuests[id] = true
        if QuestMap.savedVars["settings"].hiddenQuests[id] ~= nil then QuestMap.savedVars["settings"].hiddenQuests[id] = nil end

        QM_Log[id] = {}
        QM_Log[id].name, QM_Log[id].questType = GetCompletedQuestInfo(id)
        QM_Log[id].zoneName, QM_Log[id].objectiveName, QM_Log[id].zoneIndex, QM_Log[id].poiIndex = GetCompletedQuestLocationInfo(id)
    end
    QuestMap.savedVars["log"].data = QM_Log
end

-------------------------------------------------
----- Helper Functions                      -----
-------------------------------------------------

function generate_quest_names()
    QML_GetData()
    local result_table = {}
    local current_quest = {}
    local quest_info = {}
    QuestMap.savedVars["quest_names"].data = {}

    for count, quest_info in pairs(QuestMap.savedVars["log"].data) do
        current_quest = {}

        current_quest.number = count
        current_quest.name = quest_info.name

        quest_string = tostring(current_quest.number)..", \\dq"..current_quest.name.."\\dq"

        table.insert(QuestMap.savedVars["quest_names"].data, quest_string)
    end
end



-------------------------------------------------
----- Get Quest Scout Data                  -----
-------------------------------------------------

local function questmap_get_scout_quests()
    local result_table = {}
    local result_table_info = {}
    local current_quest = {}
    local current_quest_info = {}
    local index_id
    if QM_Scout then
        all_scout_quests = QM_Scout.quests
        for zone, zone_quests in pairs(all_scout_quests) do
            result_table[zone] = {}
            -- d(zone)
            for count, quest_info in pairs(zone_quests) do
                current_quest = {}
                current_quest_info = {}
                index_id = -1
                -- d(quest_info)
                -- quest[LQI.quest_map_pin_index.X_LIBGPS]
                if quest_info.questID == -1 then
                    current_quest[LQI.quest_map_pin_index.QUEST_ID] = quest_info.name
                else
                    current_quest[LQI.quest_map_pin_index.QUEST_ID] = quest_info.questID
                end
                current_quest[LQI.quest_map_pin_index.X_LOCATION] = quest_info.x
                current_quest[LQI.quest_map_pin_index.Y_LOCATION] = quest_info.y
                current_quest[LQI.quest_map_pin_index.X_LIBGPS] = quest_info.gpsx
                current_quest[LQI.quest_map_pin_index.Y_LIBGPS] = quest_info.gpsy
                table.insert(result_table[zone], current_quest)

                if quest_info.questID == -1 then
                    index_id = quest_info.name
                    current_quest_info[LQI.quest_data_index.QUEST_NAME] = quest_info.name
                else
                    index_id = quest_info.questID
                    current_quest_info[LQI.quest_data_index.QUEST_NAME] = quest_info.questID
                end
                current_quest_info[LQI.quest_data_index.QUEST_GIVER] = quest_info.giver
                current_quest_info[LQI.quest_data_index.QUEST_TYPE] = quest_info.quest_type
                current_quest_info[LQI.quest_data_index.QUEST_REPEAT] = quest_info.repeat_type
                current_quest_info[LQI.quest_data_index.GAME_API] = quest_info["otherInfo"].api
                current_quest_info[LQI.quest_data_index.QUEST_LINE] = 10000
                current_quest_info[LQI.quest_data_index.QUEST_NUMBER] = 10000
                current_quest_info[LQI.quest_data_index.QUEST_SERIES] = 0
                table.insert(result_table_info[index_id], current_quest_info)
            end
        end
    else
        d("QuestMapScout not loaded")
    end
    QuestMap.savedVars["scout"].data = result_table
    if QuestMap.savedVars["scout"].info == nil then QuestMap.savedVars["scout"].info = {} end
    QuestMap.savedVars["scout"].info = result_table_info
end

local function questmap_get_libquestinfo()
    local result_table = {}
    local result_table_info = {}
    local current_quest = {}
    local current_quest_info = {}
    local index_id
    if LibQuestInfo then
        all_scout_quests = LibQuestInfo_SavedVariables.quests
        for zone, zone_quests in pairs(all_scout_quests) do
            result_table[zone] = {}
            -- d(zone)
            for count, quest_info in pairs(zone_quests) do
                current_quest = {}
                current_quest_info = {}
                index_id = -1
                -- d(quest_info)
                -- quest[LQI.quest_map_pin_index.X_LIBGPS]
                if quest_info.questID == -1 then
                    current_quest[LQI.quest_map_pin_index.QUEST_ID] = quest_info.name
                else
                    current_quest[LQI.quest_map_pin_index.QUEST_ID] = quest_info.questID
                end
                current_quest[LQI.quest_map_pin_index.X_LOCATION] = quest_info.x
                current_quest[LQI.quest_map_pin_index.Y_LOCATION] = quest_info.y
                current_quest[LQI.quest_map_pin_index.X_LIBGPS] = quest_info.gpsx
                current_quest[LQI.quest_map_pin_index.Y_LIBGPS] = quest_info.gpsy
                -- d(current_quest)
                table.insert(result_table[zone], current_quest)

                if quest_info.questID == -1 then
                    index_id = quest_info.name
                    if result_table_info[index_id] == nil then result_table_info[index_id] = {} end
                    result_table_info[index_id][LQI.quest_data_index.QUEST_NAME] = quest_info.name
                else
                    index_id = quest_info.questID
                    if result_table_info[index_id] == nil then result_table_info[index_id] = {} end
                    result_table_info[index_id][LQI.quest_data_index.QUEST_NAME] = quest_info.questID
                end
                result_table_info[index_id][LQI.quest_data_index.QUEST_GIVER] = quest_info.giver
                result_table_info[index_id][LQI.quest_data_index.QUEST_TYPE] = quest_info.quest_type
                result_table_info[index_id][LQI.quest_data_index.QUEST_REPEAT] = quest_info.repeat_type
                result_table_info[index_id][LQI.quest_data_index.GAME_API] = quest_info["otherInfo"].api
                result_table_info[index_id][LQI.quest_data_index.QUEST_LINE] = 10000
                result_table_info[index_id][LQI.quest_data_index.QUEST_NUMBER] = 10000
                result_table_info[index_id][LQI.quest_data_index.QUEST_SERIES] = 0
                -- d(current_quest_info)
                -- table.insert(result_table_info[index_id], current_quest_info)
            end
        end
    else
        d("Weird, LibQuestInfo not loaded?!?")
    end
    QuestMap.savedVars["scout"].data = result_table
    if QuestMap.savedVars["scout"].info == nil then QuestMap.savedVars["scout"].info = {} end
    QuestMap.savedVars["scout"].info = result_table_info
end

-------------------------------------------------
----- Rebuild Data from ZoneQuests.lua      -----
-------------------------------------------------

local function questmap_rebuild_quest_data()
    local result_table = {}
    local current_quest = {}
    all_quest_data = QuestMap:GetQuestTable()
    for zone, zone_quests in pairs(all_quest_data) do
        result_table[zone] = {}
        for count, quest_info in pairs(zone_quests) do
            current_quest.id = quest_info.id
            if quest_info.xpos then
                current_quest.xpos = quest_info.xpos
                current_quest.ypos = quest_info.ypos
                quest_string = "{ id = "..tostring(current_quest.id)..", xpos = "..tostring(current_quest.xpos)..", ypos = "..tostring(current_quest.ypos)..", }"
            else
                current_quest.x = quest_info.x
                current_quest.y = quest_info.y
                quest_string = "{ id = "..tostring(current_quest.id)..", x = "..tostring(current_quest.x)..", y = "..tostring(current_quest.y)..", }"
            end
            table.insert(result_table[zone], quest_string)
        end
    end
    QuestMap.savedVars["quest_data"].data = result_table
end

-------------------------------------------------
----- Reset Helper Data                     -----
-------------------------------------------------

local function questmap_reset_helper_data()
    QuestMap.savedVars["quest_data"].data = {}
    QuestMap.savedVars["scout"].data = {}
    QuestMap.savedVars["scout"].info = {}
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


-- Library hack to be able to detect when a map pin filter gets unchecked (overwrite RemovePins function)
local function SetFilterToggleCallback(pinType, positiveToggle, func)
    if type(func) ~= "function" or (type(pinType) ~= "string" and type(pinType) ~= "number") then return end
    -- Convert pinTypeString to pinTypeId
    if type(pinType) == "string" then
        pinType = _G[pinType]
    end

    local isFirstRun = false
    if LMP.FilterToggleHandlers == nil then
        isFirstRun = true
        LMP.FilterToggleHandlers = {}
        LMP.FilterToggleHandlers.positiveToggle = {}
        LMP.FilterToggleHandlers.negativeToggle = {}
    end

    -- Add to list
    if positiveToggle then
        LMP.FilterToggleHandlers.positiveToggle[pinType] = func
    else
        LMP.FilterToggleHandlers.negativeToggle[pinType] = func
    end

    if isFirstRun then
        -- Update SetCustomPinEnabled function
        local oldSetCustomPinEnabled = LMP.pinManager.SetCustomPinEnabled
        local function newSetCustomPinEnabled(t, pinTypeId, enabled)
            oldSetCustomPinEnabled(t, pinTypeId, enabled)
            -- Run callback function
            if enabled then
                -- Filter enabled
                if LMP.FilterToggleHandlers.positiveToggle[pinType] ~= nil then
                    LMP.FilterToggleHandlers.positiveToggle[pinType]()
                end
            else
                -- Filter disabled
                if LMP.FilterToggleHandlers.negativeToggle[pinType] ~= nil then
                    LMP.FilterToggleHandlers.negativeToggle[pinType]()
                end
            end
        end
        LMP.pinManager.SetCustomPinEnabled = newSetCustomPinEnabled
    end
end

-- Function to check for empty table
local function isEmpty(t)
    if next(t) == nil then
        return true
    else
        return false
    end
end

-- Function to print text to the chat window including the addon name
local function p(s)
    -- Add addon name to message
    s = "|c70C0DE["..QuestMap.displayName.."]|r "..s
    -- Replace regular color (yellow) with ESO golden in this string
    s = s:gsub("|r", "|cC5C29E")
    -- Replace newline character with newline + ESO golden (because newline resets color to default yellow)
    s = s:gsub("\n", "\n|cC5C29E")
    -- Display message
    d(s)
end

-- Function for formatting the level string
--[[ Shar
Quests scale, this is not needed but I don't want to change
the lua saved variables and strip all the information
--]]
local function formatLevel(level)
    if level then
        level = string.format(level)
    else
        level = ""
    end
    return ""
end

-- Function to get the location/position of the player by slash command for reporting new quest givers / bugs
local function GetPlayerPos()
    -- Get location info and format coordinates
    local zone = LMP:GetZoneAndSubzone(true, false, true)
    local x, y = GetMapPlayerPosition("player")
    xpos, ypos = GPS:LocalToGlobal(x, y)
    -- x = string.format("%05.2f", x*100)
    -- y = string.format("%05.2f", y*100)
    d(zone)
    d("X: "..x)
    d("Y: "..y)
    d("xpos: "..xpos)
    d("ypos: "..ypos)
    -- Add to chat input field so it's copyable
    -- StartChatInput(zone.." @ "..x.."/"..y)
    -- ZO_ChatWindowTextEntryEditBox:SelectAll();
end

-- Function to update the list of completed/started quests and also clean up the lists of hidden quests
local function UpdateQuestData()
    QML_GetData()

    -- Get names of started quests from quest journal, get quest ID from lookup table
    startedQuests = {}
    for i=1, MAX_JOURNAL_QUESTS do
        if IsValidQuestIndex(i) then
            local name = GetJournalQuestName(i)
            local ids = LQI:get_questids_table(name)
            if ids ~= nil then
                -- Add all IDs for that quest name to list
                for _, id in ipairs(ids) do
                    startedQuests[id] = true
                end
            end
        end
    end
end

-- Function to update the list of zone/subzone quests
local function UpdateZoneQuestData(zone)
    -- Get quest list for that zone from database
    zoneQuests = LQI:get_quest_list(zone)

    -- Get quest list for all subzones and convert each position it for the zone
    subzoneQuests = {}
    local subzones = QuestMap:GetSubzoneList(zone)
    for subzone, conversion in pairs(subzones) do
        -- Get each quest of the subzone
        local quests = LQI:get_quest_list(subzone)
        for i, quest in ipairs(quests) do
            -- Copy values to new element and insert it in the main table
            if not isEmpty(quest) then
                local new_element = {}
                new_element[LQI.quest_map_pin_index.QUEST_ID] = quest[LQI.quest_map_pin_index.QUEST_ID]
                -- Convert to correct position (subzone --> zone)
                --[[ Shar
                Previously the x and y pos was calculated with a zoom_factor.
                How the zoom_factor was calculated was unknown. LibGPS does not
                have a way to convert the old data. LibMapPins does not use any
                calculations. Future data will use LibGPS LocalToGlobal to saving
                to saved vars and GlobalToLocal when loading the savedvars
                information
                --]]
                if quest[LQI.quest_map_pin_index.X_LIBGPS] ~= -10 then
                    new_element[LQI.quest_map_pin_index.X_LOCATION], new_element[LQI.quest_map_pin_index.Y_LOCATION] = GPS:GlobalToLocal(quest[LQI.quest_map_pin_index.X_LIBGPS], quest[LQI.quest_map_pin_index.Y_LIBGPS])
                    new_element[LQI.quest_map_pin_index.X_LIBGPS] = -10
                    new_element[LQI.quest_map_pin_index.Y_LIBGPS] = -10
                else
                    new_element[LQI.quest_map_pin_index.X_LOCATION] = (quest[LQI.quest_map_pin_index.X_LOCATION] * conversion.zoom_factor) + conversion.x
                    new_element[LQI.quest_map_pin_index.Y_LOCATION] = (quest[LQI.quest_map_pin_index.Y_LOCATION] * conversion.zoom_factor) + conversion.y
                    new_element[LQI.quest_map_pin_index.X_LIBGPS] = -10
                    new_element[LQI.quest_map_pin_index.Y_LIBGPS] = -10
                end
                -- Add element to main table
                table.insert(subzoneQuests, new_element)
            end
        end
    end

    lastZone = zone
end

-- Function for displaying window with the quest list
local function DisplayListUI(arg)
    if ListUI == nil then return end

    -- Default option
    if arg == "" or arg == nil then arg = QuestMap.savedVars["settings"].lastListArg end

    -- Get currently displayed zone and subzone from texture
    local zone = LMP:GetZoneAndSubzone(true, false, true)
    -- Update quest list for current zone if the zone changed
    if zone ~= lastZone then
        UpdateZoneQuestData(zone)
    end

    -- Init variables and custom function that will be changed depending on input argument
    local title = GetString(QUESTMAP_QUESTS)..": "
    local list = {}
    local addQuestToList = function() end

    -- Define variables and function depending on input argument
    if arg == "completed" then
        title = title..GetString(QUESTMAP_COMPLETED)
        -- Check the completedQuests list and only add matching quests
        addQuestToList = function(quest)
            local name = LQI:get_quest_name(quest[LQI.quest_map_pin_index.QUEST_ID])
            if name ~= "" and completedQuests[quest[LQI.quest_map_pin_index.QUEST_ID]] then
                local level = 1 -- level no longer needed will remove
                list[quest[LQI.quest_map_pin_index.QUEST_ID]] = formatLevel(level)..name
            end
        end

    elseif arg == "uncompleted" then
        title = title..GetString(QUESTMAP_UNCOMPLETED)
        -- Check the completedQuests list and only add not matching quests
        addQuestToList = function(quest)
            local name = LQI:get_quest_name(quest[LQI.quest_map_pin_index.QUEST_ID])
            if name ~= "" and not completedQuests[quest[LQI.quest_map_pin_index.QUEST_ID]] then
                local level = 1 -- level no longer needed will remove
                list[quest[LQI.quest_map_pin_index.QUEST_ID]] = formatLevel(level)..name
            end
        end

    elseif arg == "hidden" then
        title = title..GetString(QUESTMAP_HIDDEN)
        -- Check the hiddenQuests list in the saved variables and only add matching quests
        addQuestToList = function(quest)
            local name = LQI:get_quest_name(quest[LQI.quest_map_pin_index.QUEST_ID])
            if name ~= "" and QuestMap.savedVars["settings"].hiddenQuests[quest[LQI.quest_map_pin_index.QUEST_ID]] then
                local level = 1 -- level no longer needed will remove
                list[quest[LQI.quest_map_pin_index.QUEST_ID]] = formatLevel(level)..name
            end
        end

    elseif arg == "started" then
        title = title..GetString(QUESTMAP_STARTED)
        -- Check the startedQuests list in the saved variables and only add matching quests
        addQuestToList = function(quest)
            local name = LQI:get_quest_name(quest[LQI.quest_map_pin_index.QUEST_ID])
            if name ~= "" and startedQuests[quest[LQI.quest_map_pin_index.QUEST_ID]] then
                local level = 1 -- level no longer needed will remove
                list[quest[LQI.quest_map_pin_index.QUEST_ID]] = formatLevel(level)..name
            end
        end

    elseif arg == "cadwell" then
        title = title..GetString(QUESTMAP_CADWELL)
        -- Check if quest is a cadwell's almanac quest and only add it if true
        addQuestToList = function(quest)
            local name = LQI:get_quest_name(quest[LQI.quest_map_pin_index.QUEST_ID])
            local isSkillQuest, isCadwellQuest = QuestMap:GetQuestType(quest[LQI.quest_map_pin_index.QUEST_ID])
            if name ~= "" and isCadwellQuest then
                local level = 1 -- level no longer needed will remove
                list[quest[LQI.quest_map_pin_index.QUEST_ID]] = formatLevel(level)..name
            end
        end

    elseif arg == "skill" then
        title = title..GetString(QUESTMAP_SKILL)
        -- Check if quest is a skill quest and only add it if true
        addQuestToList = function(quest)
            local name = LQI:get_quest_name(quest[LQI.quest_map_pin_index.QUEST_ID])
            local isSkillQuest, isCadwellQuest = QuestMap:GetQuestType(quest[LQI.quest_map_pin_index.QUEST_ID])
            if name ~= "" and isSkillQuest then
                local level = 1 -- level no longer needed will remove
                list[quest[LQI.quest_map_pin_index.QUEST_ID]] = formatLevel(level)..name
            end
        end

    else
        -- Do nothing when argument invalid
        return
    end

    -- Save argument so the next time the slash command can be used without argument
    QuestMap.savedVars["settings"].lastListArg = arg

    -- Add quests of zone and subzone to list with the custom function
    for _, quest in ipairs(zoneQuests) do addQuestToList(quest) end
    for _, quest in ipairs(subzoneQuests) do addQuestToList(quest) end

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
    LMP:RefreshPins(PIN_TYPE_QUEST_COMPLETED)
    LMP:RefreshPins(PIN_TYPE_QUEST_UNCOMPLETED)
    LMP:RefreshPins(PIN_TYPE_QUEST_HIDDEN)
    LMP:RefreshPins(PIN_TYPE_QUEST_STARTED)
end

-- Callback function which is called every time another map is viewed, creates quest pins
local function MapCallbackQuestPins(pinType)
    if not LMP:IsEnabled(PIN_TYPE_QUEST_UNCOMPLETED)
        and not LMP:IsEnabled(PIN_TYPE_QUEST_COMPLETED)
        and not LMP:IsEnabled(PIN_TYPE_QUEST_HIDDEN)
        and not LMP:IsEnabled(PIN_TYPE_QUEST_STARTED) then
        return
    end
    if GetMapType() > MAPTYPE_ZONE then return end

    -- Get currently displayed zone and subzone from texture
    local zone = LMP:GetZoneAndSubzone(true, false, true)
    -- Update quest list for current zone if the zone changed
    if zone ~= lastZone then
        UpdateZoneQuestData(zone)
        -- If the list window was open, update it by running the function again without argument
        if ListUI ~= nil and not ListUI:IsHidden() then
            DisplayListUI()
        end
    end

    -- Loop over both quest list tables: For each quest, create a map pin with the quest name
    for i=1,#zoneQuests+#subzoneQuests do
        local quest
        local isFromSubzone
        -- Handle correct index
        if i <= #zoneQuests then
            isFromSubzone = false
            quest = zoneQuests[i]
        else
            isFromSubzone = true
            quest = subzoneQuests[i-#zoneQuests]
        end

        -- Get quest name and only continue if string isn't empty
        local name = LQI:get_quest_name(quest[LQI.quest_map_pin_index.QUEST_ID])
        if name ~= "" then
            if quest[LQI.quest_map_pin_index.X_LIBGPS] ~= -10 then
                quest[LQI.quest_map_pin_index.X_LOCATION], quest[LQI.quest_map_pin_index.Y_LOCATION] = GPS:GlobalToLocal(quest[LQI.quest_map_pin_index.X_LIBGPS], quest[LQI.quest_map_pin_index.Y_LIBGPS])
            end

            -- Get quest type info and level
            local isSkillQuest, isCadwellQuest = QuestMap:GetQuestType(quest[LQI.quest_map_pin_index.QUEST_ID])
            local level = 1 -- level no longer needed will remove

            -- Create table with tooltip info
            local pinInfo = {}
            if isFromSubzone then
                pinInfo[1] = formatLevel(level).."|cDDDDDD"..name
            else
                pinInfo[1] = formatLevel(level).."|cFFFFFF"..name
            end
            -- Also store quest id (wont be visible in the tooltib because key is not an index number)
            pinInfo.id = quest[LQI.quest_map_pin_index.QUEST_ID]

            -- Add quest type info to tooltip data
            if isSkillQuest or isCadwellQuest then
                pinInfo[2] = "["
                if isSkillQuest then pinInfo[2] = pinInfo[2]..GetString(QUESTMAP_SKILL) end
                if isSkillQuest and isCadwellQuest then pinInfo[2] = pinInfo[2]..", " end
                if isCadwellQuest then pinInfo[2] = pinInfo[2]..GetString(QUESTMAP_CADWELL) end
                pinInfo[2] = pinInfo[2].."]"
            end

            -- Create pins for corresponding category
            if completedQuests[quest[LQI.quest_map_pin_index.QUEST_ID]] then
                if pinType == PIN_TYPE_QUEST_COMPLETED then
                    if not LMP:IsEnabled(PIN_TYPE_QUEST_CADWELL) and not LMP:IsEnabled(PIN_TYPE_QUEST_SKILL)
                        or LMP:IsEnabled(PIN_TYPE_QUEST_CADWELL) and isCadwellQuest
                        or LMP:IsEnabled(PIN_TYPE_QUEST_SKILL) and isSkillQuest then
                        pinInfo[1] = pinInfo[1].." |c888888(X)"
                        if LMP:IsEnabled(PIN_TYPE_QUEST_COMPLETED) then
                            LMP:CreatePin(PIN_TYPE_QUEST_COMPLETED, pinInfo, quest[LQI.quest_map_pin_index.X_LOCATION], quest[LQI.quest_map_pin_index.Y_LOCATION])
                        end
                    end
                end
            else  -- Uncompleted
                if startedQuests[quest[LQI.quest_map_pin_index.QUEST_ID]] ~= nil then  -- Started
                    if pinType == PIN_TYPE_QUEST_STARTED then
                        if not LMP:IsEnabled(PIN_TYPE_QUEST_CADWELL) and not LMP:IsEnabled(PIN_TYPE_QUEST_SKILL)
                            or LMP:IsEnabled(PIN_TYPE_QUEST_CADWELL) and isCadwellQuest
                            or LMP:IsEnabled(PIN_TYPE_QUEST_SKILL) and isSkillQuest then
                            pinInfo[1] = pinInfo[1].." |c888888(  )"
                            if LMP:IsEnabled(PIN_TYPE_QUEST_STARTED) then
                                LMP:CreatePin(PIN_TYPE_QUEST_STARTED, pinInfo, quest[LQI.quest_map_pin_index.X_LOCATION], quest[LQI.quest_map_pin_index.Y_LOCATION])
                            end
                        end
                end
            elseif QuestMap.savedVars["settings"].hiddenQuests[quest[LQI.quest_map_pin_index.QUEST_ID]] ~= nil then  -- Hidden
                if pinType == PIN_TYPE_QUEST_HIDDEN then
                    if not LMP:IsEnabled(PIN_TYPE_QUEST_CADWELL) and not LMP:IsEnabled(PIN_TYPE_QUEST_SKILL)
                        or LMP:IsEnabled(PIN_TYPE_QUEST_CADWELL) and isCadwellQuest
                        or LMP:IsEnabled(PIN_TYPE_QUEST_SKILL) and isSkillQuest then
                        pinInfo[1] = pinInfo[1].." |c888888(+)"
                        if LMP:IsEnabled(PIN_TYPE_QUEST_HIDDEN) then
                            LMP:CreatePin(PIN_TYPE_QUEST_HIDDEN, pinInfo, quest[LQI.quest_map_pin_index.X_LOCATION], quest[LQI.quest_map_pin_index.Y_LOCATION])
                        end
                    end
            end
            else
                if pinType == PIN_TYPE_QUEST_UNCOMPLETED then  -- Uncompleted only
                    if not LMP:IsEnabled(PIN_TYPE_QUEST_CADWELL) and not LMP:IsEnabled(PIN_TYPE_QUEST_SKILL)
                        or LMP:IsEnabled(PIN_TYPE_QUEST_CADWELL) and isCadwellQuest
                        or LMP:IsEnabled(PIN_TYPE_QUEST_SKILL) and isSkillQuest then
                    pinInfo[1] = pinInfo[1].." |c888888(  )"
                    if LMP:IsEnabled(PIN_TYPE_QUEST_UNCOMPLETED) then
                        LMP:CreatePin(PIN_TYPE_QUEST_UNCOMPLETED, pinInfo, quest[LQI.quest_map_pin_index.X_LOCATION], quest[LQI.quest_map_pin_index.Y_LOCATION])
                    end
                end
                end
            end
            end
        end
    end
end

-- Function to refresh pin appearance (e.g. from settings menu)
function QuestMap:RefreshPinLayout()
    LMP:SetLayoutKey(PIN_TYPE_QUEST_UNCOMPLETED, "size", QuestMap.savedVars["settings"].pinSize)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_UNCOMPLETED, "level", QuestMap.savedVars["settings"].pinLevel+PIN_PRIORITY_OFFSET)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_UNCOMPLETED, "texture", QuestMap.iconSets[QuestMap.savedVars["settings"].iconSet][1])
    LMP:RefreshPins(PIN_TYPE_QUEST_UNCOMPLETED)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_COMPLETED, "size", QuestMap.savedVars["settings"].pinSize)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_COMPLETED, "level", QuestMap.savedVars["settings"].pinLevel)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_COMPLETED, "texture", QuestMap.iconSets[QuestMap.savedVars["settings"].iconSet][2])
    LMP:RefreshPins(PIN_TYPE_QUEST_COMPLETED)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_HIDDEN, "size", QuestMap.savedVars["settings"].pinSize)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_HIDDEN, "level", QuestMap.savedVars["settings"].pinLevel)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_HIDDEN, "texture", QuestMap.iconSets[QuestMap.savedVars["settings"].iconSet][2])
    LMP:RefreshPins(PIN_TYPE_QUEST_HIDDEN)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_STARTED, "size", QuestMap.savedVars["settings"].pinSize)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_STARTED, "level", QuestMap.savedVars["settings"].pinLevel+PIN_PRIORITY_OFFSET)
    LMP:SetLayoutKey(PIN_TYPE_QUEST_STARTED, "texture", QuestMap.iconSets[QuestMap.savedVars["settings"].iconSet][1])
    LMP:RefreshPins(PIN_TYPE_QUEST_STARTED)
end

-- Function to refresh pin filters (e.g. from settings menu)
function QuestMap:RefreshPinFilters()
    LMP:SetEnabled(PIN_TYPE_QUEST_UNCOMPLETED, QuestMap.savedVars["settings"].pinFilters[PIN_TYPE_QUEST_UNCOMPLETED])
    LMP:SetEnabled(PIN_TYPE_QUEST_COMPLETED,   QuestMap.savedVars["settings"].pinFilters[PIN_TYPE_QUEST_COMPLETED])
    LMP:SetEnabled(PIN_TYPE_QUEST_HIDDEN,      QuestMap.savedVars["settings"].pinFilters[PIN_TYPE_QUEST_HIDDEN])
    LMP:SetEnabled(PIN_TYPE_QUEST_STARTED,     QuestMap.savedVars["settings"].pinFilters[PIN_TYPE_QUEST_STARTED])
    LMP:SetEnabled(PIN_TYPE_QUEST_SKILL,       QuestMap.savedVars["settings"].pinFilters[PIN_TYPE_QUEST_SKILL])
    LMP:SetEnabled(PIN_TYPE_QUEST_CADWELL,     QuestMap.savedVars["settings"].pinFilters[PIN_TYPE_QUEST_CADWELL])
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
    local questlist = LQI:get_quest_list(map)

    if str == "unhide" then
        for _, quest in ipairs(questlist) do
            -- Remove from list that holds hidden quests
            QuestMap.savedVars["settings"].hiddenQuests[quest[LQI.quest_map_pin_index.QUEST_ID]] = nil
        end
        if QuestMap.savedVars["settings"].displayClickMsg then p(GetString(QUESTMAP_MSG_UNHIDDEN_P).." @ |cFFFFFF"..LMP:GetZoneAndSubzone(true, false, true)) end
    elseif str == "hide" then
        for _, quest in ipairs(questlist) do
            -- Hiding only necessary for uncompleted quests
            if not completedQuests[quest[LQI.quest_map_pin_index.QUEST_ID]] then
                -- Add to list that holds hidden quests
                QuestMap.savedVars["settings"].hiddenQuests[quest[LQI.quest_map_pin_index.QUEST_ID]] = LQI:get_quest_name(quest.id)
            end
        end
        if QuestMap.savedVars["settings"].displayClickMsg then p(GetString(QUESTMAP_MSG_HIDDEN_P).." @ |cFFFFFF"..LMP:GetZoneAndSubzone(true, false, true)) end
    else
        p(usage)
        return
    end
end
local function questmap_log_reloadui()
    QML_GetData()

    -- Reload ui so the saved variables file gets written
    ReloadUI()
end

local function questmap_log_getnames()
    QML_ImportData()
end

-- Event handler function for EVENT_PLAYER_ACTIVATED
local function OnPlayerActivated(eventCode)
    QuestMap.InitSavedVariables()

    -- Get saved variables table for current user/char directly (without metatable), so it is possible to use pairs()
    -- local sv = QuestMap_SavedVariables.Default[GetDisplayName()][GetUnitName("player")]
    -- Clean up saved variables (from previous versions)
    -- for key, val in pairs(sv) do
    -- Delete key-value pair if the key can't also be found in the default settings (except for version)
    --     if key ~= "version" and QuestMap.settings_default[key] == nil then
    --         sv[key] = nil
    --     end
    -- end

    -- Get tootip of each individual pin
    local pinTooltipCreator = {
        creator = function(pin)
            local _, pinTag = pin:GetPinTypeAndTag()
            for _, lineData in ipairs(pinTag) do
                SetTooltipText(InformationTooltip, lineData)
            end
        end,
        tooltip = 1, -- Delete the line above and uncomment this line for Update 6
    }
    -- Add new pin types for quests
    local pinLayout = {level = QuestMap.savedVars["settings"].pinLevel+PIN_PRIORITY_OFFSET, texture = QuestMap.iconSets[QuestMap.savedVars["settings"].iconSet][1], size = QuestMap.savedVars["settings"].pinSize}
    LMP:AddPinType(PIN_TYPE_QUEST_UNCOMPLETED, function() MapCallbackQuestPins(PIN_TYPE_QUEST_UNCOMPLETED) end, nil, pinLayout, pinTooltipCreator)
    LMP:AddPinType(PIN_TYPE_QUEST_STARTED, function() MapCallbackQuestPins(PIN_TYPE_QUEST_STARTED) end, nil, pinLayout, pinTooltipCreator)
    pinLayout = {level = QuestMap.savedVars["settings"].pinLevel, texture = QuestMap.iconSets[QuestMap.savedVars["settings"].iconSet][2], size = QuestMap.savedVars["settings"].pinSize}
    LMP:AddPinType(PIN_TYPE_QUEST_COMPLETED, function() MapCallbackQuestPins(PIN_TYPE_QUEST_COMPLETED) end, nil, pinLayout, pinTooltipCreator)
    LMP:AddPinType(PIN_TYPE_QUEST_HIDDEN, function() MapCallbackQuestPins(PIN_TYPE_QUEST_HIDDEN) end, nil, pinLayout, pinTooltipCreator)
    -- Add map filters
    LMP:AddPinFilter(PIN_TYPE_QUEST_UNCOMPLETED, GetString(QUESTMAP_QUESTS).." ("..GetString(QUESTMAP_UNCOMPLETED)..")", true, QuestMap.savedVars["settings"].pinFilters)
    LMP:AddPinFilter(PIN_TYPE_QUEST_COMPLETED, GetString(QUESTMAP_QUESTS).." ("..GetString(QUESTMAP_COMPLETED)..")", true, QuestMap.savedVars["settings"].pinFilters)
    LMP:AddPinFilter(PIN_TYPE_QUEST_STARTED, GetString(QUESTMAP_QUESTS).." ("..GetString(QUESTMAP_STARTED)..")", true, QuestMap.savedVars["settings"].pinFilters)
    LMP:AddPinFilter(PIN_TYPE_QUEST_HIDDEN, GetString(QUESTMAP_QUESTS).." ("..GetString(QUESTMAP_HIDDEN)..")", true, QuestMap.savedVars["settings"].pinFilters)
    QuestMap:RefreshPinFilters()
    -- Add subfilters (filters for filters); AddPinType needed or else the filters wont show up
    LMP:AddPinType(PIN_TYPE_QUEST_CADWELL, function() end, nil, pinLayout, pinTooltipCreator)
    LMP:AddPinType(PIN_TYPE_QUEST_SKILL, function() end, nil, pinLayout, pinTooltipCreator)
    LMP:AddPinFilter(PIN_TYPE_QUEST_CADWELL, "|c888888"..GetString(QUESTMAP_QUEST_SUBFILTER).." ("..GetString(QUESTMAP_CADWELL)..")", true, QuestMap.savedVars["settings"].pinFilters)
    LMP:AddPinFilter(PIN_TYPE_QUEST_SKILL, "|c888888"..GetString(QUESTMAP_QUEST_SUBFILTER).." ("..GetString(QUESTMAP_SKILL)..")", true, QuestMap.savedVars["settings"].pinFilters)
    -- Set callback functions for (un)checking subfilters
    SetFilterToggleCallback(PIN_TYPE_QUEST_CADWELL, true,  function() QuestMap:RefreshPins() end)
    SetFilterToggleCallback(PIN_TYPE_QUEST_CADWELL, false, function() QuestMap:RefreshPins() end)
    SetFilterToggleCallback(PIN_TYPE_QUEST_SKILL,   true,  function() QuestMap:RefreshPins() end)
    SetFilterToggleCallback(PIN_TYPE_QUEST_SKILL,   false, function() QuestMap:RefreshPins() end)
    -- Add click action for pins
    LMP:SetClickHandlers(PIN_TYPE_QUEST_UNCOMPLETED, {[1] = {name = function(pin) return zo_strformat(GetString(QUESTMAP_HIDE).." |cFFFFFF<<1>>|r", LQI:get_quest_name(pin.m_PinTag.id)) end,
        show = function(pin) return true end,
        duplicates = function(pin1, pin2) return pin1.m_PinTag.id == pin2.m_PinTag.id end,
        callback = function(pin)
            -- Add to table which holds all the hidden quests
            QuestMap.savedVars["settings"].hiddenQuests[pin.m_PinTag.id] = LQI:get_quest_name(pin.m_PinTag.id)
            if QuestMap.savedVars["settings"].displayClickMsg then p(GetString(QUESTMAP_MSG_HIDDEN)..": |cFFFFFF"..LQI:get_quest_name(pin.m_PinTag.id)) end
            LMP:RefreshPins(PIN_TYPE_QUEST_UNCOMPLETED)
            LMP:RefreshPins(PIN_TYPE_QUEST_HIDDEN)
        end}})
    LMP:SetClickHandlers(PIN_TYPE_QUEST_COMPLETED, {[1] = {name = function(pin) return zo_strformat("Quest |cFFFFFF<<1>>|r", LQI:get_quest_name(pin.m_PinTag.id)) end,
        show = function(pin) return true end,
        duplicates = function(pin1, pin2) return pin1.m_PinTag.id == pin2.m_PinTag.id end,
        callback = function(pin)
        -- Do nothing
        end}})
    LMP:SetClickHandlers(PIN_TYPE_QUEST_HIDDEN, {[1] = {name = function(pin) return zo_strformat(GetString(QUESTMAP_UNHIDE).." |cFFFFFF<<1>>|r", LQI:get_quest_name(pin.m_PinTag.id)) end,
        show = function(pin) return true end,
        duplicates = function(pin1, pin2) return pin1.m_PinTag.id == pin2.m_PinTag.id end,
        callback = function(pin)
            -- Remove from table which holds all the hidden quests
            QuestMap.savedVars["settings"].hiddenQuests[pin.m_PinTag.id] = nil
            if QuestMap.savedVars["settings"].displayClickMsg then p(GetString(QUESTMAP_MSG_UNHIDDEN)..": |cFFFFFF"..LQI:get_quest_name(pin.m_PinTag.id)) end
            LMP:RefreshPins(PIN_TYPE_QUEST_UNCOMPLETED)
            LMP:RefreshPins(PIN_TYPE_QUEST_HIDDEN)
        end}})

    -- Set up lists of completed and started quests
    UpdateQuestData()

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

    SLASH_COMMANDS["/qmlogimp"] = questmap_log_getnames

    SLASH_COMMANDS["/qmlog"] = questmap_log_reloadui

    SLASH_COMMANDS["/qmscout"] = questmap_get_scout_quests

    SLASH_COMMANDS["/qmgetlqi"] = questmap_get_libquestinfo

    SLASH_COMMANDS["/qmbuild"] = questmap_rebuild_quest_data

    SLASH_COMMANDS["/qmbuildnidt"] = build_names_id_table

    SLASH_COMMANDS["/qmhreset"] = questmap_reset_helper_data

    SLASH_COMMANDS["/qmgetnames"] = generate_quest_names

    EVENT_MANAGER:UnregisterForEvent(QuestMap.idName, EVENT_PLAYER_ACTIVATED)
end
EVENT_MANAGER:RegisterForEvent(QuestMap.idName, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

-- Event handler function for EVENT_QUEST_REMOVED and EVENT_QUEST_ADDED
local function OnQuestRemovedOrAdded(eventCode)
    UpdateQuestData()
    QuestMap:RefreshPins()
end
EVENT_MANAGER:RegisterForEvent(QuestMap.idName, EVENT_QUEST_ADDED,      OnQuestRemovedOrAdded)
EVENT_MANAGER:RegisterForEvent(QuestMap.idName, EVENT_QUEST_REMOVED,    OnQuestRemovedOrAdded)
