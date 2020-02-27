local vim = vim
local M = {}

function M.modifyCallback()
  local method = 'textDocument/publishDiagnostics'
  -- local default_callback = vim.lsp.callbacks[method]
  vim.lsp.callbacks[method] = function(_, _, result, _)
    if not result then return end
    local uri = result.uri
    local bufnr = vim.uri_to_bufnr(uri)
    if not bufnr then
      vim.lsp.err_message("LSP.publishDiagnostics: Couldn't find buffer for ", uri)
      return
    end
    vim.lsp.util.buf_clear_diagnostics(bufnr)
    vim.lsp.util.buf_diagnostics_save_positions(bufnr, result.diagnostics)
    vim.lsp.util.buf_diagnostics_underline(bufnr, result.diagnostics)
    if vim.api.nvim_get_var('diagnostic_enable_virtual_text') == 1 then
      vim.lsp.util.buf_diagnostics_virtual_text(bufnr, result.diagnostics)
    end
    -- util.set_loclist(result.diagnostics)
    if result and result.diagnostics then
      for _, v in ipairs(result.diagnostics) do
        v.uri = v.uri or result.uri
      end
    end
    vim.lsp.util.set_loclist(result.diagnostics)
    local loc = require 'jumpLoc'
    -- loc.init will be set to false when BufEnter
    if loc.init == false then
      loc.initLocation()
      if vim.api.nvim_get_var('diagnostic_show_sign') == 1 then
        local sign = require 'sign'
        sign.initSign()
      end
    else
      loc.updateLocation()
    end
  end
end

return M

-- do
  -- local default_callback = vim.lsp.callbacks["textDocument/publishDiagnostics"]
  -- local err, method, params, client_id

  -- vim.lsp.callbacks["textDocument/publishDiagnostics"] = function(...)
    -- err, method, params, client_id = ...
    -- if vim.api.nvim_get_mode().mode ~= "i" then
      -- publish_diagnostics()
    -- end
  -- end

  -- function publish_diagnostics()
    -- default_callback(err, method, params, client_id)
  -- end
-- end

-- local on_attach = function(_, bufnr)
  -- vim.api.nvim_command [[autocmd InsertLeave <buffer> lua publish_diagnostics()]]
-- end

-- nvim_lsp.gopls.setup({on_attach=on_attach})

