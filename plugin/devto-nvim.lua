local commands = {
  feed = "feed",
  my_articles = "my_articles",
  new_article = "new_article",
  open_url = "open_url"
}

vim.api.nvim_create_user_command(
  "Devto",
  function(data)
    local devto = require("devto-nvim")
    local notify = require("devto-nvim.notify")

    local args = data.args

    if args == commands.feed then
      return devto.feed()
    elseif args == commands.my_articles then
      return devto.my_articles()
    elseif args == commands.new_article then
      return devto.new_article()
    elseif args == commands.open_url then
      return devto.open_url()
    else
      notify.error("Unknown command: " .. args)
    end
  end,
  {
    nargs = 1,
    complete = function() return vim.tbl_values(commands) end
  }
)
