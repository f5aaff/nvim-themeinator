local M = {}

-- List of items to display in the window
local items = {
    "Option 1: Light Theme",
    "Option 2: Dark Theme",
    "Option 3: Solarized Theme",
    "Option 4: Gruvbox Theme"
}

-- Variable to keep track of the currently selected item
local selected_item = 1
local buf, win_id

-- Function to update the list in the buffer, highlighting the selected item
local function update_window()
    -- Clear buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

    -- Insert each item into the buffer and highlight the selected one
    for i, item in ipairs(items) do
        if i == selected_item then
            -- Highlight the selected item
            vim.api.nvim_buf_add_highlight(buf, -1, "Visual", i - 1, 0, -1)
        else
            vim.api.nvim_buf_add_highlight(buf, -1, "Normal", i - 1, 0, -1)
        end

        -- Set the line content
        vim.api.nvim_buf_set_lines(buf, i - 1, i, false, { item })
    end
end

-- Function to open the floating window with the selectable list
function M.open_window()
    -- Create a new buffer (false for listed, true for scratch)
    buf = vim.api.nvim_create_buf(false, true)

    -- Set the buffer to be modifiable and insert initial content
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)

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

    -- Update the buffer with the items list
    update_window()

    -- Set key mappings for navigating the list
    vim.api.nvim_buf_set_keymap(buf, "n", "j", ":lua require('themeinator').move_down()<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, "n", "k", ":lua require('themeinator').move_up()<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", ":lua require('themeinator').select_item()<CR>", { noremap = true, silent = true })
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

