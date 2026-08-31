// Fill out your copyright notice in the Description page of Project Settings.

#include "KMAnimInstance.h"
#include "EngineExt.h"
/*rog2
#include "KMTimerManager.h"
*/

struct UKMAnimInstance::FImplement
{
	UKMAnimInstance *Owner;
	FTimerHandle	MontageSectionTimerHandle;

	FImplement(UKMAnimInstance *P) : Owner(P)
	{

	}

	void OnPlayEnd(FName SectionName)
	{
		Owner->OnMontagePlayEnd(MoveTemp(SectionName));
	}

	bool PlayMontageSection(UAnimMontage *MontageToPlay, FName SectionName, float InPlayRate, bool needCallback)
	{
		if (nullptr == MontageToPlay)
		{
			return false;
		}
		Owner->Montage_Play(MontageToPlay, InPlayRate);
		Owner->Montage_JumpToSection(MoveTemp(SectionName));

		float Length = 0.f;
		const int32 SectionIndex = MontageToPlay->GetSectionIndex(MoveTemp(SectionName));
		if (!MontageToPlay->IsValidSectionIndex(SectionIndex))
		{
			return false;
		}
		Length = MontageToPlay->GetSectionLength(SectionIndex);
		//	GetWorld()->GetTimerManager().ClearTimer(impl->MontageSectionTimerHandle);
		//	GetWorld()->GetTimerManager().SetTimer(impl->MontageSectionTimerHandle, this, &UKMAnimInstance::OnMontagePlayEnd, Length, false);
		/*rog2 
		UKMGameFrame *GameFrame = UKMGameInstance::GetGameFrame(Owner);
		if (IsValid(GameFrame))
		{
			GameFrame->GetKMTimerManager().ClearTimer(MontageSectionTimerHandle);
			if (needCallback)
			{
				GameFrame->GetKMTimerManager().SetTimer(MontageSectionTimerHandle,
					std::bind(&Impl::OnPlayEnd, this, MoveTemp(SectionName)), Length);
			}
		}
		*/
		return true;
	}

	
};

UKMAnimInstance::UKMAnimInstance(const FObjectInitializer& ObjectInitializer) :Super(ObjectInitializer)
, Impl(MakeShareable(new FImplement(this)))
{
	
}

void UKMAnimInstance::OnMontagePlayEnd_Implementation(FName SectionName)
{

}

bool UKMAnimInstance::PlayMontageSection(UAnimMontage * MontageToPlay, FName SectionName, float InPlayRate/* = 1.f*/, bool needCallback/* = true*/)
{
	return Impl->PlayMontageSection(MontageToPlay, MoveTemp(SectionName), InPlayRate, needCallback);
}

