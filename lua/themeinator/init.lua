local M = {}

-- Function to open a floating window
function M.open_window()
    -- Create a new buffer (false for listed, true for scratch)
    local buf = vim.api.nvim_create_buf(false, true)

    -- Set the lines in the buffer (content)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        "Welcome to Themeinator!",
        "This floating window is part of your new Neovim plugin.",
        "Press 'q' to close this window."
    })

    -- Get the dimensions of the editor window
    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")

    -- Define window size (50% of width and 30% of height)
    local win_width = math.ceil(width * 0.5)
    local win_height = math.ceil(height * 0.3)

    -- Position the window in the center of the screen
    local row = math.ceil((height - win_height) / 2)
    local col = math.ceil((width - win_width) / 2)

    -- Open the floating window with the created buffer
    local win_id = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        style = "minimal", -- Minimal UI, no line numbers, etc.
        border = "rounded" -- Rounded border style
    })

    -- Set key mapping 'q' to close the window
    vim.api.nvim_buf_set_keymap(buf, "n", "q", ":q<CR>", { noremap = true, silent = true })

    -- Set highlight for the floating window
    vim.api.nvim_win_set_option(win_id, 'winhl', 'Normal:NormalFloat,FloatBorder:FloatBorder')

    -- Custom highlight colors for the floating window
    vim.cmd [[
        highlight NormalFloat guibg=#1e222a
        highlight FloatBorder guifg=#5e81ac guibg=#1e222a
    ]]
end

return M

