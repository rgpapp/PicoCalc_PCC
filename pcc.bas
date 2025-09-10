'---------------------------------------
' PicoCalc Commander: File Manager and
' Launcher for PicoCalc in MMBasic.
' Supports up to 100 items per directory
' with 22 lines visible, and 2 panes.
' Maximum directory depth is 32.
' Navigation is via up/down, left/right
' arrows and tab (to change panes).
' ENTER (asc=13) views or runs the
' highlighted file (depending on its
' file type). Q quits, A/B selects
' A: or B: drive and navigates to the
' root folder. Additional functions
' are displayed at the bottom, H invokes
' a small help screen.
'---------------------------------------
' version 1.03, 2025-sep-10
'---------------------------------------

Option explicit
On error ignore 1
If MM.VER < 6.0002 Then Error
If MM.Errno <> 0 Then
  Print "PCC needs firmware version 6.00.02 or greater."
  End
End If

'---------------------------------------
' Global variables

Const maxVisible = 21
Const maxItems = 100
Const maxDepth = 32

Dim integer curPane = 0
Dim integer altPane = 1
Dim integer paneLen(1)
Dim integer previSel(1,maxDepth)
Dim integer previOffset(1,maxDepth)
Dim string  file$(maxItems)
Dim string  fileType$(maxItems)
Dim string  curPath$(1)
Dim string  curDrive$(1)
Dim integer curDepth(1)
Dim integer totalItems = 0
Dim integer sel = 1
Dim integer offset = 1
Dim integer i, idx, invert, feasible, info = 0
Dim string  message$, inputString$, k$ = "", op$
' Dim string  q$ = Chr$(34)
Dim float l

paneLen(0) = 20     : paneLen(1) = 19
curPath$(0) = "/"   : curPath$(1) = "/"
curDrive$(0) = "B:" : curDrive$(1) = "A:"
curDepth(0) = 0     : curDepth(1) = 0
previSel(0,0) = 1   : previSel(1,0) = 1
previOffset(0,0)= 1 : previOffset(1,0) = 1


'---------------------------------------
' If last exit was due to launching a
' BASIC program, then reload saved state
' to continue where we left off

If MM.PERSISTENT = 1 Then
  On error ignore 1
  Load context
  Save persistent 0
End If

'---------------------------------------
' Initial display of default panes

DrawFrame

'---------------------------------------
' Main loop: gets input and selection

