local LobbyShipDef = {}
local UIDef = require("UIDef")

LobbyShipDef.WndDef = {
    ["tbKeys"] = {
        [1] = "Hull",
        [2] = "Weapon",
        [3] = "Part",
        [4] = "Handbook"
    },
    ["tbKeyToWndName"] = {
        ["Overview"] = UIDef.UI_LOBBY_SHIP_OVERVIEW,
        ["Hull"] = UIDef.UI_LOBBY_SHIP_HULL,
        ["Weapon"] = UIDef.UI_LOBBY_SHIP_WEAPON,
        ["Part"] = UIDef.UI_LOBBY_SHIP_PART,
        ["Handbook"] = UIDef.UI_LOBBY_SHIP_HANDBOOK
    },
    tbKeyToModifyKey = {
        ["Hull"] = "hull",
        ["Weapon"] = "weapon",
        ["Part"] = "part",
        ["Handbook"] = "handbook", 
    }
}

LobbyShipDef.OwningStateDef = {
    ["Owned"] = 1,
    ["Experience"] = 2,
    ["Locked"] = 3,
}

LobbyShipDef.SelectableItemRes = {
    ["Detail"] = "PaperSprite'/Game/UI/Textures/LobbyCommon/Frames/Spr_CommonZoon.Spr_CommonZoon'",
    ["Preview"] = "PaperSprite'/Game/UI/Textures/LobbyShip/Frames/Spr_LobbyShip04.Spr_LobbyShip04'",
}

return LobbyShipDef