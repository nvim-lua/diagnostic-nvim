local api = vim.api
local M = {}


function M.initSign()
  -- TODO
  local location = api.nvim_call_function('getloclist', {0})
  for _, v in ipairs(location) do
    local bufName = api.nvim_buf_get_name(v['bufnr'])
    M.placeSign(v['lnum'], bufName)
 end
end

function M.updateSign()
  -- TODO
  local bufName = api.nvim_buf_get_name(0)
  local opts = {buffer = bufName}
  api.nvim_call_function('sign_unplace', {'DiagnosticSign', opts})
  M.initSign()
end

function M.placeSign(num, bufName)
  local opts = {lnum = num}
  api.nvim_call_function("sign_place", {0, 'DiagnosticSign', 'DiagnosticErrorSign', bufName, opts})
end

return M
