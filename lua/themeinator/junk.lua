function M.open_window()
    read_themes_from_directory()
    filtered_items = items
    buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)

    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines")
    local win_width = math.ceil(width * 0.5)
    local win_height = math.ceil(height * 0.5)
    local row = math.ceil((height - win_height) / 2)
    local col = math.ceil((width - win_width) / 2)

    -- Define border with a title at the top
    local border_chars = {
        { "╭", "Theme Selector", "╮" }, -- top with title in the center
        "│", "╯", "│", "╰", "─", "─", "─" -- other border sides
    }

    -- Create a floating window with a custom border title
    win_id = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        style = "minimal",
        border = border_chars  -- Use custom border with a title
    })

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Search: ", "", "q to close | s to search | ? for help" })
    update_window()

    -- Key mappings
    vim.api.nvim_buf_set_keymap(buf, 'n', 's', ":lua require('themeinator').start_search()<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ":lua require('themeinator').close_window()<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'i', '<Esc>', ":lua require('themeinator').end_search()<CR>", { noremap = true, silent = true })
end