Do

  GetKey

  Select Case k$
    Case "A", "B" ' select drive
      curDrive$(curPane) = UCase$(k$)+":"
      curPath$(curPane) = "/"
      sel = 1 : offset = 1
      curDepth(curPane) = 0
      LoadDir curDrive$(curPane), curPath$(curPane)
    Case Chr$(27), Chr$(8) ' dir up
      If curPath(curPane) <> "/" Then
        DirSelect ".."
        LoadDir curDrive$(curPane), curPath$(curPane)
      End If
    Case "C", "M" ' copy, move
      If fileType$(sel)="D" Then
        message$ = "Directories cannot be    copied or moved."
        Dialog message$, "OK", RGB(white)
      Else If curDrive$(curPane)+curPath$(curPane)=curDrive$(altPane)+curPath$(altPane) Then
        message$ = "Cannot copy/move file to itself."
        Dialog message$, "OK", RGB(red)
      Else
        feasible = TestFeasible(file$(sel), curDrive$(altPane), curPath$(altPane))
        If k$="C" Then op$="copy" Else op$="move"
        Select Case feasible
        Case 0, 1
          message$ = "Do you want to "+Choice(feasible, "overwrite:", op$+":     ")
          message$ = message$+Chr$(34)+file$(sel)+Chr$(34)+Choice(feasible," on ", " to ")
          message$ = message$+Chr$(34)+curDrive$(altPane)+curPath$(altPane)+Chr$(34)+"?"
          Dialog message$, "YN", Choice(feasible,RGB(yellow),RGB(cyan))
          If k$="Y" Then
            If op$="copy" Then
              Progress "COPYING...",Choice(feasible,RGB(yellow),RGB(cyan))
              Copy file$(sel) To curDrive$(altPane)+curPath$(altpane)+file$(sel)
            Else If op$="move" Then
              Progress "MOVING...",Choice(feasible,RGB(yellow),RGB(cyan))
              On error ignore 1
              Copy file$(sel) To curDrive$(altPane)+curPath$(altpane)+file$(sel)
              If MM.Errno <> 0 Then
                DrawFrame
                message$ = "There was an errorwith   copying. Will not delete.(Moving is copy+delete.)"
                Dialog message$, "OK", RGB(red)
              Else
                Kill file$(sel)
              End If
            End If
           End If
        Case 2
          message$ = "There is not enough free space on the destination drive. "
          message$ = message$ + "(Moving is copy+  delete, free space is    needed.)"
          Dialog message$, "OK", RGB(red)
        End Select
      End If
      DrawFrame
    Case "D" ' delete
      message$ = "Do you want to delete:   "
      message$ = message$+Chr$(34)+file$(sel)+Chr$(34)+"?"
      Dialog message$, "YN",RGB(red)
      If k$ = "Y" Then
        Progress "DELETING...", RGB(red)
        If fileType$(sel)="D" Then
          If file$(sel)<>".." Then
            On error ignore 1
            Rmdir file$(sel)
            If MM.Errno <> 0 Then
              DrawFrame
              message$ = "Cannot delete directory. It is probably not empty."
              Dialog message$, "OK", RGB(red)
            End If
          Else
            DrawFrame
            message$=Chr$(34)+".."+Chr$(34)+" cannot be deleted."
            Dialog message$, "OK", RGB(white)
          End If
        Else
          Kill file$(sel)
        End If
      End If
      DrawFrame
    Case "K" ' mkdir
      message$ = "Type the name of the     directory to create:     "
      message$ = message$+"(leave blank to exit)"
      Dialog message$, "INPUT",RGB(cyan)
      If inputString$<>"" Then
        feasible = TestFeasible(inputString$, curDrive$(curPane), curPath$(curPane))
        If feasible = 1 Then
          message$="A file/directory named   " + Chr$(34) + inputString$ + Chr$(34) +" already exists."
          Dialog message$, "OK", RGB(red)
        Else
          Progress "CREATING...", RGB(cyan)
          Mkdir inputString$
        End If
      End If
      DrawFrame
    Case "R"
      If fileType$(sel)="D" Then
        message$ = "Directories cannot be    renamed."
        Dialog message$, "OK", RGB(white)
      Else
        message$ = "Rename "+Chr$(34)+file$(sel)+Chr$(34)+" to:"
        Dialog message$, "INPUT",RGB(cyan)
        If inputString$<>"" Then
          feasible = TestFeasible(inputString$, curDrive$(curPane), curPath$(curPane))
          If feasible = 1 Then
            message$="A file or directory with the name " + inputString$ + " already exists."
            Dialog message$, "OK", RGB(red)
          Else
            Progress "RENAMING...", RGB(cyan)
            Rename file$(sel) As inputString$
          End If
        End If
      End If
      DrawFrame
    Case "I"
      If info=0 Then
        info =1
      Else
        info = 0 : KeysDisp
      End If
    Case "H" ' help
      DisplayHelp
      DrawFrame
    Case Chr$(9), Chr$(130), Chr$(131)
      ' change pane (tab, left, right)
      DisplayList curPane, 1
      previSel(curPane, curDepth(curPane)) = sel
      previOffset(curPane, curDepth(curPane)) = offset
      sel = previSel(altPane, curDepth(altPane))
      offset = previOffset(altPane, curDepth(altPane))
      If curPane = 1 Then
        curPane = 0 : altPane = 1
      Else
        curPane = 1 : altPane = 0
      End If
      LoadDir curDrive$(curPane), curPath$(curPane)
    Case Chr$(13)  ' select (enter)
      ProcessItem
    Case Chr$(129) ' arrow down
      sel = sel + 1
      If sel > totalItems Then sel = 1
      If sel < offset Then offset = sel
      If sel > offset + maxVisible - 1 Then offset = sel - maxVisible + 1
    Case Chr$(128) ' arrow up
      sel = sel - 1
      If sel < 1 Then sel = totalItems
      If sel < offset Then offset = sel
      If sel > offset + maxVisible - 1 Then offset = sel - maxVisible + 1
    Case "Q" ' quit
      CLS
      Color RGB(green), 0
      Print curDrive$(curPane)+curPath$(curPane)
      Save persistent 1
      On error ignore 1
      Save context
      End
  End Select

  DisplayList curPane, 0
  If info=1 Then InfoDisp

