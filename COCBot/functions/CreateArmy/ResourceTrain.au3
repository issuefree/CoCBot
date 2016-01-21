Func ResourceTrain()
	; get a village report to store current resources before train into globals
	VillageReport(True, True)

	; in halt attack mode Make sure army reach 100% regardless of user Percentage of full army
	If ($CommandStop = 3 Or $CommandStop = 0) Then
		CheckOverviewFullArmy(True)
		If $fullarmy Then
			If $debugSetlog = 1 Then SetLog("FullArmy & TotalTrained = skip training", $COLOR_PURPLE)
			Return
		EndIf
	EndIf

	SetLog("Training Troops & Spells", $COLOR_BLUE)

	If goHome() == False Then Return
	If openArmyOverview() == False Then Return			

	checkAttackDisable($iTaBChkIdle) ; Check for Take-A-Break after opening train page
	checkArmyCamp()  ; sets up state variables for training 
	; I'll recheck troop counts after training counts to avoid gaps
	
	; Determine training
	; Note there WILL be errors in this caused by the detection not the algorithm due to troops finishing training mid process.

	; 1. Figure out what we have in training.
	; 2. Figure out what we've already trained.
	; 3. Figure out what is left to train for our desired comp.
	; 4. Assign troops to barracks.


	; 1. Figure out what we have in training.

Local $restartAfterTrain = False

SetLog("Currently in training:")
	Local $barracksTrainingTime[$numBarracksAvaiables + $numDarkBarracksAvaiables]
	Local $barracksTrainingSpace[$numBarracksAvaiables + $numDarkBarracksAvaiables]

	Local $barracksTrainingUnits[$numBarracksAvaiables + $numDarkBarracksAvaiables][$iArmyEnd]

	Local $barracksNumber = 0

	Local $blockedBarracks[$numBarracksAvaiables+$numDarkBarracksAvaiables]
	Local $numBlockedBarracks = 0

	If goHome() == False Then Return
	If openArmyOverview() == False Then Return	
	$debugSetlog = 1
SetLog("Debug: goToBarracks(0)")
	If goToBarracks(0) == False Then Return
SetLog("After goToBarracks(0)")
	$debugSetlog = 0

	ZeroArray($ArmyTraining)
	While isBarrack() Or isDarkBarrack()
		If $barracksNumber >= $numBarracksAvaiables + $numDarkBarracksAvaiables Then ExitLoop

		For $iUnit = 0 to $iArmyEnd-1
			Local $num = getNumTraining($iUnit, isDarkBarrack())
			$ArmyTraining[$iUnit] += $num
			$barracksTrainingTime[$barracksNumber] += $num*$UnitTime[$iUnit]
			$barracksTrainingSpace[$barracksNumber] += $num*$UnitSize[$iUnit]
			$barracksTrainingUnits[$barracksNumber][$iUnit] += $num
		Next

		$blockedBarracks[$barracksNumber] = CheckFullBarrack()
		If $blockedBarracks[$barracksNumber] Then
			$numBlockedBarracks += 1
		EndIf

		; SetLog("Barracks " & $barracksNumber & ":" & $barracksTrainingTime[$barracksNumber])

		$barracksNumber += 1
		; SetLog("Moving to barracks " & $barracksNumber+1 & "/" & $numBarracksAvaiables + $numDarkBarracksAvaiables)
		_TrainMoveBtn(+1) ;click Next button
		If _Sleep($iDelayTrain2) Then Return
	WEnd
	barracksReport($barracksTrainingUnits)

	; 1. Figure out what we've already trained.

SetLog("Currently trained:")
	goHome()
	ZeroArray($ArmyTrained) ; Zero out the in-training array before we check the camp.
	getArmyTroopCount(True)

