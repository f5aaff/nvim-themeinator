local M = {}
local util = require("themeinator.util")

-- Function to read the themes from the directory
function M.read_themes_from_directory(config)
    local items = {}
    local dir = vim.fn.expand(config.themes_directory)
    local known_themes = M.get_known_themes(config)

    if vim.fn.isdirectory(dir) == 0 then
        print("Themes directory does not exist: " .. dir)
        return items -- Return empty items if directory does not exist
    end

    local theme_files = vim.fn.readdir(dir)
    util.add_folder_to_runtimepath(dir)

    for _, file in ipairs(theme_files) do
        local theme_name = file:match("^(.*)%.%w+$")
        local theme_info = known_themes and known_themes.Themes[theme_name] or {}
        local status = string.format("%s (Downloaded: %s, Known: %s)",
            theme_name,
            theme_info.downloaded and "Yes" or "No",
            theme_info.known and "Yes" or "No")
        table.insert(items, status)
    end

    if #items == 0 then
        table.insert(items, "No themes found.")
    end

    return items
end

function M.get_known_themes(config)
    local kt_path = vim.fn.expand(config.known_themes)
    local known_themes = util.decode_json_file(kt_path)
    if known_themes then
        vim.notify(known_themes.Themes_list[1].name, vim.log.levels.INFO)
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
        colorscheme_name = colorscheme_name:gsub("%s.*", "")
        if not colorscheme_name:match("%.vim$") then
            colorscheme_name = colorscheme_name .. ".vim" -- Append ".vim" if it doesn't already end with it
        end
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

function M.download_theme(theme)
    vim.notify("theme:" .. theme.name .. "link:" .. theme.link, vim.log.levels.INFO)
    local handle = io.popen("./themeinator download " .. theme.name)
    local result = handle:read("*a") -- Read the output
    handle:close()

    print(result)
end

return M
