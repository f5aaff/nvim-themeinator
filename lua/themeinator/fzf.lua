local M = {}

-- Default configuration
local config = {
    themes_directory = "$HOME/.config/nvim/after/colors/", -- Default themes directory
    last_selected_theme_file = "", -- Store the last selected theme
}

-- List of themes (items) to display in the window
local items = {}
local filtered_items = {}
local selected_item = 1
local buf, win_id

-- Function to add a folder to the runtime path
local function add_folder_to_runtimepath(folder_path)
    local full_path = vim.fn.expand(folder_path)
    if vim.fn.isdirectory(full_path) == 0 then
        vim.notify("Directory does not exist: " .. full_path, vim.log.levels.ERROR)
        return false
    end
    vim.opt.runtimepath:append(full_path)
    vim.notify("Added to runtimepath: " .. full_path)
    return true
end

-- Function to read themes from the directory
local function read_themes_from_directory()
    local dir = vim.fn.expand(config.themes_directory)
    if vim.fn.isdirectory(dir) == 0 then
        print("Themes directory does not exist: " .. dir)
        return
    end

    items = vim.fn.readdir(dir)
    add_folder_to_runtimepath(config.themes_directory)

    if #items == 0 then
        table.insert(items, "No themes found.")
    end
end

-- Function to filter items based on search query using fzf
local function filter_items(query)
    local handle = io.popen("echo -e '" .. table.concat(items, "\n") .. "' | fzf -f '" .. query .. "'")
    local result = handle:read("*a")
    handle:close()
    return vim.split(result, "\n", { trimempty = true })
end

-- Function to update the window with filtered items
local function update_window(query)
    filtered_items = query and filter_items(query) or items
    vim.api.nvim_buf_set_lines(buf, 2, -2, false, filtered_items)

    -- Highlight selected item
    vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
    if #filtered_items > 0 then
        vim.api.nvim_buf_add_highlight(buf, -1, "Visual", selected_item + 1, 0, -1)
    end
end

-- Function to open the floating window
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

    win_id = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = win_width,
        height = win_height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded"
    })

    -- Add search box and instructions
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Search: ", "", "q to close | s to search | ? for help" })
    update_window(nil) -- Initially populate the list with all items

    -- Key mappings for search, navigation, and help
    vim.api.nvim_buf_set_keymap(buf, 'n', 's', ":lua require('themeinator').start_search()<CR>", { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ":lua require('themeinator').close_window()<CR>", { noremap = true, silent = true })
end

-- Function to handle search input
function M.start_search()
    vim.fn.inputsave()
    local query = vim.fn.input("Search: ")
    vim.fn.inputrestore()

    if query then
        update_window(query)
    end
end

-- Close the window
function M.close_window()
    if win_id then
        vim.api.nvim_win_close(win_id, true)
        win_id = nil
    end
end

return M

