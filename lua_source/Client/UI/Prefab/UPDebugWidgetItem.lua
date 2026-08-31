-----------------------------------------------------
--File Name    : UPDebugWidgetItem.lua
--Author       : Zhang Yuzhen
--Create Time  : 2017-07-12
--Description  : Prefab DebugWidgetItem
-----------------------------------------------------

local luaclass = require ("luaclass")
local ListItemBase = require("ListItemBase")
local UPDebugWidgetItem = luaclass("UPDebugWidgetItem", ListItemBase)

local L10N = require("L10N")
local UIManager = require("UIManager")
local UIDef     = require("UIDef")
-- local TradeSystem = require("TradeSystem")
-- local ShipDataTable = require("ShipDataTable")
-- local ShipBuildDataTable = require("ShipBuildDataTable")
local SceneDataTable = require("SceneDataTable")
local GMSystem_C = require("GMSystem_C")
local MediaSystem = require("MediaSystem")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local UIUtils = require("UIUtils")
-- local AtmoSphereShipSystem = require("AtmoSphereShipSystem")
local UISetUtils = require("UISetUtils")
local MatineeDataTable = require("MatineeDataTable")


local tbShipData = nil
local tbSceneData = nil
local tbMatineeData = nil
local OpTimeInterval = 0;

local L10N_OPEN = UISetUtils.GetL10NTextByKey("UPDEBUGWIDGETITEM_L10N_OPEN")
local L10N_OK = UISetUtils.GetL10NTextByKey("UPDEBUGWIDGETITEM_L10N_OK")
local L10N_DUMP_LOG = UISetUtils.GetL10NTextByKey("UPDEBUGWIDGETITEM_L10N_DUMP_LOG")
local L10N_OP_FREQUENT = UISetUtils.GetL10NTextByKey("UPDEBUGWIDGETITEM_L10N_OP_FREQUENT")

local function GetShipData()
    if tbShipData then
        return tbShipData
    end

    tbShipData = {}
    return tbShipData
end

local function FindShipId(szShipName)
    for _, v in ipairs(tbShipData) do
        if v.szShipName == szShipName then
            return v.nShipTemplateId
        end
    end
    return -1
end

local function GetSceneData()
    if tbSceneData then
        return tbSceneData
    end

    tbSceneData = {}
    local tbData = SceneDataTable.tbContainer
    for _, v in pairs(tbData) do
        if v.nID ~= 70000 then
            table.insert(tbSceneData, v)
        end
    end
    return tbSceneData
end

local function GetMatineeData()
    if tbMatineeData then
        return tbMatineeData
    end
    local tbData = MatineeDataTable.tbContainer
    tbMatineeData = {}
    for _,v in pairs(tbData) do
        table.insert(tbMatineeData, v)
    end
    return tbMatineeData
end

local function FindSceneId(szSceneName)
    for _, v in ipairs(tbSceneData) do
        if v.szName == szSceneName then
            return v.nID
        end
    end
    return -1
end

function UPDebugWidgetItem:OnBindEvent()
    local Helper = self.EventHelper
    Helper:RegisterCppDelegate(self.pWidgetRef.btnOpen.OnClicked, self, self.OnClickedButtonItem)
end

function UPDebugWidgetItem:OnRefresh(tbData)
    if tbData then
        local nActiveIndex = 0
        local tbExtraDatas = self.ListHelper.tbExtraDatas
        local pWidgetRef = self.pWidgetRef

        if self.nIndex % 2 == 0 then
            pWidgetRef.imgBG:SetVisibility(ESlateVisibility.Collapsed)
        else
            pWidgetRef.imgBG:SetVisibility(ESlateVisibility.HitTestInvisible)
        end

        if tbExtraDatas.bUI then
            pWidgetRef.txtName:SetText(tbData.szWndDesc)
            pWidgetRef.txtDesc:SetText(tbData.szWndName)
            pWidgetRef.txtOpen:SetText(L10N_OPEN)
        elseif tbExtraDatas.bGM then
            pWidgetRef.txtName:SetText(tbData.szGMName)
            pWidgetRef.txtDesc:SetText(tbData.szUsage)
            pWidgetRef.txtOpen:SetText(L10N_OK)
        elseif tbExtraDatas.bGMInstance then
            pWidgetRef.txtName:SetText(tbData.szGMName)
            pWidgetRef.txtOpen:SetText(L10N_OK)
            local nInstanceType = tbData.nInstanceType
            if nInstanceType == 1 or nInstanceType == 5 or nInstanceType == 6 or nInstanceType == 7 then
                nActiveIndex = 1
                pWidgetRef.txtCount:SetText("1")
            elseif nInstanceType == 2 then
                nActiveIndex = 2
                local cmbBox = pWidgetRef.cmbBox
                tbShipData = GetShipData()
                for _, v in pairs(tbShipData) do
                    cmbBox:AddOption(v.szShipName)
                end
                cmbBox:SetSelectedOption(cmbBox:GetOptionAtIndex(0))
            elseif nInstanceType == 3 then
                nActiveIndex = 2
                local cmbBox = pWidgetRef.cmbBox
                tbSceneData = GetSceneData()
                for _, v in pairs(tbSceneData) do
                    cmbBox:AddOption(v.szName)
                end
                cmbBox:SetSelectedOption(cmbBox:GetOptionAtIndex(0))
            elseif nInstanceType == 8 then
                nActiveIndex = 2
                local cmbBox = pWidgetRef.cmbBox
                tbMatineeData = GetMatineeData()
                for _, v in pairs(tbMatineeData) do
                    cmbBox:AddOption(v.nID)
                end
                cmbBox:SetSelectedOption(cmbBox:GetOptionAtIndex(0))
            elseif nInstanceType == 4 then
                pWidgetRef.txtDesc:SetText("gm me:AddAward(7000)")
            elseif nInstanceType >= 100  then
                pWidgetRef.txtDesc:SetText(tbData.szUsage)
            end
        end
        pWidgetRef.WidgetSwitcher_0:SetActiveWidgetIndex(nActiveIndex)
    else
        logerror("UPDebugWidgetItem:OnRefresh(tbData)")
    end
