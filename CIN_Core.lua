-- CUSTOM ITEM NOTES
-- Author: Arkaan (GenomeWhisperer on Github)

CIN_Save = CIN_Save or {};

local CIN = {};
local CIN_G = {};

CIN_G.addonName = "Custom_Item_Notes";


-- Slash Commands
SLASH_CIN1 = '/cin';

----------------------
-- SET NOTE LOGIC ----
----------------------

-- Method:          CIN.AddNote ( string , int , int )
-- What it Does:    Adds the given player input note to the save file
-- Purpose:         To save between sessions the given notes.
CIN.AddNote = function ( note , position , itemID )
    local ID = itemID or CIN.GetItemID();

    if ID then
        local id = tostring (ID);
        if not CIN_Save[id] then
            CIN_Save[id] = {};
        end

        if #note > 255 then
            note = string.sub ( note , 1 , 255 );
            print("Max note length is 255 characters.")
        else
            note = CIN.WrapNote ( note );
        end

        if not position or position > ( #CIN_Save[id] + 1 ) then
            position = #CIN_Save[id] + 1;
        end
        table.insert ( CIN_Save[id] , position , note );
    end
end

-- Method:          CIN.EditNote ( string , int , int )
-- What it Does:    Allows the player to edit a given note with a new one without needing to delete and add again
-- Purpose:         One less step for the efficient user.
CIN.EditNote = function ( newNote , position , itemID )
    local ID = itemID or CIN.GetItemID();

    if ID then
        local id = tostring (ID);
        if CIN_Save[id] then
            if CIN_Save[id][position] then
                CIN_Save[id][position] = newNote;
            else
                if #CIN_Save[id] > 1 then
                    print("Note not found. There are only " .. #CIN_Save[id] .. " notes set and you selected " .. position .. "." );
                else
                    print("Note not found. There is only 1 note set and you selected " .. position .. "." );
                end
            end
        end
    end
end

-- Method:          CIN.DeleteNote ( int , int )
-- What it Does:    Deletes the most recent set note on the item, or by given number.
-- Purpose:         To be able to allow player control of notes added.
CIN.DeleteNote = function ( position , itemID )
    local ID = itemID or CIN.GetItemID();

    if ID then
        local id = tostring (ID);

        if CIN_Save[id] then
        local number = position or #CIN_Save[id];

            if CIN_Save[id][number] then
                table.remove ( CIN_Save[id] , number );
            else
                if #CIN_Save[id] > 1 then
                    print("Note not found. There are only " .. #CIN_Save[id] .. " notes set and you selected " .. number .. "." );
                else
                    print("Note not found. There is only 1 note set and you selected " .. number .. "." );
                end
            end
        end
    end
end

-- Method:          CIN.ClearAllNotes ( int )
-- What it Does:    Removes all the notes of the given item, be it a given itemID, or by mouseover of item
-- Purpose:         Easy to clear mass notes
CIN.ClearAllNotes = function ( itemID )
    local ID = itemID or CIN.GetItemID();

    if ID then
        local id = tostring (ID);
        if CIN_Save[id] then
            CIN_Save[id] = {};
        end
    end
end

-- Method:          CIN.WrapNote ( string )
-- What it Does:    Takes text and wraps it to be no longer than 100 chars long.
-- Purpose:         Quality of Life for tooltips to keep you from adding one that goes full screen wide!
CIN.WrapNote = function ( note )
    local tempNote , tempNote2 = "" , "";
    local finalNote = "";
    local ind = 0;

    if #note > 100 then

        -- First Line
        tempNote = string.sub ( note , 100 );
        ind = string.find ( tempNote , " " );

        if ind then
            finalNote = string.sub ( note , 1 , ind + 100 - 1 ) .. "\n";    -- Remaining note is on the tempNote;
            tempNote = string.sub ( tempNote , ind + 1 );                   -- Parse out what has been added
        else
            finalNote = note;
            return finalNote;   -- No spaces, no need to wrap this.
        end

        -- Moving on to 2nd line.
        if #tempNote > 100 then
            tempNote2 = string.sub ( tempNote , 100 );
            ind = string.find ( tempNote2 , " " );
            if ind then
                finalNote = finalNote .. string.sub ( tempNote , 1 , ind + 100 - 1 ) .. "\n"; -- Remaining note is on the tempNote;
                finalNote = finalNote .. string.sub ( tempNote2 , ind + 1 );
            else
                finalNote = finalNote .. tempNote;
            end

        else
            finalNote = finalNote .. tempNote;
        end

    else
        finalNote = note;
    end

    return finalNote;
end

----------------------
-- NOTE LOADING LOGIC
----------------------

-- Quickly parse item ID
CIN.GetItemID = function()
    local link , id = select ( 2 , GameTooltip:GetItem() );

    if not id and link then
        id = string.match ( link , "|Hitem:(%d+):" );
    end	

    return id;
end

-- Logic handler for building tooltip
CIN.SetTooltipNote = function()

    -- Ok, let's obtain the itemID.
    local ID = CIN.GetItemID();

    if ID then
        local id = tostring (ID);
        if CIN_Save[id] then
            CIN.BuildTooltip ( CIN_Save[id] );
        end
    end
end

-- Method:          CIN.BuildTooltip ( table )
-- What it Does:    Adds the notes to end of tooltip
-- Purpose:         To be able to add notes to tooltips easily.
CIN.BuildTooltip = function ( notes )
    GameTooltip:AddLine ( " " );
    for i = 1 , #notes do
        GameTooltip:AddLine ( "|CFF1DC5D3Note" .. i .. ":|r " .. notes[i] , 1 , 1 , 1 );
    end
end

-- Just cleanup the text - remove white space
CIN.Trim = function ( text )
    return text:gsub ( "^%s*(.-)%s*$" , "%1" );
end

-- Method:          CIN.ParseInput ( string )
-- What it Does:    Parses out the command, the new note, and the index 
-- Purpose:         Ease of handling slash commands for user input.
CIN.ParseInput= function ( input )

    input = CIN.Trim( input )

    local command, remainingNote = string.match ( input , "(%a+)%s+(.+)" );
    if not command then
        return input;
    end

    local text = string.match ( CIN.Trim ( remainingNote ) , "(.+)%s+|(%d+)" );
    local number;

    if not text then
        text = remainingNote;
    end

    if string.find ( text , "|%d+" ) ~= nil then
        number = string.match ( text , ".+|(%d+)");
        text = string.sub ( text , 1 , string.find ( text , "|%d+" ) - 2 );
    end

    if number and tonumber ( string.sub ( remainingNote , #remainingNote , #remainingNote ) ) ~= nil then -- Just confirming the parse was successful AND that the final text is a number
        number = tonumber ( number );
    end

    return string.lower ( command ) , CIN.Trim (text), number;
end

-- Method:          CIN.SlashCommandHelp()
-- What it Does:    Builds the help printout for addon slash commands
-- Purpose:         Easily access the help commands.
CIN.SlashCommandHelp = function()
    print ( "\n|CFF1DC5D3Custom Item Notes:" );
    print( "/cin <Insert any note here> - You must be mousing over the item" );
    print( "/cin add <Insert Any Note Here> |x - Add a new note at \"x\" position. X=any number." );
    print( "/cin edit <Insert Any Note Here> |x - Edit note at \"x\" position. X=any number." );
    print( "/cin del |x - Del note at \"x\" position. X not required. Default is last note." );
    print( "/cin clearall - Clears all notes of the given item." );
end

-- Slash command logic
SlashCmdList["CIN"] = function ( input )  
    local errorMsg = "Please type '/cin help' for assistance.";
    local errorMsg2 = "Please mouse over an item first.";
    
    local id = CIN.GetItemID();

    if not input or input == "" then
        print(errorMsg);
        return;
    end

    if not id and string.lower ( CIN.Trim( input ) ) ~= "help" then
        print(errorMsg2);
        return;
    end

    local command , text , index = CIN.ParseInput ( input );

    if command == "help" then
        CIN.SlashCommandHelp();

    elseif command == "add" then
        if not text or text == "" then
            print ( "Please include the new note." );
        else
            CIN.AddNote ( text , index );
        end

    elseif command == "edit" then
        if not text or text == "" then
            print ( "Please include the new note." );
        else
            CIN.EditNote ( text , index );
        end

    elseif command == "delete" or command == "del" then
        CIN.DeleteNote ( index );

    elseif command == "clearall" then
        CIN.ClearAllNotes();

    elseif GameTooltip:IsVisible() then 
        CIN.AddNote ( input );

    else
        print (errorMsg);
    end
end

CIN.Initialize = function()
    -- Possibly for future use.
end

-- Method:          CIN.ActivateAddon ( ... , string , string )
-- What it Does:"   Controls load order of addon to ensure it doesn't initialize until player has fully logged into the world
-- Purpose:         Some things don't needto load until player is entering the world.
CIN.ActivateAddon = function ( _ , event , addon )

    if event == "ADDON_LOADED" then
    -- initiate addon once all variable are loaded.
        if addon == CIN_G.addonName then
            CIN.Initialization:RegisterEvent ( "PLAYER_ENTERING_WORLD" ); -- Ensures this check does not occur until after Addon is fully loaded. By registering, it acts recursively throug hthis method
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        CIN.Initialize();
        CIN.Initialization:UnregisterAllEvents();
    end

end

-- New Tooltip handler logic as of 10.0.2
if TooltipDataProcessor then
    TooltipDataProcessor.AddTooltipPostCall ( Enum.TooltipDataType.Item , function ( GameTooltip )
        CIN.SetTooltipNote();
    end);
else
    GameTooltip:HookScript ( "OnTooltipSetItem" , CIN.SetTooltipNote );
end

-- Initialize the first frames as game is being loaded.
CIN.Initialization = CreateFrame ( "Frame" );
CIN.Initialization:RegisterEvent ( "ADDON_LOADED" );
CIN.Initialization:SetScript ( "OnEvent" , CIN.ActivateAddon );