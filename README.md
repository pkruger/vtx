# vtx

Lua script for FrSky Taranis 9XD Plus for VTX channel selection

## Description
This script aids in finding suitable FPV channels when flying with other pilots.  The band and channel (frequency) used by each pilot is entered and the script will tell you which frequencies to avoid.  If a frequency that any pilot is using is highlighted, that pilot should change to another frequency to  avoid interference.  This script uses a deviation algorithm checking if any of the selected frequencies is within the deviation value (20MHz / 40MHz) of each other, i.e: 

      selected frequency + 20MHz   OR
      selected frequency - 20MHz


## Installation      
1. Put the script in the /Scripts/Telemetry folder of the SD card in your Taranis.
2. On the "Display" tab/menu of a model (after the Telemetry screen), choose a screen of Screen 1-4.  Press Enter and select script.  For script, select the name of this script from the list.
3. You can also run this script in the radio simulator in Open TX Companion.


## Usage
1. The script uses 2 pages, the first is a table of all the available frequencies.  The second page shows a different view of the bands and channels.
2. On the first page, press enter to active edit mode and to select the frequencies (band and channels) used by pilots.  (Use the + and - keys to navigate the table and enter to select a frequency.)  Selected frequencies will be highlighted.
3. Holding the Menu key on this page dislpays the Clear Pilots option which will clear all the chosen frequencies for pilots when enter is pressed.
4. Once all the frequencies used by pilots have been chosen, press the menu key to move to the second  page.  This page indicates the frequencies to be avoided by highlighting them (dark black background).


Happy flying, with company...!!!
