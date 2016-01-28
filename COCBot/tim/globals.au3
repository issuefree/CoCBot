#include <Array.au3>
#include <String.au3>
; I know a lot of this info is already defined in the bot but I like my format better :)

; These should map directly to the $e[Troop] enum from the bot. Bugs could be introduced if this changes.
Global Enum _
	$iBarbarian, _
	$iArcher, _
	$iGiant, _
	$iGoblin, _
	$iWallBreaker , _
	$iBalloon, _
	$iWizard, _
	$iHealer, _
	$iDragon, _
	$iPekka, _
	$iMinion, _
	$iHogRider, _
	$iValkyrie, _
	$iGolem, _
	$iWitch, _
	$iLavaHound, _
	$iArmyEnd	

Global $ArmyTrainTime = 0

Global $ArmyComposition[$iArmyEnd]
Global $ArmyTrained[$iArmyEnd]
Global $ArmyTraining[$iArmyEnd]

Global $ArmyDonationTraining[$iArmyEnd]

Global $UnitIsDark[$iArmyEnd]
$UnitIsDark[$iBarbarian] = False
$UnitIsDark[$iArcher] = False
$UnitIsDark[$iGiant] = False
$UnitIsDark[$iGoblin] = False
$UnitIsDark[$iWallBreaker ] = False
$UnitIsDark[$iBalloon] = False
$UnitIsDark[$iWizard] = False
$UnitIsDark[$iHealer] = False
$UnitIsDark[$iDragon] = False
$UnitIsDark[$iPekka] = False
$UnitIsDark[$iMinion] = True
$UnitIsDark[$iHogRider] = True
$UnitIsDark[$iValkyrie] = True
$UnitIsDark[$iGolem] = True
$UnitIsDark[$iWitch] = True
$UnitIsDark[$iLavaHound] = True

Global $UnitName[$iArmyEnd]
$UnitName[$iBarbarian] = "Barbarian"
$UnitName[$iArcher] = "Archer"
$UnitName[$iGiant] = "Giant"
$UnitName[$iGoblin] = "Goblin"
$UnitName[$iWallBreaker ] = "WallBreaker"
$UnitName[$iBalloon] = "Balloon"
$UnitName[$iWizard] = "Wizard"
$UnitName[$iHealer] = "Healer"
$UnitName[$iDragon] = "Dragon"
$UnitName[$iPekka] = "Pekka"
$UnitName[$iMinion] = "Minion"
$UnitName[$iHogRider] = "HogRider"
$UnitName[$iValkyrie] = "Valkyrie"
$UnitName[$iGolem] = "Golem"
$UnitName[$iWitch] = "Witch"
$UnitName[$iLavaHound] = "LaavHound"

Global $UnitRequiresBarracksLevel[$iArmyEnd]
$UnitRequiresBarracksLevel[$iBarbarian] = 1
$UnitRequiresBarracksLevel[$iArcher] = 2
$UnitRequiresBarracksLevel[$iGiant] = 3
$UnitRequiresBarracksLevel[$iGoblin] = 4
$UnitRequiresBarracksLevel[$iWallBreaker ] = 5
$UnitRequiresBarracksLevel[$iBalloon] = 6
$UnitRequiresBarracksLevel[$iWizard] = 7
$UnitRequiresBarracksLevel[$iHealer] = 8
$UnitRequiresBarracksLevel[$iDragon] = 9
$UnitRequiresBarracksLevel[$iPekka] = 10
$UnitRequiresBarracksLevel[$iMinion] = 1
$UnitRequiresBarracksLevel[$iHogRider] = 2
$UnitRequiresBarracksLevel[$iValkyrie] = 3
$UnitRequiresBarracksLevel[$iGolem] = 4
$UnitRequiresBarracksLevel[$iWitch] = 5
$UnitRequiresBarracksLevel[$iLavaHound] = 6


Func getI($name)
	For $i = 0 to UBound($UnitName) - 1
		If $UnitName[$i] == $name Then Return $i
	Next
EndFunc

