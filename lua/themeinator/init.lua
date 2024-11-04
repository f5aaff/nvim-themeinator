local M = {}

local ui = require("themeinator.ui")
local thememan = require("themeinator.thememan")
local util = require("themeinator.util")


-- Default configuration
local config = {
    themes_directory = "$HOME/.config/nvim/colors/", -- Default themes directory
    last_selected_theme_file = "",                         -- Store the last selected theme
}

util.add_folder_to_runtimepath("$HOME/.config/nvim/lua/themeinator/")
print("INIT:"..config.themes_directory)
util.add_folder_to_runtimepath(config.themes_directory)
local items = thememan.read_themes_from_directory(config)
thememan.load_last_theme(config)
--ui.open_window("",items,config)
return M
