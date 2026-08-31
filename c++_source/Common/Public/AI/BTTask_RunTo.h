#pragma once

#include "BehaviorTree/Tasks/BTTask_MoveTo.h"
#include "BTTask_RunTo.generated.h"

UCLASS(Blueprintable)
class COMMON_API UBTTask_RunTo : public UBTTask_MoveTo
{
    GENERATED_UCLASS_BODY()

    virtual void OnTaskFinished(UBehaviorTreeComponent& OwnerComp, uint8* NodeMemory, EBTNodeResult::Type TaskResult) override;
 
    virtual EBTNodeResult::Type ExecuteTask(UBehaviorTreeComponent& OwnerComp, uint8* NodeMemory) override;

    UFUNCTION(BlueprintCallable, BlueprintNativeEvent, Category = "Run To")
    void StopRun(AAIController* AIController);

    UFUNCTION(BlueprintCallable, BlueprintNativeEvent, Category = "Run To")
    void StartRun(AAIController* AIController);

};