local luaclass = require("luaclass")
local UILogicBase = require("UILogicBase")

local ULLobbyHumanItemInfoBase = luaclass("ULLobbyHumanItemInfoBase", UILogicBase)

local UIDef = require("UIDef")



function ULLobbyHumanItemInfoBase:MakeData(nItemTemplateId)
    --override in subclass
end


function ULLobbyHumanItemInfoBase:DisplayData(tbData)
    self.pbLobbyItemInfo:SetAvatarData(tbData, true)
end

function ULLobbyHumanItemInfoBase:Display(nItemTemplateId)
    local tbData = self:MakeData(nItemTemplateId)
    self:DisplayData(tbData)
end



function ULLobbyHumanItemInfoBase:OnLoad()
    self.pbLobbyItemInfo = self.PrefabHelper:BindPrefab(self.pWidgetRef.pbLobbyItemInfo, UIDef.UP_CAPTAIN_ITEM_INFO)
end

function ULLobbyHumanItemInfoBase:OnUnload()
    if self.LevelCheckBoxGroupHelper then
        self.LevelCheckBoxGroupHelper:Uninit()
    end
end



return ULLobbyHumanItemInfoBase