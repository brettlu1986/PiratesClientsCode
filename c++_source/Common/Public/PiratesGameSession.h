#pragma once
#include "GameFramework/GameSession.h"
#include "PiratesGameSession.generated.h"

UCLASS()
class COMMON_API APiratesGameSession : public AGameSession
{
    GENERATED_BODY()

public:

    /**
    * Called from GameMode.PreLogin() and Login().
    * @param	Options	The URL options (e.g. name/spectator) the player has passed
    * @return	Non-empty Error String if player not approved
    */
    virtual FString ApproveLogin(const FString& Options) override;
};