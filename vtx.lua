--MIT License
--
--Copyright (c) 2017 Dana Sorensen
--
--Permission is hereby granted, free of charge, to any person obtaining a copy
--of this software and associated documentation files (the "Software"), to deal
--in the Software without restriction, including without limitation the rights
--to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--copies of the Software, and to permit persons to whom the Software is
--furnished to do so, subject to the following conditions:
--
--The above copyright notice and this permission notice shall be included in all
--copies or substantial portions of the Software.
--
--THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--SOFTWARE.

-- PURPOSE:
-- The purpose of this script is to aid in finding suitable FPV channels when flying 
-- with other pilots.  The band and channel (frequency) used by each pilot is entered
-- and the script will tell you which frequencies to avoid.  If a frequency that any 
-- pilot is using is highlighted, that pilot should change to another frequency to 
-- avoid interference.  This script uses a deviation algorithm checking if any of the
-- selected frequencies is within the deviation value (20MHz / 40MHz) of any of them
-- other selected frequencies, i.e:
--      selected frequency + 20MHz   OR
--      selected frequency - 20MHz

-- INSTALLATION:
-- 1. Put the script in the /Scripts/Telemetry folder of the SD card in your Taranis.
-- 2. On the "Display" tab/menu of a model (after the Telemetry screen), choose a 
--    screen of Screen 1-4.  Press Enter and select script.  For script, select the
--    name of this script from the list.
-- 3. You can also run this script in the radio simulator in Open TX Companion.

-- USAGE:
-- 1. The script uses 2 pages, the first is a table of all the available frequencies.
--    The second page shows a different view of the bands and channels.
-- 2. On the first page, press enter to select the frequencies (band and channels) 
--    used by pilots.  (Use the + and - keys to navigate the table.)  Selected frequencies
--    will be highlighted.
-- 3. Holding the Menu key on this page dislpays the Clear Pilots option which will 
--   clear all the chosen frequencies for pilots when enter is pressed.
-- 4. Once all the frequencies used by pilots have been chosen, press the menu key 
--    to move to the second  page.  This page indicates the frequencies to be avoided 
--    by highlighting them (dark black background).

-- Happy flying, with company...!!!

local DEBUG = 0
local current_screen = 1
local min_screen = 1
local max_screen
if DEBUG == 1 then
    max_screen = 3
else
    max_screen = 2
end    
    
local pageStatus =
{
    display     = 1,
    edit        = 2,
    displayMenu = 3
}

local current_state = pageStatus.display
local last_state = current_state

-- minimum and maximum FPV frequencies - default US/AU bands
local min_freq = 5645
local max_freq = 5945

local min_allowed = min_freq-1
local max_allowed = max_freq+1

local deviation = 20

-- minimum and maximum screen x-coordinates for position screen
local min_xpos = 11
local max_xpos = 201

local freq = {
    A = {"5865", "5845", "5825", "5805", "5785", "5765", "5745", "5725"},
    B = {"5733", "5752", "5771", "5790", "5809", "5828", "5847", "5866"},
    E = {"5705", "5685", "5665", "5645", "5885", "5905", "5925", "5945"},
    F = {"5740", "5760", "5780", "5800", "5820", "5840", "5860", "5880"},
    R = {"5658", "5695", "5732", "5769", "5806", "5843", "5880", "5917"}
}

local pos = {
    A = {},
    B = {},
    E = {},
    F = {},
    R = {}
}

local avoid_freq = {
    A = {},
    B = {},
    E = {},
    F = {},
    R = {}
}

local max_pilots = 8
local selected_freqs = {0, 0, 0, 0, 0, 0, 0, 0}
local selected_index = 1


    -- table coordinates
local xpos_freq = { 13, 38, 63, 88, 113, 138, 163, 188 }
local ypos_freq = { A = 12, B = 22, E = 32, F = 42, R = 52 }
local ypos_fff  = { 12, 22, 32, 42, 52 }

local x_index = 1
local y_index = 1
local select_x = xpos_freq[x_index]
local select_y = ypos_fff[y_index]
local cursor_freq = 0

local menuActive = 1
local menuMaxLine = 5
local menuMinLine = 1
MenuBox = { x=40, y=12, w=120, x_offset=36, h_line=8, h_offset=3 }
backgroundFill = backgroundFill or ERASE
foregroundColor = foregroundColor or SOLID
globalTextOptions = globalTextOptions or 0

