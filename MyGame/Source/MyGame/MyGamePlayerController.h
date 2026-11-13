#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "MyGamePlayerController.generated.h"

class AMyGamePawn;

/**
 * Routes multi-touch input to the pawn: the left half of the screen drives a
 * virtual joystick, the right half drags the camera. No input assets required.
 */
UCLASS()
class MYGAME_API AMyGamePlayerController : public APlayerController
{
	GENERATED_BODY()

public:
	AMyGamePlayerController();

	virtual void SetupInputComponent() override;

	/** Normalised joystick centre and current knob position, for the HUD. */
	FVector2D GetJoystickCentre() const { return JoystickCentre; }
	FVector2D GetJoystickKnob() const { return JoystickKnob; }
	float GetJoystickRadius() const { return JoystickRadius; }

protected:
	void OnTouchPressed(ETouchIndex::Type FingerIndex, FVector Location);
	void OnTouchMoved(ETouchIndex::Type FingerIndex, FVector Location);
	void OnTouchReleased(ETouchIndex::Type FingerIndex, FVector Location);

private:
	AMyGamePawn* GetMyPawn() const;

	/** Radius in pixels within which joystick deflection saturates. */
	float JoystickRadius = 140.0f;

	int32 MoveFingerIndex = INDEX_NONE;
	int32 LookFingerIndex = INDEX_NONE;

	FVector2D JoystickCentre = FVector2D::ZeroVector;
	FVector2D JoystickKnob = FVector2D::ZeroVector;
	FVector2D LastLookLocation = FVector2D::ZeroVector;
};