end

function UPDebugWidgetItem:OnClickedButtonItem()
    local pWidgetRef = self.pWidgetRef
    local tbData = self.tbData
    local Owner = self.ListHelper.Owner
    local tbExtraDatas = self.ListHelper.tbExtraDatas
    if tbExtraDatas.bUI then
        local szWndName = tbData.szWndName
        if szWndName == UIDef.UI_PRICING_LIST then
            -- TradeSystem:RequestOpenTradePriceUI()
            return
        elseif szWndName == UIDef.UI_TRADE then
            -- TradeSystem:RequestOpenTradeUI()
            return
        elseif szWndName == UIDef.UI_DRINKINGGAME then
            -- local MiniGameSystem = require("MiniGameSystem")
            -- local MiniGameDef = require("MiniGameDefine")
            -- MiniGameSystem:StartMiniGame(MiniGameDef.DRINKING, 1)
            return
        else
            UIManager:OpenWnd(tbData.szWndName)
        end
    elseif tbExtraDatas.bGM then
        Owner:SetGmContent(tbData.szUsage)
    elseif tbExtraDatas.bGMInstance then
        local szGM
        local nInstanceType = tbData.nInstanceType
        if nInstanceType == 4 then
            szGM = L10N:ToString(pWidgetRef.txtDesc:GetText())
        elseif nInstanceType == 6 then
            MediaSystem:PlayMedia(tonumber(L10N:ToString(pWidgetRef.txtCount:GetText())))
            return
        elseif nInstanceType == 7 then
            -- local szParam = pWidgetRef.txtCount:GetText().sz Text
            -- if szParam == "1" then
            --     AtmoSphereShipSystem:Active()
            -- else
            --     AtmoSphereShipSystem:Deactive()
            -- end
            return
        elseif nInstanceType == 100 then
            assert(false, "this is a test, please ignore this error")
            return
        elseif nInstanceType == 101 then
            ClientShell.GetClient(GWorld):TriggerCrashMannual(ECrashType.CTNullPointerAssignment)
            return
        elseif nInstanceType == 102 then
            ClientShell.GetClient(GWorld):TriggerCrashMannual(ECrashType.CTCheckFalse)
            return
        elseif nInstanceType == 103 then
            ClientShell.GetClient(GWorld):TriggerCrashMannual(ECrashType.CTFatalLog)
            return
        elseif nInstanceType == 104 then
            local CurrentTime = GlobalVariableSystem:GetServerTimeUtc()
            if CurrentTime - OpTimeInterval > 5 then
                OpTimeInterval = CurrentTime
                ClientShell.GetClient(GWorld):DumpMemoryLogManual()
                UIUtils.ShowToast(L10N_DUMP_LOG)
            else
                UIUtils.ShowToast(L10N_OP_FREQUENT)
            end
            return
        elseif nInstanceType == 105 then
            -- Dump10KLogTime = ClientShell.GetClient(GWorld):Dump10KLogManual()
            -- self.ListHelper.Owner:SetDump10KLogTime(Dump10KLogTime)
            return
        else
            local nPos = string.find(tbData.szUsage, "%(")
            if nPos and nPos > 0 then
                szGM =  string.sub(tbData.szUsage, 1, nPos)
                if nInstanceType == 1 then
                    szGM = szGM .. L10N:ToString(pWidgetRef.txtCount:GetText())
                elseif nInstanceType == 2 then
                    szGM = szGM .. FindShipId(pWidgetRef.cmbBox:GetSelectedOption())
                elseif nInstanceType == 3 then
                    szGM = szGM .. FindSceneId(pWidgetRef.cmbBox:GetSelectedOption()) .. " , 0"
                elseif nInstanceType == 5 then
                    szGM = szGM .. "me, " .. L10N:ToString(pWidgetRef.txtCount:GetText())
                else
                    logerror("invalid GM: " .. tbData.szUsage)
                    return
                end
                szGM = szGM .. ")"
            else
                if nInstanceType == 8 then
                    self.Owner:CloseSelf()
                    szGM =  string.sub(tbData.szUsage, 1, nPos)
                    szGM = szGM .. " " .. tonumber(pWidgetRef.cmbBox:GetSelectedOption())
                else
                    logerror("invalid GM: " .. tbData.szUsage)
                    return
                end
            end
        end

        if string.len(szGM) > 0 then
            log("GM: " .. szGM)
            GMSystem_C:Exec(szGM)
        end
    end
end

return UPDebugWidgetItem