-- initialize frequency positions (pos) for screen 2
local function init_func()
    local freq_range = max_freq - min_freq
    local pos_range = max_xpos - min_xpos

    -- populate postion arrays
    for band, freqs in pairs(freq) do
        for i=1,8 do
            pos[band][i] = (tonumber(freqs[i]) - min_freq) / freq_range * pos_range + min_xpos
         end
    end
end

-- clear the array of frequencies to avoid
local function clear_avoids()

    for band, freqs in pairs(freq) do
        for i=1,8 do
             avoid_freq[band][i] = 0            
        end
    end
end

-- returns if a frequency should be avoided
local function is_avoid(b, i)

    if avoid_freq[b][i] == 1 then
        return true
    else
        return false
    end    
end


-- find frequencies that should be avoided
local function get_avoid_freq(selectedFreq, selectedDeviation)
    local freq_check
    local freq_fil

   
    minFreq = selectedFreq - selectedDeviation
    maxFreq = selectedFreq + selectedDeviation

    -- find the frequencoes that should be avoided because they are within the deviation of the selected frequency
    for band, freqs in pairs(freq) do
        for i=1,8 do
            freq_check = tonumber(freqs[i])
            freq_fil = 0;
            if ((minFreq <= freq_check) and (freq_check < selectedFreq)) then
                freq_fil = 1
                avoid_freq[band][i] = freq_fil                
            end
            if ((maxFreq >= freq_check) and (freq_check >= selectedFreq)) then
                freq_fil = 1            
                avoid_freq[band][i] = freq_fil                
            end
        end
    end
end

-- returns if a frequency is legal
local function is_legal(freq)
    if max_allowed == nil or min_allowed == nil then
        return true
    else
        return tonumber(freq) > min_allowed and tonumber(freq) < max_allowed
    end
end

-- draw a channel number and border
local function draw_chan(chan, x, y, flags)
    -- draw number
    lcd.drawText(x+2, y+2, chan, SMLSIZE + flags)

    -- draw border
    lcd.drawLine(x,   y,   x+7, y,   SOLID, FORCE)
    lcd.drawLine(x,   y,   x,   y+9, SOLID, FORCE)
    lcd.drawLine(x+7, y,   x+7, y+9, SOLID, FORCE)
    lcd.drawLine(x,   y+9, x+7, y+9, SOLID, FORCE)

    -- clear other pixel(s) inside the border
    if flags ~= INVERS then
        lcd.drawLine(x+1, y+5, x+1, y+5, SOLID, ERASE)
    end
end

-- frequency screen
local function draw_freq_screen()

    lcd.clear()

    -- draw vertical dividers
    for i=9,209,25 do
        lcd.drawLine(i, 1, i, 59, SOLID, FORCE)
    end

    -- draw horizontal dividers
    for i=10,60,10 do
        lcd.drawLine(1, i, 209, i, SOLID, FORCE)
    end

    -- draw channel numbers
    for i=1,8 do
        lcd.drawText(xpos_freq[i]+7, 2, i)
    end

    -- draw band letters and frequencies
    local yyy = 0
    for band, freqs in pairs(freq) do
        -- draw band letter
        lcd.drawText(2, ypos_freq[band], band)
        yyy = yyy + 1
        -- draw frequencies
        for i=1,8 do
            if is_legal(freqs[i]) then
                local in_selected = 0
                for z=1,max_pilots do
                    if (selected_freqs[z] == tonumber(freqs[i])) then
                        in_selected = 1
                    end
                end                
                if ((select_x == xpos_freq[i]) and (select_y == ypos_freq[band]) and
                    (current_state == pageStatus.edit)) then
                    if in_selected == 0 then
                        lcd.drawText(xpos_freq[i], ypos_freq[band], freqs[i], BLINK)                
                    else
                        lcd.drawText(xpos_freq[i], ypos_freq[band], freqs[i], BLINK + INVERS)                                    
                    end 
                    cursor_freq = tonumber(freqs[i])
                else
                    if in_selected == 0 then
                        lcd.drawText(xpos_freq[i], ypos_freq[band], freqs[i])
                    else
                        lcd.drawText(xpos_freq[i], ypos_freq[band], freqs[i], INVERS)                    
                    end
                end
            else
                if ((select_x == xpos_freq[i]) and (select_y == ypos_freq[band]) and
                    (current_state == pageStatus.edit)) then
                    lcd.drawText(xpos_freq[i], ypos_freq[band], "----", BLINK+INVERS)                    
                else
                    -- fill out box
                    lcd.drawFilledRectangle(xpos_freq[i]-4, ypos_freq[band]-2, 26, 10, SOLID)                
                end
            end
        end
    end
