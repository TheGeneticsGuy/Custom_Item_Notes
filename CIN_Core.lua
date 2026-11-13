-- CUSTOM ITEM NOTES
-- Author: Arkaan (GenomeWhisperer on Github)

CIN_Save = CIN_Save or {};
CIN = {};       -- Global variable across all files

local CIN_G = {};
CIN_G.BuildVersion = select ( 4 , GetBuildInfo() )
CIN_G.addonName = "Custom_Item_Notes";

-- Slash Commands
SLASH_CIN1 = '/cin';

----------------------
-- SET NOTE LOGIC ----
----------------------

-- Method:          CIN.AddNote ( string , int , int , int )
-- What it Does:    Adds the given player input note to the save file
-- Purpose:         To save between sessions the given notes.
CIN.AddNote = function ( note , position , index , explicitItemID )
    local name = index;
    local itemID = explicitItemID;

    if not name then
        name , itemID = CIN.GetItemNameAndID();
    end

    if name then
        local id = tostring ( name );
        if not CIN_Save[id] then
            CIN_Save[id] = {};
            CIN_Save[id].itemID = tonumber ( itemID );
        elseif itemID and not CIN_Save[id].itemID then
            CIN_Save[id].itemID = tonumber ( itemID );
        end

        -- Clean out any accidental newlines so notes stay single-entry strings
        note = CIN.Trim ( note:gsub ( "\n" , " " ) );

        if #note > 255 then
            note = string.sub ( note , 1 , 255 );
            print ( "Max note length is 255 characters." );
        end

        if not position or position > ( #CIN_Save[id] + 1 ) then
            position = #CIN_Save[id] + 1;
        end
        table.insert ( CIN_Save[id] , position , note );

        -- Refresh UI if open
        if CIN.RefreshGUI then
            CIN.RefreshGUI();
        end
    end
end

-- Method:          CIN.EditNote ( string , int , int )
-- What it Does:    Allows the player to edit a given note with a new one without needing to delete and add again
-- Purpose:         One less step for the efficient user.
CIN.EditNote = function ( newNote , position , itemID )
    local name = itemID or CIN.GetItemNameAndID();

    if name then
        local id = tostring ( name );
        if CIN_Save[id] then
            if CIN_Save[id][position] then
                CIN_Save[id][position] = CIN.Trim ( newNote:gsub ( "\n" , " " ) );
                if CIN.RefreshGUI then
                    CIN.RefreshGUI();
                end
            else
                if #CIN_Save[id] > 1 then
                    print ( "Note not found. There are only " .. #CIN_Save[id] .. " notes set and you selected " .. position .. "." );
                else
                    print ( "Note not found. There is only 1 note set and you selected " .. position .. "." );
                end
            end
        end
    end
end

-- Method:          CIN.DeleteNote ( int , int )
-- What it Does:    Deletes the most recent set note on the item, or by given number.
-- Purpose:         To be able to allow player control of notes added.
CIN.DeleteNote = function ( position , itemID )
    local name = itemID or CIN.GetItemNameAndID();

    if name then
        local id = tostring ( name );

        if CIN_Save[id] then
            local number = position or #CIN_Save[id];

            if CIN_Save[id][number] then
                table.remove ( CIN_Save[id] , number );

                -- Wipe the memory index if no more notes.
                if #CIN_Save[id] == 0 then
                    CIN_Save[id] = nil;
                end

                if CIN.RefreshGUI then
                    CIN.RefreshGUI();
                end
            else
                if #CIN_Save[id] > 1 then
                    print ( "Note not found. There are only " .. #CIN_Save[id] .. " notes set and you selected " .. number .. "." );
                else
                    print ( "Note not found. There is only 1 note set and you selected " .. number .. "." );
                end
            end
        end
    end
end

-- Method:          CIN.ClearAllNotes ( int )
-- What it Does:    Removes all the notes of the given item, be it a given itemID, or by mouseover of item
-- Purpose:         Easy to clear mass notes
CIN.ClearAllNotes = function ( itemID )
    local name = itemID or CIN.GetItemNameAndID();

    if name then
        local id = tostring ( name );
        if CIN_Save[id] then
            CIN_Save[id] = nil;
            if CIN.RefreshGUI then
                CIN.RefreshGUI();
            end
        end
    end
end

----------------------
-- NOTE LOADING LOGIC
----------------------

CIN.GetItemQuality = function ( id )
    local quality , _ , _ , typeOfItem = select ( 3 , C_Item.GetItemInfo ( id ) );
    return quality , typeOfItem;
end

-- Quickly parse item ID and name
CIN.GetItemNameAndID = function()
    local link = select ( 2 , GameTooltip:GetItem() );
    local name;
    local id;

    -- Classic ID will not be give on the GetItem() dump.
    if link then
        name = C_Item.GetItemInfo ( link );
        id = C_Item.GetItemInfoInstant ( link );
        if id then
            id = tonumber ( id );
        end
    end

    return name , id;
end

-- Logic handler for building tooltip
CIN.SetTooltipNote = function()

    if not CIN.S().keyToSee or IsKeyDown ( CIN.S().keyToSeeName or "TAB" ) then
        -- Ok, let's obtain the itemID.
        local name , itemID = CIN.GetItemNameAndID();

        if name then
            local id = tostring ( name );
            if CIN_Save[id] then
                -- Self-heal missing itemID if user had an old entry without one
                if itemID and not CIN_Save[id].itemID then
                    CIN_Save[id].itemID = itemID;
                end
                CIN.BuildTooltip ( CIN_Save[id] );
            end
        end
    end
end

-- Method:          CIN.BuildTooltip ( table )
-- What it Does:    Adds the notes to end of tooltip
-- Purpose:         To be able to add notes to tooltips easily.
CIN.BuildTooltip = function ( notes )

    if #notes == 0 then
        return;
    end

    local lastTooltipLine = _G["GameTooltipTextLeft" .. GameTooltip:NumLines()];
    local line = lastTooltipLine and lastTooltipLine:GetText();
    if CIN.IsSecretValue ( line ) then
        return; -- Kill it if secret protected
    end

    local lastLine = "|CFF1DC5D3Note" .. #notes .. ":|r " .. notes[#notes];
    local lineToAdd = "";

    if line == lastLine then
        return;
    end

    for i = 1 , #notes do

        lineToAdd = "|CFF1DC5D3Note" .. i .. ":|r " .. notes[i];

        if i == 1 then
            GameTooltip:AddLine ( " " );
        end
        GameTooltip:AddLine ( lineToAdd , 1 , 1 , 1 , true );
    end
end

-- Just cleanup the text - remove white space
CIN.Trim = function ( text )
    return text:gsub ( "^%s*(.-)%s*$" , "%1" );
end

-- Method:          CIN.ParseInput ( string )
-- What it Does:    Parses out the command, the new note, and the index
-- Purpose:         Ease of handling slash commands for user input.
CIN.ParseInput = function ( input )

    input = CIN.Trim ( input );

    local command , remainingNote = string.match ( input , "(%a+)%s+(.+)" );
    if not command then
        return string.lower ( input );
    end

    local text = string.match ( CIN.Trim ( remainingNote ) , "(.+)%s+|(%d+)" );
    local number;

    if not text then
        text = remainingNote;
    end

    if string.find ( text , "|%d+" ) ~= nil then
        number = string.match ( text , ".+|(%d+)" );
        text = string.sub ( text , 1 , string.find ( text , "|%d+" ) - 2 );
    end

    if number and tonumber ( string.sub ( remainingNote , #remainingNote , #remainingNote ) ) ~= nil then -- Just confirming the parse was successful AND that the final text is a number
        number = tonumber ( number );
    end

    return string.lower ( command ) , CIN.Trim ( text ) , number;
end

-- Method:          CIN.SlashCommandHelp()
-- What it Does:    Builds the help printout for addon slash commands
-- Purpose:         Easily access the help commands.
CIN.SlashCommandHelp = function()
    print ( "\n|CFFFFD100Custom Item Notes - Slash Commands:|r" );
    print ( "|CFF1DC5D3/cin|r - Opens the Custom Item Notes Manager window." );
    print ( "|CFF1DC5D3/cin help|r - Displays this help menu." );
    print ( "|CFF1DC5D3/cin <Note>|r - Adds a note to the item you are currently mousing over." );
    print ( "|CFF1DC5D3/cin add <Note> |x|r - Add a new note at \"x\" position. X=any number." );
    print ( "|CFF1DC5D3/cin edit <Note> |x|r - Edit note at \"x\" position. X=any number." );
    print ( "|CFF1DC5D3/cin del |x|r - Del note at \"x\" position. X not required. Default is last note." );
    print ( "|CFF1DC5D3/cin clearall|r - Clears all notes of the given item." );
    print ( " " );
    print ( "|CFFFFD100Quick Note Editor:|r" );
    print ( "Press 'CTRL-ALT-A' whilst hovering over an item to open that item directly in the CIN Manager." );
    print ( " " );
end

-- Slash command logic
-- Typing '/cin' alone now toggles the Note Manager UI!
SlashCmdList["CIN"] = function ( input )
    local errorMsg = "Please mouse over an item to add a note, or type '/cin help' for assistance.";

    input = input and CIN.Trim ( input ) or "";

    -- If no arguments (or '/cin ui'), toggle the Note Manager window
    if input == "" or string.lower ( input ) == "ui" then
        CIN.ToggleGUI();
        return;
    end

    local command , text , index = CIN.ParseInput ( input );

    if command == "help" then
        CIN.SlashCommandHelp();
        return;
    end

    local name = CIN.GetItemNameAndID();

    if not name then
        print ( errorMsg );
        return;
    end

    if command == "add" then
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
        print ( errorMsg );
    end
end

-- Method:          CIN.Initialize()
-- What it Does:    Ensures that the core loadout of the addon doesn't occur until the events of logging in trigger
-- Purpose:         Important to control load of data to be delayed in some cases.
CIN.Initialize = function()
    CIN.CreateGUI();
    C_Timer.After ( 1 , CIN.PatchCheck );
end

-- Method:          CIN.ActivateAddon ( ... , string , string )
-- What it Does:    Controls load order of addon to ensure it doesn't initialize until player has fully logged into the world
-- Purpose:         Some things don't need to load until player is entering the world.
CIN.ActivateAddon = function ( _ , event , addon )

    if event == "ADDON_LOADED" then
        -- initiate addon once all variable are loaded.
        if addon == CIN_G.addonName then
            CIN.Initialization:RegisterEvent ( "PLAYER_ENTERING_WORLD" ); -- Ensures this check does not occur until after Addon is fully loaded.
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        CIN.Initialize();
        CIN.Initialization:UnregisterAllEvents();
    end

end

-- Tooltip handler logic as of 10.0.2
CIN.ToolTipPostCallInitialization = function()

    if C_TooltipInfo then
        TooltipDataProcessor.AddTooltipPostCall ( Enum.TooltipDataType.Item , CIN.SetTooltipNote );
    else
        GameTooltip:HookScript ( "OnTooltipSetItem" , CIN.SetTooltipNote );
    end
end

---------------------
-- TECHNICAL TOOLS --
---------------------

-- Method:          CIN.DeepCopyArray(array)
-- What it Does:    Makes a Deep copy, including all children, recursively, so as to create a new memory reference of the array
CIN.DeepCopyArray = function ( tableToCopy )
    local copy;
    if type ( tableToCopy ) == 'table' then
        copy = {};
        for orig_key , orig_value in next , tableToCopy , nil do
            copy[CIN.DeepCopyArray ( orig_key )] = CIN.DeepCopyArray ( orig_value );
        end
        setmetatable ( copy , CIN.DeepCopyArray ( getmetatable ( tableToCopy ) ) );
    else
        copy = tableToCopy;         -- Imported data was not a table... just return orig. value - error protection
    end
    return copy;
end

-- Method:          CIN.IsSecretValue(Any)
-- What it Does:    Returns true/false if value is a secret value as introduced by Blizz in 12.0
CIN.IsSecretValue = function ( value )
    if issecretvalue and issecretvalue ( value ) then
        return true;
    end
    return false;
end

---------------------
-- APLIT-PANE GUI ---
---------------------

-- Local helper to split editor text into individual notes (empty lines act as delimiter)
local function split_string ( s , delimiter )
    local result = {};
    local from = 1;
    local current_string = "";
    local united_string = "";
    local delim_from , delim_to = string.find ( s , delimiter , from );

    while delim_from do
        current_string = CIN.Trim ( string.sub ( s , from , delim_from - 1 ) );
        if current_string == "" then
            if united_string ~= "" then
                table.insert ( result , united_string );
                united_string = "";
            end
        else
            if united_string ~= "" then
                united_string = united_string .. " " .. current_string;
            else
                united_string = current_string;
            end
        end
        from = delim_to + 1;
        delim_from , delim_to = string.find ( s , delimiter , from );
    end

    current_string = CIN.Trim ( string.sub ( s , from ) );
    if current_string ~= "" then
        if united_string ~= "" then
            united_string = united_string .. " " .. current_string;
        else
            united_string = current_string;
        end
    end

    if united_string ~= "" then
        table.insert ( result , united_string );
    end

    return result;
end

-- Method:          CIN.ToggleGUI ( string , int )
-- What it Does:    Opens/closes the Note Manager, optionally selecting a specific item
CIN.ToggleGUI = function ( itemName , itemID )
    if not CIN.GUIFrame then
        return;
    end

    if itemName then
        CIN.SelectItemInGUI ( itemName , itemID );
        CIN.GUIFrame:Show();
        CIN.GUIEditBox:SetFocus();
    else
        if CIN.GUIFrame:IsShown() then
            CIN.GUIFrame:Hide();
        else
            CIN.GUIFrame:Show();
            CIN.RefreshGUI();
        end
    end
end

-- Method:          CIN.SelectItemInGUI ( string , int )
-- What it Does:    Loads the selected item's notes into the right-hand editor pane
CIN.SelectItemInGUI = function ( itemName , itemID )
    if not itemName then
        CIN.GUICurrentName = nil;
        CIN.GUICurrentId = nil;
        CIN.RightPaneTitle:SetText ( "Select an item from the list" );
        CIN.GUIEditBox:SetText ( "" );
        CIN.GUIEditBox:ClearFocus();
        CIN.GUIEditBox:Disable();
        CIN.GUIButtonSave:Disable();
        CIN.GUIButtonDelete:Disable();
        return;
    end

    itemName = tostring ( itemName );
    CIN.GUICurrentName = itemName;
    CIN.GUICurrentId = itemID or ( CIN_Save[itemName] and CIN_Save[itemName].itemID ) or nil;

    CIN.GUIEditBox:Enable();
    CIN.GUIButtonSave:Enable();
    CIN.GUIButtonDelete:Enable();

    local tooltip_strings = "";
    if CIN_Save[itemName] then
        for i = 1 , #CIN_Save[itemName] do
            local cleanNote = CIN_Save[itemName][i]:gsub ( "\n" , " " );
            tooltip_strings = tooltip_strings .. cleanNote .. "\n\n";
        end
    end

    local titleText = itemName;
    if CIN.GUICurrentId then
        titleText = titleText .. " |CFF888888(ID: " .. tostring ( CIN.GUICurrentId ) .. ")|r";
    end

    CIN.RightPaneTitle:SetText ( titleText );
    CIN.GUIEditBox:SetText ( tooltip_strings );
    CIN.GUIEditBox:SetCursorPosition ( 0 );

    CIN.RefreshGUI();
end

-- Method:          CIN.CreateGUI()
-- What it Does:    Creates the Split-Pane Note Manager and Editor UI
CIN.CreateGUI = function()

    local ROW_HEIGHT = 28;
    local filteredItems = {};
    local rowFrames = {};

    -- Create named base frame so UISpecialFrames can close it via ESC natively without combat taint!
    CIN.GUIFrame = CreateFrame ( "Frame" , "CIN_ManagerFrame" , UIParent , "BasicFrameTemplateWithInset" );
    table.insert ( UISpecialFrames , "CIN_ManagerFrame" );

    CIN.GUIFrame.TitleBg:SetHeight ( 30 );
    CIN.GUIFrame.title = CIN.GUIFrame:CreateFontString ( nil , "OVERLAY" , "GameFontHighlight" );
    CIN.GUIFrame.title:SetPoint ( "TOPLEFT" , CIN.GUIFrame.TitleBg , "TOPLEFT" , 8 , -3 );
    CIN.GUIFrame.title:SetText ( "Custom Item Notes - Manager" );
    CIN.GUIFrame:SetSize ( 720 , 480 );
    CIN.GUIFrame:SetPoint ( "CENTER" );
    CIN.GUIFrame:EnableMouse ( true );
    CIN.GUIFrame:SetMovable ( true );
    CIN.GUIFrame:RegisterForDrag ( "LeftButton" );
    CIN.GUIFrame:SetScript ( "OnDragStart" , CIN.GUIFrame.StartMoving );
    CIN.GUIFrame:SetScript ( "OnDragStop" , CIN.GUIFrame.StopMovingOrSizing );
    CIN.GUIFrame:SetScript ( "OnHide" , CIN.GUIFrame.StopMovingOrSizing );
    CIN.GUIFrame:Hide();

    ---------------------------------
    -- LEFT PANE: SEARCH & ITEM LIST
    ---------------------------------

    -- Search Box
    local searchLabel = CIN.GUIFrame:CreateFontString ( nil , "OVERLAY" , "GameFontNormalSmall" );
    searchLabel:SetPoint ( "TOPLEFT" , 16 , -36 );
    searchLabel:SetText ( "Search Items or Notes:" );

    CIN.SearchBox = CreateFrame ( "EditBox" , nil , CIN.GUIFrame , "InputBoxTemplate" );
    CIN.SearchBox:SetSize ( 215 , 22 );
    CIN.SearchBox:SetPoint ( "TOPLEFT" , 20 , -52 );
    CIN.SearchBox:SetAutoFocus ( false );

    -- Clear Search 'X' Button
    local clearSearchBtn = CreateFrame ( "Button" , nil , CIN.GUIFrame , "UIPanelButtonTemplate" );
    clearSearchBtn:SetSize ( 24 , 22 );
    clearSearchBtn:SetPoint ( "LEFT" , CIN.SearchBox , "RIGHT" , 4 , 0 );
    clearSearchBtn:SetText ( "X" );
    clearSearchBtn:SetScript ( "OnClick" , function()
        CIN.SearchBox:SetText ( "" );
        CIN.SearchBox:ClearFocus();
        CIN.RefreshGUI();
    end );

    CIN.SearchBox:SetScript ( "OnTextChanged" , function()
        CIN.RefreshGUI();
    end );
    CIN.SearchBox:SetScript ( "OnEscapePressed" , function ( self )
        self:ClearFocus();
    end );
    CIN.SearchBox:SetScript ( "OnEnterPressed" , function ( self )
        self:ClearFocus();
    end );

    -- Left Scroll Frame for Item List
    CIN.ListScrollFrame = CreateFrame ( "ScrollFrame" , nil , CIN.GUIFrame , "UIPanelScrollFrameTemplate" );
    CIN.ListScrollFrame:SetPoint ( "TOPLEFT" , 14 , -82 );
    CIN.ListScrollFrame:SetPoint ( "BOTTOMLEFT" , 14 , 14 );
    CIN.ListScrollFrame:SetWidth ( 235 );

    CIN.ListScrollChild = CreateFrame ( "Frame" , nil , CIN.ListScrollFrame );
    CIN.ListScrollChild:SetSize ( 235 , 1 );
    CIN.ListScrollFrame:SetScrollChild ( CIN.ListScrollChild );

    -- Vertical Divider Line
    local divider = CIN.GUIFrame:CreateTexture ( nil , "ARTWORK" );
    divider:SetColorTexture ( 0.3 , 0.3 , 0.3 , 0.8 );
    divider:SetSize ( 2 , 425 );
    divider:SetPoint ( "TOPLEFT" , 278 , -36 );

    ---------------------------------
    -- RIGHT PANE: NOTE EDITOR
    ---------------------------------

    CIN.RightPaneTitle = CIN.GUIFrame:CreateFontString ( nil , "OVERLAY" , "GameFontNormalLarge" );
    CIN.RightPaneTitle:SetPoint ( "TOPLEFT" , 292 , -38 );
    CIN.RightPaneTitle:SetPoint ( "RIGHT" , -20 , 0 );
    CIN.RightPaneTitle:SetJustifyH ( "LEFT" );
    CIN.RightPaneTitle:SetWordWrap ( false );
    CIN.RightPaneTitle:SetText ( "Select an item from the list" );

    local editorHint = CIN.GUIFrame:CreateFontString ( nil , "OVERLAY" , "GameFontHighlightSmall" );
    editorHint:SetPoint ( "TOPLEFT" , CIN.RightPaneTitle , "BOTTOMLEFT" , 0 , -4 );
    editorHint:SetText ( "|CFF888888Separate multiple notes with an empty blank line.|r" );

    -- ScrollFrame for EditBox
    CIN.GUIFrameScroll = CreateFrame ( "ScrollFrame" , nil , CIN.GUIFrame , "UIPanelScrollFrameTemplate" );
    CIN.GUIFrameScroll:SetPoint ( "TOPLEFT" , 292 , -78 );
    CIN.GUIFrameScroll:SetPoint ( "BOTTOMRIGHT" , CIN.GUIFrame , "BOTTOMRIGHT" , -32 , 45 );

    -- Subtle Background for the EditBox area
    local editBg = CIN.GUIFrame:CreateTexture ( nil , "BACKGROUND" );
    editBg:SetColorTexture ( 0 , 0 , 0 , 0.45 );
    editBg:SetPoint ( "TOPLEFT" , CIN.GUIFrameScroll , "TOPLEFT" , -4 , 4 );
    editBg:SetPoint ( "BOTTOMRIGHT" , CIN.GUIFrameScroll , "BOTTOMRIGHT" , 4 , -4 );

    -- EditBox for editing notes
    CIN.GUIEditBox = CreateFrame ( "EditBox" , nil , CIN.GUIFrame );
    CIN.GUIEditBox:SetMultiLine ( true );
    CIN.GUIEditBox:SetAutoFocus ( false );
    CIN.GUIEditBox:SetFontObject ( ChatFontNormal );
    CIN.GUIEditBox:SetWidth ( 385 );
    CIN.GUIEditBox:SetHeight ( 340 );
    CIN.GUIEditBox:SetText ( "" );
    CIN.GUIEditBox:SetScript ( "OnEscapePressed" , function ( self )
        self:ClearFocus();
    end );
    CIN.GUIFrameScroll:SetScrollChild ( CIN.GUIEditBox );

    -- Clicking anywhere in the empty scroll area focuses the EditBox
    CIN.GUIFrameScroll:EnableMouse ( true );
    CIN.GUIFrameScroll:SetScript ( "OnMouseDown" , function()
        if CIN.GUIEditBox:IsEnabled() then
            CIN.GUIEditBox:SetFocus();
        end
    end );

    -- Save Button
    CIN.GUIButtonSave = CreateFrame ( "Button" , nil , CIN.GUIFrame , "UIPanelButtonTemplate" );
    CIN.GUIButtonSave:SetSize ( 90 , 24 );
    CIN.GUIButtonSave:SetText ( "Save" );
    CIN.GUIButtonSave:SetPoint ( "BOTTOMLEFT" , 292 , 12 );
    CIN.GUIButtonSave:SetScript ( "OnClick" , function()
        if not CIN.GUICurrentName then
            return;
        end

        local list_notes = split_string ( CIN.GUIEditBox:GetText() , "\n" );
        if #list_notes > 0 then
            if not CIN_Save[CIN.GUICurrentName] then
                CIN_Save[CIN.GUICurrentName] = {};
                CIN_Save[CIN.GUICurrentName].itemID = tonumber ( CIN.GUICurrentId );
            end
            local len_current_saves = #CIN_Save[CIN.GUICurrentName];
            for i = 1 , len_current_saves do
                table.remove ( CIN_Save[CIN.GUICurrentName] );
            end
            for i = 1 , #list_notes do
                CIN.AddNote ( list_notes[i] , nil , CIN.GUICurrentName , CIN.GUICurrentId );
            end
        else
            CIN_Save[CIN.GUICurrentName] = nil;
            CIN.SelectItemInGUI ( nil );
        end
        CIN.GUIEditBox:ClearFocus();
        CIN.RefreshGUI();
    end );

    -- Revert / Cancel Button
    CIN.GUIButtonCancel = CreateFrame ( "Button" , nil , CIN.GUIFrame , "UIPanelButtonTemplate" );
    CIN.GUIButtonCancel:SetSize ( 90 , 24 );
    CIN.GUIButtonCancel:SetText ( "Revert" );
    CIN.GUIButtonCancel:SetPoint ( "LEFT" , CIN.GUIButtonSave , "RIGHT" , 8 , 0 );
    CIN.GUIButtonCancel:SetScript ( "OnClick" , function()
        if CIN.GUICurrentName then
            CIN.SelectItemInGUI ( CIN.GUICurrentName , CIN.GUICurrentId );
        end
        CIN.GUIEditBox:ClearFocus();
    end );

    -- Delete All Button
    CIN.GUIButtonDelete = CreateFrame ( "Button" , nil , CIN.GUIFrame , "UIPanelButtonTemplate" );
    CIN.GUIButtonDelete:SetSize ( 100 , 24 );
    CIN.GUIButtonDelete:SetText ( "Delete Item" );
    CIN.GUIButtonDelete:SetPoint ( "BOTTOMRIGHT" , -14 , 12 );
    CIN.GUIButtonDelete:SetScript ( "OnClick" , function()
        if CIN.GUICurrentName and CIN_Save[CIN.GUICurrentName] then
            CIN_Save[CIN.GUICurrentName] = nil;
            CIN.SelectItemInGUI ( nil );
            CIN.RefreshGUI();
        end
    end );

    ---------------------------------
    -- LIST POPULATION & SEARCH LOGIC
    ---------------------------------

    local function GetOrCreateRow ( index )
        if not rowFrames[index] then
            local row = CreateFrame ( "Button" , nil , CIN.ListScrollChild );
            row:SetSize ( 230 , ROW_HEIGHT );
            row:SetPoint ( "TOPLEFT" , 0 , - ( index - 1 ) * ROW_HEIGHT );

            -- Hover Highlight
            row.highlight = row:CreateTexture ( nil , "HIGHLIGHT" );
            row.highlight:SetAllPoints();
            row.highlight:SetColorTexture ( 1 , 1 , 1 , 0.12 );

            -- Selected Highlight
            row.selectedTex = row:CreateTexture ( nil , "BACKGROUND" );
            row.selectedTex:SetAllPoints();
            row.selectedTex:SetColorTexture ( 0.11 , 0.77 , 0.82 , 0.25 );
            row.selectedTex:Hide();

            -- Item Icon
            row.icon = row:CreateTexture ( nil , "ARTWORK" );
            row.icon:SetSize ( 22 , 22 );
            row.icon:SetPoint ( "LEFT" , 4 , 0 );

            -- Note Count Badge
            row.countText = row:CreateFontString ( nil , "OVERLAY" , "GameFontNormalSmall" );
            row.countText:SetPoint ( "RIGHT" , -4 , 0 );
            row.countText:SetTextColor ( 0.11 , 0.77 , 0.82 );

            -- Item Name
            row.nameText = row:CreateFontString ( nil , "OVERLAY" , "GameFontHighlightSmall" );
            row.nameText:SetPoint ( "LEFT" , row.icon , "RIGHT" , 6 , 0 );
            row.nameText:SetPoint ( "RIGHT" , row.countText , "LEFT" , -4 , 0 );
            row.nameText:SetJustifyH ( "LEFT" );
            row.nameText:SetWordWrap ( false );

            -- Click Behavior (Select Item or Shift-Click to link in chat)
            row:SetScript ( "OnClick" , function ( self )
                if IsModifiedClick ( "CHATLINK" ) and self.itemID then
                    local _ , link = C_Item.GetItemInfo ( self.itemID );
                    if link then
                        ChatEdit_InsertLink ( link );
                        return;
                    end
                end
                CIN.SelectItemInGUI ( self.itemName , self.itemID );
            end );

            -- Tooltip Preview on Hover
            row:SetScript ( "OnEnter" , function ( self )
                GameTooltip:SetOwner ( self , "ANCHOR_RIGHT" );
                if self.itemID then
                    GameTooltip:SetItemByID ( self.itemID );
                else
                    GameTooltip:SetText ( self.itemName , 1 , 1 , 1 );
                    if CIN_Save[self.itemName] then
                        CIN.BuildTooltip ( CIN_Save[self.itemName] );
                    end
                end
                GameTooltip:Show();
            end );

            row:SetScript ( "OnLeave" , function()
                GameTooltip:Hide();
            end );

            rowFrames[index] = row;
        end
        return rowFrames[index];
    end

    -- Refresh the Left-Hand List based on CIN_Save and Search Filter
    CIN.RefreshGUI = function()
        if not CIN.GUIFrame or not CIN.GUIFrame:IsShown() then
            return;
        end

        wipe ( filteredItems );
        local query = string.lower ( CIN.Trim ( CIN.SearchBox:GetText() or "" ) );

        for itemName , data in pairs ( CIN_Save ) do
            if itemName ~= "VERSION" and type ( data ) == "table" and #data > 0 then
                local match = false;

                if query == "" then
                    match = true;
                elseif string.find ( string.lower ( itemName ) , query , 1 , true ) then
                    match = true;
                else
                    -- Also search inside the notes themselves!
                    for i = 1 , #data do
                        if string.find ( string.lower ( data[i] ) , query , 1 , true ) then
                            match = true;
                            break;
                        end
                    end
                end

                if match then
                    table.insert ( filteredItems , {
                        name = itemName ,
                        itemID = data.itemID ,
                        count = #data
                    } );
                end
            end
        end

        -- Sort Alphabetically by Item Name
        table.sort ( filteredItems , function ( a , b )
            return a.name < b.name;
        end );

        -- Hide existing rows
        for i = 1 , #rowFrames do
            rowFrames[i]:Hide();
        end

        -- Populate matching rows
        for i = 1 , #filteredItems do
            local item = filteredItems[i];
            local row = GetOrCreateRow ( i );

            row.itemName = item.name;
            row.itemID = item.itemID;
            row.countText:SetText ( "(" .. item.count .. ")" );

            if CIN.GUICurrentName == item.name then
                row.selectedTex:Show();
            else
                row.selectedTex:Hide();
            end

            -- Default icon & color while item info caches
            local icon = 134400; -- Question mark icon
            local r , g , b = 1 , 1 , 1;

            if item.itemID then
                local instantIcon = select ( 5 , C_Item.GetItemInfoInstant ( item.itemID ) );
                if instantIcon then
                    icon = instantIcon;
                end

                local quality = select ( 3 , C_Item.GetItemInfo ( item.itemID ) );
                if quality and C_Item.GetItemQualityColor then
                    r , g , b = C_Item.GetItemQualityColor ( quality );
                elseif quality and GetItemQualityColor then
                    r , g , b = GetItemQualityColor ( quality );
                end
            end

            row.icon:SetTexture ( icon );
            row.nameText:SetText ( item.name );
            row.nameText:SetTextColor ( r , g , b );
            row:Show();
        end

        CIN.ListScrollChild:SetHeight ( math.max ( 1 , #filteredItems * ROW_HEIGHT ) );
    end

    -- Initialize right pane in empty state
    CIN.SelectItemInGUI ( nil );

    ---------------------------------
    -- SCOPED KEYBOARD SHORTCUT HOOK
    ---------------------------------

    CIN.inCombat = InCombatLockdown();

    -- Listener frame only activates when GameTooltip is visible out of combat
    CIN.GUIFrameOnKeyPress = CreateFrame ( "Frame" , nil , UIParent );
    CIN.GUIFrameOnKeyPress:Hide();
    CIN.GUIFrameOnKeyPress:SetScript ( "OnKeyDown" , function ( self , key )
        if not CIN.inCombat then
            local shiftDown = IsShiftKeyDown();
            local ctrlDown  = IsControlKeyDown();
            local altDown   = IsAltKeyDown();

            if ( key == "A" ) and not shiftDown and ctrlDown and altDown then
                local name , itemID = CIN.GetItemNameAndID();

                if name then
                    CIN.GUIFrameOnKeyPress:SetPropagateKeyboardInput ( false );
                    CIN.ToggleGUI ( tostring ( name ) , itemID );
                else
                    CIN.GUIFrameOnKeyPress:SetPropagateKeyboardInput ( true );
                end
            else
                CIN.GUIFrameOnKeyPress:SetPropagateKeyboardInput ( true );
            end
        end
    end );

    -- Only listen for CTRL-ALT-A while GameTooltip is actually shown
    GameTooltip:HookScript ( "OnShow" , function()
        if not CIN.inCombat then
            CIN.GUIFrameOnKeyPress:Show();
        end
    end );

    GameTooltip:HookScript ( "OnHide" , function()
        if not CIN.inCombat then
            CIN.GUIFrameOnKeyPress:Hide();
        end
    end );

    -- PLAYER STATUS MAINTENANCE FOR INCOMBAT/OUTOFCOMBAT STATUS
    CIN.StatusChecking = CreateFrame ( "Frame" , nil , UIParent );
    CIN.StatusChecking:RegisterEvent ( "PLAYER_REGEN_ENABLED" );
    CIN.StatusChecking:RegisterEvent ( "PLAYER_REGEN_DISABLED" );
    CIN.StatusChecking:SetScript ( "OnEvent" , function ( _ , event )
        if event == "PLAYER_REGEN_ENABLED" then
            CIN.inCombat = false;
            if GameTooltip:IsShown() then
                CIN.GUIFrameOnKeyPress:Show();
            end
        elseif event == "PLAYER_REGEN_DISABLED" then
            CIN.inCombat = true;
            CIN.GUIFrameOnKeyPress:Hide();
        end
    end );

end

-- Initialize the first frames as game is being loaded.
CIN.Initialization = CreateFrame ( "Frame" );
CIN.Initialization:RegisterEvent ( "ADDON_LOADED" );
CIN.Initialization:SetScript ( "OnEvent" , CIN.ActivateAddon );