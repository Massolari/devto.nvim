local M = {}

--- Set the local options of the current buffer
--- @param values table<string, any> The options to set
function M.set_locals(values)
  for key, value in pairs(values) do
    vim.opt_local[key] = value
  end
end

--- Check if a path is executable
--- @param path string The path to check
--- @return boolean
local function is_executable(path)
  return vim.fn.executable(path) == 1
end

--- Get the command to open a URL
--- @return string?
local function get_open_command()
  if is_executable("xdg-open") then
    return "xdg-open"
  elseif is_executable("open") then
    return "open"
  elseif is_executable("start") then
    return "start"
  else
    return nil
  end
end

--- Open a URL on the browser
--- @param url string The URL to open
function M.open_url_on_browser(url)
  local cmd = get_open_command()
  if not cmd then
    vim.api.nvim_err_writeln("Could not find a command to open the URL: $[url]")
    return
  end
  vim.fn.system((cmd .. " ") .. url)
end

--- Pluralize a word
--- @param count number The count to check
--- @param singular string The singular form of the word
--- @param plural string The plural form of the word
function M.pluralize(count, singular, plural)
  if count == 1 then
    return singular
  end
  return plural or singular .. "s"
end

--- Open a floating menu
--- @param content string[] The content of the menu
--- @param options table<string, any> The options of the floating window
function M.open_float_menu(content, options)
  local width = 0
  for _, line in ipairs(content) do
    width = math.max(width, #line)
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  local float_options = vim.tbl_extend("keep", options or {}, {
    relative = "cursor",
    col = 0,
    row = 1,
    style = "minimal",
    width = width,
    border = "rounded",
    height = #content
  })
  local window = vim.api.nvim_open_win(bufnr, false, float_options)
  vim.api.nvim_buf_set_lines(
    bufnr,
    0,
    -1,
    true,
    content
  )
  vim.api.nvim_buf_set_name(bufnr, "devto://feed/floatmenu")
  vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
  vim.api.nvim_set_option_value("bufhidden", "delete", { buf = bufnr })
  vim.api.nvim_set_option_value("cursorline", true, { win = window })
end

return M