Global $UnitTime[$iArmyEnd]
$UnitTime[$iBarbarian] = 20
$UnitTime[$iArcher] = 25
$UnitTime[$iGiant] = 2*60
$UnitTime[$iGoblin] = 30
$UnitTime[$iWallBreaker ] = 2*60
$UnitTime[$iBalloon] = 8*60
$UnitTime[$iWizard] = 8*60
$UnitTime[$iHealer] = 15*60
$UnitTime[$iDragon] = 30*60
$UnitTime[$iPekka] = 45*60
$UnitTime[$iMinion] = 45
$UnitTime[$iHogRider] = 2*60
$UnitTime[$iValkyrie] = 8*60
$UnitTime[$iGolem] = 45*60
$UnitTime[$iWitch] = 20*60
$UnitTime[$iLavaHound] = 45*60

Global $UnitSize[$iArmyEnd]
$UnitSize[$iBarbarian] = 1
$UnitSize[$iArcher] = 1
$UnitSize[$iGiant] = 5
$UnitSize[$iGoblin] = 1
$UnitSize[$iWallBreaker ] = 2
$UnitSize[$iBalloon] = 5
$UnitSize[$iWizard] = 4
$UnitSize[$iHealer] = 14
$UnitSize[$iDragon] = 20
$UnitSize[$iPekka] = 25
$UnitSize[$iMinion] = 2
$UnitSize[$iHogRider] = 5
$UnitSize[$iValkyrie] = 8
$UnitSize[$iGolem] = 30
$UnitSize[$iWitch] = 12
$UnitSize[$iLavaHound] = 30

Global $UnitTrainOrder[$iArmyEnd] = [ _
	$iPekka, _
	$iDragon, _
	$iHealer, _
	$iWizard, _
	$iBalloon, _
	$iGiant, _
	$iWallBreaker , _
	$iGoblin, _
	$iBarbarian, _
	$iArcher, _
	$iGolem, _
	$iHogRider, _
	$iValkyrie, _
	$iLavaHound, _
	$iWitch, _
	$iMinion _
]


Global $UnitShortName[$iArmyEnd]
$UnitShortName[$iBarbarian] = "Barb"
$UnitShortName[$iArcher] = "Arch"
$UnitShortName[$iGiant] = "Giant"
$UnitShortName[$iGoblin] = "Gobl"
$UnitShortName[$iWallBreaker ] = "Wall"
$UnitShortName[$iBalloon] = "Ball"
$UnitShortName[$iWizard] = "Wiza"
$UnitShortName[$iHealer] = "Heal"
$UnitShortName[$iDragon] = "Drag"
$UnitShortName[$iPekka] = "Pekk"
$UnitShortName[$iMinion] = "Mini"
$UnitShortName[$iHogRider] = "Hogs"
$UnitShortName[$iValkyrie] = "Valk"
$UnitShortName[$iGolem] = "Gole"
$UnitShortName[$iWitch] = "Witc"
$UnitShortName[$iLavaHound] = "Lava"


; Conversions with bot structure

; real unit name from bot short name
Func getRealName($shortName)
	For $i = 0 to UBound($UnitShortName) - 1
		If $UnitShortName[$i] == $shortName Then Return $UnitName[$i]
	Next
EndFunc

; translate from my enum to the bot troop index

Func getBotIndex($iUnit)
	For $i = 0 To UBound($TroopName)-1
		If $TroopName[$i] == $UnitShortName[$iUnit] Then Return $i
	Next
	For $i = 0 To UBound($TroopDarkName)-1
		If $TroopDarkName[$i] == $UnitShortName[$iUnit] Then Return $i
	Next
EndFunc

; Utility

Func ZeroArray(ByRef $array)
	For $i = 0 To UBound($array) - 1
		$array[$i] = 0
	Next
EndFunc

;ConsoleWrite($iGolem)

Func goHome($maxDelay = 5000)
	ClickP($aAway, 2, $iDelayTrain5, "#0501"); Click away twice with 250ms delay
	If WaitforPixel(28, 505, 30, 507, Hex(0xE4A438, 6), 5, $maxDelay/500) Then
		If _Sleep(500) Then Return
		Return True
	EndIf
	Return False
EndFunc

