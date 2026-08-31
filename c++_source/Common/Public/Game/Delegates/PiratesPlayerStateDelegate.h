#pragma once
#include "KMObject.h"
#include "PiratesPlayerStateDelegate.generated.h"


UCLASS()
class COMMON_API UPiratesPlayerStateDelegate : public UKMObject
{
    GENERATED_BODY()
    DECLARE_DYNAMIC_DELEGATE_OneParam(FOnPlayerStateDelegate, APlayerState*, PlayerState);

public:
    UPROPERTY()
	FOnPlayerStateDelegate OnPlayerStateActorChannelOpen;

    UPROPERTY()
	FOnPlayerStateDelegate OnPlayerStateBeginPlay;

    UPROPERTY()
	FOnPlayerStateDelegate OnPlayerStateEndPlay;

	UPROPERTY()
	FOnPlayerStateDelegate OnPostNetInit;
};