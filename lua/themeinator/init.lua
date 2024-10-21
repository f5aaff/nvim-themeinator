local M = {}

-- Default configuration
local config = {
    themes_directory = "~/.config/nvim/themes",                                               -- Default themes directory
    last_selected_theme_file = vim.fn.stdpath('config') .. "~/.config/nvim/themes/catppuccin-mocha.vim", -- Store the last selected theme
}

-- List of themes (items) to display in the window
local items = {}
local selected_item = 1
local buf, win_id

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

    items = {}
    for _, file in ipairs(theme_files) do
        table.insert(items, file)
    end

    if #items == 0 then
        table.insert(items, "No themes found.")
    end
end

-- Function to apply a theme from the themes directory
local function apply_theme(theme_name)
    local theme_path = vim.fn.expand(config.themes_directory) .. "/" .. theme_name

    if vim.fn.isdirectory(theme_path) == 0 and vim.fn.filereadable(theme_path .. ".vim") == 0 then
        print("Theme not found: " .. theme_name)
        return
    end
    print(theme_path)
    -- Add the theme directory to runtimepath and apply the colorscheme
    vim.opt.rtp:append(theme_path)
    vim.cmd("colorscheme " .. theme_name)

    -- Save the selected theme to persist for next session
    local file = io.open(config.last_selected_theme_file, "w")
    if file then
        file:write("return '" .. theme_name .. "'\n")
        file:close()
        print("Theme applied and saved: " .. theme_name)
    else
        print("Failed to save the theme: " .. theme_name)
    end
end

-- Function to load the last saved theme on startup
local function load_last_theme()
    local ok, last_theme = pcall(dofile, config.last_selected_theme_file)
    if ok and last_theme then
        apply_theme(last_theme)
    else
        print("No saved theme found, loading default theme.")
    end
end

-- Function to update the list in the buffer, highlighting the selected item
local function update_window()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    for i, item in ipairs(items) do
        if i == selected_item then
            vim.api.nvim_buf_add_highlight(buf, -1, "Visual", i - 1, 0, -1)
        else
            vim.api.nvim_buf_add_highlight(buf, -1, "Normal", i - 1, 0, -1)
        end
        vim.api.nvim_buf_set_lines(buf, i - 1, i, false, { item })
    end
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
    vim.api.nvim_buf_set_keymap(buf, "n", "k", ":lua require('themeinator').move_up()<CR>",
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

-- Function to move the selection down
function M.move_down()
    if selected_item < #items then
        selected_item = selected_item + 1
        update_window()
    end
end

-- Function to move the selection up
function M.move_up()
    if selected_item > 1 then
        selected_item = selected_item - 1
        update_window()
    end
end

-- Function to select and apply the current theme
function M.select_item()
    vim.api.nvim_win_close(win_id, true)
    apply_theme(items[selected_item])
end

-- Load the last saved theme when Neovim starts
function M.load_last_theme_on_startup()
    load_last_theme()
end

-- Load the last saved theme automatically
M.load_last_theme_on_startup()

return M