Func clearTroops()
	Local $icount = 0

	If _ColorCheck(_GetPixelColor(187, 212, True), Hex(0xD30005, 6), 10) Then ; check if the existe more then 6 slots troops on train bar
		While Not _ColorCheck(_GetPixelColor(573, 212, True), Hex(0xD80001, 6), 10) ; while until appears the Red icon to delete troops
			_PostMessage_ClickDrag(550, 240, 170, 240, "left", 1000)
			$icount += 1
			If _Sleep($iDelayTrain1) Then Return
			If $icount = 7 Then ExitLoop
		WEnd
	EndIf

	If _Sleep($iDelayTrain1) Then Return
	
	_CaptureRegion()

	$icount = 0
	SetLog("Yet another")
	While Not _ColorCheck(_GetPixelColor(593, 200 + $midOffsetY, True), Hex(0xD0D0C0, 6), 20) ; while not disappears  green arrow
		SetLog("Yet here")
		If Not (IsTrainPage()) Then Return ;exit if no train page
		Click(568, 177 + $midOffsetY, 10, 0, "#0284") ; Remove Troops in training
		$icount += 1
		If $icount = 100 Then ExitLoop
	WEnd
EndFunc

; this relies on you being on the army overview
Func goToBarracks($targetBarracks)
	; SetLog("goToBarracks(" & $targetBarracks & ")")
	Local $currentBarracks = -1
	While $currentBarracks < 6
		_TrainMoveBtn(+1) ;click Next button
		If _Sleep($iDelayTrain2) Then Return
		$currentBarracks += 1
		If $currentBarracks == $targetBarracks Then Return True
	WEnd
	Return False
EndFunc

; UI variables

Global $rtTankPerc
Global $rtMeleePerc
Global $rtRangedPerc
Global $rtResourcePerc

Global $rtGoldMax
Global $rtGoldRes
Global $rtElixirMax
Global $rtElixirRes
Global $rtDarkMax
Global $rtDarkRes

Global $rtBarracksLevel[6]

Global $SentRequestCC = False

; this requires that your profiles are the same number as your accounts in play
Global $currentAccount = 1
Global $accountSwitchTimer = TimerInit()
Global $accountSwitchTimeout = 0
Global $rtAccountSwitch
Global $rtAccountList[5]

Func loadAccount($accountNum)
	SetLog("Loading account: " & $accountNum)
	goHome()
	Click(820, 590) ; settings button
	; check pixel for b4de50 at 476 415
	If WaitforPixel(476, 415, 477, 416, Hex(0xffffff, 6), 5, 2) Then ; White in connected button font
		Click(476, 415)
		_Sleep(500)
	Else
		SetLog("Failed to find connected button, it's ok maybe we're not connected. Try the disconnect button.")
		SetLog(_GetPixelColor(476, 415, True))
	EndIf
	; wait for ffffff at 500 415
	If WaitforPixel(500, 415, 501, 416, Hex(0xffffff, 6), 5, 2) Then ; White in disconnected button font
		Click(500, 415)
		_Sleep(500)
	Else
		SetLog("Failed to find disconnected button aborting")
		SetLog(_GetPixelColor(500, 415, True))
		Return False
	EndIf

	;wait for 689f38 at 460 230
	If WaitForPixel(460, 230, 461, 231, Hex(0x689f38, 6), 5, 30) Then ; green in header of profile picker
		;click account number at 175 x 290+num*50 (num = 0-n)
		SetLog("Selecting account " & $accountNum)
		Click(175, 290+($accountNum*50))
		_Sleep(500)
	Else
		SetLog("Failed to find account screen, this isn't great.")
		SetLog(_GetPixelColor(460,230, True))
		Return False
	EndIf

	Click(575, 530) ; ok button
	_Sleep(500)

	;Wait for 284807 at 534 437
	If WaitForPixel(403, 409, 404, 410, Hex(0xf0bc68, 6), 5, 20) Then ; orange in cancel button
		Click(534, 437) ; click load
		_Sleep(500)
	Else
		SetLog("Couldn't find cancel button.")
		SetLog(_GetPixelColor(534, 437, True))

		SetLog("Checking if we're connected still connected")
		If WaitforPixel(476, 415, 477, 416, Hex(0xffffff, 6), 5, 2) Then ; White in connected button font
			SetLog("I think we're already connected to the account we were asking for.")
			_GUICtrlComboBox_SetCurSel($cmbProfile, $accountNum)
			cmbProfile()
			Return True
		EndIf
		SetLog("Abort. Unknown state.")
		Return False
	EndIf
	
	; Wait for cbcbcb at 586 178
	If WaitForPixel(586, 178, 587, 179, Hex(0xcbcbcb, 6), 5, 2) Then ; gray in confirm button
		_Sleep(500)
		Click(300, 200) ; text box
		_Sleep(500)
	Else
		SetLog("Couldn't find confirm screen")
		SetLog(_GetPixelColor(586, 178, True))
		Return False
	EndIf

	ControlSend($Title, "", "", "{LSHIFT DOWN}{C DOWN}{C UP}{O DOWN}{O UP}{N DOWN}{N UP}{F DOWN}{F UP}{I DOWN}{I UP}{R DOWN}{R UP}{M DOWN}{M UP}{LSHIFT UP}")  ;Enter  Confirm  txt
	Click(586, 178) ; Confirm load


	_GUICtrlComboBox_SetCurSel($cmbProfile, $accountNum)
	cmbProfile()

	$currentAccount = $accountNum
	Initiate()
