--- Load a module from a git repository.
--- @param module string
--- @param source string
local function load_module(module, source, directory)
  local module_dir = directory or ("/tmp/" .. module)
  local directory_exists = vim.fn.isdirectory(module_dir)

  if directory_exists == 0 then
    vim.fn.system({ "git", "clone", source, module_dir })
  end

  vim.opt.rtp:append(module_dir)
end

local plenary_dir = os.getenv("PLENARY_DIR") or "/tmp/plenary.nvim"
load_module("plenary.nvim", "https://github.com/nvim-lua/plenary.nvim", plenary_dir)
load_module("telescope.nvim", "https://github.com/nvim-telescope/telescope.nvim")
vim.opt.rtp:append(".")
vim.cmd("runtime plugin/plenary.vim")
vim.cmd("runtime plugin/telescope.lua")
require("plenary.busted")