SetLog("Check for deadlocks:")
	; check for deadlock.
	; A deadlock is when 1 or more barracks is blocked and all other barracks are not training.
	; this is not a very aggressive check and could waste some time but it'll probably do for now.

	If $numBlockedBarracks > 0 And $CurCamp <> $TotalCamp Then	
		If $numBlockedBarracks >= $numBarracksAvaiables Then ; Hard deadlock.
			SetLog("Hard deadlock")
			; Gotta stop training on something. Probably the barracks with the least training.
			Local $bestBarracks
			Local $bestBarracksTime = 9999
			SetLog("Finding best barracks to clean out")
			For $barracksNumber = 0 To $numBarracksAvaiables-1
				If $barracksTrainingTime[$barracksNumber] < $bestBarracksTime Then
					$bestBarracks = $barracksNumber
					$bestBarracksTime = $blockedTrainingTime
				EndIf
			Next
			; Stop training all troops in $bestBarracks

			If goHome() == False Then Return
			If openArmyOverview() == False Then Return			
			goToBarracks($bestBarracks)
			clearTroops()

			; ; Set capacity to what we need for a full army.
			; SetLog("Train " & $TotalCamp - $CurCamp & " Archers")
			; TrainIt($eArch, $TotalCamp - $CurCamp)
		Else ; Possible deadlock
			SetLog("Possible deadlock.")
			; maybe prevent training into the blocked barracks? seems unlikely.
			; I could remove the troops in blocked baracks from army consideration.
			; Then we'd build an army on the remaining barracks. This might get messy.
			; I have no elegant solutions. I propose we wait to until it resolves itslef or results in a full deadlock.
			; We'll handle it there.
		EndIf
	EndIf


	If _Sleep($iDelayTrain2) Then Return

	; 3. Figure out what is left to train for our desired comp.
	; Extra stuff will be in ArmyToTrain as a negative number as it's stuff that's trained or training that wasn't in my comp

	; Build what I was going to. It will build too much. Troop capacity will reach 200 with some leftover troops. Next pass through they'll either (likely since they'll probably be archers barbs or goblins) be absorbed into the proper composition or treated as "extras" but they're not "bad" since they're the tail end of a proper build.
	; I'll do this in the above loop.

SetLog("Get army composition:")
	; figure already trained troops and add the ones in training
	Local $currentArmy = $ArmyTraining	
	If $fullarmy <> True Then  ; If the army is full we're training our next army so don't consider the currently trained ones.
		For $i = 0 To $iArmyEnd-1
			$currentArmy[$i] += $ArmyTrained[$i]
		Next
	EndIf

	$ArmyToTrain = getArmyComposition($currentArmy)
	dumpArmy($ArmyToTrain, "Army to train:")

	; build final army
	$ArmyComposition = $ArmyToTrain
	For $i = 0 To $iArmyEnd-1
		$ArmyComposition[$i] += $currentArmy[$i]
	Next

	dumpArmy($ArmyComposition, "Final army:")

SetLog("Assign to barracks:")
	; 4. Assign troops to barracks.

	; How about I find the barracks with the lowest train time and put the highest train time unit into it. Repeat until I'm out of units.

	Local $needTraining = False
	Local $barracksTraining[$numBarracksAvaiables + $numDarkBarracksAvaiables][$iArmyEnd]

	While findLongestUnit($ArmyToTrain) >= 0
		Local $needTraining = True
		Local $longestUnit = findLongestUnit($ArmyToTrain)
		Local $lowBarracks = getShortestBarracks($longestUnit, $barracksTrainingTime)
		$barracksTrainingTime[$lowBarracks] += $UnitTime[$longestUnit]
		$barracksTraining[$lowBarracks][$longestUnit] += 1
		$ArmyToTrain[$longestUnit] -= 1
	WEnd

