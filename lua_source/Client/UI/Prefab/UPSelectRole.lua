local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPSelectRole = luaclass("UPSelectRole", PrefabBase)
local LuaDelegate = require("LuaDelegate")
local HumanDataTable = require("HumanDataTable")
local UIResourceDef = require("UIResourceDef")
local UISetUtils = require("UISetUtils")
local UITextDef = require("UITextDef")
local L10N = require("L10N")
-- local GenderTypeDef = require("GenderTypeDefine")
-- local RaceTypeDefine = require("RaceTypeDefine")
UPSelectRole.OnClicked = nil 
UPSelectRole.tbData = nil 
UPSelectRole.bSelected = false
UPSelectRole.nID = 0
function UPSelectRole:OnShow()

end 

function UPSelectRole:OnHide()
    if self.OnClicked then 
        self.OnClicked:UnbindAll()
        self.OnClicked = nil 
    end 
end 

local function GetRes(nHumanID)
    local tbHumanData = HumanDataTable:GetTemplate(nHumanID)
    if not tbHumanData then 
        return nil 
    end	          
    local nKey = (tbHumanData.nRace - 1) * 2 + tbHumanData.nGender
    return UIResourceDef.tbSelectPlayerHeadIcon[nKey]
end 

function UPSelectRole:SetData(nID, tbData, bSelected, fnOnClicked, tbParent)
    self.nID = nID
    if not self.OnClicked then 
        self.OnClicked = LuaDelegate()
    end     
    self.OnClicked:Bind(fnOnClicked, tbParent)
    local pWidgetRef = self.pWidgetRef
    self.tbData = tbData
    self:SetSelect(bSelected)    
    if tbData then 
        pWidgetRef.img_Head:SetVisibility(ESlateVisibility.HitTestInvisible)
        pWidgetRef.property:SetVisibility(ESlateVisibility.HitTestInvisible)
        
        pWidgetRef.txtLv:SetText(L10N:Format(UITextDef.COMMON_LEVEL_1, tbData.level))
        pWidgetRef.txtName:SetText(tbData.name)
        pWidgetRef.bdCreateNew:SetVisibility(ESlateVisibility.Hidden)
  
        local szRes = GetRes(tbData.preview.human.avatar_id)
        if szRes then 
            UISetUtils.SetImageBrushRes(pWidgetRef.img_Head, szRes:load())  
        end 
        
    else
        pWidgetRef.img_Head:SetVisibility(ESlateVisibility.Hidden)
        pWidgetRef.property:SetVisibility(ESlateVisibility.Hidden)        
        pWidgetRef.bdCreateNew:SetVisibility(ESlateVisibility.HitTestInvisible)
    end 

end 

function UPSelectRole:SetSelect(bSelected)
    if bSelected then 
        if self.tbData then 
            self.pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.Visible)
        end 
    else     
        self.pWidgetRef.imgSelected:SetVisibility(ESlateVisibility.Hidden)
    end     
    self.bSelected = bSelected    
end 

function UPSelectRole:OnBindEvent(EventHelper)
    local pWidgetRef = self.pWidgetRef
    EventHelper:RegisterCppDelegate(pWidgetRef.btnClick.OnPressed  , self, self.OnClickBtn)
end

function UPSelectRole:OnClickBtn()
    if self.bSelected then 
        return 
    end

    self:SetSelect(true)
    if self.OnClicked then 
        self.OnClicked:Fire(self.nID)
    end 
end 

return UPSelectRole