# PicoCalc_PCC
PicoCalc Commander (PCC) is a dual-pane file manager and launcher for PicoCalc written in MMBasic

Based on an improved version of menu.bas from https://github.com/huntergdavis/picocalc

## Requirements

PCC requires MMBasic for PicoCalc version 6.00.02 or later

## Description

pcc.bas - PicoCalc Commander allows you to browse the SD Card and built-in flash drive of the Picocalc, and has the following features:

* Dual-pane browsing
* Select A: or B: drive
* Copy, move, delete files (one at a time)
* Will check for free space before moving or copying
* Will warn when overwriting
* Rename files
* Create directories
* Color-coded files: files with a color code can be launched or viewed (grey files cannot):
  * Text files (white) can be viewed
  * BASIC files (salmon) can be launched
  * WAV files (blue) can be played
  * JPEG and BMP pictures (cyan) can be viewed
  * Directories (green) can be opened
* When re-starting PCC after having launched a BASIC program from it, or after quitting PCC using "Q", it will remember its last state (the directories and file selections in its panes) - this function is based on LOAD CONTEXT, and uses 159KB on A: drive
* Toggle file info on the status line (displays size, modified date, and free space available on the selected drive)

## Usage

* Launch with: run "pcc" 
* It is recommended to configure a function key for easier launching, for example to use F6 here is the configuration line (provided you copied pcc.bas to the A: drive):
  * OPTION F6 "*"+chr$(34)+"a:pcc"+chr$(34)+chr$(13)
* There is a help function built-in (press H) that lists all the functions
* Usable keys are as follows:
  * **left, right arrows, tab:** select pane
  * **up, down arrows:** select file or directory
  * **A, B:** select A: or B: drive
  * **Enter:** open directory, launch or view file
  * **Esc, backspace:** parent directory
  * **C:** Copy file
  * **M:** Move file (implemented as copy and delete)
  * **D:** Delete file or directory (if empty)
  * **K:** create directory
  * **R:** rename file
  * **I:** toggle file info line
  * **Q:** quit
  * **H:** help

## Bugs, limitations

* PCC is limited to 100 files per directory, and 32 nested directories total.
* Only one file can be copied, moved or deleted at a time (no select function)
* Directories cannot be moved or copied, and can only be deleted when empty
* Sometimes, the first time PCC checks for the available free space on a drive (when using file info function, or when PCC checks for free space before copying or moving) it can take a really long time (10 seconds or so) and the program will be unresponsive. I am trying to figure out why that is.

## Picture

<img width="630" height="995" alt="Screenshot 2025-09-10 130452" src="https://github.com/user-attachments/assets/3ee667bd-1ecc-4242-bbea-87edbe3f3d45" />

  
