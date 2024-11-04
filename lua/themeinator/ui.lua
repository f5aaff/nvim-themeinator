local M = {}

local thememan = require('themeinator.thememan')
local util = require('themeinator.util')


local selected_item = 1
local buf, win_id

-- Function to open a floating input window for user input
function M.open_floating_input()
    -- Set dimensions and position for the floating window
    local width = 40
    local height = 3
    local row = math.floor((vim.o.lines - height) / 2 - 1)
    local col = math.floor((vim.o.columns - width) / 2)

    -- Create a buffer for the floating window
    buf = vim.api.nvim_create_buf(false, true) -- (listed, scratch)

    -- Configure the floating window options
    local opts = {
        style = "minimal",
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        border = "rounded",
    }

    -- Open the floating window with the buffer
    local win = vim.api.nvim_open_win(buf, true, opts)

    -- Set some options for the buffer
---@diagnostic disable-next-line: deprecated
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
---@diagnostic disable-next-line: deprecated
    vim.api.nvim_buf_set_option(buf, "modifiable", true)

    -- Set an initial prompt message
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Enter input:" })

    -- Capture input on Enter
    vim.api.nvim_buf_set_keymap(buf, 'n', '<CR>', [[:lua handle_input() <CR>]], { noremap = true, silent = true })

    -- Close the window if Esc is pressed
    vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', [[<Cmd>lua vim.api.nvim_win_close(0, true)<CR>]], { noremap = true, silent = true })

    -- Function to handle the input
    _G.handle_input = function()
        local input = vim.api.nvim_get_current_line()
        print("You entered:", input)  -- Handle input as needed
        vim.api.nvim_win_close(win, true) -- Close the floating window
    end
end

-- Function to update the window to reflect the currently selected item
local function update_window(items)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, items) -- Refresh the theme list

    -- Clear previous highlighting
    vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)

    -- Highlight the selected item
    vim.api.nvim_buf_add_highlight(buf, -1, "Visual", selected_item - 1, 0, -1)
end

local title_win_id
-- Function to close both main and title windows
function M.close_window()
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_close(win_id, true)
    end
    if title_win_id and vim.api.nvim_win_is_valid(title_win_id) then
        vim.api.nvim_win_close(title_win_id, true)
    end
end

-- Function to move the selection down
function M.move_down(items)
    if selected_item < #items then
        selected_item = selected_item + 1
        update_window(items) -- Ensure the window is updated when moving down
    end
end

-- Function to move the selection up
function M.move_up(items)
    if selected_item > 1 then
        selected_item = selected_item - 1
        update_window(items) -- Ensure the window is updated when moving up
    end
end

-- Function to select and apply the current theme
function M.select_item(items)
    vim.api.nvim_win_close(win_id, true)
thememan.apply_theme(items[selected_item])
    M.close_window()
end

-- Function to create a title bar window
local function create_title_window(title, main_win_config)
    local title_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(title_buf, 0, -1, false, { title })

    -- Create a small floating window for the title
    title_win_id = vim.api.nvim_open_win(title_buf, false, {
        relative = "editor",
        width = #title + 2,
        height = 1,
        row = main_win_config.row - 3, -- Position title window above main window
        col = main_win_config.col + math.floor((main_win_config.width - #title) / 2),
        style = "minimal",
        border = "rounded"
    })
end

-- Function to open the floating window with the selectable list of themes
function M.open_window(config_path,items,config)
    util.read_config(config_path)
    thememan.read_themes_from_directory(items,config)

    buf = vim.api.nvim_create_buf(false, true)

    ---@diagnostic disable-next-line: deprecated
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)

    ---@diagnostic disable-next-line: deprecated
    local width = vim.api.nvim_get_option("columns")

    ---@diagnostic disable-next-line: deprecated
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

    update_window(items)
    -- Main floating window configuration
    local main_win_config = {
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded"
    }
    create_title_window("themeinator", main_win_config)
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

-- Set up the key mapping for 's' in normal mode
    vim.api.nvim_set_keymap("n", "s", ":lua require('themeinator').open_floating_input()<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ":lua require('themeinator').close_window()<CR>",
        { noremap = true, silent = true })
    ---@diagnostic disable-next-line: deprecated
    vim.api.nvim_win_set_option(win_id, 'winhl', 'Normal:NormalFloat,FloatBorder:FloatBorder')

    vim.cmd [[
        highlight NormalFloat guibg=#1e222a
        highlight FloatBorder guifg=#5e81ac guibg=#1e222a
    ]]
end
--

return M
