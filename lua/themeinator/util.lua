local M = {}




-- Function to add a folder to the runtime path
function M.add_folder_to_runtimepath(folder_path)
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
function M.read_config(config_path)
    local user_config_path = vim.fn.stdpath('config') .. config_path
    local ok, user_config = pcall(dofile, user_config_path)
    local config = {}
    if ok and type(user_config) == "table" then
        vim.notify("config found",vim.log.levels.INFO)
        config = vim.tbl_extend("force", config, user_config)
    end
    print(user_config.themes_directory)
    return config
end

function M.save_table_to_file(tbl, path)
    local f = io.open(path, "w")
    if not f then
        error("failed to write to", path)
    end
    local inspect = require("vim.inspect")
    f:write("return " .. inspect(tbl))
    f:close()
end


return M
