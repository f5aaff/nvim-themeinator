local M = {}
local util = require("themeinator.util")

-- Function to read the themes from the directory
function M.read_themes_from_directory(config)
    local items = {}
    local dir = vim.fn.expand(config.themes_directory)


    if vim.fn.isdirectory(dir) == 0 then
        print("Themes directory does not exist: " .. dir)
        return items -- Return empty items if directory does not exist
    end

    local theme_files = vim.fn.readdir(dir)

    -- Ensure the directory is added to runtimepath
    util.add_folder_to_runtimepath(dir)

    -- Loop through each theme file
    for _, file in ipairs(theme_files) do
        table.insert(items, file)
        vim.opt.runtimepath:append(file) -- Make sure file path is correct
    end

    -- Add a fallback message if no themes were found
    if #items == 0 then
        table.insert(items, "No themes found.")
    end

    return items
end

function M.get_known_themes(config)
    local kt_path = vim.fn.expand(config.known_themes)
    local known_themes = util.decode_json_file(kt_path)
    if known_themes then
        vim.notify(known_themes.Themes_list[1].name,vim.log.levels.INFO)
        return known_themes
    else
        return nil
    end
end

-- Function to evaluate and load the colorscheme if it matches a file in the folder
function M.apply_theme(config, config_path, colorscheme_name)
    -- Expand the folder path
    local folder_path = config.themes_directory
    local full_path = vim.fn.expand(folder_path)
    -- Check if the directory exists
    if vim.fn.isdirectory(full_path) == 0 then
        vim.notify("Directory does not exist: " .. full_path, vim.log.levels.ERROR)
        return false
    end
    -- Get the list of theme files in the directory
    local theme_files = vim.fn.readdir(full_path)

    -- Loop through the theme files and match the provided colorscheme name
    for _, file in ipairs(theme_files) do
        -- If the colorscheme name matches the file
        if colorscheme_name == file then
            local name = file:match("^(.*)%.%w+$")
            local extension = file:match("^.+(%..+)$")
            if extension == ".vim" then
                vim.cmd("colorscheme " .. name)
                config.last_selected_theme_file = name .. extension
                local user_config_path = config_path
                util.save_table_to_file(config, user_config_path)
                return true
            end
        end
    end

    -- If no matching file is found
    vim.notify("Colorscheme not found: " .. colorscheme_name, vim.log.levels.WARN)
    return false
end

return M
