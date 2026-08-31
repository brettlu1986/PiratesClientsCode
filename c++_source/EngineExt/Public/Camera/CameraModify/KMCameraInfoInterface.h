// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "UObject/Interface.h"
#include "Camera/CameraModify/KMCameraInfo.h"

#include "KMCameraInfoInterface.generated.h"
/**
 * 
 */
UINTERFACE(Blueprintable)
class ENGINEEXT_API UKMCameraInfoInterface : public UInterface
{
    GENERATED_UINTERFACE_BODY()
};

class ENGINEEXT_API IKMCameraInfoInterface
{
    GENERATED_IINTERFACE_BODY()

    virtual void ApplyCameraInfo(UInfoBase* Info) = 0;


};
