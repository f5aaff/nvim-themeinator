local M = {}

-- Function to open a floating window
function M.open_window()
    -- Create a new buffer
    local buf = vim.api.nvim_create_buf(false, true)

    -- Set the lines in the buffer (content)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "This is my custom UI window!",
        "You can put anything here.",
        "Press q to close."
    })

    -- Define the window layout (size, position, etc.)
    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")

    local win_height = math.ceil(height * 0.3)  -- 30% of the screen height
    local win_width = math.ceil(width * 0.5)    -- 50% of the screen width
    local row = math.ceil((height - win_height) / 2)  -- Center vertically
    local col = math.ceil((width - win_width) / 2)    -- Center horizontally

    -- Open a floating window with the created buffer
    local win_id = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        style = "minimal",
        border = "single" -- You can choose: 'single', 'double', 'rounded', etc.
    })

    -- Map 'q' to close the window
    vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })
end

return M

