local M = {}

local thememan = require('themeinator.thememan')

local selected_item = 1
local buf, win_id

local input_buf, input_win_id, result_buf, result_win_id
local selected_index = 1 -- Keeps track of the currently selected item

-- Function to open the main input window for filtering items
function M.open_search_window(items, on_select)
    selected_index = 1 -- Reset selection index each time the window opens

    -- Create a buffer for the input window
    input_buf = vim.api.nvim_create_buf(false, true)

    local width, height = 40, 3
    local row, col = math.floor((vim.o.lines - height) / 2 - 1), math.floor((vim.o.columns - width) / 2)

    input_win_id = vim.api.nvim_open_win(input_buf, true, {
        style = "minimal",
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        border = "rounded"
    })

    -- Set options for the buffer
    vim.api.nvim_buf_set_option(input_buf, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(input_buf, "modifiable", true)
    vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, { "" })

    -- Autocommand to filter and update results on every text change
    vim.api.nvim_create_autocmd("TextChangedI", {
        buffer = input_buf,
        callback = function() M.update_results(items) end
    })

    -- Key mappings for navigation and selection
    vim.api.nvim_buf_set_keymap(input_buf, "i", "<Down>", "<Cmd>lua require('themeinator.ui').move_selection(1)<CR>",
        { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(input_buf, "i", "<Up>", "<Cmd>lua require('themeinator.ui').move_selection(-1)<CR>",
        { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(input_buf, "i", "<CR>",
        "<Cmd>lua require('themeinator.ui').select_current_item(" .. vim.inspect(on_select) .. ")<CR>",
        { noremap = true, silent = true })
end

-- Function to update the filtered results based on input
function M.update_results(items)
    local query = vim.api.nvim_get_current_line()
    local filtered_items = {}
    if query ~= "" then
        -- Filter items based on query
        for _, item in ipairs(items) do
            if item:lower():match(query:lower()) then
                table.insert(filtered_items, item)
            end
        end
    else
        for _, item in ipairs(items) do
            table.insert(filtered_items, item)
        end
    end
    -- Reset selected index if results have changed
    selected_index = 1

    -- Show results in the results window
    M.show_results(filtered_items)
end

-- Function to display filtered items in a floating results window
function M.show_results(filtered_items)
    -- Close previous results window if it exists
    if result_win_id and vim.api.nvim_win_is_valid(result_win_id) then
        vim.api.nvim_win_close(result_win_id, true)
    end

    -- Set the height to at least 1 or up to a maximum of 10 lines
    local result_height = math.max(math.min(#filtered_items, 10), 1)

    -- Create a buffer and window for results if needed
    result_buf = vim.api.nvim_create_buf(false, true)
    result_win_id = vim.api.nvim_open_win(result_buf, false, {
        style = "minimal",
        relative = "editor",
        width = 40,
        height = result_height,
        row = math.floor((vim.o.lines - 1) / 2) + 2,
        col = math.floor((vim.o.columns - 40) / 2),
        border = "rounded",
    })

    -- Display filtered items in the result buffer
    if #filtered_items == 0 then
        vim.api.nvim_buf_set_lines(result_buf, 0, -1, false, { "No matches found" })
    else
        vim.api.nvim_buf_set_lines(result_buf, 0, -1, false, filtered_items)
    end

    -- Highlight the currently selected item
    M.highlight_selected_item()
end

-- Function to highlight the currently selected item in the results
function M.highlight_selected_item()
    vim.api.nvim_buf_clear_namespace(result_buf, -1, 0, -1)
    vim.api.nvim_buf_add_highlight(result_buf, -1, "Visual", selected_index - 1, 0, -1)
end

-- Function to move selection up or down
function M.move_selection(direction)
    local line_count = vim.api.nvim_buf_line_count(result_buf)

    -- Update selected_index based on direction, clamping within bounds
    selected_index = math.max(1, math.min(selected_index + direction, line_count))

    -- Update the visual highlight
    M.highlight_selected_item()
end

-- Function to handle selecting the currently highlighted item
function M.select_current_item()
    -- Get the selected line's text
    local selected = vim.api.nvim_buf_get_lines(result_buf, selected_index - 1, selected_index, false)[1]

    local config = require("themeinator.init").get_config()
    vim.api.nvim_win_close(win_id, true)
    thememan.apply_theme(config, config.config_path, selected)
    M.close_window()
end

-- Function to update the window to reflect the currently selected item
local function update_window(items)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then
        print("Buffer is not valid")
        return
    end
    -- Ensure items list is valid
    if not items or #items == 0 then
        items = { "No themes found." .. #items }
    end

    -- Set the theme items in the buffer
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, items)

    -- Clear previous highlighting
    vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)

    -- Highlight the selected item
    vim.api.nvim_buf_add_highlight(buf, -1, "Visual", selected_item - 1, 0, -1)
end

local title_win_id

---- Function to close both main and title windows
function M.close_window()
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_close(win_id, true)
    end
    if title_win_id and vim.api.nvim_win_is_valid(title_win_id) then
        vim.api.nvim_win_close(title_win_id, true)
    end
    if input_win_id and vim.api.nvim_win_is_valid(input_win_id) then
        vim.api.nvim_win_close(input_win_id, true)
    end
    if result_win_id and vim.api.nvim_win_is_valid(result_win_id) then
        vim.api.nvim_win_close(result_win_id, true)
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
    local config = require("themeinator.init").get_config()
    vim.api.nvim_win_close(win_id, true)
    thememan.apply_theme(config, config.config_path, items[selected_item])
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
function M.open_window(items)
    buf = vim.api.nvim_create_buf(false, true)

    if not buf then
        print("Failed to create buffer")
        return
    end

    -- Ensure items is a non-empty list
    if not items or #items == 0 then
        items = { "No themes found." .. #items } -- Default message if items is empty
    end

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

    -- Create the main floating window
    win_id = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded"
    })

    -- Check if win_id is valid
    if not win_id then
        print("Failed to create window")
        return
    end

    -- Update the window with theme items
    update_window(items)

    -- Configuration for creating title window
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

    -- Key mappings for navigation and selection
    vim.api.nvim_buf_set_keymap(buf, "n", "j",
        ":lua require('themeinator.ui').move_down(" .. vim.inspect(items) .. ")<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, "n", "<DOWN>",
        ":lua require('themeinator.ui').move_down(" .. vim.inspect(items) .. ")<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, "n", "k", ":lua require('themeinator.ui').move_up(" .. vim.inspect(items) .. ")<CR>",
        { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, "n", "<UP>",
        ":lua require('themeinator.ui').move_up(" .. vim.inspect(items) .. ")<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, "n", "<CR>",
        ":lua require('themeinator.ui').select_item(" .. vim.inspect(items) .. ")<CR>", { noremap = true, silent = true })

    vim.api.nvim_set_keymap("n", "s",
        ":lua require('themeinator.ui').open_search_window(" .. vim.inspect(items) .. ")<CR>",
        { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ":lua require('themeinator.ui').close_window()<CR>",
        { noremap = true, silent = true })

    ---@diagnostic disable-next-line: deprecated
    vim.api.nvim_win_set_option(win_id, 'winhl', 'Normal:NormalFloat,FloatBorder:FloatBorder')
end

return M