local M = {}
local Article = require("devto-nvim.article")
local util = require("devto-nvim.util")
local set_locals = util.set_locals

--- Set the basic options for a markdown buffer
function M.set_basic_options()
  set_locals({
    filetype = "markdown",
    modified = false
  })
end

--- Write lines to a buffer
--- @param buffer number The buffer to write to
--- @param lines string[] The lines to write
function M.write(buffer, lines, offset)
  local modifiable = vim.opt_local.modifiable:get()
  vim.opt_local.modifiable = true
  vim.api.nvim_buf_set_lines(
    buffer,
    offset or 0,
    -1,
    false,
    lines
  )
  vim.opt_local.modifiable = modifiable
end

--- Get the content of the current buffer
--- @return {content: string, bufnr: number}
function M.get_content()
  local buffer = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, true)
  return {
    content = table.concat(lines, "\n"),
    bufnr = buffer
  }
end

--- Open an article of the current user in a buffer by its ID
--- @param article Article The article to open
function M.open_my_article(article)
  vim.cmd(":edit devto://my-article/" .. tostring(article.id))
  local buffer = vim.api.nvim_get_current_buf()
  M.write(
    buffer,
    Article.get_body_lines(article)
  )
  M.set_basic_options()
  set_locals({ buftype = "acwrite", swapfile = false })
end

--- Open an article in a buffer by its title
--- @param article Article The article to open
function M.load_article(article)
  vim.cmd(":edit devto://article/" .. article.title)
  set_locals({ linebreak = true, textwidth = 80 })
  local buffer = vim.api.nvim_get_current_buf()
  local body = Article.get_body_lines(article)
  M.write(buffer, body)
  M.set_basic_options()
  set_locals({
    modifiable = false,
    spell = false,
    buftype = "nowrite",
    swapfile = false
  })
end

return M
