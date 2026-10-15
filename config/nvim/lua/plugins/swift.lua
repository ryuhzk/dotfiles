-- Use the installed Swift toolchain and xtool's per-project .bsp/xtool.json.
local function xtool(args)
  local root = vim.fs.root(0, "xtool.yml") or vim.fs.root(vim.fn.getcwd(), "xtool.yml")
  if not root then
    vim.notify("Open an xtool project (xtool.yml) first", vim.log.levels.WARN)
    return
  end
  if vim.fn.executable("xtool") ~= 1 then
    vim.notify("xtool is not on PATH", vim.log.levels.ERROR)
    return
  end
  vim.cmd("wall")
  require("snacks").terminal.open(vim.list_extend({ "xtool" }, args), {
    cwd = root,
    auto_close = false,
    win = { position = "bottom", height = 0.4 },
  })
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        sourcekit = {
          mason = false,
          cmd = { "sourcekit-lsp" },
          filetypes = { "swift" },
        },
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "swift" } },
  },
  {
    "stevearc/conform.nvim",
    opts = { formatters_by_ft = { swift = { "swift" } } },
  },
  {
    "folke/snacks.nvim",
    init = function()
      for name, args in pairs({
        XtoolBuild = { "dev", "build" },
        XtoolRun = { "dev", "run" },
        XtoolDevices = { "devices", "--no-wait" },
      }) do
        vim.api.nvim_create_user_command(name, function()
          xtool(args)
        end, { desc = table.concat(vim.list_extend({ "xtool" }, args), " ") })
      end
    end,
    keys = {
      { "<leader>cxb", "<cmd>XtoolBuild<cr>", ft = "swift", desc = "xtool Build iOS App" },
      { "<leader>cxr", "<cmd>XtoolRun<cr>", ft = "swift", desc = "xtool Build and Install on Device" },
      { "<leader>cxd", "<cmd>XtoolDevices<cr>", ft = "swift", desc = "xtool List Devices" },
    },
  },
  {
    "folke/which-key.nvim",
    opts = { spec = { { "<leader>cx", group = "xtool", mode = "n" } } },
  },
  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")
      local swift = vim.uv.fs_realpath(vim.fn.exepath("swift"))
      local adapter = swift and (vim.fs.dirname(swift) .. "/lldb-dap") or "lldb-dap"
      local env = vim.fn.environ()
      -- Arch's Swift binary uses Python 3.12; keep this local to the debugger.
      local python = vim.fn.expand("~/.local/share/uv/python/cpython-3.12-linux-x86_64-gnu")
      if vim.uv.fs_stat(python .. "/lib/libpython3.12.so.1.0") then
        env.PYTHONHOME = python
        env.LD_LIBRARY_PATH = python .. "/lib" .. (vim.env.LD_LIBRARY_PATH and (":" .. vim.env.LD_LIBRARY_PATH) or "")
      end
      local adapter_env = {}
      for key, value in pairs(env) do
        adapter_env[#adapter_env + 1] = key .. "=" .. value
      end
      dap.adapters["swift-lldb"] = {
        type = "executable",
        command = adapter,
        name = "Swift LLDB",
        options = { env = adapter_env },
      }
      -- These launch native host executables. iOS device debugging needs a remote setup.
      dap.configurations.swift = {
        {
          name = "Swift: launch local executable",
          type = "swift-lldb",
          request = "launch",
          program = function()
            return require("dap.utils").pick_file({ executables = true })
          end,
          cwd = "${workspaceFolder}",
        },
        {
          name = "Swift: attach to local process",
          type = "swift-lldb",
          request = "attach",
          pid = function()
            return require("dap.utils").pick_process()
          end,
        },
      }
    end,
  },
}
