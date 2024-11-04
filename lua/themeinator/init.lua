local M = {}

local ui = require("themeinator.ui")
local thememan = require("themeinator.thememan")
local util = require("themeinator.util")
local config_path = "/home/f/.config/nvim/lua/themeinator/config.lua"

-- Default configuration
local config = {
    themes_directory = "$HOME/.config/nvim/colors/", -- Default themes directory
    last_selected_theme_file = "",                   -- Store the last selected theme
    config_path = "/home/f/.config/nvim/lua/themeinator/config.lua"
}

function M.read_config()
    local ok, user_config = pcall(dofile, config_path)
    if ok and type(user_config) == "table" then
        config = vim.tbl_extend("force", config, user_config)
    else
        vim.notify("config not found at: " .. config_path, vim.log.levels.ERROR)
    end
end

function M.get_config()
    return config
end

M.read_config()
thememan.apply_theme(config, config.config_path, config.last_selected_theme_file)
local items = thememan.read_themes_from_directory(config)
function M.open_window()
    ui.open_window(items)
end

return M