SetLog("Train troops:")

	If $needTraining == True Then
		barracksReport($barracksTraining)

		If goHome() == False Then Return
		If openArmyOverview() == False Then Return	
		goToBarracks(0)

		$barracksNumber = 0
		While isBarrack() Or isDarkBarrack()
			If $debugSetlog = 1 Then SetLog("====== Checking available Barrack: " & $barracksNumber & " ======", $COLOR_PURPLE)

			If Not (IsTrainPage()) Then Return
			If $barracksNumber >= $numBarracksAvaiables + $numDarkBarracksAvaiables Then ExitLoop

			For $iUnit In $UnitTrainOrder
				If $barracksTraining[$barracksNumber][$iUnit] > 0 Then
					TrainIt(Eval("e" & $UnitShortName[$iUnit]), $barracksTraining[$barracksNumber][$iUnit])
					If _Sleep($iDelayTrain1) Then ExitLoop
				EndIf
			Next

			$barracksNumber += 1
			; SetLog("Moving to barracks " & $barracksNumber+1 & "/" & $numBarracksAvaiables + $numDarkBarracksAvaiables)
			_TrainMoveBtn(+1) ;click Next button
			If _Sleep($iDelayTrain2) Then Return
		WEnd
	EndIf


	Local $maxTrainTime = 0
	For $barracksNumber = 0 To $numBarracksAvaiables + $numDarkBarracksAvaiables - 1
		If $barracksTrainingTime[$barracksNumber] > $maxTrainTime Then
			$maxTrainTime = $barracksTrainingTime[$barracksNumber]
		EndIf
	Next

	If $rtAccountSwitch == True Then
		SetLog("")
		SetLog("Checking account switch:")
		SetLog("  Train time: " & Round($maxTrainTime/60) & " mins")
		SetLog("  Can swap in " & Round(($accountSwitchTimeout - TimerDiff($accountSwitchTimer))/60/1000) & " mins")

		If $maxTrainTime > 600 And _  ; I can't get an attack in in under 10 mins probably so no point in switching
		   $fullarmy <> True And _
		   TimerDiff($accountSwitchTimer) > $accountSwitchTimeout _
		Then
			SetLog("I have " & Round($maxTrainTime/60) & " mins left in training and I'm not ready for attack.")
			SetLog("Swap accounts after train.")
			$accountSwitchTimer = TimerInit()
			$accountSwitchTimeout = ($maxTrainTime / 2)*1000 ; Don't come back until I'm half way done training. I'm thinking this will keep me balanced between accounts.
			SetLog("Can come back in " & Round($maxTrainTime / 60 / 2) & " mins")
			$restartAfterTrain = True
		EndIf
	EndIf
	
SetLog("End train")

	If _Sleep($iDelayTrain4) Then Return
	BrewSpells() ; Create Spells

	getTrainCosts()

	; assume matching accounts. I'll put UI on this to do it better.
	$currentAccount = Number($sCurrProfile)-1
	If $restartAfterTrain == True Then
		If $currentAccount == 0 Then
			loadAccount(1)
		Else
			loadAccount(0)
		EndIf
	EndIf

EndFunc

