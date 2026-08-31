#include "PiratesGameSession.h"
#include "Common.h"
#include "Game/GameCommon.h"

FString APiratesGameSession::ApproveLogin(const FString& Options)
{
    FString ErrorMsg = "";
    auto GameCommon = UGameCommon::Get(this);
    if (GameCommon)
    {
        ErrorMsg = GameCommon->ApproveLogin(Options);
    }

    if (ErrorMsg.IsEmpty())
    {
        ErrorMsg = Super::ApproveLogin(Options);
    }
    return ErrorMsg;
}
