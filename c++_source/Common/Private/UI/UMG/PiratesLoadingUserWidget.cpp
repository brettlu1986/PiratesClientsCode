// Copyright 1998-2014 Epic Games, Inc. All Rights Reserved.

#include "UI/UMG/PiratesLoadingUserWidget.h"
#include "Common.h"





void UPiratesLoadingUserWidget::OnPostLoadMap(UWorld* CurrentWorld)
{
	if (GWorld == GetWorld())
	{
		bRemovedByLevelUnload = false;
		FCoreUObjectDelegates::PostLoadMapWithWorld.RemoveAll(this);
	}
	//Super::OnPostLoadMap(CurrentWorld);
}