EndFunc

Func runTest()

	loadAccount(1)

	; If WaitforPixel(476, 415, 477, 416, Hex(0xffffff, 6), 5) Then ; White in connected button font
	; 	ControlSend($Title, "", "", "{ESC}")
	; Else
	; 	SetLog("Failed to find connected button")
	; 	SetLog(_GetPixelColor(476, 415, True))
	; EndIf


EndFunc


Global $gLogFileHandle = ""
Func CreateGlobalLogFile()
    Local $sLogFName = @YEAR & "-" & @MON & "-" & @MDAY & "_" & @HOUR & "." & @MIN & "." & @SEC & ".log"
	Local $sLogPath = @ScriptDir & "\Logs\"
	DirCreate($sLogPath)
	$gLogFileHandle = FileOpen($sLogPath & $sLogFName, $FO_APPEND)
EndFunc


Func StringJoin($array, $delim=",")
	If UBound($array) == 0 Then Return ""
	If UBound($array) == 1 Then Return $array[0]
	$str = $array[0]
	For $i = 1 To UBound($array)-1
		$str &= "," & $array[$i]
	Next
	Return $str
EndFunc

Global Enum $eGold, $eElixir, $eDark
Func getRich($resource, $softCap=.75)
	Switch $resource
		Case $eGold
			Return (($iGoldCurrent/$rtGoldMax) - $softCap) / (1-$softCap)
		Case $eElixir
			Return (($iElixirCurrent/$rtElixirMax) - $softCap) / (1-$softCap)
		Case $eDark
			Return (($iDarkCurrent/$rtDarkMax) - $softCap) / (1-$softCap)
	EndSwitch
EndFunc


Func checkSwitchAccount()
	Local $minTrainTime = 300 ; Don't switch accounts for long training if this is all I have left
	If $rtAccountSwitch Then
		SetLog("Checking account switch.")

		Local $canSwitch = False
		If $CommandStop == 3 Then
			$canSwitch = True
			SetLog("In halt mode and full army.")
		ElseIf $SentRequestCC Then
			$canSwitch = True
			SetLog("Just sent request for cc.")
		ElseIf $ArmyTrainTime > $minTrainTime And _  ; I can't get an attack in in under 10 mins probably so no point in switching
		   $fullarmy <> True And _
		   TimerDiff($accountSwitchTimer) > $accountSwitchTimeout _
		Then
			SetLog("I have " & Round($ArmyTrainTime/60) & " mins left in training and I'm not ready for attack.")
			$canSwitch = True
		EndIf
		SetLog("Can swap in " & Round(($accountSwitchTimeout - TimerDiff($accountSwitchTimer))/60/1000) & " mins")
		If $canSwitch Then
			$accountSwitchTimer = TimerInit()
			$accountSwitchTimeout = ($ArmyTrainTime / 2)*1000 ; Don't come back until I'm half way done training. I'm thinking this will keep me balanced between accounts.
			SetLog("Can come back in " & Round($ArmyTrainTime / 2 / 60) & " mins")
			; assume matching accounts. I'll put UI on this to do it better.
			$currentAccount = Number($sCurrProfile)-1
			If $currentAccount == 0 Then
				loadAccount(1)
			Else
				loadAccount(0)
			EndIf
		EndIf
	EndIf
EndFunc
