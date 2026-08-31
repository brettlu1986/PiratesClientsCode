local UILobbySailorDef = {}

local UIDef = require("UIDef")

UILobbySailorDef.UI =
{
    UIDef.UI_LOBBY_SAILOR_EQUIPPING, 
    UIDef.UI_LOBBY_SAILOR_BAG, 
    UIDef.UI_LOBBY_SAILOR_SUMMONING,
}

UILobbySailorDef.Name =
{
    "ckSailorEquipping", 
    "ckSailorBag", 
    "ckSailorSummoning"
}

UILobbySailorDef.Bg = 
{
    "Texture2D'/Game/UI/Textures/UI_LobbySailor/Textures/T_UI_SailorFireBg_UI.T_UI_SailorFireBg_UI'",
    "Texture2D'/Game/UI/Textures/UI_LobbySailor/Textures/T_UI_SailorDefBg_UI.T_UI_SailorDefBg_UI'",
    "Texture2D'/Game/UI/Textures/UI_LobbySailor/Textures/T_UI_SailorHelpBg_UI.T_UI_SailorHelpBg_UI'",
}

--Sailor Equipping
UILobbySailorDef.EquippingLogic = 
{
    "ULSailorEquippingCanon",
    "ULSailorEquippingDeck",
    "ULSailorEquippingLogistics",
}

UILobbySailorDef.EquippingItemState =
{
    LOCK_WITH_GRADE = 1,
    LOCK_WITH_COIN  = 2,
    LOCK            = 3,
    UNLOCK          = 4,
}

UILobbySailorDef.MAX_SLOT_COUNT_PER_TYPE = 10
UILobbySailorDef.MAX_GRADE = 4
UILobbySailorDef.CURRENCY_ID = 1400003

return UILobbySailorDef