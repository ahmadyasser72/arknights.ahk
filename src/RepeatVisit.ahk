#Requires AutoHotkey v2.0

#Include Utilities.ahk

RepeatVisit() {
  idx := 1
  while idx < 10
    if ClickImage('visit-next', 1160, 620, 1360, 720)
      idx += 1
}