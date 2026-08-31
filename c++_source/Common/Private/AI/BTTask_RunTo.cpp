#include "AI/BTTask_RunTo.h"
#include "Common.h"
#include "Kismet/GameplayStatics.h"
#include "AI/BTTask_RunTo.h"

UBTTask_RunTo::UBTTask_RunTo(const FObjectInitializer& ObjectInitializer) : Super(ObjectInitializer)
{
    NodeName = "Run To";
}

EBTNodeResult::Type UBTTask_RunTo::ExecuteTask(UBehaviorTreeComponent& OwnerComp, uint8* NodeMemory)
{
    EBTNodeResult::Type Result = Super::ExecuteTask(OwnerComp, NodeMemory);
    if (EBTNodeResult::Succeeded == Result || EBTNodeResult::InProgress == Result)
    {
        AAIController* MyController = OwnerComp.GetAIOwner();
        StartRun(MyController);
    }
    return Result;
}

void UBTTask_RunTo::OnTaskFinished(UBehaviorTreeComponent& OwnerComp, uint8* NodeMemory, EBTNodeResult::Type TaskResult)
{
    AAIController* MyController = OwnerComp.GetAIOwner();
    StopRun(MyController);
    Super::OnTaskFinished(OwnerComp, NodeMemory, TaskResult);
}


void UBTTask_RunTo::StartRun_Implementation(AAIController* AIController)
{

}

void UBTTask_RunTo::StopRun_Implementation(AAIController* AIController)
{

}
