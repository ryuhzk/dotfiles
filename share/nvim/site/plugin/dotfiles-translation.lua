local function visual_selection()
  local mode = vim.fn.mode(1)
  local prefix = mode:sub(1, 1)
  if prefix ~= "v" and prefix ~= "V" and prefix ~= "\22" then return nil end

  local anchor = vim.fn.getpos("v")
  local cursor = vim.fn.getpos(".")
  local region = vim.fn.getregion(anchor, cursor, { type = mode })
  if #region == 0 then return nil end

  local first = { row = anchor[2], column = anchor[3] }
  local last = { row = cursor[2], column = cursor[3] }
  if first.row > last.row or (first.row == last.row and first.column > last.column) then
    first, last = last, first
  end

  return {
    buffer = vim.api.nvim_get_current_buf(),
    changedtick = vim.api.nvim_buf_get_changedtick(0),
    mode = prefix,
    first = first,
    last = last,
    text = table.concat(region, "\n"),
  }
end

local function character_length_at(buffer, row, column)
  local line = vim.api.nvim_buf_get_lines(buffer, row - 1, row, false)[1] or ""
  local first_byte = line:byte(column)
  if not first_byte or first_byte < 0x80 then return 1 end
  if first_byte < 0xE0 then return 2 end
  if first_byte < 0xF0 then return 3 end
  return 4
end

local function replace_selection(selection, replacement)
  local lines = vim.split(replacement, "\n", { plain = true })
  if selection.mode == "V" then
    vim.api.nvim_buf_set_lines(
      selection.buffer,
      selection.first.row - 1,
      selection.last.row,
      false,
      lines
    )
    return
  end

  if selection.mode == "\22" then
    vim.notify("Blockwise translation is not supported.", vim.log.levels.WARN)
    return
  end

  local end_column = selection.last.column - 1
    + character_length_at(selection.buffer, selection.last.row, selection.last.column)
  vim.api.nvim_buf_set_text(
    selection.buffer,
    selection.first.row - 1,
    selection.first.column - 1,
    selection.last.row - 1,
    end_column,
    lines
  )
end

local function translate_selection()
  local selection = visual_selection()
  if not selection then
    vim.notify("Select text before translating.", vim.log.levels.WARN)
    return
  end

  local command = vim.g.dotfiles_translate_command
    or vim.fn.expand("~/.local/bin/dotfiles-translate")
  if vim.fn.executable(command) ~= 1 then
    vim.notify("dotfiles-translate is not installed.", vim.log.levels.ERROR)
    return
  end

  vim.notify("Translating selection…", vim.log.levels.INFO)
  vim.system(
    { command, "--stdin", "--stdout" },
    { stdin = selection.text, text = true },
    function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          local message = vim.trim(result.stderr or "")
          vim.notify(message ~= "" and message or "Translation failed.", vim.log.levels.ERROR)
          return
        end

        local replacement = vim.trim(result.stdout or "")
        if replacement == "" then
          vim.notify("Translation returned empty text.", vim.log.levels.ERROR)
          return
        end

        if not vim.api.nvim_buf_is_valid(selection.buffer)
          or vim.api.nvim_buf_get_changedtick(selection.buffer) ~= selection.changedtick then
          vim.fn.setreg("+", replacement)
          vim.notify("Buffer changed; translation copied to the clipboard.", vim.log.levels.WARN)
          return
        end

        replace_selection(selection, replacement)
        vim.notify("Translation complete.", vim.log.levels.INFO)
      end)
    end
  )
end

vim.keymap.set("x", "<leader>tr", translate_selection, {
  desc = "Translate selection",
  silent = true,
})
