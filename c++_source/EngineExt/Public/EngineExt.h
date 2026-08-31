#pragma once

#include "Engine.h"
#include "GlobalDefinition.h"

//#include "Components/PoseableMeshComponent.h"
//
//#include "Animation/AnimCurveTypes.h"
//#include "Animation/AnimSequenceBase.h"
//#include "Animation/AnimCompositeBase.h"
//#include "Animation/AnimComposite.h"
//#include "Animation/AnimMontage.h"
//#include "Animation/AnimSequence.h"
//#include "Animation/BlendSpaceBase.h"
//#include "Animation/AnimStateMachineTypes.h"
//#include "Animation/AnimInstance.h"
//#include "Animation/BlendSpace.h"
//#include "Animation/AimOffsetBlendSpace.h"
//#include "Animation/BlendSpace1D.h"
//#include "Animation/AimOffsetBlendSpace1D.h"
//#include "Animation/AnimSingleNodeInstance.h"
//#include "Animation/AnimNotifies/AnimNotify.h"
//#include "Animation/AnimNotifies/AnimNotifyState.h"
//#include "Animation/AnimNotifies/AnimNotifyState_TimedParticleEffect.h"
//#include "Animation/AnimNotifies/AnimNotifyState_Trail.h"
//
//#include "PhysicsEngine/BodySetup.h"
//#include "PhysicsEngine/BodyInstance.h"
//#include "PhysicsEngine/DestructibleActor.h"
//#include "PhysicsEngine/ConstraintInstance.h"
//#include "PhysicsEngine/PhysicsConstraintComponent.h"


class FEngineExtModule : public IModuleInterface
{
public:

    /** IModuleInterface implementation */
    virtual void StartupModule() override;
    virtual void ShutdownModule() override;
};
