// Fill out your copyright notice in the Description page of Project Settings.

#include "Components/AbilityComponent.h"
#include "Common.h"

void UAbilityComponent::AddBuffByIdWithCauser(int32 CauserId, int32 BuffId, int32 Count, int32 Level)
{
    if (OnAddBuffByIdWithCauser.IsBound())
    {
        OnAddBuffByIdWithCauser.Execute(CauserId, BuffId, Count, Level);
    }
}

void UAbilityComponent::AddBuffById(int32 BuffId, int32 Count, int32 Level)
{
	if (OnAddBuffById.IsBound())
	{
		OnAddBuffById.Execute(BuffId, Count, Level);
	}
}

void UAbilityComponent::RemoveBuffById(int32 BuffId)
{
	if (OnRemoveBuffById.IsBound())
	{
		OnRemoveBuffById.Execute(BuffId);
	}
}

void UAbilityComponent::RemoveBuffByGroupId(int32 GroupId)
{
	if (OnRemoveBuffByGroupId.IsBound())
	{
		OnRemoveBuffByGroupId.Execute(GroupId);
	}
}

void UAbilityComponent::RemoveAllBuff()
{
	if (OnRemoveAllBuff.IsBound())
	{
		OnRemoveAllBuff.Execute();
	}
}

bool UAbilityComponent::RequestCastSkill(int32 SkillID, int32& CastFailedReasonID)
{
    bool Ret = false;
    TempCastFailedReasonID = -1;
    if (OnRequestCastSkill.IsBound())
    {
        Ret = OnRequestCastSkill.Execute(SkillID);
        CastFailedReasonID = TempCastFailedReasonID;
    }
    return Ret;
}

bool UAbilityComponent::CheckCondition(int32 SkillID, int32& CastFailedReasonID)
{
    bool Ret = false;
    TempCastFailedReasonID = -1;
    if (OnCheckCondition.IsBound())
    {
        Ret = OnCheckCondition.Execute(SkillID);
        CastFailedReasonID = TempCastFailedReasonID;
    }
    return Ret;
}

void UAbilityComponent::ExcuteActionGroup(UAnimSequenceBase* Animation, int32 ActionGroupIndex)
{
    if (OnExcuteActionGroup.IsBound())
    {
        OnExcuteActionGroup.Execute(ActionGroupIndex);
    }
}

void UAbilityComponent::ExcuteActionGroupEnd(UAnimSequenceBase* Animation, int32 ActionGroupIndex)
{
    if (OnExcuteActionGroupEnd.IsBound())
    {
        OnExcuteActionGroupEnd.Execute(ActionGroupIndex);
    }
}

void UAbilityComponent::ExcuteSubSkill(UAnimSequenceBase * Animation)
{
    if (OnExcuteSubSkill.IsBound())
    {
        OnExcuteSubSkill.Execute();
    }
}

void UAbilityComponent::SetSkillEnabled(int32 SkillID, bool Enabled)
{
    if (OnSetSkillEnabled.IsBound())
    {
        OnSetSkillEnabled.Execute(SkillID, Enabled);
    }
}