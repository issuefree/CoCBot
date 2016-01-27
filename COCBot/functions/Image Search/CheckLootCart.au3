Func CheckLootCart()
	SetLog("Checking for loot cart")
	Local $TombX, $TombY
	$cartImage = @ScriptDir & "\images\lootCart.png"
	If Not FileExists($cartImage) Then Return False
	$TombLoc = 0
	_CaptureRegion()
	If _Sleep($iDelayCheckTombs1) Then Return
	For $TombTol = 0 To 75
		If $TombLoc = 0 Then
			$TombX = 0
			$TombY = 0
			$TombLoc = _ImageSearch($cartImage, 1, $TombX, $TombY, $TombTol) ; Getting Tree Location
			If $TombLoc = 1 And isInsideDiamondXY($TombX, $TombY) Then
				; SetLog("Found Loot Cart,  Removing...", $COLOR_GREEN)
				SetLog("Loot Cart found (" & $TombX & "," & $TombY & ") tolerance:" & $TombTol, $COLOR_PURPLE)
				If IsMainPage() Then Click($TombX, $TombY,1,0,"#0120")
				Local $collectButton[3] = [425, 680, Hex(0xffffff, 6)]
				If WaitforPixel($collectButton[0], $collectButton[1], $collectButton[0]+1, $collectButton[1]+1, $collectButton[2], 1, 5) Then
					Click($collectButton[0], $collectButton[1])
				Else
					SetLog("Clicked on the wrong thing at tolerance: " & $TombTol)
				EndIf
				If _Sleep($iDelayCheckTombs1) Then Return
				Return
			EndIf
		EndIf
	Next
	checkMainScreen(False) ; check for screen errors while function was running
EndFunc
