local M = {}

---@class Article
---@field id number
---@field type_of string
---@field title string
---@field slug string
---@field description string
---@field url string
---@field body_markdown string?
---@field user Author
---@field reading_time_minutes number
---@field tags string[]
---@field positive_reactions_count number
---@field comments_count number
---@field readable_publish_date string
---@field published_at string?

---@class Author
---@field name string
---@field username string

--- Get the lines of the body of an article
--- @param article Article
--- @return string[]
function M.get_body_lines(article)
  return vim.split(article.body_markdown or "", "\n")
end

--- Get the template for a new article
--- @param title string The title of the new article
--- @return string
function M.get_template(title)
  return string.format(
    "---\ntitle: %s\npublished: false\ndescription:\ntags:\n# cover_image: https://direct_url_to_image.jpg\n# Use a ratio of 100:42 for best results.\n---\n\n",
    title)
end

return M
