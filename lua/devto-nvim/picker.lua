local M = {}
local buffer = require("devto-nvim.buffer")
local Article = require("devto-nvim.article")
local notify = require("devto-nvim.notify")

--- Open the Telescope picker to select an article
--- @param articles Article[]
local function my_articles_telescope_picker(articles)
  local telescope_config = require("telescope.config")
  local config_values = telescope_config.values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  local finders = require("telescope.finders")
  local pickers = require("telescope.pickers")
  local previewers = require("telescope.previewers")

  pickers.new(
    {},
    {
      prompt_title = "My Articles",
      finder = finders.new_table({
        results = articles,
        entry_maker = function(article)
          return { value = article, display = article.title, type_of = article.type_of, ordinal = article.title }
        end
      }),
      previewer = previewers.new_buffer_previewer({
        title = "Article Preview",
        dyn_title = function(_, entry) return entry.display end,
        define_preview = function(self, entry)
          if self.state.bufname then
            return
          end
          local body = Article.get_body_lines(entry.value)
          vim.api.nvim_set_option_value("filetype", "markdown", { buf = self.state.bufnr })
          buffer.write(self.state.bufnr, body)
        end,
        get_buffer_by_name = function(_, entry) return entry.value.slug end
      }),
      sorter = config_values.prefilter_sorter({
        tag = "type_of",
        sorter = config_values.generic_sorter({})
      }),
      attach_mappings = function(prompt_bufnr)
        return actions.select_default.replace(function()
          local selection = action_state.get_selected_entry(prompt_bufnr)
          actions.close(prompt_bufnr)
          buffer.open_my_article(selection.value)
        end)
      end
    }
  ):find()
end

--- Open the FZF Lua picker to select an article
--- @param articles Article[]
local function my_articles_fzf_lua_picker(articles)
  local articles_name = vim.tbl_map(function(article) return article.title end, articles)
  local ArticlePreviewer = require 'fzf-lua.previewer.builtin'.base:extend()

  function ArticlePreviewer:new(o, opts, fzf_win)
    ArticlePreviewer.super.new(self, o, opts, fzf_win)
    setmetatable(self, ArticlePreviewer)
    return self
  end

  function ArticlePreviewer:populate_preview_buf(article_title)
    local tmpbuf = self:get_tmp_buffer()
    local article = vim.tbl_filter(function(a) return a.title == article_title end, articles)[1]
    local body = Article.get_body_lines(article)
    vim.api.nvim_set_option_value("filetype", "markdown", { buf = tmpbuf })
    buffer.write(tmpbuf, body)
    self:set_preview_buf(tmpbuf)
    -- self.win:update_scrollbar()
  end

  -- Disable line numbering and word wrap
  function ArticlePreviewer:gen_winopts()
    local new_winopts = {
      wrap   = false,
      number = false
    }
    return vim.tbl_extend("force", self.winopts, new_winopts)
  end

  require 'fzf-lua'.fzf_exec(
    articles_name,
    {
      fzf_opts = {
        ["--preview-window"] = "nohidden,right,50%",
      },
      previewer = ArticlePreviewer,
      prompt = "My Articles> ",
      actions = {
        ["default"] = function(selected)
          local article = vim.tbl_filter(function(a) return a.title == selected[1] end, articles)[1]
          buffer.open_my_article(article)
        end
      }
    }
  )
end

--- Open the picker to select an article
--- @param articles Article[]
function M.my_articles(articles)
  local telescope_status, _ = pcall(require, "telescope")
  if telescope_status then
    my_articles_telescope_picker(articles)
    return
  end

  local fzflua_status, _ = pcall(require, "fzf-lua")
  if fzflua_status then
    my_articles_fzf_lua_picker(articles)
    return
  end

  vim.ui.select(vim.tbl_map(function(article)
    return article.title
  end, articles), {
    prompt = "My Articles",
  }, function(selection)
    ---@type Article?
    local article = vim.tbl_filter(function(a)
      return a.title == selection
    end, articles)[1]

    if not article then
      notify.error(string.format("Could not find article %s", selection))
      return
    end
    buffer.open_my_article(article)
  end)
end

return M
