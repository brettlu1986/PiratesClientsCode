-----------------------------------------------------
--File Name    : UISetPlayerName.lua
--Author       : Ran Jie
--Create Time  : 2018-03-20
--Description  : 角色取名，创建角色
-----------------------------------------------------
local luaclass = require("luaclass")
local WndBase = require("WndBase")
local UISetPlayerName = luaclass("UISetPlayerName", WndBase)


local UITextDef = require("UITextDef")
local NetworkManager = dynamic_require("NetworkManager")
local Proto = require("ClientProtoNames")
local HumanDataTable = require("HumanDataTable")
local RenderTargetManager = require("RenderTargetManager")
local RenderActor = require("RenderActor")
local NpcAnimStateDefine = require("NpcAnimStateDefine")
local SelfAnimationHelper = require("SelfAnimationHelper")
local GlobalVariableSystem = require("GlobalVariableSystem_C")
local RandomNameTable = require("RandomNameTable")
local PlayerNameIni = require("PlayerNameIni")
local GenderTypeDef = require("GenderTypeDefine")
local UIUtils = require("UIUtils")
local WidgetAnimationHandle = require("WidgetAnimationHandle")
local UTF8NameValidatorHelper = require("UTF8NameValidatorHelper")
local SensitiveWordsSystem = require("SensitiveWordsSystem")
local RenderTargetType = require("RenderTargetType")
local GamePlayerSelfHelper = require("GamePlayerSelfHelper")
local L10N = require("L10N")


UISetPlayerName.tbAvatars = {}
UISetPlayerName.pRenderTarget = nil
UISetPlayerName.bLoadEnd = false
UISetPlayerName.nCurrentSelectSex = GenderTypeDef.MALE
UISetPlayerName.tbNameValidator = nil
UISetPlayerName.nAvatarId = nil
UISetPlayerName.bSkipGuide = false

local function GetRandomData(nSex, nMinLen, nMaxLen, bPostfix)
    -- local nIndex = math.random()
    -- if nIndex < 0.5 then     -- 通用前缀
    --     nSex = 0
    -- end
    -- logdebug("nSex" .. nSex)
    local tbNameDatas = RandomNameTable:GetTemplate(nSex)
    local tbNames = {}
    for _,v in ipairs(tbNameDatas) do
        if bPostfix then
            if v.nPostfixLen > nMinLen and v.nPostfixLen <= nMaxLen then
                table.insert( tbNames, v )
            end
        else
            if v.nPrefixLen > nMinLen and v.nPrefixLen <= nMaxLen then
                table.insert( tbNames, v )
            end
        end
    end
    local nNameLen = #tbNames
    if nNameLen <= 0 then
        return nil
    end
    local nIndex = math.random(1, nNameLen)
    local szTemp = tbNames[nIndex]
    return szTemp
end

local function GetRandomName(nSex)
    local tbPrefix = GetRandomData(nSex, 0, PlayerNameIni.nMaxDisplayWidth, false)
    local nMinLen = (tbPrefix.nPrefixLen > PlayerNameIni.nMinDisplayWidth) and 0 or (PlayerNameIni.nMinDisplayWidth - tbPrefix.nPrefixLen)
    local tbPostfix = GetRandomData(nSex, nMinLen, PlayerNameIni.nMaxDisplayWidth - tbPrefix.nPrefixLen, true)

    if tbPostfix then
        return L10N:ToString(tbPrefix.l10nPrefix) .. L10N:ToString(tbPostfix.l10nPostfix)
    else
        return L10N:ToString(tbPrefix.l10nPrefix)
    end
end

local function OnAnimFinished(self)
	self.bLoadEnd = true
end

local function OnConfirmClick(self)
	local szAvatarName = L10N:ToString(self.pWidgetRef.txtUserName:GetText())
    -- local szAvatarId = self.pWidgetRef.txtAvatarId:GetText().sz Text
    -- local nAvatarId = tonumber(szAvatarId)
    local nRet, _ = self.tbNameValidator:Validate(szAvatarName)
    if nRet == self.tbNameValidator.Result.InvalidUTF8 then
        UIUtils.ShowToast(UITextDef.USER_NAME_EMPTY)
        return
    elseif nRet == self.tbNameValidator.Result.InvalidLength then
        UIUtils.ShowToast(UITextDef.USER_NAME_LEN_ERROR)
        return
    elseif nRet == self.tbNameValidator.Result.InvalidCodePoint then
        UIUtils.ShowToast(UITextDef.NAME_ILLEGAL)
        return
    end

    local bRet = SensitiveWordsSystem:Check(szAvatarName)
    if bRet then
        UIUtils.ShowToast(UITextDef.NAME_ILLEGAL)
        return
	end
	--向服务器发送请求
	local Socket = NetworkManager:GetHubServerProxy()
	local c2s_CreatePlayer =
	{
		name = szAvatarName,
		avatar_id = self.nAvatarId,
		skip_tutorial = self.bSkipGuide
	}
	UIUtils.ShowLoadingDialog()
	if(not Socket:SendPacket(Proto.c2s_CreatePlayer, c2s_CreatePlayer)) then
		UIUtils.ShowToastWithKey("SEND_LOGIN_PACKET_FAILED")
		logwarning("Send login packet failed.")
	end

end

local function OnRandomClick(self)
	--logdebug("UISetPlayerName:OnRandomClick,self.nCurrentSelectSex=",self.nCurrentSelectSex)
	self.pWidgetRef.txtUserName:SetText(GetRandomName(self.nCurrentSelectSex))
