#Requires AutoHotkey v2.0
#SingleInstance Force
; Second clipboard that keeps formatting (Remote Desktop strips the normal one).
; Ctrl+Shift+C = copy into the formatted clipboard
; Ctrl+Shift+V = paste from the formatted clipboard
global Saved := ""

^+c:: {
    global Saved
    old := ClipboardAll()
    A_Clipboard := ""
    Send "^c"
    if ClipWait(2, 1) {
        Saved := ClipboardAll()
        ToolTip "Copied with formatting"
    } else
        ToolTip "Nothing copied"
    A_Clipboard := old
    SetTimer () => ToolTip(), -1000
}

^+v:: {
    global Saved
    if !IsObject(Saved) {
        ToolTip "Formatted clipboard is empty"
        SetTimer () => ToolTip(), -1000
        return
    }
    old := ClipboardAll()
    A_Clipboard := Saved
    Sleep 50
    Send "^v"
    Sleep 300
    A_Clipboard := old
}
