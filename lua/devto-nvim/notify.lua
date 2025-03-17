local M = {}

--- Notify the user
--- @param message string The message to display
--- @param level string The level of the message. Must be one of `vim.log.levels`
local function notify(message, level)
  vim.notify(message, vim.log.levels[level], { title = "Devto.nvim" })
end

--- Notify the user of an error
--- @param message string The message to display
function M.error(message) return notify(message, "ERROR") end

--- Notify the user of a warning
--- @param message string The message to display
function M.info(message) return notify(message, "INFO") end

return M