Loop

'---------------------------------------
' Subs

Sub LoadDir(drive$ As string, path$ As string)

  ' Load current dir into an array

  Local d$
  Drive drive$
  Chdir path$
  totalItems = 0

  ' If Not at root, add a parent dir
  If path$ <> "/" Then
    totalItems = 1
    file$(totalItems) = ".."
    fileType$(totalItems) = "D"
  End If

  ' Load directories first:
  d$ = Dir$("*", DIR)
  Do While d$ <> ""
    totalItems = totalItems + 1
    If totalItems > maxItems Then Return
    file$(totalItems) = d$
    fileType$(totalItems) = "D"
    d$ = Dir$()
  Loop

  ' Load files:
  d$ = Dir$("*.*", FILE)
  Do While d$ <> ""
    totalItems = totalItems + 1
    If totalItems > maxItems Then Return
    file$(totalItems) = d$
    Select Case UCase$(Right$(d$,3))
      Case "BAS"
        fileType$(totalItems) = "B"
      Case "BMP"
        fileType$(totalItems) = "I"
      Case "JPG"
        fileType$(totalItems) = "J"
      Case "TXT", ".MD", "BAT"
        fileType$(totalItems) = "T"
      Case "WAV"
        fileType$(totalItems) = "W"
      Case Else
        fileType$(totalItems) = "M"
    End Select
    d$ = Dir$()
  Loop

End Sub

Sub DisplayList(pane As integer, isAlt As integer)

  Local dispPath$, dispLine$, fileName$
  Local i, dotPos, nameLen

  ' Display path
  ItemColor "H", 1
  dispPath$ = curDrive$(pane)+curPath$(pane)
  If Len(dispPath$) > 40 Then
    dispPath$ = Left$(dispPath$,39)+"~"
  Else
    dispPath$ = dispPath$+String$(40-Len(dispPath$)," ")
  End If
  Print @(0,4) dispPath$;

  ' Display directory list
  For i = 0 To maxVisible
    idx = offset + i
    If idx > totalItems Then Exit For
    invert = 0
    If idx = sel And isAlt = 0 Then invert = 1
    ItemColor fileType$(idx), invert
    fileName$ = file$(idx)
    nameLen = Len(fileName$)
    If fileType$(idx) = "D" Then ' dirs
      If nameLen > paneLen(pane)-4 Then
        dispLine$ = Left$(fileName$,paneLen(pane)-5)+"~ <d>"
      Else
        dispLine$ = fileName$+String$(paneLen(pane)-nameLen-3," ")+"<d>"
      End If
    Else 'file names
      dotPos = Instr(1,fileName$,"\.[^\.]*$",l)
      If dotPos = 1 Then
        fileName$=Right$(fileName$,nameLen-1)+".<h>"
        nameLen = Len(fileName$)
        dotPos = Instr(1,fileName$,"\.[^\.]*$",l)
      EndIf
      Select Case dotPos
        Case 0 ' no dot in the name
          If nameLen > paneLen(pane)-4 Then
            dispLine$ = Left$(fileName$,paneLen(pane)-4)+"~   "
          Else ' name not long
            dispLine$ = fileName$+String$(paneLen(pane)-nameLen," ")
          End If
        Case is > paneLen(pane)-3
          dispLine$ = Left$(fileName$,paneLen(pane)-5)+"~ "
          dispLine$ = dispLine$ + Right$(fileName$+"   ",nameLen-dotPos+3)
          dispLine$ = Left$(dispLine$,paneLen(pane))
        Case Else ' name before dot not long
          dispLine$ = Left$(fileName$,dotPos-1)+String$(paneLen(pane)-dotPos-2," ")
          dispLine$ = dispLine$ + Right$(fileName$+"   ",nameLen-dotPos+3)
          dispLine$ = Left$(dispLine$,paneLen(pane))
      End Select
    End If
    Print @(pane*168,i*12+24) dispLine$;
  Next i
  ClearPane pane, i
  ItemColor "M", 0

