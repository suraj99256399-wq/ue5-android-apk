#include "CoreMinimal.h"
#include "GameFramework/Pawn.h"
#include "MyGamePawn.generated.h"

class UCameraComponent;
class USceneComponent;
class UFloatingPawnMovement;

/**
 * A first-person style pawn driven entirely from touch input, so it is
 * playable on a phone without any editor-authored assets.
 */
UCLASS()
class MYGAME_API AMyGamePawn : public APawn
{
	GENERATED_BODY()

public:
	AMyGamePawn();

	virtual void Tick(float DeltaSeconds) override;

	/** Movement input from the virtual joystick, range [-1, 1] on each axis. */
	void SetMoveInput(const FVector2D& InMoveInput) { MoveInput = InMoveInput; }

	/** Accumulates look input in pixels from the right-hand touch zone. */
	void AddLookInput(const FVector2D& Delta) { LookInput += Delta; }

	/** Enables or disables look handling for the current frame. */
	void SetLooking(bool bInLooking) { bLooking = bInLooking; }

protected:
	UPROPERTY(VisibleAnywhere, Category = "MyGame")
	TObjectPtr<USceneComponent> Root;

	UPROPERTY(VisibleAnywhere, Category = "MyGame")
	TObjectPtr<UCameraComponent> Camera;

	UPROPERTY(VisibleAnywhere, Category = "MyGame")
	TObjectPtr<UFloatingPawnMovement> Movement;

	/** Units per second at full joystick deflection. */
	UPROPERTY(EditAnywhere, Category = "MyGame")
	float MoveSpeed = 900.0f;

	/** Degrees of yaw per pixel of horizontal drag. */
	UPROPERTY(EditAnywhere, Category = "MyGame")
	float YawSensitivity = 0.18f;

	/** Degrees of pitch per pixel of vertical drag. */
	UPROPERTY(EditAnywhere, Category = "MyGame")
	float PitchSensitivity = 0.14f;

private:
	FVector2D MoveInput = FVector2D::ZeroVector;
	FVector2D LookInput = FVector2D::ZeroVector;
	bool bLooking = false;
};
