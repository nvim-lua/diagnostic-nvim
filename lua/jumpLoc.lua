local vim = vim
local api = vim.api
local util = require'diagnostic.util'
local diagnostic = require'diagnostic'
local M = {}

function M.get_next_loc()
  M.location = api.nvim_call_function('getloclist', {0})
  if #M.location <= 0 then
    return -1
  end

  local cur_row = api.nvim_call_function('line', {"."})
  local cur_col = api.nvim_call_function('col', {"."})

  for i, v in ipairs(M.location) do
    if v['lnum'] > cur_row or (v['lnum'] == cur_row and v['col'] > cur_col + 1) then
      return i
    end
  end
  return -1
end

function M.get_prev_loc()
  M.location = api.nvim_call_function('getloclist', {0})
  if #M.location == 0 then
    return -1
  end

  local cur_row = api.nvim_call_function('line', {"."})
  local cur_col = api.nvim_call_function('col', {"."})

  for i, v in ipairs(M.location) do
    local is_next = v['lnum'] > cur_row or (v['lnum'] == cur_row and v['col'] > cur_col);
    local is_prev = v['lnum'] == cur_row and cur_col > v['col'];
    local same_pos = v['lnum'] == cur_row and v['col'] == cur_col;
    if is_next or same_pos then
      return i - 1
    elseif is_prev then
      return i
    end
  end

  return -1
end

function jumpToLocation(i)
  if i >= 1 and i <= #M.location then
    api.nvim_command("silent! ll"..i)
    M.openLineDiagnostics()
  end
end

-- Jump to next location
-- Show warning text when no next location is available
function M.jumpNextLocation()
  local i = M.get_next_loc()
  if i >= 1 then
    jumpToLocation(i)
  else
    api.nvim_command("echohl WarningMsg | echo 'no next diagnostic' | echohl None")
  end
end

function M.jumpPrevLocation()
  local i = M.get_prev_loc()
  if i >= 1 then
    jumpToLocation(i)
  else
    api.nvim_command("echohl WarningMsg | echo 'no prev diagnostic' | echohl None")
  end
end

function M.jumpNextLocationCycle()
  local next_i = M.get_next_loc()
  if next_i > 0 then
      jumpToLocation(next_i)
  elseif M.get_prev_loc() >= 0 then
    jumpToLocation(1)
  else
    return api.nvim_command("echohl WarningMsg | echo 'No diagnostics found' | echohl None")
  end
end

-- Open line diagnostics when jump
-- Don't do anything if diagnostic_auto_popup_while_jump == 0
-- NOTE need to delay a certain amount of time to show correctly
function M.openLineDiagnostics()
  if api.nvim_get_var('diagnostic_auto_popup_while_jump') == 1 then
    local timer = vim.loop.new_timer()
    timer:start(100, 0, vim.schedule_wrap(function()
      util.show_line_diagnostics()
      timer:stop()
      timer:close()
    end))
  end
end

-- Open location window and jump back to current window
function M.openDiagnostics()
  api.nvim_command("lopen")
  api.nvim_command("wincmd p")
end

return M
