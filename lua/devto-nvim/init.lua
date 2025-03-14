local M = {}
local api = require("devto-nvim.api")
local buffer = require("devto-nvim.buffer")
local feed = require("devto-nvim.feed")
local notify = require("devto-nvim.notify")
local picker = require("devto-nvim.picker")

local NO_API_KEY_ERROR = "devto.nvim: DEVTO_API_KEY environment variable is missing"

local function check_api_key(callback)
  if api.key() then
    callback()
    return
  end
  notify.error(NO_API_KEY_ERROR)
end

local function my_articles()
  return api.my_articles(picker.my_articles)
end

local function save_article()
  local buffer_content = buffer.get_content()
  local bufnr = buffer_content.bufnr
  local content = buffer_content.content
  local id = tonumber(vim.fn.expand("%:t"))

  if not id then
    notify.error("devto.nvim: Could not find article id")
    return
  end

  local response = api.save_article(id, content)
  api.handle_error(
    response,
    function()
      notify.info("Article saved")
      vim.api.nvim_set_option_value("modified", false, { buf = bufnr })
    end
  )
end

local function new_article()
  local status, title = pcall(
    function(prompt) return vim.fn.input(prompt) end,
    "Article's Title: "
  )

  if not status or title == "" then
    return
  end

  local response = api.new_article(title)
  api.handle_error(
    response,
    function(article)
      buffer.open_my_article(article)
    end
  )
end

local function open_by_url()
  local status, url = pcall(
    function(prompt) return vim.fn.input(prompt) end,
    "Article's URL: "
  )

  if not status or url == "" then
    return
  end

  local path = string.match(url, "(%w+/[%w|-]+)$")

  if path == nil then
    notify.error("This URL is not valid: " .. url)
    return
  end

  api.get_article_by_path(path, buffer.load_article)
end

local devto_au_group = vim.api.nvim_create_augroup("devto_autocmds", {})

vim.api.nvim_create_autocmd("BufWriteCmd",
  { group = devto_au_group, pattern = "devto://my-article/*", callback = save_article })
vim.api.nvim_create_autocmd("BufEnter",
  { group = devto_au_group, pattern = "devto://articles/feed", callback = feed.load })
vim.api.nvim_create_autocmd(
  "CursorMoved",
  {
    group = devto_au_group,
    pattern = "devto://*/floatmenu",
    callback = function()
      local bufnum, line, column, off = unpack(vim.fn.getpos("."))
      if column <= 1 then
        return
      end
      vim.fn.setpos(".", { bufnum, line, 1, off })
    end
  }
)
vim.api.nvim_create_autocmd(
  "BufEnter",
  {
    group = devto_au_group,
    pattern = "devto://*/floatmenu",
    callback = function()
      vim.keymap.set(
        "n",
        "<Esc>",
        function() return vim.api.nvim_win_close(0, false) end
      )
    end
  }
)

if not api.key() then
  notify.error(NO_API_KEY_ERROR)
end

local function check_api_middleware(callback)
  return function()
    check_api_key(callback)
  end
end

M.my_articles = check_api_middleware(my_articles)
M.new_article = check_api_middleware(new_article)
M.feed = check_api_middleware(feed.open)
M.open_url = check_api_middleware(open_by_url)
return M