end

-- position screen
local function draw_pos_screen()

    lcd.clear()

    -- band coordinates
    local ypos = { A = 3, B = 15, E = 27, F = 39, R = 51 }

    -- draw vertical divider
    lcd.drawLine(8, 3, 8, 60, SOLID, FORCE)

    -- draw horizontal dividers
    for i=8,56,12 do
        lcd.drawLine(9, i, 210, i, SOLID, FORCE)
    end
    
    -- draw band letters and channel boxes
    for band, freqs in pairs(freq) do
        -- draw band letter
        lcd.drawText(2, ypos[band]+2, band, SMLSIZE)
        -- draw channel boxes
        for i=1,8 do
            local flags = 0
            if not is_legal(freqs[i]) then
                flags = INVERS
            end
            draw_chan(i, pos[band][i], ypos[band], flags)
        end
    end
end

-- used frequency select screen
local function draw_use_freq_screen()

    lcd.clear()
    
    -- clear any previous values
    clear_avoids()

    for i=1,max_pilots do
        if selected_freqs[i] ~= 0 then
            get_avoid_freq(selected_freqs[i], deviation)
        end
    end
    
    -- band coordinates
    local ypos = { A = 3, B = 15, E = 27, F = 39, R = 51 }

    -- draw vertical divider
    lcd.drawLine(8, 3, 8, 60, SOLID, FORCE)

    -- draw horizontal dividers
    for i=8,56,12 do
        lcd.drawLine(9, i, 210, i, SOLID, FORCE)
    end

    -- draw band letters and channel boxes
    for band, freqs in pairs(freq) do
        -- draw band letter
        lcd.drawText(2, ypos[band]+2, band, SMLSIZE)
        -- draw channel boxes
        for i=1,8 do
            local flags = 0
            if not is_legal(freqs[i]) then
                flags = INVERS
            end
            if is_avoid(band, i) then 
                if freq_selected == tonumber(freqs[i]) then
                    flags = 0            
                else
                    flags = INVERS + BLINK                
                end
            end
            draw_chan(i, pos[band][i], ypos[band], flags)
        end
    end
end

-- input screen where user enters band and channel
local function draw_input_screen()
    
    lcd.clear()

    lcd.drawNumber(10, 10, LCD_W, 0)
    lcd.drawNumber(10, 20, LCD_H, 0)  
    
    lcd.drawNumber(30, 10, x_index, 0)      
    lcd.drawNumber(30, 20, y_index, 0)          

    lcd.drawNumber(50, 0,  selected_freqs[1], 0)    
    lcd.drawNumber(50, 10, selected_freqs[2], 0)
    lcd.drawNumber(50, 20, selected_freqs[3], 0)    
    lcd.drawNumber(50, 30, selected_freqs[4], 0)        

    lcd.drawNumber(80, 0,  selected_freqs[5], 0)    
    lcd.drawNumber(80, 10, selected_freqs[6], 0)
    lcd.drawNumber(80, 20, selected_freqs[7], 0)    
    lcd.drawNumber(80, 30, selected_freqs[8], 0)        

    if current_state == pageStatus.edit then
        lcd.drawText(10, 30, "EDIT", INVERS)
    else
        lcd.drawText(10, 30, "EDIT", 0)    
    end

    lcd.drawNumber(110,  0, min_allowed, 0)    
    lcd.drawNumber(110, 10, max_allowed, 0)        

    lcd.drawNumber(110, 20, min_freq, 0)    
    lcd.drawNumber(110, 30, max_freq, 0)        
   
end

local function clearPilots()
    clear_avoids()

    for i=1,max_pilots do
        selected_freqs[i] = 0
    end
    selected_index = 1
end

local function select20MHz()
    deviation = 20
end

local function select40MHz()
    deviation = 40
end

local function selectEUBands()
    min_allowed = 5725
    max_allowed = 5875
end

local function selectUSAUBands()
    min_allowed = min_freq-1
    max_allowed = max_freq+1
