local M = {}

local json = require("themeinator.json")

-- Function to read a JSON file and decode it into a Lua table
function M.decode_json_file(filename)
    -- Open the file in read mode
    local file = io.open(filename, "r")
    if not file then
        error("Could not open file: " .. filename)
    end

    -- Read the entire file content
    local file_content = file:read("*a")
    file:close()

    -- Decode JSON content into a Lua table
    local lua_table, pos, err = json.decode(file_content)
    if err then
        error("Error parsing JSON: " .. err)
    end

    return lua_table
end

-- Usage example
--  local filename = "path/to/your_file.json"  -- Update this path to your JSON file
--  local data = decode_json_file(filename)
--  print(vim.inspect(data))  -- Use `vim.inspect` for a readable output in Neovim

-- ensures the themes file is present.
function M.ensure_themes_file(file_path)
  if vim.fn.filereadable(file_path) == 0 then
    vim.fn.mkdir(file_path, "p")
    local default = {
    }
    local encoded = vim.fn.json_encode(default)
    local f = io.open(file_path, "w")
    if f then
      f:write(encoded)
      f:close()
      vim.notify("Created default themes.json", vim.log.levels.INFO)
    else
      vim.notify("Failed to create themes.json", vim.log.levels.ERROR)
    end
  end
end


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
        error("failed to write to".. path)
    end
    local inspect = require("vim.inspect")
    f:write("return " .. inspect(tbl))
    f:close()
end


return M
