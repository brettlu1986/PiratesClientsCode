// Copyright 1998-2014 Epic Games, Inc. All Rights Reserved.

#pragma  once

#include "PiratesUserWidget.h"
#include "PiratesLoadingUserWidget.generated.h"


UCLASS()
class COMMON_API UPiratesLoadingUserWidget : public UPiratesUserWidget
{
public:
	GENERATED_BODY()



protected:

	virtual void OnPostLoadMap(UWorld* CurrentWorld) override;
};