End Sub

Sub ProcessItem

  ' Process the highlighted item
  Select Case fileType$(sel)
    Case "D"
      DirSelect file$(sel)
      LoadDir curDrive$(curPane), curPath$(curPane)
    Case "B"
      CLS
      Save persistent 1
      On error ignore 1
      Save context
      Run file$(sel)
    Case "I"
      CLS
      Load image file$(sel)
      GetKey : DrawFrame
    Case "J"
      CLS
      Load jpg file$(sel)
      GetKey : DrawFrame
    Case "T"
      CLS
      ItemColor fileType$(sel), 0
      List file$(sel)
      GetKey : DrawFrame
    Case "W"
      Play wav file$(sel)
  End Select

End Sub

Sub DirSelect(d$ As string)

  If d$=".." Then
    curDepth(curPane) = curDepth(curPane)-1
    sel = previSel(curPane, curDepth(curPane))
    offset = previOffset(curPane, curDepth(curPane))
    curPath$(curPane)=Left$(curPath$(curPane),Instr(1,curPath$(curPane),"[^/]\+/$",l)-1)
  Else
    previSel(curPane, curDepth(curPane)) = sel
    previOffset(curPane, curDepth(curPane)) = offset
    curDepth(curPane) = curDepth(curPane)+1
    sel = 1 : offset = 1
    curPath$(curPane)=curPath$(curPane)+d$+"/"
  End If

  Chdir d$

End Sub

Sub GetKey

  Do : k$ = Inkey$
  Loop Until k$ <> ""
  k$=UCase$(k$)

End Sub

Sub ItemColor(c$ As string,i As integer)

  Local integer selCol

  Select Case c$
    Case "D" 'directory
      selCol = RGB(green)
    Case "B" 'basic program
      selCol = RGB(salmon)
    Case "M" 'misc items (non actionable)
      selCol = RGB(lightgrey)
    Case "H" 'header
      selCol = RGB(gold)
    Case "I", "P", "J" 'images
      selCol = RGB(cyan)
    Case "T" 'text file
      selCol = RGB(white)
    Case "W" 'wav file
      selCol = RGB(blue)
  End Select
  If i=1 Then
    Color 0, selCol
  Else
    Color selCol, 0
  End If

End Sub

Sub DrawFrame

  ' initialize screen and display
  ' the file lists in the panes,
  ' at program start, or when screen
  ' needs to be redrawn

  Local i, frColor = RGB(lightgrey)
  Local v$=Chr$(179)
  Local h1$=String$(20,196)
  Local h2$=String$(19,196)
  Local top$=h1$+Chr$(194)+h2$
  Local bot$=h1$+Chr$(193)+h2$

  CLS
  Color frColor, 0

  Print @(0,12) top$
  Print @(0,288) bot$
  For i=24 To 276 Step 12
    Print @(160,i) v$
  Next i
  If info = 0 Then KeysDisp Else InfoDisp

  Box 0,2,320,2,1,RGB(gold),RGB(gold)
  Box 0,16,320,2,1,RGB(gold),RGB(gold)

  LoadDir curDrive$(altPane), curPath$(altPane)
  previOffset(curPane, curDepth(curPane))=offset
  offset = previOffset(altPane, curDepth(altPane))
  DisplayList altPane, 1
  LoadDir curDrive$(curPane), curPath$(Curpane)
  offset = previOffset(curPane, curDepth(curPane))
  DisplayList curPane, 0

End Sub

Sub ClearPane(pane As integer, row As integer)

  Local i,p,spaces$
  p=pane*168
  spaces$=String$(paneLen(pane)," ")

  Color RGB(lightgrey), 0

  For i=row To maxVisible
    Print @(p,i*12+24) spaces$
  Next i

End Sub

