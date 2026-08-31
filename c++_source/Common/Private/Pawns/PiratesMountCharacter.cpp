#include "Pawns/PiratesMountCharacter.h"
#include "Common.h"


DEFINE_LOG_CATEGORY_STATIC(LogPiratesMount, Log, All);

APiratesMountCharacter::APiratesMountCharacter(const FObjectInitializer& ObjectInitializer)
    : Super(ObjectInitializer.SetDefaultSubobjectClass<UHumanMountMovementComponent>(ACharacter::CharacterMovementComponentName))
{
 //   NavMoveAIController = nullptr;
    //MovementComponent = nullptr;

	//IsRelativePath = false;

 //   if (!HasAnyFlags(RF_ClassDefaultObject))
 //   {
 //       EmitterActivateComponent = CreateDefaultSubobject<UEmitterActivateComponent>(TEXT("EmitterActivate"));
 //       AddOwnedComponent(EmitterActivateComponent);
 //   }
}

void APiratesMountCharacter::PostNetReceiveRole()
{
    if (GetLocalRole() == ROLE_AutonomousProxy && GetCharacterMovement()->bWasSimulatingRootMotion)
    {
        UE_LOG(LogPiratesMount, Log, TEXT("Character local role change to ROLE_AutonomousProxy, force changing CharacterMovement->bWasSimulatingRootMotion to false."));
        GetCharacterMovement()->bWasSimulatingRootMotion = false;
    }
}
