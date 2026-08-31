-----------------------------------------------------
--Author       : Ran Jie
--Create Time  : 2019-01-29
--Description  : UPMapObjForFFATeamMember
-----------------------------------------------------

local luaclass = require ("luaclass")
local PrefabBase = require("PrefabBase")
local UPMapObjForFFATeamMember = luaclass("UPMapObjForFFATeamMember", PrefabBase)

-- import require
local UISetUtils = require("UISetUtils")
local UIResourceDef = require("UIResourceDef")
local DCProto = require("DungeonCommonProtoNames")


--member veriable
UPMapObjForFFATeamMember.bIsInUse = false
UPMapObjForFFATeamMember.tbData = nil
UPMapObjForFFATeamMember.szLastIcon = nil 
UPMapObjForFFATeamMember.pLastSalteTintColor = nil

local SELF_HIT_TEST_IN_VISIBLE = ESlateVisibility.SelfHitTestInvisible
local COLLAPSED = ESlateVisibility.Collapsed

--member function
function UPMapObjForFFATeamMember:ShowContent(tbData)
    self.bIsInUse = true
    self.tbData = tbData
    if(self.pWidgetRef == nil) then
        return
    end
    local pWidgetRef = self.pWidgetRef
    self.pWidgetRef:SetVisibility(SELF_HIT_TEST_IN_VISIBLE)
    
    local pLinearColor = UIResourceDef.TEAM_INDEX_COLOR[tbData.nIndex]
    if tbData.bTransparentColor then
        pLinearColor = UIResourceDef.TEAM_INDEX_COLOR_TRANSPARENT[tbData.nIndex]
    end
    if not pLinearColor then
        logerror("UPMapObjForFFATeamMember:SetData error index, ", tbData.nIndex)
        pLinearColor = UIResourceDef.COLOR.WHITE.LINEAR_COLOR
    end
    pWidgetRef.txtName:SetVisibility(COLLAPSED)
    if tbData.nState == DCProto.TeamInfo_EState.NONE then 
        pWidgetRef.txtNameNumber:SetText(tbData.nIndex)
        pWidgetRef.txtNameNumber:SetVisibility(SELF_HIT_TEST_IN_VISIBLE)
    else
        pWidgetRef.txtNameNumber:SetVisibility(COLLAPSED)
    end
    
    pWidgetRef.txtNameNumberEx:SetText(tbData.nIndex)
    local szIcon = UIResourceDef.TEAM_MEMBER_STATE_ICON[tbData.nState]
    self:SetIcon(szIcon, pLinearColor)
    pWidgetRef.imgStateIconEx:SetColorAndOpacity(pLinearColor)
    if tbData.UILocation then
        local UIPos = Vector2D{X = tbData.UILocation.X, Y = tbData.UILocation.Y}
        self.pWidgetRef.Slot:SetPosition(UIPos)
    end
    if tbData.UIRotation then
        self.pWidgetRef:SetRenderTransformAngle(tbData.UIRotation)
    else
        self.pWidgetRef:SetRenderTransformAngle(0)
    end
end

function UPMapObjForFFATeamMember:HideContent()
    self.bIsInUse = false
    self.tbData = nil
    if(self.pWidgetRef == nil) then
        return
    end    
    self.pWidgetRef:SetVisibility(ESlateVisibility.Collapsed)
end

function UPMapObjForFFATeamMember:SetIcon(szIcon, pSlateColor, bMatchSize)
    local imgStateIcon = self.pWidgetRef.imgStateIcon
    if szIcon then
        imgStateIcon:SetVisibility(ESlateVisibility.SelfHitTestInvisible)
    else
        imgStateIcon:SetVisibility(ESlateVisibility.Collapsed)
        return
    end

    if pSlateColor and pSlateColor ~= self.pLastSalteTintColor then
        self.pLastSalteTintColor = pSlateColor
        imgStateIcon:SetColorAndOpacity(pSlateColor)
    end

    if self.szLastIcon ~= szIcon then 
        self.szLastIcon = szIcon
        UISetUtils.SetImageBrushRes(imgStateIcon, szIcon:load())
    end
    
end

function UPMapObjForFFATeamMember:GetUseState()
    return self.bIsInUse
end

function UPMapObjForFFATeamMember:HideDistance(bHideDistance)
    local pVisibility = bHideDistance and COLLAPSED or SELF_HIT_TEST_IN_VISIBLE
    self.pWidgetRef.ovlDistance:SetVisibility(pVisibility)
end

function UPMapObjForFFATeamMember:SetName(szName)
    if szName then
        self.pWidgetRef.txtName:SetVisibility(SELF_HIT_TEST_IN_VISIBLE)
        self.pWidgetRef.txtName:SetText(szName)
    end
end


return UPMapObjForFFATeamMember