Function TestFeasible(fileName$ As string, destDrive$ As string, destPath$ As string)

  Local integer fSize
  fSize = MM.Info(FILESIZE file$(sel))

  If destDrive$ <> "" Then
    Drive destDrive$
  End If
  If destPath$ <> "" Then
    Chdir destPath$
  End If

  If MM.Info(EXISTS FILE fileName$)<>0 Or MM.Info(EXISTS DIR fileName$) Then
    TestFeasible = 1
  Else If MM.Info(FREE SPACE) < fSize Then
    TestFeasible = 2
  Else
    TestFeasible = 0
  End If

  Drive curDrive$(curPane)
  Chdir curPath$(curPane)

End Function


Sub Dialog(dispText$ As string, choices$ As string, selCol As integer)

  Local i
  Play tone 900,900,70
  Color selCol, 0

  RBox  32,  72,  256,  120  , 10, RGB(lightgrey), 0
  If Len(dispText$)> 125 Then
    dispText = Left$(dispText$, 122)+"..."
  End If
  For i=1 To Fix(Len(dispText$)/25+0.96)
    Print @(60,80+i*12) Mid$(dispText$,(i-1)*24+i,25)
  Next i
  Color RGB(white), 0
  Select Case choices$
    Case "YN"
      Print @(132,72+(i+2)*12,2) "Y";
      Print "es/";
      Print @(132+36,72+(i+2)*12,2) "N";
      Print "o"
      Do : GetKey
      Loop Until k$="Y" Or k$="N"
    Case "OK"
      Print @(156,72+(i+2)*12,2) "OK"
      GetKey
    Case "INPUT"
      Print @(72,72+(i+2)*12,2);
      Input ""; inputString$
  End Select

End Sub

Sub Progress(dispText$ As string, selCol As integer)

  Color selCol, 0
  RBox  96,  180,  128,  24  , 10, selCol, selCol
  Print @(104,186,2) dispText$

End Sub

Sub DisplayHelp

  Color RGB(white), 0
  RBox  32,  60,  256,  202, 10, RGB(lightgrey), 0
  Print @(48,72) Chr$(149)+"/"+Chr$(148)+"/TAB:  select pane"
  Print @(48,84) Chr$(146)+"/"+Chr$(147)+":      select file/dir"
  Print @(48,96) "A/B:      select A:/B: drive"
  Print @(48,108) "Enter:    run/view file"
  Print @(48,120) "          open directory"
  Print @(48,132) "Esc/Back: parent directory"
  Print @(48,144) "C/M/D:    copy/move/delete"
  Print @(48,156) "K:        create directory"
  Print @(48,168) "R:        rename"
  Print @(48,180) "I:        toggle file info"
  Print @(48,192) "          display"
  Print @(48,204) "Q:        quit"
  Print @(48,216) "H:        this help"
  Print @(156,238,2) "OK"
  GetKey

End Sub

Function FormSize$(size As integer)

  Select Case size
    Case is >= 1.0e9
      FormSize$=Str$(Cint(size/1024^3))+"GB"
    Case is >= 1.0e6
      FormSize$=Str$(Cint(size/1024^2))+"MB"
    Case is >= 1.0e3
      FormSize$=Str$(Cint(size/1024))+"KB"
    Case Else
      FormSize$=Str$(Cint(size))+"B"
  End Select

End Function

Sub InfoDisp

  Color RGB(white), 0
  Print @(0,300) String$(40," ");
  If file$(sel) <> ".." Then
    Print @(0,300) Left$(MM.Info(modified file$(sel)),10);
  End If
  If fileType$(sel)<>"D" Then
    Print @(88,300) FormSize$(MM.Info(filesize file$(sel)));
  End If
  Color RGB(gold), 0
  Print @(168,300) curDrive$(curPane);
  Print @(192,300) FormSize$(MM.Info(free space))+" free/"+FormSize$(MM.Info(disk size));

End Sub

Sub KeysDisp

  Color RGB(lightgrey), 0
  Print @(0,300) String$(40," ");
  Print @(0,300,2) "A/B";
  Print @(80,300,2) "C";
  Print @(120,300,2) "M";
  Print @(160,300,2) "D";
  Print @(200,300,2) "K";
  Print @(240,300,2) "H";
  Print @(288,300,2) "Q";
  Print @(0,300,1) "   :drive  opy  ove  el m dir  elp   uit";

End Sub
