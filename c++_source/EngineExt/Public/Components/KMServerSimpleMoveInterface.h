// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "KMServerSimpleMoveInterface.generated.h"

/*
* Server simple move means client will take charges of computing movement and server just trust what client does
*/
UINTERFACE(MinimalAPI, meta = (CannotImplementInterfaceInBlueprint))
class UKMServerSimpleMoveInterface : public UInterface
{
	GENERATED_UINTERFACE_BODY()
};

class ENGINEEXT_API IKMServerSimpleMoveInterface
{
	GENERATED_IINTERFACE_BODY()

	virtual bool EnableServerSimpleMove(bool bEnable) = 0;

	virtual bool IsServerSimpleMoveEnabled() const = 0;
};
