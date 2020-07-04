--[[

Quest Map
by CaptainBlagbird
https://github.com/CaptainBlagbird

--]]

local strings = {
    -- General
    QUESTMAP_UNCOMPLETED            = "Unerledigt",
    QUESTMAP_COMPLETED              = "Erledigt",
    QUESTMAP_HIDDEN                 = "Manuell ausgeblendet",
    QUESTMAP_STARTED                = "Begonnen",
    QUESTMAP_REPEATABLE             = "Repeatable",
    QUESTMAP_DAILY                  = "Daily",
    QUESTMAP_CADWELL                = "Cadwells Almanach",
    QUESTMAP_SKILL                  = "Fertigkeitspunkt",

    QUESTMAP_HIDE                   = "Quest ausblenden",
    QUESTMAP_UNHIDE                 = "Quest einblenden",

    QUESTMAP_MSG_HIDDEN             = "Quest ausgeblendet",
    QUESTMAP_MSG_UNHIDDEN           = "Quest eingeblendet",
    QUESTMAP_MSG_HIDDEN_P           = "Quests ausgeblendet",
    QUESTMAP_MSG_UNHIDDEN_P         = "Quests eingeblendet",

    QUESTMAP_QUESTS                 = "Quests",
    QUESTMAP_QUEST_SUBFILTER        = "Subfilter",

    QUESTMAP_SLASH_USAGE            = "Bitte verwende ein Argument nach dem Befehl:\n 'hide' - Alle quests in der aktuellen Karte ausblenden\n 'unhide' - Alle quests in der aktuellen Karte einblenden",
    QUESTMAP_SLASH_MAPINFO          = "Bitte erst die Karte öffnen.",

    QUESTMAP_LIB_REQUIRED           = "nicht installiert/aktiviert.",

    -- Settings menu
    QUESTMAP_MENU_ICON_SET          = "Icon-Set",
    QUESTMAP_MENU_REPEATABLE_ICON_SET        = "Repeatable Icon set",

    QUESTMAP_MENU_PIN_SIZE          = "Grösse der Kartenmarkierung",
    QUESTMAP_MENU_PIN_SIZE_TT       = "Definiert die Anzeigegrösse der Kartenmarkierungen (Standard: "..QuestMap.settings_default.pinSize..")",

    QUESTMAP_MENU_PIN_LVL           = "Ebene der Kartenmarkierung",
    QUESTMAP_MENU_PIN_LVL_TT        = "Definiert auf welcher Ebene die Kartenmarkierungen gezeichnet werden (Standard: "..QuestMap.settings_default.pinLevel..")",

    QUESTMAP_MENU_DISP_MSG          = "Ein-/ausblende-Nachricht anzeigen",
    QUESTMAP_MENU_DISP_MSG_TT       = "Ein-/ausschalten der Nachricht die angezeigt wird, wenn Markierungen ein-/ausgeblendet werden",

    QUESTMAP_MENU_TOGGLE_HIDDEN_MSG  = "Toggle option to hide or unhide Quests",
    QUESTMAP_MENU_TOGGLE_HIDDEN_MSG_TT  = "Enable or disable option to hide or unhide quests when you click a quest pin.",

    QUESTMAP_MENU_TOGGLE_COMPLETED_MSG  = "Toggle option to show completed quest list",
    QUESTMAP_MENU_TOGGLE_COMPLETED_MSG_TT  = "Enable or disable option to show quest list when you click a completed quest pin and pins are stacked on top one another.",

    QUESTMAP_MENU_HIDDEN_QUESTS_T   = "Quests manuell ausblenden",
    QUESTMAP_MENU_HIDDEN_QUESTS_1   = "Du kannst Questmarkierungen manuell ausblenden indem du sie anklickst. (Um ausgeblendete Questmarkierungen zu sehen, aktiviere den Filter für Kartenmarkierungen rechts neben der Karte.)",
    QUESTMAP_MENU_HIDDEN_QUESTS_2   = "Zum gleichzeitigen ein-/ausblenden aller Kartenmarkierung einer bestimmten Karte kannst du den Chat-Befehl '/qm hide' oder '/qm unhide' verwenden.",
    QUESTMAP_MENU_HIDDEN_QUESTS_B   = "Willst du ALLE ausgeblendeten Markierungen zurücksetzen, dann benütze diese Schaltfläche:",

    QUESTMAP_MENU_RESET_HIDDEN      = "Ausgebl. zurücksetzen",
    QUESTMAP_MENU_RESET_HIDDEN_TT   = "Manuell ausgeblendete Markierungen zurücksetzen",
    QUESTMAP_MENU_RESET_HIDDEN_W    = "Kann nicht rückgängig gemacht werden!",

    QUESTMAP_MENU_RESET_NOTE        = "Hinweis: Unten auf '"..GetString(SI_OPTIONS_DEFAULTS).."' klicken setzt die manuell ausgeblendeten Questmarkierungen NICHT zurück.",
}

for key, value in pairs(strings) do
   ZO_CreateStringId(key, value)
   SafeAddVersion(key, 1)
end
