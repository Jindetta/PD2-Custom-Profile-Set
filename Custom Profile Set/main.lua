local default_value, user, this = 15, Steam:userid(), {
    name = "menu_custom_profile_sets_id",
    description = "menu_custom_profile_sets_desc",

    profile_name = "item_custom_profile_sets_profile_id",
    profile_description = "item_custom_profile_sets_profile_desc",

    skills_name = "item_custom_profile_sets_skills_id",
    skills_description = "item_custom_profile_sets_skills_desc",

    input_name = "item_custom_profile_sets_input_id",
    input_description = "item_custom_profile_sets_input_desc",

    rearrange_name = "item_custom_profile_sets_rearrange_id",
    rearrange_description = "item_custom_profile_sets_rearrange_desc",

    masks_name = "item_custom_profile_sets_masks_id",
    masks_description = "item_custom_profile_sets_masks_desc",

    weapons_name = "item_custom_profile_sets_weapons_id",
    weapons_description = "item_custom_profile_sets_weapons_desc",

    save_name = "item_custom_profile_sets_save_id",
    save_description = "item_custom_profile_sets_save_desc",

    reset_name = "item_custom_profile_sets_reset_id",
    reset_description = "item_custom_profile_sets_reset_desc",

    dialog_saved = "dialog_custom_profile_sets_saved_desc",
    dialog_launch = "dialog_custom_profile_sets_launch_desc",
    dialog_rearrange = "dialog_custom_profile_sets_rearrange_desc",
    dialog_continue = "dialog_custom_profile_sets_option_continue",
    dialog_setup = "dialog_custom_profile_sets_option_setup",
    dialog_skip = "dialog_custom_profile_sets_option_skip",

    skill_menu_name = "dialog_custom_profile_sets_skill_menu_id",
    skill_menu_description = "dialog_custom_profile_sets_skill_menu_desc",

    skill_menu_copy = "dialog_custom_profile_sets_skill_menu_copy",
    skill_menu_paste = "dialog_custom_profile_sets_skill_menu_paste",
    skill_menu_swap = "dialog_custom_profile_sets_skill_menu_swap",
    skill_menu_respec = "dialog_custom_profile_sets_skill_menu_respec",
    skill_menu_cancel = "dialog_custom_profile_sets_skill_menu_cancel",

    requirements_text = "text_custom_profile_sets_requirements",

    default_profiles_limit = 0,
    default_skillsets_limit = 0,
    default_max_input_limit = 20,
    default_inventory_pages = 0,

    min_setup_value = 0,
    max_setup_value = 50,
    min_input_value = 15,
    max_input_value = 50
}

CustomProfileSet = CustomProfileSet or {}
CustomProfileSet._lang = ModPath .. "localization/"
CustomProfileSet._path = SavePath .. "profiles_data.json"

function CustomProfileSet:IsInit()
    self._data = self._data or {}
    self._data[user] = self._data[user] or {}

    if not self._loaded then
        self._loaded = true
        self:Load()

        local setup_data = self._data[user] and self._data[user].setup
        self.custom_profiles = setup_data and setup_data.profiles or this.default_profiles_limit
        self.custom_skill_sets = setup_data and setup_data.skillsets or this.default_skillsets_limit
        self.custom_input_limit = setup_data and setup_data.max_input or this.default_max_input_limit
        self.custom_mask_pages = setup_data and setup_data.mask_pages or this.default_inventory_pages
        self.custom_weapon_pages = setup_data and setup_data.weapon_pages or this.default_inventory_pages
        self._is_rearrange = self.custom_skill_sets == self.custom_profiles

        if not Global.__coresetup_bootdone and not setup_data then
            Hooks:Add( "MenuManagerOnOpenMenu", "CPS_MenuManager_OnOpenMenu", function( _, name )
                if not this._setup and self._loaded and name == "menu_main" then
                    DelayedCalls:Add( this.name, 1, function()
                        QuickMenu:new(
                            managers.localization:text( this.name ),
                            managers.localization:text( this.dialog_launch ),
                            {
                                {
                                    text = managers.localization:text( this.dialog_setup ),
                                    callback = function()
                                        managers.menu:open_node( this.name )
                                    end
                                },
                                {
                                    text = managers.localization:text( this.dialog_skip ),
                                    is_cancel_button = true
                                }
                            },
                            true
                        )
                    end)

                    this._setup = true
                end
            end)
        end
    end

    return self._loaded and self._data[user] and type( self._data[user].setup ) == "table"
