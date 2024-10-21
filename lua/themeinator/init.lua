local M = {}

-- Default configuration
local config = {
    themes_directory = "~/.config/nvim/themes",  -- Default themes directory
}

-- List of items (themes) to display in the window
local items = {}
local selected_item = 1
local buf, win_id

-- Function to read the configuration file
local function read_config()
    -- Path to the user's config file for Themenator (e.g., ~/.config/nvim/lua/themenator/config.lua)
    local user_config_path = vim.fn.stdpath('config') .. "/lua/themenator/config.lua"
    local ok, user_config = pcall(dofile, user_config_path)

    if ok and type(user_config) == "table" then
        -- Merge user config into the default config
        config = vim.tbl_extend("force", config, user_config)
    else
        print("No valid Themenator config found. Using default configuration.")
    end
end

-- Function to read the themes from the directory
local function read_themes_from_directory()
    local dir = vim.fn.expand(config.themes_directory)  -- Expand tilde to full path

    -- Check if the directory exists
    if vim.fn.isdirectory(dir) == 0 then
        print("Themes directory does not exist: " .. dir)
        return
    end

    -- Get the list of files/directories in the themes directory
    local theme_files = vim.fn.readdir(dir)

    -- Populate the items list with the theme names
    items = {}
    for _, file in ipairs(theme_files) do
        table.insert(items, file)
    end

    -- Ensure there's at least one item to select
    if #items == 0 then
        table.insert(items, "No themes found.")
    end
end

-- Function to update the list in the buffer, highlighting the selected item
local function update_window()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})  -- Clear buffer content
    for i, item in ipairs(items) do
        if i == selected_item then
            vim.api.nvim_buf_add_highlight(buf, -1, "Visual", i - 1, 0, -1)  -- Highlight selected item
        else
            vim.api.nvim_buf_add_highlight(buf, -1, "Normal", i - 1, 0, -1)
        end
        vim.api.nvim_buf_set_lines(buf, i - 1, i, false, { item })
    end
end

-- Function to open the floating window with the selectable list of themes
function M.open_window()
    -- Read the config and themes directory
    read_config()
    read_themes_from_directory()

    -- Create a new buffer (false for listed, true for scratch)
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)  -- Buffer is modifiable

    -- Get the editor dimensions
    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")

    -- Define window size (50% of width, 30% of height)
    local win_width = math.ceil(width * 0.5)
    local win_height = math.ceil(height * 0.3)

    -- Center the window on the screen
    local row = math.ceil((height - win_height) / 2)
    local col = math.ceil((width - win_width) / 2)

    -- Open the floating window
    win_id = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        style = "minimal", -- Minimal UI
        border = "rounded" -- Rounded border
    })

    -- Update the buffer with the items (themes) list
    update_window()

    -- Set key mappings for navigating and selecting
    vim.api.nvim_buf_set_keymap(buf, "n", "j", ":lua require('themenator').move_down()<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, "n", "k", ":lua require('themenator').move_up()<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", ":lua require('themenator').select_item()<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })

    -- Set highlight for the floating window
    vim.api.nvim_win_set_option(win_id, 'winhl', 'Normal:NormalFloat,FloatBorder:FloatBorder')

    -- Custom highlight colors
    vim.cmd [[
        highlight NormalFloat guibg=#1e222a
        highlight FloatBorder guifg=#5e81ac guibg=#1e222a
    ]]
end

-- Function to move the selection down
function M.move_down()
    if selected_item < #items then
        selected_item = selected_item + 1
        update_window() -- Update window to reflect the new selection
    end
end

-- Function to move the selection up
function M.move_up()
    if selected_item > 1 then
        selected_item = selected_item - 1
        update_window() -- Update window to reflect the new selection
    end
end

-- Function to handle selecting the current item
function M.select_item()
    -- Close the window and print the selected option
    vim.api.nvim_win_close(win_id, true)
    print("You selected: " .. items[selected_item])
end

return M

