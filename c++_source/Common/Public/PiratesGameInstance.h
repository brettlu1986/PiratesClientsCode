#pragma once
#include "KMGameInstance.h"
#include "PiratesGameInstance.generated.h"

UCLASS(Blueprintable)
class COMMON_API UPiratesGameInstance : public UKMGameInstance
{
    GENERATED_UCLASS_BODY()

public:
    /**
    *	The Init method of this class is only for init this instance but not game logics.
    */
    //virtual void Init() override;

    //static void AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector);

    /** @return OnlineSession class to use for this game instance  */
    virtual TSubclassOf<UOnlineSession> GetOnlineSessionClass() override;
};