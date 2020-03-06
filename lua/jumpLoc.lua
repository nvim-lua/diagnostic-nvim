local vim = vim
local api = vim.api
local util = require'util'
local diagnostic = require'diagnostic'
local M = {}


---------------------------------
--  local function declartion  --
---------------------------------

-- currentLocation is an indicator that user has perform a jump
-- need to re-adjust prevLocationIndex and nextLocationIndex to prevent issues
local adjustLocation = function(row, col)
  if row > M.location[M.currentLocationIndex]['lnum'] or (row == M.location[M.currentLocationIndex]['lnum'] and col > M.location[M.currentLocationIndex]['col']) then
    M.prevLocationIndex = M.currentLocationIndex
  else
    M.nextLocationIndex = M.currentLocationIndex
  end
  M.currentLocationIndex = -1
end

local checkCurrentLocation = function(row, col)
  if row == M.location[M.currentLocationIndex]['lnum'] and col == M.location[M.currentLocationIndex]['col'] then
    return true
  -- handle C/C++ edge case
  elseif row == M.location[M.currentLocationIndex]['lnum'] then
    local line = api.nvim_get_current_line()
    if M.location[M.currentLocationIndex]['col'] > #line and col == #line then
      return true
    end
  end
  return false
end

-- check if M.prevLocationIndex is a valid next jump index
-- @Return bool: true if it's valid, false othwise
local checkPrevLocation = function(row, col)
  if M.prevLocationIndex == 0 then
    return true
  end
  if (row < M.location[M.prevLocationIndex]['lnum'] or (row == M.location[M.prevLocationIndex]['lnum'] and col < M.location[M.prevLocationIndex]['col'])) then
    return false
  else
    return true
  end
end

-- check if M.nextLocationIndex is a valid next jump index
-- @Return bool: true if it's valid, false othwise
local checkNextLocation = function(row, col)
  if M.nextLocationIndex >  #M.location then
    return true
  end
  if row > M.location[M.nextLocationIndex]['lnum'] or (row == M.location[M.nextLocationIndex]['lnum'] and col > M.location[M.nextLocationIndex]['col']) then
    return false
  else
    return true
  end
end

----------------------------------
--  member function declartion  --
----------------------------------

-- Init variable
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

  if M.currentLocationIndex ~= -1 then
    if M.currentLocationIndex > #M.location then
      M.currentLocationIndex = -1
    elseif checkCurrentLocation(current_row, current_col) then
      return
    else
      adjustLocation(current_row, current_col)
    end
  end
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
  M.initLocation()
end


function M.refreshBufEnter()
  -- HACK location list will not refresh when BufEnter
  -- Use :edit to force refresh buffer, not work if the buffer is modified
  local bufnr = api.nvim_win_get_buf(0)
  if diagnostic.bufferDiagnostic[bufnr] ~= nil then
    diagnostic.diagnostics_loclist(bufnr)
  end
end

-- Jump to next location
-- Show warning text when no next location is available
function M.jumpNextLocation()
  M.initLocation()
  if M.nextLocationIndex > #M.location or M.nextLocationIndex == -1 then
    api.nvim_command("echohl WarningMsg | echo 'no next diagnostic' | echohl None")
  else
    while true do
    end
    checkNextLocation()
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
  M.initLocation()
  if M.prevLocationIndex == 0 or M.prevLocationIndex == -1 then
    api.nvim_command("echohl WarningMsg | echo 'no previous diagnostic' | echohl None")
  else
    checkPrevLocation()
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
