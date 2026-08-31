#pragma once

#include "UObject/Object.h"
#include "KMObject.generated.h"

/**
*
*/
UCLASS(Blueprintable)
class ENGINEEXT_API UKMObject : public UObject
{
	GENERATED_UCLASS_BODY()

	DECLARE_LOG_CATEGORY_CLASS(UKMObjectLog, Log, All);
public:
	virtual UWorld* GetWorld() const override;
};
