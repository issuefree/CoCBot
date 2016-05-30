; #FUNCTION# ====================================================================================================================
; Name ..........: CompareResources
; Description ...: Compaires Resources while searching for a village to attack
; Syntax ........: CompareResources()
; Parameters ....:
; Return values .: True if compaired resources match the search conditions, False if not
; Author ........: (2014)
; Modified ......: AtoZ, Hervidero (2015), kaganus (June 2015, August 2015)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2016
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......: VillageSearch, GetResources
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

Func CompareResources($pMode) ;Compares resources and returns true if conditions meet, otherwise returns false
	If $iChkSearchReduction = 1 Then
		If ($iChkEnableAfter[$pMode] = 0 And $SearchCount <> 0 And Mod($SearchCount, $ReduceCount) = 0) Or ($iChkEnableAfter[$pMode] = 1 And $SearchCount - $iEnableAfterCount[$pMode] > 0 And Mod($SearchCount - $iEnableAfterCount[$pMode], $ReduceCount) = 0) Then
			If $iAimGold[$pMode] - $ReduceGold >= 0 Then $iAimGold[$pMode] -= $ReduceGold
			If $iAimElixir[$pMode] - $ReduceElixir >= 0 Then $iAimElixir[$pMode] -= $ReduceElixir
			If $iAimDark[$pMode] - $ReduceDark >= 0 Then $iAimDark[$pMode] -= $ReduceDark
			If $iAimTrophy[$pMode] - $ReduceTrophy >= 0 Then $iAimTrophy[$pMode] -= $ReduceTrophy
			If $iAimGoldPlusElixir[$pMode] - $ReduceGoldPlusElixir >= 0 Then $iAimGoldPlusElixir[$pMode] -= $ReduceGoldPlusElixir

			If $iCmbMeetGE[$pMode] = 2 Then
				SetLog("Aim:           [G+E]:" & StringFormat("%7s", $iAimGoldPlusElixir[$pMode]) & " [D]:" & StringFormat("%5s", $iAimDark[$pMode]) & " [T]:" & StringFormat("%2s", $iAimTrophy[$pMode]) & $iAimTHtext[$pMode] & " for: " & $sModeText[$pMode], $COLOR_GREEN, "Lucida Console", 7.5)
			Else
				SetLog("Aim: [G]:" & StringFormat("%7s", $iAimGold[$pMode]) & " [E]:" & StringFormat("%7s", $iAimElixir[$pMode]) & " [D]:" & StringFormat("%5s", $iAimDark[$pMode]) & " [T]:" & StringFormat("%2s", $iAimTrophy[$pMode]) & $iAimTHtext[$pMode] & " for: " & $sModeText[$pMode], $COLOR_GREEN, "Lucida Console", 7.5)
			EndIf
		EndIf
	EndIf


	; For simplicity I'm using the max elixir/gold setting from the resource troop training.
	; I'm looking at some sort of falloff of threshold based on resources.
	; 	like mult the thresh by % of resource over 75% of your resource.
	;	At 75% you need 100% of your threshold.
	;	At 100% you need 0% of your threshold.
	; 	At 90% you need 60% of your threshold.

	Local $gThresh = Number($iAimGold[$pMode])
	Local $eThresh = Number($iAimElixir[$pMode])
	Local $dThresh = Number($iAimDark[$pMode])

	Local $gRich = getRich($eGold)
	Local $eRich = getRich($eElixir)
	Local $dRich = getRich($eDark)

	Local $showThresh = False
	If $gRich > 0 Then
		$gThresh = Floor($gThresh * (1 - $gRich))
		$showThresh = True
	EndIf
	If $eRich > 0 Then
		$eThresh = Floor($eThresh * (1 - $eRich))
		$showThresh = True
	EndIf
	If $dRich > 0 Then
		$dThresh = Floor($dThresh * (1 - $dRich))
		$showThresh = True
	EndIf

	If $showThresh And ($iCmbMeetGE[$pMode] == 0 Or $iCmbMeetGE[$pMode] == 1) Then
		SetLog("      [G]:  " & $gThresh & " [E]:  " & $eThresh & " [D]:  " & $dThresh)
	EndIf

	Local $G = (Number($searchGold) >= $gThresh)
	Local $E = (Number($searchElixir) >= $eThresh)
	Local $D = (Number($searchDark) >= $dThresh)

	Local $T = (Number($searchTrophy) >= Number($iAimTrophy[$pMode]))
	Local $GPE = ((Number($searchGold) + Number($searchElixir)) >= Number($iAimGoldPlusElixir[$pMode]))






	If $iChkMeetOne[$pMode] = 1 Then
		;		If $iChkWeakBase[$pMode] = 1 Then
		;			If $bIsWeakBase Then Return True
		;		EndIf

		If $iCmbMeetGE[$pMode] = 0 Then
			If $G = True And $E = True Then Return True
		EndIf

		If $iChkMeetDE[$pMode] = 1 Then
			If $D = True Then Return True
		EndIf

		If $iChkMeetTrophy[$pMode] = 1 Then
			If $T = True Then Return True
		EndIf

		If $iCmbMeetGE[$pMode] = 1 Then
			If $G = True Or $E = True Then Return True
		EndIf



		If $iCmbMeetGE[$pMode] = 2 Then
			If $GPE = True Then Return True
		EndIf

		If $iCmbMeetGE[$pMode] == 3 Then ; need
			Local $resourceTarget = Number($iAimGoldPlusElixir[$pMode]) ; just for simplicity
			Local $deFactor = 50 ; value of dark elixir

			Local $baseValue = _
				Number($searchGold) * (1-$gRich) + _
				Number($searchElixir) * (1-$eRich) + _
				Number($searchDark) * $deFactor * (1-$dRich)

			SetLog("      Base value: " & Round($baseValue))

			If $baseValue >= $resourceTarget Then
				Return True
			EndIf
		EndIf

		Return False
	Else
		;		If $iChkWeakBase[$pMode] = 1 Then
		;			If Not $bIsWeakBase Then Return False
		;		EndIf

		If $iCmbMeetGE[$pMode] == 3 Then ; need
			Local $resourceTarget = Number($iAimGoldPlusElixir[$pMode]) ; just for simplicity
			Local $deFactor = 50 ; value of dark elixir

			Local $baseValue = _
				Number($searchGold) * (1-$gRich) + _
				Number($searchElixir) * (1-$eRich) + _
				Number($searchDark) * $deFactor * (1-$dRich)

			SetLog("      Base value: " & Round($baseValue))
			
			If $baseValue < $resourceTarget Then
				Return False
			EndIf
		EndIf

		If $iCmbMeetGE[$pMode] = 0 Then
			If $G = False Or $E = False Then Return False
		EndIf

		If $iChkMeetDE[$pMode] = 1 Then
			If $D = False Then Return False
		EndIf

		If $iChkMeetTrophy[$pMode] = 1 Then
			If $T = False Then Return False
		EndIf

		If $iCmbMeetGE[$pMode] = 1 Then
			If $G = False And $E = False Then Return False
		EndIf



		If $iCmbMeetGE[$pMode] = 2 Then
			If $GPE = False Then Return False
			;SetLog("[G + E]:" & StringFormat("%7s", $searchGold + $searchElixir), $COLOR_GREEN, "Lucida Console", 7.5)
		EndIf
	EndIf

	Return True
EndFunc   ;==>CompareResources

Func CompareTH($pMode)
	Local $THL = -1, $THLO = -1

	For $i = 0 To 5 ;add th11
		If $searchTH = $THText[$i] Then $THL = $i
	Next

	Switch $THLoc
		Case "In"
			$THLO = 0
		Case "Out"
			$THLO = 1
	EndSwitch
	$SearchTHLResult = 0
	If $THL > -1 And $THL <= $YourTH And $searchTH <> "-" Then $SearchTHLResult = 1
	If $iChkMeetOne[$pMode] = 1 Then
		If $iChkMeetTH[$pMode] = 1 Then
			If $THL <> -1 And $THL <= $iCmbTH[$pMode] Then Return True
		EndIf

		If $iChkMeetTHO[$pMode] = 1 Then
			If $THLO = 1 Then Return True
		EndIf
		Return False
	Else
		If $iChkMeetTH[$pMode] = 1 Then
			If $THL = -1 Or $THL > $iCmbTH[$pMode] Then Return False
		EndIf

		If $iChkMeetTHO[$pMode] = 1 Then
			If $THLO <> 1 Then Return False
		EndIf

	EndIf
	Return True
EndFunc