end

local menuList = {
    {
        t = "Clear Pilots",
        f = clearPilots
    },
    {
        t = "Deviation 20MHz",
        f = select20MHz
    },
    {
        t = "Deviation 40MHz",
        f = select40MHz
    },
    {
        t = "EU Bands",
        f = selectEUBands
    },
    {
        t = "US/AU Bands",
        f = selectUSAUBands
    }
}

local function drawMenu()
    local x = MenuBox.x
    local y = MenuBox.y
    local w = MenuBox.w
    local h_line = MenuBox.h_line
    local h_offset = MenuBox.h_offset
    local h = #(menuList) * h_line + h_offset*2

    lcd.drawFilledRectangle(x,y,w,h,backgroundFill)
    lcd.drawRectangle(x,y,w-1,h-1,foregroundColor)
    lcd.drawText(x+h_line/2,y+h_offset,"Menu:",globalTextOptions)

    for i,e in ipairs(menuList) do
        local text_options = globalTextOptions
        if menuActive == i then
            text_options = text_options + INVERS
        end
        lcd.drawText(x+MenuBox.x_offset,y+(i-1)*h_line+h_offset,e.t,text_options)
    end
end

local function set_state(state)
    last_state = current_state
    current_state = state
end    

local function run_func(event)
    
    -- handle keypresses
    -- menu key press
    if event == EVT_MENU_BREAK then
        if current_state ~= pageStatus.displayMenu then
            current_screen = current_screen + 1 
            if current_screen > max_screen then
                current_screen = min_screen
            end
        end
    end

    -- menu key hold
    if event == EVT_MENU_LONG then
        if current_screen == min_screen then        
            set_state(pageStatus.displayMenu)
            menuActive = 1
        end
    end
    
    -- enter key hold
    -- don't use - this is used to reset telemetry
    if event == EVT_ENTER_LONG then
        
    end
    
    -- enter key
    if event == EVT_ENTER_BREAK then
        if current_screen == min_screen then    
            if current_state ==  pageStatus.display then
                set_state(pageStatus.edit)
            elseif current_state == pageStatus.edit then
                if is_legal(cursor_freq) then
                    local already_selected = 0
                    for z=1,max_pilots do
                        if selected_freqs[z] == cursor_freq then
                            selected_freqs[z] = 0
                            already_selected = 1
                        end
                    end            
                    if already_selected == 0 then
                        selected_freqs[selected_index] = cursor_freq
                        if selected_index < max_pilots then
                            selected_index = selected_index + 1
                        end
                    end
                end
            elseif current_state == pageStatus.displayMenu then
                set_state(pageStatus.display)            
                menuList[menuActive].f()
            end
        end
    end
    
    -- exit key
    if event == EVT_EXIT_BREAK then
        if current_screen == min_screen then        
            set_state(pageStatus.display)                        
        elseif current_screen == max_screen then
            set_state(pageStatus.display)                    
        end
    end
    
    -- plus key
    if event == EVT_PLUS_BREAK then
        if current_screen == min_screen then
            if current_state == pageStatus.displayMenu then        
                menuActive = menuActive - 1
                if menuActive == (menuMinLine-1) then
                    menuActive = menuMaxLine
                end                
            else
                if x_index < 8 then
                    x_index = x_index + 1
                else
                    x_index = 1
                end
                select_x = xpos_freq[x_index]
                select_y = ypos_fff[y_index]
            end            
        end
    end

    -- minus key
    if event == EVT_MINUS_BREAK then
        if current_screen == min_screen then
            if current_state == pageStatus.displayMenu then        
                menuActive = menuActive + 1
                if menuActive == (menuMaxLine+1) then
                    menuActive = menuMinLine1
                end
            else
                if y_index < 5 then
                    y_index = y_index + 1
                else
                    y_index = 1
                end
                select_x = xpos_freq[x_index]
                select_y = ypos_fff[y_index]
            end
        end
    end
    
    -- draw current screen
    if current_screen == min_screen then
        if current_state == pageStatus.displayMenu then
            drawMenu()
        else
            draw_freq_screen()
        end
    elseif current_screen == (min_screen + 1) then
        draw_use_freq_screen()
    else
        if DEBUG == 1 then    
            draw_input_screen()
        end        
    end
    return 0
end

return { init=init_func, run=run_func }
