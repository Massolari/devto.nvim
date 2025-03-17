local M = {}
local api = require("devto-nvim.api")
local buffer = require("devto-nvim.buffer")
local notify = require("devto-nvim.notify")
local util = require("devto-nvim.util")
local set_locals = util.set_locals

---@class FeedArticle
---@field id number
---@field title string
---@field url string
---@field description string
---@field user Author
---@field reading_time_minutes number
---@field tag_list string[]
---@field positive_reactions_count number
---@field comments_count number
---@field readable_publish_date string

--- Open the feed in a new buffer
function M.open()
  return vim.cmd("edit devto://articles/feed")
end

--- Set the basic options for the feed buffer
local function set_basic_options()
  buffer.set_basic_options()
  set_locals({
    modifiable = false,
    spell = false,
    buftype = "nowrite",
    swapfile = false
  })
end

--- Seek the title of the article
--- @param line number The line to start the search
--- @param get_next_line fun(line: number): number The function to get the next line
--- @param count number The number of iterations
--- @return string? The title of the article, or nil if it was not found
local function seek_title(line, get_next_line, count)
  local line_content = vim.fn.getline(line)
  local title = string.match(line_content, " ## (.+)", 1)

  if title ~= nil then
    return title
  end

  if count > 1000 then
    notify.error("Could not find the title of the article")
    return nil
  end

  return seek_title(
    get_next_line(line),
    get_next_line,
    count + 1
  )
end

--- Get the title of the card
--- @param line number The line to start the search
--- @return string? The title of the card, or nil if it was not found
local function get_card_title(line)
  local content = vim.fn.getline(line)

  local is_inside_of_card = string.match(content, "^[ |🭽|▏|🭼]", 1)
  if not is_inside_of_card then
    return nil
  end

  local is_upper_border = string.match(content, "🭽", 1)
  local get_next_line = is_upper_border ~= nil and (function(current_line) return current_line + 1 end) or
      (function(current_line) return current_line - 1 end)

  return seek_title(line, get_next_line, 0)
end

--- Open an article in a new buffer or in the browser
--- @param location "buffer"|"browser" The location to open the article
function M.open_article(location)
  local title = get_card_title(vim.fn.line("."))

  if not title then
    notify.error("Could not find article data. Please reopen the feed.")
    return
  end

  local article_data = _G.devto_feed_articles and _G.devto_feed_articles[title]
  if not article_data then
    notify.error("Could not find article data. Please reload the feed.")
    return
  end

  if location == "browser" then
    util.open_url_on_browser(article_data.url)
  else
    api.get_article(article_data.id, buffer.load_article)
  end
end

--- Set the key maps for the feed buffer
local function set_key_maps()
  vim.keymap.set(
    "n",
    "<CR>",
    function() return M.open_article("buffer") end,
    { buffer = true, silent = true }
  )
  vim.keymap.set(
    "n",
    "<C-b>",
    function() return M.open_article("browser") end,
    { buffer = true, silent = true }
  )
end

--- Populate the global variable with the feed articles
--- @param articles FeedArticle[] The articles to populate the global variable
local function populate_global_feed_articles(articles)
  _G.devto_feed_articles = {}
  for _, article in ipairs(articles) do
    _G.devto_feed_articles[article.title] = { id = article.id, url = article.url }
  end
end

--- Return the card for an article
--- @param article FeedArticle The article to create the card
--- @param maxColumns number The maximum number of columns for the card
--- @return string[] The card for the article
local function article_to_feed(article, maxColumns)
  return {
    ("🭽" .. string.rep("▔", maxColumns)) .. "🭾",
    " ## " .. article.title,
    " " .. article.description,
    (((" 👤" .. article.user.name) .. "  (") .. article.user.username) .. ")",
    "▏",
    (((" 🕒 " .. tostring(article.reading_time_minutes)) .. " ") .. util.pluralize(article.reading_time_minutes, "minute")) ..
    " of reading time",
    " Tags: " .. M.tags_to_string(article.tag_list),
    ((" 💕" .. tostring(article.positive_reactions_count)) .. " 💬") .. tostring(article.comments_count),
    " 📆" .. article.readable_publish_date,
    "▏",
    ("🭼" .. string.rep("▁", maxColumns)) .. "🭿",
    ""
  }
end

--- Load the feed
function M.load()
  set_basic_options()
  local bufnr = vim.api.nvim_get_current_buf()
  buffer.write(bufnr, { "Loading feed..." })
  api.feed(function(articles)
    set_key_maps()
    populate_global_feed_articles(articles)
    local max_column = 0
    for _, article in ipairs(articles) do
      max_column = math.max(#article.title, #article.description, max_column)
    end

    local feed = {}
    for _, article in ipairs(articles) do
      local article_feed = article_to_feed(article, max_column)
      for _, line in ipairs(article_feed) do
        table.insert(feed, line)
      end
    end

    buffer.write(
      bufnr,
      {
        "# Your Feed",
        "",
        "Press <Enter> in a card to open the article in a new buffer",
        "and <C-b> to open it in the browser.",
        "",
        unpack(feed)
      }
    )
  end)
end

--- Convert tags to a string
--- Each tag will be prefixed with a hash
--- ```lua
--- tags_to_string({ "lua", "neovim" }) -- "#lua, #neovim"
--- ```
--- @param tags string[] The tags to convert
--- @return string The tags as a string
function M.tags_to_string(tags)
  local formatted_tags = vim.tbl_map(function(tag)
    return "#" .. tag
  end, tags)

  return table.concat(formatted_tags, ", ")
end

return M
