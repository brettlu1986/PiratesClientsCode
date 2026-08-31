#pragma once
#include "KMJsonExportInterface.generated.h"

UINTERFACE(Blueprintable)
class ENGINEEXT_API UKMJsonExportInterface : public UInterface
{
    GENERATED_UINTERFACE_BODY()
};

class ENGINEEXT_API IKMJsonExportInterface
{
    GENERATED_IINTERFACE_BODY()

public:
    UFUNCTION(BlueprintImplementableEvent, Category = "KMJsonExportComponent", meta = (CallInEditor = "true"))
    void OnConstructNodeTree(int RootNodeIndex);
};