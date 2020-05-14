--[[

Quest Map
by CaptainBlagbird
https://github.com/CaptainBlagbird

--]]

-- Local variables
local iconUncollectedTexture, iconCollectedTexture
local iconSets = {}
for k,v in pairs(QuestMap.iconSets) do
    table.insert(iconSets, k)
end

local panelData = {
    type = "panel",
    name = QuestMap.displayName,
    displayName = "|c70C0DE"..QuestMap.displayName.."|r",
    author = "|c70C0DECaptainBlagbird|r",
    version = "1.9",
    slashCommand = "/questmap", --(optional) will register a keybind to open to this panel
    registerForRefresh = true,  --boolean (optional) (will refresh all options controls when a setting is changed and when the panel is shown)
    registerForDefaults = true, --boolean (optional) (will set all options controls back to default values)
    resetFunc = function()
                    -- Also reset pin filters. The only thing in the saved variables will be the hidden quests (QuestMap.savedVars["settings"].hiddenQuests)
                    QuestMap.savedVars["settings"].pinFilters = QuestMap.settings_default.pinFilters
                    QuestMap:RefreshPinFilters()
                end,    --function (optional) if registerForDefaults is true, this custom function will run after settings are reset to defaults
}

local function ChangePinSize(value)
    QuestMap.savedVars["settings"].pinLevel = value
    QuestMap:InitPins()
end

local optionsTable = {
    {
        type = "dropdown",
        name = GetString(QUESTMAP_MENU_ICON_SET),
        choices = iconSets,
        getFunc = function()
                return QuestMap.savedVars["settings"].iconSet
            end,
        setFunc = function(value)
                QuestMap.savedVars["settings"].iconSet = value
                QuestMap:RefreshPinLayout()
                iconUncollectedTexture:SetTexture(QuestMap.iconSets[QuestMap.savedVars["settings"].iconSet][1])
                iconCollectedTexture:SetTexture(QuestMap.iconSets[QuestMap.savedVars["settings"].iconSet][2])
            end,
        default = QuestMap.settings_default.iconSet,
        width = "full",
    },
    {
        type = "slider",
        name = GetString(QUESTMAP_MENU_PIN_SIZE),
        tooltip = GetString(QUESTMAP_MENU_PIN_SIZE_TT),
        min = 5,
        max = 70,
        step = 1,
        getFunc = function() return QuestMap.savedVars["settings"].pinSize end,
        setFunc = function(value)
                QuestMap.savedVars["settings"].pinSize = value
                QuestMap:RefreshPinLayout()
            end,
        width = "full",
        default = QuestMap.settings_default.pinSize,
    },
    {
        type = "slider",
        name = GetString(QUESTMAP_MENU_PIN_LVL),
        tooltip = GetString(QUESTMAP_MENU_PIN_LVL_TT),
        min = 10,
        max = 200,
        step = 1,
        getFunc = function() return QuestMap.savedVars["settings"].pinLevel end,
        setFunc = function(value)
                QuestMap.savedVars["settings"].pinLevel = value
                QuestMap:RefreshPinLayout()
            end,
        width = "full",
        default = QuestMap.settings_default.pinLevel,
    },
    {
        type = "checkbox",
        name = GetString(QUESTMAP_MENU_DISP_MSG),
        tooltip = GetString(QUESTMAP_MENU_DISP_MSG_TT),
        getFunc = function() return QuestMap.savedVars["settings"].displayClickMsg end,
        setFunc = function(value) QuestMap.savedVars["settings"].displayClickMsg = value end,
        default = QuestMap.settings_default.displayClickMsg,
        width = "full",
    },
    {
        type = "header",
        name = "",
        width = "full",
    },
    {
        type = "description",
        title = GetString(QUESTMAP_MENU_HIDDEN_QUESTS_T),
        text = GetString(QUESTMAP_MENU_HIDDEN_QUESTS_1),
        width = "full",
    },
    {
        type = "description",
        title = "",
        text = GetString(QUESTMAP_MENU_HIDDEN_QUESTS_2),
        width = "full",
    },
    {
        type = "description",
        title = "",
        text = GetString(QUESTMAP_MENU_HIDDEN_QUESTS_B),
        width = "half",
    },
    {
        type = "button",
        name = GetString(QUESTMAP_MENU_RESET_HIDDEN),
        tooltip = GetString(QUESTMAP_MENU_RESET_HIDDEN_TT),
        func = function()
                QuestMap.savedVars["settings"].hiddenQuests = {}
                QuestMap:RefreshPinLayout()
            end,
        width = "half",
        warning = GetString(QUESTMAP_MENU_RESET_HIDDEN_W),
    },
    {
        type = "description",
        title = "",
        text = GetString(QUESTMAP_MENU_RESET_NOTE),
        width = "full",
    },
}

-- Create texture on first load of the Better Rally LAM panel
local function CreateTexture(panel)
    if panel == WINDOW_MANAGER:GetControlByName(QuestMap.idName, "_Options") then
        -- Create texture control
        iconUncollectedTexture = WINDOW_MANAGER:CreateControl(QuestMap.idName.."_Options_UncollectedTexture", panel.controlsToRefresh[1], CT_TEXTURE)
        iconUncollectedTexture:SetAnchor(CENTER, panel.controlsToRefresh[1].dropdown:GetControl(), LEFT, -60, 0)
        iconUncollectedTexture:SetTexture(QuestMap.iconSets[QuestMap.savedVars["settings"].iconSet][1])
        iconUncollectedTexture:SetDimensions(28, 28)
        iconCollectedTexture = WINDOW_MANAGER:CreateControl(QuestMap.idName.."_Options_CollectedTexture", panel.controlsToRefresh[1], CT_TEXTURE)
        iconCollectedTexture:SetAnchor(CENTER, panel.controlsToRefresh[1].dropdown:GetControl(), LEFT, -30, 0)
        iconCollectedTexture:SetTexture(QuestMap.iconSets[QuestMap.savedVars["settings"].iconSet][2])
        iconCollectedTexture:SetDimensions(28, 28)
        
        CALLBACK_MANAGER:UnregisterCallback("LAM-PanelControlsCreated", CreateTexture)
    end
end
CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated", CreateTexture)

-- Wait until all addons are loaded
local function OnPlayerActivated(event)
    local LAM = LibAddonMenu2
    if LAM ~= nil then
        LAM:RegisterAddonPanel(QuestMap.idName.."_Options", panelData)
        LAM:RegisterOptionControls(QuestMap.idName.."_Options", optionsTable)
    end
    EVENT_MANAGER:UnregisterForEvent(QuestMap.idName.."_Options", EVENT_PLAYER_ACTIVATED)
end
EVENT_MANAGER:RegisterForEvent(QuestMap.idName.."_Options", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)