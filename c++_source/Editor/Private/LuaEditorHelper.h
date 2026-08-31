#pragma once
#include "LuaEditorHelper.generated.h"

UCLASS(transient)
class ULuaEditorHelper : public UObject
{
	GENERATED_UCLASS_BODY()

public:
	bool Init();
	void Uninit();
	bool PlayInEditor(FString& ErrorMessage);
	bool PlayInCommandlet(const FString& LanuchScript, const FString& Params);

	UFUNCTION()
	void SetIsDedicatedServer(bool bServer);

protected:
	static void AddReferencedObjects(UObject* InThis, FReferenceCollector& Collector);

private:
	struct FImplement;
	TSharedPtr<FImplement> Impl;
};