end

function CustomProfileSet:Save()
    local f = io.open( self._path, "w+" )
    if type( f ) == "userdata" then
        local data = json.encode( self._data )
        f:write( ( data:gsub( "%[%]", "{}" ) ) )

        f:close()
    end
end

function CustomProfileSet:Load()
    local f = io.open( self._path, "r" )
    if type( f ) == "userdata" then
        local valid, data = pcall( json.decode, f:read( "*a" ) )
        if valid and type( data ) == "table" then
            self._data = data
        end

        f:close()
    end
end

function CustomProfileSet:Language()
    local language, blt_supported = "", {
        "english", "german", "french", "russian", "turkish", "indonesian", "chinese"
    }

    for key, name in ipairs( file.GetFiles( self._lang ) or {} ) do
        key = name:gsub( "%.txt$", "" ):lower()
        local is_system = SystemInfo:language():key() == key:key()
        local is_blt = blt_supported[LuaModManager:GetLanguageIndex()] == key

        if is_blt or ( is_system and key ~= "english" ) then
            language = self._lang .. name
            if is_system then break end
        end
    end

    return language
end

function CustomProfileSet:SetupHooks()
    if self:IsInit() then
        if RequiredScript == "lib/managers/multiprofilemanager" then
            Hooks:PostHook( MultiProfileManager, "save", "CPS_ProfileManager_Save", function( gd )
                self._data[user].profiles = {}
                if self.custom_profiles > this.min_setup_value then
                    for i = default_value + 1, default_value + self.custom_profiles do
                        table.insert( self._data[user].profiles, gd._global._profiles[i] )
                    end
                end

                self._data[user].current_profile = gd._global._current_profile or 1
                self:Save()
            end)

            Hooks:PostHook( MultiProfileManager, "load", "CPS_ProfileManager_Load", function( gd, data )
                if type( self._data[user].profiles ) == "table" then
                    for i, profile in ipairs( self._data[user].profiles ) do
                        if i > self.custom_profiles then break end
                        if not gd._global._profiles[default_value + i] then
                            gd:_add_profile( profile, default_value + i )
                        end
                    end

                    gd._global._current_profile = self._data[user].current_profile or data.multi_profile.current_profile
                    gd:_check_amount()
                end
            end)

            function MultiProfileManager._check_amount( gd )
                local limit = default_value + self.custom_profiles
                if not gd:current_profile() then
                    gd:save_current()
                end

                if limit < gd:profile_count() then
                    table.crop( gd._global._profiles, limit )
                    gd._global._current_profile = math.min( gd._global._current_profile, limit )
                elseif limit > gd:profile_count() then
                    local prev_current = gd._global._current_profile
                    gd._global._current_profile = gd:profile_count()

                    while limit > gd._global._current_profile do
                        gd._global._current_profile = gd._global._current_profile + 1
                        gd:save_current()
                    end

                    gd._global._current_profile = prev_current
                end
            end
        elseif RequiredScript == "lib/managers/skilltreemanager" then
            Hooks:PostHook( SkillTreeManager, "save", "CPS_SkillManager_Save", function( gd )
                self._data[user].skill_sets = {}
                if self.custom_skill_sets > this.min_setup_value then
                    for i = default_value + 1, default_value + self.custom_skill_sets do
                        table.insert( self._data[user].skill_sets, gd._global.skill_switches[i] )
                    end
                end

                self._data[user].current_skillset = gd._global.selected_skill_switch or 1
                self:Save()
            end)

            Hooks:PostHook( SkillTreeManager, "load", "CPS_SkillManager_Load", function( gd, data )
                if type( self._data[user].skill_sets ) == "table" then
                    local lock_additional_skillsets = gd:default_skillsets_locked()
                    for i, skill_set in ipairs( self._data[user].skill_sets ) do
                        if i > self.custom_skill_sets then break end
                        if not gd._global.skill_switches[default_value + i] then
                            if lock_additional_skillsets then skill_set.unlocked = false end
                            gd._global.skill_switches[default_value + i] = skill_set
                        end
                    end

                    gd._global.selected_skill_switch = self._data[user].current_skillset or data.SkillTreeManager.selected_skill_switch
                end
            end)

            local _unlock = SkillTreeManager.can_unlock_skill_switch
            function SkillTreeManager:can_unlock_skill_switch( selected )
                if selected > default_value and self:default_skillsets_locked() then
                    return false, { "_" }
                end

                return _unlock( self, selected )
            end

            function SkillTreeManager:default_skillsets_locked()
                for i = 2, default_value do
                    if not self._global.skill_switches[i].unlocked then
                        return true
                    end
                end

                return false
            end

            function SkillTreeManager:_update_skill_set( index, new_index, skill_set )
                skill_set = skill_set and deep_clone( skill_set )
                index = index or self:get_selected_skill_switch()

                if not skill_set then
                    skill_set = self._global.skill_switches[index]
                    local points, trees = self:digest_value( skill_set.points, false ), {}

                    for tree in pairs( tweak_data.skilltree.trees ) do
                        points = points + self:digest_value( skill_set.trees[tree].points_spent, false )
                        trees[tree] = { unlocked = true, points_spent = self:digest_value( 0, true ) }
                    end

                    skill_set.name = nil
                    skill_set.trees = trees
                    skill_set.points = self:digest_value( points, true )
                    skill_set.skills = {}

                    for skill, data in pairs( tweak_data.skilltree.skills ) do
                        skill_set.skills[skill] = { unlocked = 0, total = #data }
                    end
                end

                if self:get_selected_skill_switch() == index then
                    self._global.trees = skill_set.trees
                    self._global.skills = skill_set.skills
                    self._global.points = skill_set.points
                end

                self._global.skill_switches[index] = skill_set
                self._global.selected_skill_switch = new_index or index

                MenuCallbackHandler:_update_outfit_information()
            end
        elseif RequiredScript == "lib/managers/menu/renderers/menunodeskillswitchgui" then
            Hooks:PostHook( MenuNodeSkillSwitchGui, "_create_menu_item", "CPS_SkillSwitchGui_CreateMenuItem", function( _, item )
                local gui = item.skill_points_gui
                if gui and gui:text() == managers.localization:to_upper_text( "menu_st_requires_skill_switch", { reasons = "" } ) then
                    gui:set_text( gui:text() .. managers.localization:to_upper_text( this.requirements_text ) )
                end
            end)

            Hooks:PostHook( MenuNodeSkillSwitchGui, "mouse_pressed", "CPS_SkillSwitchGui_MousePressed", function( gui, button, x, y )
                local item = gui:row_item( gui._highlighted_item )
                if item and item.gui_panel and item.gui_panel:inside( x, y ) then
                    if button == ( "1" ):id() and tostring( item.name ):find( "^%d+$" ) then
                        gui:open_item_menu( item.name )
                    end
                end
            end)

            function MenuNodeSkillSwitchGui:open_item_menu( index )
                local skill_set = Global.skilltree_manager.skill_switches[index]

                if skill_set and skill_set.unlocked then
                    local selected = Global.skilltree_manager.selected_skill_switch
                    local perk_deck = Application:digest_value( skill_set.specialization, false )

                    local menu = QuickMenu:new(
                        managers.localization:text( this.skill_menu_name, { name = managers.skilltree:get_skill_switch_name( index, true ) } ),
                        managers.localization:text( this.skill_menu_description, { name = managers.localization:text( tweak_data.skilltree.specializations[perk_deck].name_id ) } ),
                        {
                            {
                                text = managers.localization:text( this.skill_menu_copy ),
                                callback = function()
                                    this._cache = deep_clone( skill_set )
                                end
                            },
                            {
                                text = managers.localization:text( this.skill_menu_paste ),
                                callback = function()
                                    if type( this._cache ) == "table" then
                                        managers.skilltree:_update_skill_set( index, selected, this._cache )
                                    end
                                end
                            },
                            {
                                text = managers.localization:text( this.skill_menu_swap ),
                                callback = function()
                                    local cache = Global.skilltree_manager.skill_switches[selected]
                                    Global.skilltree_manager.skill_switches[selected] = skill_set
                                    managers.skilltree:_update_skill_set( index, nil, cache )
                                end
                            },
                            {
                                text = managers.localization:text( this.skill_menu_respec ),
                                callback = function()
                                    managers.skilltree:_update_skill_set( index, selected )
                                end
                            },
                            {
                                text = managers.localization:text( this.skill_menu_cancel ),
                                is_cancel_button = true
                            }
                        }
                    )

                    if index == selected then
                        table.remove( menu.dialog_data.button_list, 3 )
                    end

                    if type( this._cache ) ~= "table" then
                        table.remove( menu.dialog_data.button_list, 2 )
                    end

                    menu:Show()

                    menu = managers.menu:active_menu()
                    if menu and menu.logic then
                        menu.logic:refresh_node()
                    end
                end
            end
        elseif RequiredScript == "lib/tweak_data/skilltreetweakdata" then
            Hooks:PostHook( SkillTreeTweakData, "init", "CPS_SkillTweakData_Init", function( td )
                if self.custom_skill_sets > this.min_setup_value then
                    for i = default_value + 1, default_value + self.custom_skill_sets do
                        td.skill_switches[i] = { name_id = td.skill_switches[1].name_id:gsub( "1", i ) }
                    end
                end
            end)
        elseif RequiredScript == "lib/tweak_data/guitweakdata" then
            Hooks:PostHook( GuiTweakData, "init", "CPS_GuiTweakData_Init", function( td )
                td.rename_max_letters = self.custom_input_limit or 20
                td.rename_skill_set_max_letters = self.custom_input_limit or 15

                td.MAX_MASK_PAGES = td.MAX_MASK_PAGES + ( self.custom_mask_pages or 0 )
                td.MAX_MASK_SLOTS = td.MAX_MASK_PAGES * td.MASK_ROWS_PER_PAGE * td.MASK_COLUMNS_PER_PAGE

                td.MAX_WEAPON_PAGES = td.MAX_WEAPON_PAGES + ( self.custom_weapon_pages or 0 )
                td.MAX_WEAPON_SLOTS = td.MAX_WEAPON_PAGES * td.WEAPON_ROWS_PER_PAGE * td.WEAPON_COLUMNS_PER_PAGE
            end)
        elseif RequiredScript == "lib/managers/menu/multiprofileitemgui" then
            Hooks:PostHook( MultiProfileItemGui, "init", "CPS_ProfileItemGui_Init", function( td )
                td._max_length = self.custom_input_limit or 15
            end)
        end
    end

    Hooks:Add( "LocalizationManagerPostInit", "CPS_LocalizationManager_PostInit", function( manager )
        local localization_strings = {
            [this.name] = "Custom Profile Set",
            [this.description] = "Change \"Custom Profile Set\" settings.",

            [this.profile_name] = "Number of additional profiles",
            [this.profile_description] = "Additional profiles limit.\nIncreasing this number will grow \"configuration\" filesize.",

            [this.skills_name] = "Number of additional skill sets",
            [this.skills_description] = "Additional skill sets limit.\nIncreasing this number will grow \"configuration\" filesize.",

            [this.input_name] = "Number of allowed input characters",
            [this.input_description] = "Maximum number of allowed input characters.\nApplies to weapon, skill set and profile names.",

            [this.masks_name] = "Number of additional mask pages",
            [this.masks_description] = "Additional mask pages limit.\nAll masks are stored in in-game savefile.",

            [this.weapons_name] = "Number of additional weapon pages",
            [this.weapons_description] = "Additional weapon pages limit.\nAll weapons are stored in in-game savefile.",

            [this.rearrange_name] = "Rearrange profile data (skill set)",
            [this.rearrange_description] = "Adjust each profile (#n) to its corresponding skill set (#n).",

            [this.save_name] = "Save values",
            [this.save_description] = "Save configuration.\nChanges are applied only after the game is restarted.",

            [this.reset_name] = "Reset values",
            [this.reset_description] = "Reset values back to default.\nThis does not save configuration.",

            [this.dialog_saved] = "All settings saved.\n\nRestart the game for settings to take effect.",
            [this.dialog_launch] = "Setup is required.\nIf you skip this step then, mod is disabled until setup is completed.",
            [this.dialog_rearrange] = "Warning: These changes are irreversible.\nAll profiles will be adjusted to their corresponding skill sets.",
            [this.dialog_continue] = "Continue",
            [this.dialog_setup] = "Setup now",
            [this.dialog_skip] = "Skip",

            [this.skill_menu_name] = "Skill set: $name",
            [this.skill_menu_description] = "Perk Deck: $name",

            [this.skill_menu_copy] = "Copy",
            [this.skill_menu_paste] = "Paste",
            [this.skill_menu_swap] = "Swap active",
            [this.skill_menu_respec] = "Respec",
            [this.skill_menu_cancel] = "Cancel",

            [this.requirements_text] = "All default skill sets must be unlocked first",
        }

        if self.custom_skill_sets > this.min_setup_value then
            local name = tweak_data.skilltree.skill_switches[1].name_id
            local text = manager:text( name ) or localization_strings[this.name]

            for i = default_value + 1, default_value + self.custom_skill_sets do
                localization_strings[name:gsub( "1", i )] = text:gsub( "1", i )
            end
        end

        manager:add_localized_strings( localization_strings )
        manager:load_localization_file( self:Language() )
    end)

    Hooks:Add( "MenuManagerSetupCustomMenus", "CPS_MenuManager_CustomMenus", function()
        MenuHelper:NewMenu( this.name )

        this._values_storage = {
            profiles = self.custom_profiles,
            skillsets = self.custom_skill_sets,
            max_input = self.custom_input_limit,
            mask_pages = self.custom_mask_pages,
            weapon_pages = self.custom_weapon_pages
        }

        MenuCallbackHandler[this.name] = function( _, item )
            local name, value = item:name(), function()
                return ( math.modf( item:value() ) )
            end

            if name == this.profile_name then
                this._values_storage.profiles = value()
            elseif name == this.skills_name then
                this._values_storage.skillsets = value()
            elseif name == this.input_name then
                this._values_storage.max_input = value()
            elseif name == this.masks_name then
                this._values_storage.mask_pages = value()
            elseif name == this.weapons_name then
                this._values_storage.weapon_pages = value()
            elseif name == this.save_name then
                self._data[user].setup = {
                    profiles = this._values_storage.profiles,
                    skillsets = this._values_storage.skillsets,
                    max_input = this._values_storage.max_input,
                    mask_pages = this._values_storage.mask_pages,
                    weapon_pages = this._values_storage.weapon_pages
                }

                self:Save()
                managers.savefile:save_progress()
                managers.menu:back()

                QuickMenu:new(
                    managers.localization:text( this.name ),
                    managers.localization:text( this.dialog_saved ),
                    {}, true
                )
            elseif name == this.rearrange_name then
                QuickMenu:new(
                    managers.localization:text( this.rearrange_name ),
                    managers.localization:text( this.dialog_rearrange ),
                    {
                        {
                            text = managers.localization:text( this.dialog_continue ),
                            callback = function()
                                Global.skilltree_manager.selected_skill_switch = Global.multi_profile._current_profile
                                for profile_id, profile_data in ipairs( Global.multi_profile._profiles ) do
                                    profile_data.skillset = profile_id
                                end
                            end
                        },
                        {
                            text = managers.localization:text( this.dialog_skip ),
                            is_cancel_button = true
                        }
                    },
                    true
                )
            elseif name == this.reset_name then
                local setup_data = {
                    [this.profile_name] = { _ = "profiles", v = this.default_profiles_limit },
                    [this.skills_name] = { _ = "skillsets", v = this.default_skillsets_limit },
                    [this.input_name] = { _ = "max_input", v = this.default_max_input_limit },
                    [this.masks_name] = { _ = "mask_pages", v = this.default_inventory_pages },
                    [this.weapons_name] = { _ = "weapon_pages", v = this.default_inventory_pages }
                }

                for k, v in ipairs( self.node._items ) do
                    if setup_data[v:name()] then
                        k = setup_data[v:name()]
                        this._values_storage[k._] = k.v
                        v:set_value( k.v )
                        v:reload()
                    end
                end
            end
        end
    end)

    Hooks:Add( "MenuManagerPopulateCustomMenus", "CPS_MenuManager_PopulateCustomMenus", function()
        MenuHelper:AddSlider(
            {
                priority = 11,
                callback = this.name,
                id = this.profile_name,
                title = this.profile_name,
                desc = this.profile_description,
                value = self.custom_profiles,
                min = this.min_setup_value,
                max = this.max_setup_value,
                menu_id = this.name
            }
        )
        MenuHelper:AddSlider(
            {
                priority = 10,
                callback = this.name,
                id = this.skills_name,
                title = this.skills_name,
                desc = this.skills_description,
                value = self.custom_skill_sets,
                min = this.min_setup_value,
                max = this.max_setup_value,
                menu_id = this.name
            }
        )
        MenuHelper:AddDivider(
            {
                size = 4,
                priority = 9,
                menu_id = this.name
            }
        )
        MenuHelper:AddSlider(
            {
                priority = 8,
                callback = this.name,
                id = this.input_name,
                title = this.input_name,
                desc = this.input_description,
                value = self.custom_input_limit,
                min = this.min_input_value,
                max = this.max_input_value,
                menu_id = this.name
            }
        )
        MenuHelper:AddDivider(
            {
                size = 4,
                priority = 7,
                menu_id = this.name
            }
        )
        MenuHelper:AddSlider(
            {
                priority = 6,
                callback = this.name,
                id = this.masks_name,
                title = this.masks_name,
                desc = this.masks_description,
                value = self.custom_mask_pages,
                min = this.min_setup_value,
                max = this.max_setup_value,
                menu_id = this.name
            }
        )
        MenuHelper:AddSlider(
            {
                priority = 5,
                callback = this.name,
                id = this.weapons_name,
                title = this.weapons_name,
                desc = this.weapons_description,
                value = self.custom_weapon_pages,
                min = this.min_setup_value,
                max = this.max_setup_value,
                menu_id = this.name
            }
        )
        MenuHelper:AddDivider(
            {
                priority = 4,
                menu_id = this.name
            }
        )
        MenuHelper:AddButton(
            {
                priority = 3,
                callback = this.name,
                id = this.rearrange_name,
                title = this.rearrange_name,
                desc = this.rearrange_description,
                menu_id = this.name
            }
        )
        MenuHelper:AddDivider(
            {
                priority = 2,
                menu_id = this.name
            }
        )
        MenuHelper:AddButton(
            {
                priority = 1,
                callback = this.name,
                id = this.save_name,
                title = this.save_name,
                desc = this.save_description,
                menu_id = this.name
            }
        )
        MenuHelper:AddButton(
            {
                priority = 0,
                callback = this.name,
                id = this.reset_name,
                title = this.reset_name,
                desc = this.reset_description,
                menu_id = this.name
            }
        )
    end)

    Hooks:Add( "MenuManagerBuildCustomMenus", "CPS_MenuManager_BuildCustomMenus", function( _, nodes )
        self.node = MenuHelper:BuildMenu( this.name )
        MenuHelper:AddMenuItem( nodes[LuaModManager.Constants._lua_mod_options_menu_id], this.name, this.name, this.description )
        nodes[this.name] = self.node

        for k, v in ipairs( self.node._items ) do
            if v._type == "slider" then
                v.reload = function( self, item )
                    local p = self:percentage() / 100
                    item = item or v._parameters.gui_node.row_items[k]
                    item.gui_slider_text:set_text( ( "#%d" ):format( self:value() ) )
                    item.gui_slider_marker:set_center_x( item.gui_slider:left() + item.gui_slider:w() * p )
                    item.gui_slider_gfx:set_w( item.gui_slider:w() * p )
                    return true
                end
            end

            v:set_enabled( self._is_rearrange and not nodes.pause or v:name() ~= this.rearrange_name )
        end
    end)
end

CustomProfileSet:SetupHooks()