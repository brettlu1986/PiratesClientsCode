-----------------------------------------------------
--File Name    : UILoading.lua
--Author       : Song Fuhao
--Create Time  : 2016-08-11
--Description  : Loading UI
-----------------------------------------------------

local luaclass = require ("luaclass")
local WndBase = require("WndBase")
local UILoadingNew = luaclass("UILoadingNew", WndBase)

-- require
local UISetUtils = require("UISetUtils")
local LoadingBgDataTable = require("LoadingBgDataTable")
local UIResourceDef = require("UIResourceDef")

UILoadingNew.pDialogMessage    = nil


local function LoadLoadingBg(self)
    local tbBgContainer = LoadingBgDataTable:GetContainer()
    local nDungeonId = self.tbOpenArgs.nDungeonId
    if nDungeonId ~= nil then
        local szPath = tbBgContainer[nDungeonId]
        if szPath == nil or szPath == "" then
            UISetUtils.SetImageBrushRes(self.pWidgetRef.imgBG, UIResourceDef.LOADING_BG_DUNGEN:load())
        else
            UISetUtils.SetImageBrushRes(self.pWidgetRef.imgBG, szPath:load())
        end   
    else
        local nSceneId = self.tbOpenArgs.nSceneId
        if nSceneId ~= nil then
            local szPath = tbBgContainer[nSceneId]
            if szPath == nil or szPath == "" then
                UISetUtils.SetImageBrushRes(self.pWidgetRef.imgBG, UIResourceDef.LOADING_BG_BIG_WORLD:load())
            else
                UISetUtils.SetImageBrushRes(self.pWidgetRef.imgBG, szPath:load())
            end
        end
    end
end

function UILoadingNew:OnBindEvent()
    self.pDialogMessage = self.PrefabHelper:BindPrefab(self.pWidgetRef.pDialogMessage)
end

function UILoadingNew:OnShow()
    LoadLoadingBg(self)
    self.pWidgetRef.kmgrgbLoading:SetPercent(0)
    self.pWidgetRef.txtLoading:SetVisibility(ESlateVisibility.Collapsed)
    
    
    ClientShell.GetClient(GWorld):BeginLoading(self.pWidgetRef, 1, 1)
    KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "s.EnablePlayMovieWhenPreLoadMap 0", nil)
    --KMUMGLibrary.SwitchRendering(false)
    self.pDialogMessage:HideMessageDialog()
end

function UILoadingNew:OnExit()
    --KMUMGLibrary.SwitchRendering(true)
    --ClientShell.GetClient(GWorld):EndLoading()
    --KismetSystemLibrary.ExecuteConsoleCommand(GWorld, "s.EnablePlayMovieWhenPreLoadMap 1", nil)
end

function UILoadingNew:ShowDialogMessage(tbParam)
    self.pDialogMessage:ShowMessageDialog(tbParam)
end

return UILoadingNew
