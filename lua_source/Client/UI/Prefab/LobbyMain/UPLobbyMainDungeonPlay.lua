-----------------------------------------------------
--File Name    : UPLobbyMainDungeonPlay.lua
--Author       : Ran Jie
--Create Time  : 2020-04-20
-----------------------------------------------------
local luaclass       = require ("luaclass")
local ScrollPageItemBase = require("ScrollPageItemBase")
local UPLobbyMainDungeonPlay  = luaclass("UPLobbyMainDungeonPlay", ScrollPageItemBase)

local UISetUtils = require("UISetUtils")
local DungeonDataTable = require("DungeonDataTable")

function UPLobbyMainDungeonPlay:OnRefresh(tbData)
    local tbDungeonTemplate = DungeonDataTable:GetTemplate(tbData.nDungeonId)
    if not tbDungeonTemplate then
        return
    end
    if tbDungeonTemplate.szUIThumbnail and tbDungeonTemplate.szUIThumbnail ~= "" then
        local pResouceObject = tbDungeonTemplate.szUIThumbnail:load()
        if pResouceObject then
            if self.nIndex == 1 then
                local pDynamicMaterial = self.pWidgetRef.bdrDungeon:GetDynamicMaterial()
                if pDynamicMaterial then
                    pDynamicMaterial:SetTextureParameterValue("Maintexture", pResouceObject)
                    self:PlayAnimation("anim_LobbyMainDungeonPlayIn", 0, 1, EUMGSequencePlayMode.Forward, 1)
                else
                    UISetUtils.SetBorderBrushRes(self.pWidgetRef.bdrDungeon, pResouceObject, true)
                end
            else
                UISetUtils.SetBorderBrushRes(self.pWidgetRef.bdrDungeon, pResouceObject, true)
            end
        end
    end
end

return UPLobbyMainDungeonPlay