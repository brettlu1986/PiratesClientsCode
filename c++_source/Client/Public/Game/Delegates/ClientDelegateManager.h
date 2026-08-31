#pragma once

#include "Game/Delegates/GameDelegateManager.h"
#include "ClientDelegateManager.generated.h"


UCLASS()
class CLIENT_API UClientDelegateManager : public UGameDelegateManager
{
    GENERATED_BODY()

public:
    UPROPERTY(BlueprintReadOnly, Category = ClientDelegate)
    class UClientSdkDelegate* SdkDelegate;
    UPROPERTY(BlueprintReadOnly, Category = ClientDelegate)
    class UGVoiceSdkNotifyDelegate* GVoiceSdkNotifyDelegate;

public:
    virtual void Init() override;
};
