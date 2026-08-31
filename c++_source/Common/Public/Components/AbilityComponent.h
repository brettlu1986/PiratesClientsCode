#pragma once

#include "AbilityComponent.generated.h"


UCLASS(Blueprintable)
class COMMON_API UAbilityPostProcessData : public UDataAsset
{
	GENERATED_BODY()
public:
	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	UMaterialInterface* MaterialInterface;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	bool bAutoDestroy;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	float Duration;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	float ParamterCurveSplitTime;

	UPROPERTY(BlueprintReadWrite, EditAnywhere)
	TMap<FName, UCurveFloat*> ParamterCurveMap;
};

UCLASS(Blueprintable, meta = (BlueprintSpawnableComponent))
class COMMON_API UAbilityComponent : public UActorComponent
{
    DECLARE_DYNAMIC_DELEGATE_FourParams(FOnAddBuffByIdWithCauser, int32, CauserId, int32, BuffId, int32, Count, int32, Level);
    DECLARE_DYNAMIC_DELEGATE_ThreeParams(FOnAddBuffById, int32, BuffId, int32, Count, int32, Level);
    DECLARE_DYNAMIC_DELEGATE_OneParam(FOnRemoveBuffById, int32, BuffId);
    DECLARE_DYNAMIC_DELEGATE_OneParam(FOnRemoveBuffByGroupId, int32, GroupId);
    DECLARE_DYNAMIC_DELEGATE(FOnRemoveAllBuff);
    DECLARE_DYNAMIC_DELEGATE_RetVal_OneParam(bool, FOnRequestCastSkill, int32, SkillID);
    DECLARE_DYNAMIC_DELEGATE_RetVal_OneParam(bool, FOnCheckCondition, int32, SkillID);
    DECLARE_DYNAMIC_DELEGATE_OneParam(FOnExcuteActionGroup, int32, ActionGroupIndex);
    DECLARE_DYNAMIC_DELEGATE(FOnExcuteSubSkill);
    DECLARE_DYNAMIC_DELEGATE_TwoParams(FOnSetSkillEnabled, int32, SkillID, bool, Enabled);

public:
	GENERATED_BODY()
    
// Buff
    // 添加Buff with causerId
    UFUNCTION(BlueprintCallable, Category = "BuffComponent")
    void AddBuffByIdWithCauser(int32 CauserId, int32 BuffId, int32 Count = 1, int32 Level = 1);
	// 添加Buff
    UFUNCTION(BlueprintCallable, Category = "BuffComponent")
	void AddBuffById(int32 BuffId, int32 Count = 1, int32 Level = 1);
	
	// 移除Buff
    UFUNCTION(BlueprintCallable, Category = "BuffComponent")
	void RemoveBuffById(int32 BuffId);
	
	// 通过GroupId移除Buff
    UFUNCTION(BlueprintCallable, Category = "BuffComponent")
	void RemoveBuffByGroupId(int32 GroupId);
	
	// 移除所有Buff
    UFUNCTION(BlueprintCallable, Category = "BuffComponent")
    void RemoveAllBuff();

// Skill
	// 请求释放技能
    UFUNCTION(BlueprintCallable, Category = "SkillComponent")
    bool RequestCastSkill(int32 SkillID, int32& CastFailedReasonID);
    
	// 判断当前是否能够释放某技能
    UFUNCTION(BlueprintPure, Category = "SkillComponent")
	bool CheckCondition(int32 SkillID, int32& CastFailedReasonID);

	// 执行Action
	UFUNCTION(BlueprintCallable, Category = "SkillComponent")
	void ExcuteActionGroup(UAnimSequenceBase* Animation, int32 ActionGroupIndex);

	// 执行Action
	UFUNCTION(BlueprintCallable, Category = "SkillComponent")
	void ExcuteActionGroupEnd(UAnimSequenceBase* Animation, int32 ActionGroupIndex);

	// 执行Action
	UFUNCTION(BlueprintCallable, Category = "SkillComponent")
	void ExcuteSubSkill(UAnimSequenceBase* Animation);
	
	// 启用/禁用指定技能
	UFUNCTION(BlueprintCallable, Category = "SkillComponent")
	void SetSkillEnabled(int32 SkillID, bool Enabled);

    UPROPERTY()
    FOnAddBuffByIdWithCauser OnAddBuffByIdWithCauser;

	UPROPERTY()
	FOnAddBuffById OnAddBuffById;

	UPROPERTY()
	FOnRemoveBuffById OnRemoveBuffById;

	UPROPERTY()
	FOnRemoveBuffByGroupId OnRemoveBuffByGroupId;

	UPROPERTY()
	FOnRemoveAllBuff OnRemoveAllBuff;

	UPROPERTY()
	FOnRequestCastSkill OnRequestCastSkill;

	UPROPERTY()
	FOnCheckCondition OnCheckCondition;

	UPROPERTY()
	FOnExcuteActionGroup OnExcuteActionGroup;

	UPROPERTY()
	FOnExcuteActionGroup OnExcuteActionGroupEnd;

	UPROPERTY()
	FOnExcuteSubSkill OnExcuteSubSkill;
	
	UPROPERTY()
	FOnSetSkillEnabled OnSetSkillEnabled;

	UPROPERTY()
	int32 TempCastFailedReasonID;
};
