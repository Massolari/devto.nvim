local M = {}
local stub = require("luassert.stub")
local spy = require("luassert.spy")
local match = require("luassert.match")
local assert = require("luassert.assert")
local article = require("devto-nvim.article")
local busted = require("plenary.busted")
local describe = busted.describe
local before_each = busted.before_each
local after_each = busted.after_each
local it = busted.it

--- Mocks a module and returns the mocked module
--- @param module string
--- @return table
local function mock_internal(module)
  _G.package.loaded["devto-nvim"] = nil
  _G.package.loaded[module] = nil
  local mocked = require(module)
  return mocked
end

describe(
  "devto.nvim",
  function()
    local devto_nvim
    local snapshot

    before_each(function()
      vim.env.DEVTO_API_KEY = "foo"
      _G.package.loaded["devto-nvim"] = nil
      devto_nvim = require("devto-nvim")
      snapshot = assert:snapshot()
    end)

    after_each(function()
      snapshot:revert()
    end)

    it(
      "should show a notification when no api key is set",
      function()
        vim.env.DEVTO_API_KEY = nil
        stub.new(vim, "notify")
        devto_nvim.my_articles()
        assert.stub(vim.notify).was.called()
      end
    )

    it(
      "should call the api to get the articles",
      function()
        local mocked_api = mock_internal("devto-nvim.api")
        mocked_api.my_articles = spy.new(function()
        end)
        local devto_nvim_mocked = require("devto-nvim")
        devto_nvim_mocked.my_articles()
        assert.spy(mocked_api.my_articles).was.called()
      end
    )

    it(
      "should create a new article and open it",
      function()
        local input = stub.new(vim.fn, "input")
        input.returns("Title")
        local api = mock_internal("devto-nvim.api")
        local api_new_article = stub.new(api, "new_article")
        local new_article = {
          id = 1,
          body_markdown = article.get_template("Title")
        }
        api_new_article.returns({ status = 201, body = new_article })
        local buffer = mock_internal("devto-nvim.buffer")
        local buffer_open_my_article = spy.on(buffer, "open_my_article")
        local devto_nvim_mocked = require("devto-nvim")
        devto_nvim_mocked.new_article()
        assert.stub(api_new_article).was.called_with("Title")
        assert.spy(buffer_open_my_article).was_called_with(match.is_same(new_article))
        assert.are.same(
          "devto://my-article/" .. tostring(new_article.id),
          vim.api.nvim_buf_get_name(0)
        )
        local buffer_content = vim.api.nvim_buf_get_lines(0, 0, -1, true)
        assert.are.same(
          article.get_body_lines(new_article),
          buffer_content
        )
      end
    )
  end
)
return M
