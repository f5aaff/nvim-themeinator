local M = {}

-- Default configuration
local config = {
    themes_directory = "$HOME/.config/nvim/after/colors/", -- Default themes directory
    last_selected_theme_file = "",                  -- Store the last selected theme
}

-- List of themes (items) to display in the window
local items = {}
local selected_item = 1
local buf, win_id

-- Function to add a folder to the runtime path
local function add_folder_to_runtimepath(folder_path)
    -- Expand the folder path to handle things like ~
    local full_path = vim.fn.expand(folder_path)

    -- Check if the directory exists
    if vim.fn.isdirectory(full_path) == 0 then
        vim.notify("Directory does not exist: " .. full_path, vim.log.levels.ERROR)
        return false
    end

    -- Add the folder to Neovim's runtime path
    vim.opt.runtimepath:append(full_path)
    vim.notify("Added to runtimepath: " .. full_path)

    return true
end

-- Function to read the configuration file
local function read_config()
    local user_config_path = vim.fn.stdpath('config') .. "/lua/themeinator/config.lua"
    local ok, user_config = pcall(dofile, user_config_path)

    if ok and type(user_config) == "table" then
        config = vim.tbl_extend("force", config, user_config)
    end
end

-- Function to read the themes from the directory
local function read_themes_from_directory()
    local dir = vim.fn.expand(config.themes_directory)

    if vim.fn.isdirectory(dir) == 0 then
        print("Themes directory does not exist: " .. dir)
        return
    end

    local theme_files = vim.fn.readdir(dir)
    add_folder_to_runtimepath(config.themes_directory)
    items = {}
    for _, file in ipairs(theme_files) do
        table.insert(items, file)
        vim.opt.runtimepath:append(file)
    end

    if #items == 0 then
        table.insert(items, "No themes found.")
    end
end


-- Function to evaluate and load the colorscheme if it matches a file in the folder
local function apply_theme(colorscheme_name)
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
            local path = full_path .. file
            local name = file:match("^(.*)%.%w+$")
            local extension = file:match("^.+(%..+)$")
            if extension == "vim" then
                vim.notify("colorscheme set: " .. name)
                return true
                --vim.cmd("colorscheme " .. name)
                --return true
            end
            local ok, err = pcall(dofile, path)
            if not ok then
                vim.notify("Error loading theme: " .. err, vim.log.levels.ERROR)
                return false
            end
            config.last_selected_theme_file = path
            local theme_to_apply = colorscheme_name:gsub("%.lua$", "")
            vim.cmd("colorscheme " .. theme_to_apply)

            vim.notify("Colorscheme set: " .. name)
            return true
        end
    end

    -- If no matching file is found
    vim.notify("Colorscheme not found: " .. colorscheme_name, vim.log.levels.WARN)
    return false
end

-- Function to load the last saved theme on startup
local function load_last_theme()
    local ok, last_theme = pcall(dofile, config.last_selected_theme_file)
    if ok and (last_theme ~= "") then
        apply_theme(last_theme)
    else
        print("No saved theme found, loading default theme.")
    end
end


-- Function to update the window to reflect the currently selected item
local function update_window()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, items) -- Refresh the theme list

    -- Clear previous highlighting
    vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)

    -- Highlight the selected item
    vim.api.nvim_buf_add_highlight(buf, -1, "Visual", selected_item - 1, 0, -1)
end

-- Function to move the selection down
function M.move_down()
    if selected_item < #items then
        selected_item = selected_item + 1
        update_window() -- Ensure the window is updated when moving down
    end
end

-- Function to move the selection up
function M.move_up()
    if selected_item > 1 then
        selected_item = selected_item - 1
        update_window() -- Ensure the window is updated when moving up
    end
end

-- Function to select and apply the current theme
function M.select_item()
    vim.api.nvim_win_close(win_id, true)
    apply_theme(items[selected_item])
end

-- Function to open the floating window with the selectable list of themes
function M.open_window()
    read_config()
    read_themes_from_directory()

    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)

    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")

    local win_width = math.ceil(width * 0.5)
    local win_height = math.ceil(height * 0.3)

    local row = math.ceil((height - win_height) / 2)
    local col = math.ceil((width - win_width) / 2)

    win_id = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded"
    })

    update_window()

    vim.api.nvim_buf_set_keymap(buf, "n", "j", ":lua require('themeinator').move_down()<CR>",
        { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, "n", "<DOWN>", ":lua require('themeinator').move_down()<CR>",
        { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, "n", "k", ":lua require('themeinator').move_up()<CR>",
        { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, "n", "<UP>", ":lua require('themeinator').move_up()<CR>",
        { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", ":lua require('themeinator').select_item()<CR>",
        { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })

    vim.api.nvim_win_set_option(win_id, 'winhl', 'Normal:NormalFloat,FloatBorder:FloatBorder')

    vim.cmd [[
        highlight NormalFloat guibg=#1e222a
        highlight FloatBorder guifg=#5e81ac guibg=#1e222a
    ]]
end

-- Load the last saved theme when Neovim starts
function M.load_last_theme_on_startup()
    load_last_theme()
end

-- Load the last saved theme automatically
M.load_last_theme_on_startup()

return M
