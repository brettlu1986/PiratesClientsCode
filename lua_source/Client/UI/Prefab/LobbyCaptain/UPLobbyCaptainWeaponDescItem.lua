-----------------------------------------------------
--File Name    : UPLobbyCaptainWeaponDescItem.lua
--Author       : WuJizhou
--Create Time  : 5/18/2020, 3:10:30 PM
--Description  : UPLobbyCaptainWeaponDescItem
-----------------------------------------------------
local luaclass = require("luaclass")
local ListItemBase = require("ListItemBase")

local UPLobbyCaptainWeaponDescItem = luaclass("UPLobbyCaptainWeaponDescItem", ListItemBase)


function UPLobbyCaptainWeaponDescItem:OnRefresh(tbData)
    if tbData[1] then
        self.pWidgetRef.txtCategoryName:SetText(tbData[1])
        self.pWidgetRef.txtCategoryName:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.pWidgetRef.txtCategoryName:SetVisibility(ESlateVisibility.Collapsed)
    end
    if tbData[2] then
        self.pWidgetRef.txtScore:SetText(tbData[2])
        self.pWidgetRef.txtScore:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        self.pWidgetRef.txtScore:SetVisibility(ESlateVisibility.Collapsed)
    end

end


----------life cycle----------
-- function UPLobbyCaptainWeaponDescItem:OnCreate()
-- end

-- function UPLobbyCaptainWeaponDescItem:OnDestroy()
-- end

-- function UPLobbyCaptainWeaponDescItem:OnLoad()
-- end

-- function UPLobbyCaptainWeaponDescItem:OnUnload()
-- end

-- function UPLobbyCaptainWeaponDescItem:OnEnter()
-- end

-- function UPLobbyCaptainWeaponDescItem:OnShow()
-- end

-- function UPLobbyCaptainWeaponDescItem:OnHide()
-- end

-- function UPLobbyCaptainWeaponDescItem:OnExit()
-- end

-- function UPLobbyCaptainWeaponDescItem:OnBindEvent(EventHelper)
-- end

-- function UPLobbyCaptainWeaponDescItem:OnUnbindEvent(EventHelper)
-- end

return UPLobbyCaptainWeaponDescItem