﻿#Requires AutoHotkey v2.0

#Include Adb.ahk

StartAnnihilation() {
  Adb.ClickImage(['start-annihilation-1'], [1040, 640, 200, 40])
  Adb.ClickImage(['start-annihilation-2'], [1040, 640, 200, 40])
}

StartStage() {
  Adb.ClickImage(["start-1a", "start-1b", "start-1c"], [1040, 640, 200, 40])
  Adb.ClickImage(["start-2a", "start-2b"], [1035, 370, 135, 280])
}

WaitUntilOperationComplete() {
  static OPERATION_COMPLETE_REGION := [60, 175, 220, 80]

  Adb.OCR_Click(OPERATION_COMPLETE_REGION, "OPERATION COMPLETE",
    , 3000 ; add delay to wait for the dialoge to finish
  )
}

RepeatAnnihilation() {
  loop 5 {
    StartAnnihilation()
    WaitUntilOperationComplete()
  }
}

RepeatStage() {
  prompt := InputBox(, "RepeatStage", "w150 h75")
  if prompt.Result != "OK"
    return

  LoopStage(n) {
    loop n {
      StartStage()
      WaitUntilOperationComplete()
    }
  }

  if prompt.Value == ""
    LoopStage(GetCurrentSanity() // GetStageCost())
  else if IsNumber(prompt.Value)
    LoopStage(Number(prompt.Value))
}

GetCurrentSanity() {
  static SANITY_REGION := [1130, 20, 110, 40]

  sanity_and_max_sanity := Adb.OCR(SANITY_REGION, 2.5)
  sanity := StrSplit(sanity_and_max_sanity, "/")[1]
  return Number(sanity)
}

GetStageCost() {
  static STAGE_COST_REGION := [1185, 690, 45, 25]

  stage_cost := -Number(Adb.OCR(STAGE_COST_REGION, 2.5))
  return stage_cost
}
