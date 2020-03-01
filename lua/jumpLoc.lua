local vim = vim
local api = vim.api
local lsp = vim.lsp
local M = {}

M.init = false
M.prevLocationIndex = -1
M.currentLocationIndex = -1
M.nextLocationIndex = -1
-- Initialize location and set jump index

function M.initLocation()
  -- TODO
  M.location = api.nvim_call_function('getloclist', {0})
  if #M.location == 0 then
    -- let both index be invalid
    M.prevLocationIndex = -1
    M.nextLocationIndex = -1
    return
  end
  local current_row = api.nvim_call_function('line', {"."})
  local current_col = api.nvim_call_function('col', {"."})
  for i, v in ipairs(M.location) do
    if v['lnum'] > current_row or (v['lnum'] == current_row and v['col'] > current_col) then
      M.nextLocationIndex = i
      M.prevLocationIndex = i-1
      return
    end
  end

  -- TODO Documentation
  M.nextLocationIndex = #M.location+1
  M.prevLocationIndex = #M.location
  M.init = true
end

-- Update location and jump index upon changing location list
function M.updateLocation()
  M.location = api.nvim_call_function('getloclist', {0})
  if #M.location == 0 then
    M.prevLocationIndex = -1
    M.nextLocationIndex = -1
  end
  M.currentLocationIndex = -1
  M.initLocation()
end

-- adjust location
function M.updatePosition()
  if M.prevLocationIndex == -1 and M.nextLocationIndex == -1 then
    M.initLocation()
    return
  end
  -- Solve some unknown issue
  -- if M.prevLocationIndex > #M.location or M.nextLocationIndex > #M.location then
    -- M.initLocation()
    -- return
  -- end
  local row = api.nvim_call_function('line', {"."})
  local col = api.nvim_call_function('col', {"."})

  if M.currentLocationIndex ~= -1 then
    if row == M.location[M.currentLocationIndex]['lnum'] and col == M.location[M.currentLocationIndex]['col'] then
      return
    end
    M.checkCurrentLocation(row, col)
  end
  if not M.checkNextLocation(row, col) then
    -- loop till finding a valid index
    repeat
      M.nextLocationIndex = M.nextLocationIndex + 1
      if M.nextLocationIndex > #M.location then
        break
      end
    until M.checkNextLocation(row, col)
    M.prevLocationIndex = M.nextLocationIndex - 1

  elseif not M.checkPrevLocation(row, col) then
    repeat
      M.prevLocationIndex = M.prevLocationIndex - 1
      if M.prevLocationIndex == 0 then
        break
      end
    until M.checkPrevLocation(row, col)
    M.nextLocationIndex = M.prevLocationIndex + 1
  end
end

function M.refreshBufEnter()
  -- HACK location list will not refresh when BufEnter
  -- Use :edit to force refresh buffer, not work if the buffer is modified
  if api.nvim_buf_get_name(0) ~= '' and #vim.inspect(vim.lsp.buf_get_clients()) ~= 0 then
    api.nvim_command("silent! exec 'edit'")
    M.init = false
  end
end

-- Jump to next location
-- Show warning text when no next location is available
function M.jumpNextLocation()
  M.updatePosition()
  if M.nextLocationIndex > #M.location or M.nextLocationIndex == -1 then
    api.nvim_command("echohl WarningMsg | echo 'no next diagnostic' | echohl None")
  else
    api.nvim_command("ll"..M.nextLocationIndex)
    M.currentLocationIndex = M.nextLocationIndex
    M.nextLocationIndex = M.currentLocationIndex + 1
    M.prevLocationIndex = M.currentLocationIndex - 1
    M.openLineDiagnostics()
  end
end

-- Jump to previous location
-- Show warning text when no previous location is available
function M.jumpPrevLocation()
  M.updatePosition()
  if M.prevLocationIndex == 0 or M.prevLocationIndex == -1 then
    api.nvim_command("echohl WarningMsg | echo 'no previous diagnostic' | echohl None")
  else
    api.nvim_command("ll"..M.prevLocationIndex)
    M.currentLocationIndex = M.prevLocationIndex
    M.nextLocationIndex = M.currentLocationIndex + 1
    M.prevLocationIndex = M.currentLocationIndex - 1
    M.openLineDiagnostics()
  end
end

-- Open line diagnostics when jump
-- Don't do anything if diagnostic_auto_popup_while_jump == 0
-- NOTE need to delay a certain amount of time to show correctly
function M.openLineDiagnostics()
  if api.nvim_get_var('diagnostic_auto_popup_while_jump') == 1 then
    local timer = vim.loop.new_timer()
    timer:start(100, 0, vim.schedule_wrap(function()
      lsp.util.show_line_diagnostics()
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

-- check if M.nextLocationIndex is a valid next jump index
-- @Return bool: true if it's valid, false othwise
function M.checkNextLocation(row, col)
  if M.nextLocationIndex >  #M.location then
    return true
  end
  if row > M.location[M.nextLocationIndex]['lnum'] or (row == M.location[M.nextLocationIndex]['lnum'] and col > M.location[M.nextLocationIndex]['col']) then
    return false
  else
    return true
  end
end

-- check if M.prevLocationIndex is a valid next jump index
-- @Return bool: true if it's valid, false othwise
function M.checkPrevLocation(row, col)
  if M.prevLocationIndex == 0 then
    return true
  end
  if (row < M.location[M.prevLocationIndex]['lnum'] or (row == M.location[M.prevLocationIndex]['lnum'] and col < M.location[M.prevLocationIndex]['col'])) then
    return false
  else
    return true
  end
end

-- currentLocation is an indicator that user has perform a jump
-- need to re-adjust prevLocationIndex and nextLocationIndex to prevent issues
function M.checkCurrentLocation(row, col)
  if row == M.location[M.currentLocationIndex]['lnum'] and col == M.location[M.currentLocationIndex]['col'] then
    return
  elseif row > M.location[M.currentLocationIndex]['lnum'] or (row == M.location[M.currentLocationIndex]['lnum'] and col > M.location[M.currentLocationIndex]['col']) then
    M.prevLocationIndex = M.currentLocationIndex
  else
    M.nextLocationIndex = M.currentLocationIndex
  end
  M.currentLocationIndex = -1
end

return M