; this will figure out my target army based on 
Func getArmyComposition($currentArmy)
	Local $capacity = $TotalCamp
	; Resource based troop comp

	; dumpArmy($currentArmy, "Current army:")

	; army composition calculations

	Local $tankUnits[2] = [$iGolem, $iGiant]
	Local $meleeUnits[3] = [$iPekka, $iValkyrie, $iBarbarian]
	Local $rangedUnits[2] = [$iWizard, $iArcher]
	Local $resourceUnits[1] = [$iGoblin]

	; dark vs elixir units are in globals but for syntax similarity I'll reproduce here.
	; high value elixir units
	local $deUnits[2] = [$iGolem, $iValkyrie]
	Local $hvUnits[2] = [$iPekka, $iWizard]

	; by resource type then by size
	Local $unitEvalOrder[$iArmyEnd] = [ _
		$iGolem, _
		$iValkyrie, _
		$iPekka, _
		$iGiant, _
		$iWizard, _
		$iArcher, _
		$iBarbarian, _
		$iGoblin, _
		$iWallBreaker, _
		$iLavaHound, _
		$iWitch, _
		$iHogRider, _
		$iMinion, _
		$iDragon, _
		$iHealer, _
		$iBalloon _
	]


	; resource calculations

	Local $weightedElixir = (Number($iElixirCurrent) - $rtElixirRes) / ($rtElixirMax - $rtElixirRes)
	If $weightedElixir < 0 Then $weightedElixir = 0
	$weightedElixir = $weightedElixir*$weightedElixir
	Local $weightedDarkElixir = (Number($iDarkCurrent) - $rtDarkRes) / ($rtDarkMax - $rtDarkRes)
	If $weightedDarkElixir < 0 Then $weightedDarkElixir = 0
	$weightedDarkElixir = $weightedDarkElixir * $weightedDarkElixir

	; trying squaring the weights. This should let me spend when I'm capped but ease off SHARPLY as I approach my reserve.
	; ; Estimate of de value over elixir value. Started with 3. I'd like to use more DE troops so I set it to 2.	
	; ; Changing to 1. Maybe just let the reserve handle it.
	; Local $deValue = 1 
	; $weightedDarkElixir = $weightedDarkElixir / $deValue ; This is an estimate of relative dark elixir value 


	Local $base = $weightedElixir + $weightedDarkElixir
	If $base < 1 Then
		$base = 1
	EndIf
	Local $elixirRatio = $weightedElixir / $base
	Local $darkElixirRatio = $weightedDarkElixir / $base

	; this is hard coded. I could figure it based on my assigned categories...
	Local $tankRatio[2] = [0, $weightedDarkElixir]		; how much of each ratio to apply
	Local $meleeRatio[2] = [$elixirRatio, $darkElixirRatio]
	Local $rangedRatio[2] = [$weightedElixir,0]
	Local $resourceRatio[2] = [0, 0]

	SetLog("Resource allocation:")
	SetLog("  [E]: " & Round($weightedElixir*100) & "%  [DE]: " & Round($weightedDarkElixir*100) & "%    [E/DE]: " & Round($elixirRatio*100) & "/" & Round($darkElixirRatio*100))
	; SetLog("Elixir ratio = " & Floor($elixirRatio*100) & "%")

	; I need some buckets.
	; The big bucket is the army size. Everything needs to fit in the army size.
	; The second level is the troop types. The breakdown of how many tanks to how many ranged (etc) I'm going for.
	; The third level is the resource breakdown. How many expensive troops vs cheap or dark elixir troops.
	; 	This is where I don't have great answers. I'm using "expensive" vs "cheap" troops because that fits the buckets I've chosen for the troops that exist today. We'll proceed with this even though it's not a good generalized solution.

	; For a good distribution I want to honor resource ratios within types for the first pass then ignore them for the second pass. This means I need to track both the internal resource breakdown for a type as well as the overall breakdown.
	; actually I don't think I need to track internal resource buckets (just the initial calculation) since there's not more than one troop type for any sub bucket. I can merely assign the right number of units and then forget about it.

	; Desired number of troops of each type for the army
	Local $troopCount = $capacity
	SetLog("Capacity: " & $troopCount)

	Local $tankCount = Round($rtTankPerc/100 * $capacity) 	
	Local $meleeCount = Round($rtMeleePerc/100 * $capacity)
	Local $rangedCount = Round($rtRangedPerc/100 * $capacity)
	Local $resourceCount = Round($rtResourcePerc/100 * $capacity)

	Local $hvCount = Round($capacity*$elixirRatio)
	Local $deCount = Round($capacity*$darkElixirRatio)

	SetLog("Base counts: [T]: " & $tankCount & " [M]: " & $meleeCount & " [R]: " & $rangedCount & " [r]:" & $resourceCount)

	; reduce these by the number of each we already have in our army
	; we'll also track the total troopCount we need. These numbers won't line up as there
	; could be stuff in our current army not in any of these buckets.
	; I think this is ok. We know we have extra troops (one assumes for donation). If we attack before we get rid of them.
	; we'll use them and the extras will just be in our next army.
	; We just care if at the end there's leftover capacity we need to fill. We won't fill negative capacity
	; and we don't use the $troopCount for building before then, just the bucket counts.

	For $iUnit = 0 To $iArmyEnd-1
		If $currentArmy[$iUnit] > 0 Then
			If _ArraySearch($tankUnits, $iUnit) <> -1 Then
				$tankCount -= $currentArmy[$iUnit]*$UnitSize[$iUnit]				
			ElseIf _ArraySearch($meleeUnits, $iUnit) <> -1 Then
				$meleeCount -= $currentArmy[$iUnit]*$UnitSize[$iUnit]
			ElseIf _ArraySearch($rangedUnits, $iUnit) <> -1 Then
				$rangedCount -= $currentArmy[$iUnit]*$UnitSize[$iUnit]
			ElseIf _ArraySearch($resourceUnits, $iUnit) <> -1 Then
				$resourceCount -= $currentArmy[$iUnit]*$UnitSize[$iUnit]
			EndIf
			If _ArraySearch($deUnits, $iUnit) <> -1 Then
				$deCount -= $currentArmy[$iUnit]*$UnitSize[$iUnit]
			ElseIf _ArraySearch($hvUnits, $iUnit) <> -1 Then
				$hvCount -= $currentArmy[$iUnit]*$UnitSize[$iUnit]
			EndIf
			$troopCount -= $currentArmy[$iUnit]*$UnitSize[$iUnit]
		EndIf
	Next

	SetLog("Need counts: [T]: " & $tankCount & " [M]: " & $meleeCount & " [R]: " & $rangedCount & " [r]:" & $resourceCount)

	; at this point $tankCount + $meleeCount + $rangeCount + $resourceCount should equal $troopCount (including negatives as we'll balance those against the counts in a minute.)

	; get ready to figure what new troops we need for our army composition
	Local $newArmyComp[$iArmyEnd]
	ZeroArray($newArmyComp)

	If $troopCount <= 0 Then ; We're building too much already.	Return zeros.
		Return $newArmyComp
	EndIf

	Local $extraCount = 0
	If $tankCount < 0 Then 
		$extraCount -= $tankCount
		$tankCount = 0
	EndIf
	If $meleeCount < 0 Then 
		$extraCount -= $meleeCount
		$meleeCount = 0
	EndIf
	If $rangedCount < 0 Then 
		$extraCount -= $rangedCount
		$rangedCount = 0
	EndIf
	If $resourceCount < 0 Then 
		$extraCount -= $resourceCount
		$resourceCount = 0
	EndIf
	If $deCount < 0 Then $deCount = 0
	If $hvCount < 0 Then $hvCount = 0

	SetLog("Extra: " & $extraCount)

	Local $sum = $tankCount+$meleeCount+$rangedCount+$resourceCount

	$tankCount = Floor($tankCount - $extraCount*$tankCount/($sum))
	$meleeCount = Floor($meleeCount - $extraCount*$meleeCount/($sum))
	$rangedCount = Floor($rangedCount - $extraCount*$rangedCount/($sum))
	$resourceCount = Floor($resourceCount - $extraCount*$resourceCount/($sum))

	Local Enum $rHV, $rDE
	Local $tankCounts[2]
	$tankCounts[$rHV] = Floor($tankCount*$tankRatio[$rHV])
	$tankCounts[$rDE] = Floor($tankCount*$tankRatio[$rDE])
	Local $meleeCounts[3]
	$meleeCounts[$rHV] = Floor($meleeCount*$meleeRatio[$rHV])
	$meleeCounts[$rDE] = Floor($meleeCount*$meleeRatio[$rDE])
	Local $rangedCounts[3]
	$rangedCounts[$rHV] = Floor($rangedCount*$rangedRatio[$rHV])
	$rangedCounts[$rDE] = Floor($rangedCount*$rangedRatio[$rDE])
	Local $resourceCounts[3]
	$resourceCounts[$rHV] = Floor($resourceCount*$resourceRatio[$rHV])
	$resourceCounts[$rDE] = Floor($resourceCount*$resourceRatio[$rDE])

	SetLog("Capacity: " & $troopCount)
	SetLog("ToTrain counts: [T]: " & $tankCount & "(" & $tankCounts[$rHV] & "/" & $tankCounts[$rDE] & ")" & _
		                  " [M]: " & $meleeCount & "(" & $meleeCounts[$rHV] & "/" & $meleeCounts[$rDE] & ")" & _
		                  " [R]: " & $rangedCount & "(" & $rangedCounts[$rHV] & "/" & $rangedCounts[$rDE] & ")" & _
		                  " [r]: " & $resourceCount & "(" & $resourceCounts[$rHV] & "/" & $resourceCounts[$rDE] & ")")

	; I'm thinking 2 passes evaluating units in order
	; First pass: assign the base army
	;	"type" and "resource" the troop and there's room in that type/resource assign the right number
	;	Subtract the counts
	; Second pass: This is to deal with leftovers
	; 	Ignore the type and respect the resource only and assign more troops.
	; 	Subtract the counts

	; We go into our slot picking with a de and a hv ratio.
	; This ratio is applied to each slot to get a count. Assuming 40 space in the slot and full 



	For $iUnit In $unitEvalOrder
		If _ArraySearch($deUnits, $iUnit) <> -1 Then
			If _ArraySearch($tankUnits, $iUnit) <> -1 Then
				$newArmyComp[$iUnit] = Floor($tankCounts[$rDE]/$UnitSize[$iUnit])
				$tankCount -= $newArmyComp[$iUnit]*$UnitSize[$iUnit]
			ElseIf _ArraySearch($meleeUnits, $iUnit) <> -1 Then
				$newArmyComp[$iUnit] = Floor($meleeCounts[$rDE]/$UnitSize[$iUnit])
				$meleeCount -= $newArmyComp[$iUnit]*$UnitSize[$iUnit]
			ElseIf _ArraySearch($rangedUnits, $iUnit) <> -1 Then
				$newArmyComp[$iUnit] = Floor($rangedCounts[$rDE]/$UnitSize[$iUnit])
				$rangedCount -= $newArmyComp[$iUnit]*$UnitSize[$iUnit]
			ElseIf _ArraySearch($resourceUnits, $iUnit) <> -1 Then
				$newArmyComp[$iUnit] = Floor($resourceCounts[$rDE]/$UnitSize[$iUnit])
				$resourceCount -= $newArmyComp[$iUnit]*$UnitSize[$iUnit]
			EndIf
			$deCount -= $newArmyComp[$iUnit]*$UnitSize[$iUnit]
		ElseIf _ArraySearch($hvUnits, $iUnit) <> -1 Then
			If _ArraySearch($tankUnits, $iUnit) <> -1 Then
				$newArmyComp[$iUnit] = Floor($tankCounts[$rHV]/$UnitSize[$iUnit])
				$tankCount -= $newArmyComp[$iUnit]*$UnitSize[$iUnit]
			ElseIf _ArraySearch($meleeUnits, $iUnit) <> -1 Then
				$newArmyComp[$iUnit] = Floor($meleeCounts[$rHV]/$UnitSize[$iUnit])
				$meleeCount -= $newArmyComp[$iUnit]*$UnitSize[$iUnit]
			ElseIf _ArraySearch($rangedUnits, $iUnit) <> -1 Then
				$newArmyComp[$iUnit] = Floor($rangedCounts[$rHV]/$UnitSize[$iUnit])
				$rangedCount -= $newArmyComp[$iUnit]*$UnitSize[$iUnit]
			ElseIf _ArraySearch($resourceUnits, $iUnit) <> -1 Then
				$newArmyComp[$iUnit] = Floor($resourceCounts[$rHV]/$UnitSize[$iUnit])
				$resourceCount -= $newArmyComp[$iUnit]*$UnitSize[$iUnit]
			EndIf
			$hvCount -= $newArmyComp[$iUnit]*$UnitSize[$iUnit]
		Else
			If _ArraySearch($tankUnits, $iUnit) <> -1 Then
				$newArmyComp[$iUnit] = Floor($tankCount/$UnitSize[$iUnit])
				$tankCount -= $newArmyComp[$iUnit]*$UnitSize[$iUnit]
			ElseIf _ArraySearch($meleeUnits, $iUnit) <> -1 Then
				$newArmyComp[$iUnit] = Floor($meleeCount/$UnitSize[$iUnit])
				$meleeCount -= $newArmyComp[$iUnit]*$UnitSize[$iUnit]
			ElseIf _ArraySearch($rangedUnits, $iUnit) <> -1 Then
				$newArmyComp[$iUnit] = Floor($rangedCount/$UnitSize[$iUnit])
				$rangedCount -= $newArmyComp[$iUnit]*$UnitSize[$iUnit]
			ElseIf _ArraySearch($resourceUnits, $iUnit) <> -1 Then
				$newArmyComp[$iUnit] = Floor($resourceCount/$UnitSize[$iUnit])
				$resourceCount -= $newArmyComp[$iUnit]*$UnitSize[$iUnit]
			EndIf
		EndIf
		$troopCount -= $newArmyComp[$iUnit]*$UnitSize[$iUnit]
	Next

	SetLog("Remaining capacity: " & $troopCount)
	; I think the only scenario I would have leftovers is in the tank slot (with the current troops). Everything else should fill with 1 slot troops (barbs for melee, archers for ranged, goblins for resoruce.) If I decided I didn't want to use archers or something then this would be more common.
	SetLog("Leftovers: [T]: " & $tankCount & " [M]: " & $meleeCount & " [R]: " & $rangedCount & " [r]:" & $resourceCount)

	If $troopCount > 0 Then ; I've build my comp as best I can but I have some slots left over.
		For $iUnit In $unitEvalOrder
			If $deCount > $troopCount Then $deCount = $troopCount
			If $hvCount > $troopCount Then $hvCount = $troopCount
			Local $leftoverCount = 0
			If _ArraySearch($deUnits, $iUnit) <> -1 Then
				$leftoverCount = Floor($deCount/$UnitSize[$iUnit])
				$newArmyComp[$iUnit] += $leftoverCount
				$deCount -= $leftoverCount*$UnitSize[$iUnit]
			ElseIf _ArraySearch($hvUnits, $iUnit) <> -1 Then
				$leftoverCount = Floor($hvCount/$UnitSize[$iUnit])
				$newArmyComp[$iUnit] += $leftoverCount
				$hvCount -= $leftoverCount*$UnitSize[$iUnit]
			Else
				$leftoverCount = Floor($troopCount/$UnitSize[$iUnit])
				$newArmyComp[$iUnit] += $leftoverCount
			EndIf
			$troopCount -= $leftoverCount*$UnitSize[$iUnit]
		Next
	EndIf

	Return $newArmyComp
EndFunc



Func findLongestUnit($units)
	Local $max = 0, $maxi = -1

	For $i = 0 to $iArmyEnd-1
		If $units[$i] > 0 Then
			If $UnitTime[$i] > $max Then
				$max = $UnitTime[$i]
				$maxi = $i
			EndIf
		EndIf
	Next
	return $maxi
EndFunc

Func getNumTraining($iUnit, $darkBarracks = False)
	If $UnitIsDark[$iUnit] <> $darkBarracks Then Return 0

	Local $posArray = $TroopNamePosition
	If $darkBarracks Then
		$posArray = $TroopDarkNamePosition
	EndIf

	Local $i = getBotIndex($iUnit)
	$heightTroop = 296 + $midOffsetY
	$positionTroop = $posArray[$i]
	If $posArray[$i] > 4 Then
		$heightTroop = 403 + $midOffsetY
		$positionTroop = $posArray[$i] - 5
	EndIf

	Local $num = Number(getBarracksTroopQuantity(175 + 107 * $positionTroop, $heightTroop))			

	; There's a bug in the bot code resulting in reporting 222 healers being trained if the camp is full.
	; Since the max capacity of a barracks is 75 we'll consider any reports higher than that as a misread.
	; If they add support for larger barracks at some point this will have to be readdressed.
	If $num > 75 Then
		SetLog("Error reading " & $UnitName[$iUnit])
		$num = 0
	EndIf

	Return $num
EndFunc

Func getShortestBarracks($iUnit, $barracksTrainingTime)
	Local $bTime
	Local $offset = 0
	If $UnitIsDark[$iUnit] Then
		$bTime = _ArrayExtract($barracksTrainingTime, $numBarracksAvaiables, UBound($barracksTrainingTime)-1)
		$offset = $numBarracksAvaiables 
	Else
		$bTime = _ArrayExtract($barracksTrainingTime, 0, $numBarracksAvaiables-1)
	EndIf

	Return _ArrayMinIndex($bTime) + $offset
EndFunc

Func dumpArmy($unitArray, $heading = "Army:", $showSize = True)
	If $showSize Then
		$heading &= " " & getArmySize($unitArray)
	EndIf
	SetLog($heading)
	For $iUnit = 0 To $iArmyEnd-1
		If $unitArray[$iUnit] <> 0 Then
			SetLog($UnitName[$iUnit] & " : " & $unitArray[$iUnit])
		EndIf
	Next
EndFunc

Func getArmySize($army)
	Local $size = 0
	For $iUnit = 0 To $iArmyEnd-1
		$size += $army[$iUnit]*$UnitSize[$iUnit]
	Next
	Return $size
EndFunc

; $barracks - 2D array of barracks and the units in each.
Func barracksReport($barracks)
	Local $barracksSpace = 4
	Local $unitNameSpace = 13
	Local $line = _StringRepeat(" ", $unitNameSpace)
	For $barracksNumber = 0 To UBound($barracks)-1
		$line = $line & $barracksNumber & _StringRepeat(" ", $barracksSpace-StringLen($barracksNumber))
	Next
	SetLog($line, $COLOR_PURPLE, "Lucida Console")
	For $iUnit = 0 To $iArmyEnd-1
		Local $needLine
		$line = $UnitName[$iUnit] & _StringRepeat(" ", $unitNameSpace-StringLen($UnitName[$iUnit]))
		$needLine = False
		For $b = 0 To Ubound($barracks)-1
			If $barracks[$b][$iUnit] > 0 Then
				$line = $line & $barracks[$b][$iUnit] & _StringRepeat(" ", $barracksSpace-StringLen($barracks[$b][$iUnit]))
				$needLine = True
			Else
				$line = $line & _StringRepeat(" ", $barracksSpace)
			EndIf
		Next
		If $needLine Then
			SetLog($line, $COLOR_PURPLE, "Lucida Console")
		EndIf
	Next
EndFunc

Func getTrainCosts()
	; store off current resources before we recheck village
	Local $tempElixir = $iElixirCurrent
	Local $tempDElixir = $iDarkCurrent

	; copy pasta
	If _Sleep($iDelayTrain4) Then Return
	ClickP($aAway, 2, $iDelayTrain5, "#0504"); Click away twice with 250ms delay
	$FirstStart = False

	; Read Resource Values For army cost Stats
	Local $tempElixirSpent = 0
	Local $tempDElixirSpent = 0

	;;;;;; Protect Army cost stats from being messed up by DC and other errors ;;;;;;;
	If _Sleep($iDelayTrain4) Then Return
	VillageReport(True, True)

	If $tempElixir <> "" And $iElixirCurrent <> "" Then
		$tempElixirSpent = ($tempElixir - $iElixirCurrent)
		$iTrainCostElixir += $tempElixirSpent
		$iElixirTotal -= $tempElixirSpent
	EndIf

	If $tempDElixir <> "" And $iDarkCurrent <> "" Then
		$tempDElixirSpent = ($tempDElixir - $iDarkCurrent)
		$iTrainCostDElixir += $tempDElixirSpent
		$iDarkTotal -= $tempDElixirSpent
	EndIf

	UpdateStats()

EndFunc