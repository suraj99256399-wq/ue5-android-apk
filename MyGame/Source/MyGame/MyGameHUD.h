#include "CoreMinimal.h"
#include "GameFramework/HUD.h"
#include "MyGameHUD.generated.h"

/** Draws the virtual joystick so the touch controls are visible on device. */
UCLASS()
class MYGAME_API AMyGameHUD : public AHUD
{
	GENERATED_BODY()

public:
	virtual void DrawHUD() override;
};
