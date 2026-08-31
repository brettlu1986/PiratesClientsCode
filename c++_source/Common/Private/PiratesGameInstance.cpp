#include "PiratesGameInstance.h"
#include "Common.h"
#include "Game/GameCommon.h"
#include "PiratesOnlineSession.h"

UPiratesGameInstance::UPiratesGameInstance(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer)
{
}

//void UPiratesGameInstance::Init()
//{
//    Super::Init();
//}

//void UPiratesGameInstance::AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector)
//{
//    UPiratesGameInstance* This = CastChecked<UPiratesGameInstance>(InThis);
//    Super::AddReferencedObjects(This, Collector);
//}

TSubclassOf<UOnlineSession> UPiratesGameInstance::GetOnlineSessionClass()
{
    return UPiratesOnlineSession::StaticClass();
}