end

local function OnEnterNameClick(self)
	local pPlayerController = GameplayStatics.GetPlayerController(GWorld, 0)
	self.pWidgetRef.txtUserName:SetUserFocus(pPlayerController)
	self.pWidgetRef.txtUserName:SetKeyboardFocus()
end

local function OnTextChanged(self, l10nText)
    local szTemp = string.gsub(L10N:ToString(l10nText), '\n', '')
    self.pWidgetRef.txtUserName:SetText(szTemp)
end

function UISetPlayerName:OnEnter()
	self.tbNameValidator = UTF8NameValidatorHelper:CreatePlayerNameValidator()
end

function UISetPlayerName:OnShow()
	KMUMGLibrary.SwitchRendering(false)
	local ViewportSize = WidgetLayoutLibrary.GetViewportSize(GWorld)
	local fHeight = ViewportSize.X / 1920
	-- pBrush.ImageSize = pDimension
	-- logdebug("ViewportSize.X" .. ViewportSize.X .. "ViewportSize.Y " .. ViewportSize.Y .. " fHeight" .. fHeight)
	self.pRenderTarget = RenderTargetManager:TryGetRenderTarget(RenderTargetType.Human, 760 * fHeight , ViewportSize.Y)



	--self.pRenderTarget = RenderTargetManager:TryGetRenderTarget(RenderTargetType.Human)
	local pWidgetRef = self.pWidgetRef
	local tbDialog = {}
	tbDialog.nDisplayId = 0
	tbDialog.szAnimKey = nil
	tbDialog.szMsg = UITextDef.GUIDE_PLAYER_NAME_DIALOGUE

	local nHumanTemplateId = GlobalVariableSystem:GetNewRoleAvatarId()
	self.bSkipGuide = GlobalVariableSystem:IsSkipGuide()
	self.nAvatarId = nHumanTemplateId
	local tbResData = HumanDataTable:GetResData(nHumanTemplateId)
	local tbTemplate = HumanDataTable:GetTemplate(nHumanTemplateId)
	self.nCurrentSelectSex = tbTemplate.nGender
	local roleResource = tbResData.szPawnClassName
	local tbAvatar = self:GetAvatar(0, pWidgetRef.imgAvatarLeft,
					roleResource, Rotator {Pitch = 0, Yaw = 90, Roll = 0}, true)
	self:PlayAnimation(tbAvatar, nHumanTemplateId, tbDialog.szAnimKey)
	pWidgetRef.txtDialogue:SetText(tbDialog.szMsg)
	local PlayerSelf = GamePlayerSelfHelper:Get()
	if PlayerSelf then
		pWidgetRef.txtPlayerName:SetText(PlayerSelf.szName)
	else
		pWidgetRef.txtPlayerName:SetText(UITextDef.GUIDE_PLAYER_NAME_SELF)
	end

end

function UISetPlayerName:OnBindEvent(Helper)
	local pWidgetRef = self.pWidgetRef
	Helper:RegisterCppDelegate(pWidgetRef.btnOk.OnClicked, self, OnConfirmClick)
	Helper:RegisterCppDelegate(pWidgetRef.btnRandom.OnClicked, self, OnRandomClick)
	Helper:RegisterHandle(WidgetAnimationHandle:BindToAnimationFinished(pWidgetRef, pWidgetRef.animComeIn, OnAnimFinished, self))
	Helper:RegisterCppDelegate(pWidgetRef.btnEnterName.OnClicked, self, OnEnterNameClick)
	Helper:RegisterCppDelegate(pWidgetRef.txtUserName.OnTextChanged, self, OnTextChanged)
end

function UISetPlayerName:OnExit()
	for _, v in pairs(self.tbAvatars) do
		v:Destroy()
		-- RenderTargetManager:DestroyActor(v.szClassPath)
	end
	if self.pRenderTarget then
		self.pRenderTarget:Destroy()
	end
	self.pRenderTarget = nil
	self.tbAvatars = {}
	KMUMGLibrary.SwitchRendering(true)
end

function UISetPlayerName:PlayAnimation(target, nTemplateId, szAnimKey)
	if not target or not target.pUEActor or not szAnimKey then
		return
	end

	-- target.pUEActor:PlayAnimMontage(tbMontage.szRes:load(), 1, "Default")
	SelfAnimationHelper:PlayActorAnimation(target.pUEActor,nTemplateId,szAnimKey)
end

function UISetPlayerName:GetAvatar(nID, pTargetImg, szClassPath, inRotator, bSelf)
	local tbAvatar = self.tbAvatars[nID]
	if tbAvatar then
		self.pRenderTarget:BindShowActor(pTargetImg, tbAvatar)
		return tbAvatar
	end
	if szClassPath == nil then
		return nil
	end
	tbAvatar= RenderTargetManager:TryGetActor(self.pRenderTarget, RenderActor.ActorType.Human, pTargetImg, szClassPath, "KMSceneCaptureRecord")
	if tbAvatar.pUEActor then
		local AnimInstance = tbAvatar.pUEActor.Mesh:GetAnimInstance()
		if AnimInstance and AnimInstance.SetAnimState ~= nil then
			AnimInstance:SetAnimState(NpcAnimStateDefine.STAND)
		end
	end
	self.tbAvatars[nID] = tbAvatar
	return tbAvatar
end




return UISetPlayerName
