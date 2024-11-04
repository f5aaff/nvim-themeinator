local M = {}

local cjson = require('cjson')
local vim = vim -- Reference to vim for better clarity

function M.load_json_from_file(filepath)
    -- Open the file in read mode
    local file, err = io.open(filepath, "r")
    if not file then
        vim.api.nvim_err_writeln("Error opening file: " .. err)
        return nil
    end

    -- Read the entire file content
    local content = file:read("*a")
    file:close() -- Close the file

    -- Decode the JSON content
    local status, json_data = pcall(cjson.decode, content)
    if not status then
        vim.api.nvim_err_writeln("Error decoding JSON: " .. json_data)
        return nil
    end

    return json_data
end

-- Usage example
--  local filepath = "path/to/your/file.json" -- Replace with your JSON file path
--  local data = load_json_from_file(filepath)
--
--  if data then
--      print(vim.inspect(data)) -- Display the loaded Lua table
--  else
--      print("Failed to load JSON data.")
--  end


return M
