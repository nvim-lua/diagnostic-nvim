local vim = vim
local util = require 'util'
local M = {}
local err, method, result, client_id

M.bufferDiagnostic = {}

function M.modifyCallback()
  local callback = 'textDocument/publishDiagnostics'
  vim.lsp.callbacks[callback] = function(...)
    err, method, result, client_id = ...
    if vim.api.nvim_get_var('diagnostic_insert_delay') == 1 then
      if vim.api.nvim_get_mode()['mode'] == "i" or vim.api.nvim_get_mode()['mode'] == "ic" then
        return
      end
    end
    if not result then
      return
    end
    local uri = result.uri
    local bufnr = vim.uri_to_bufnr(uri)
    M.bufferDiagnostic[bufnr] = result
    if not bufnr then
      vim.lsp.err_message("LSP.publishDiagnostics: Couldn't find buffer for ", uri)
      return
    end
    util.buf_clear_diagnostics(bufnr)
    util.buf_diagnostics_save_positions(bufnr, result.diagnostics)
    util.buf_diagnostics_underline(bufnr, result.diagnostics)
    if vim.api.nvim_get_var('diagnostic_show_sign') == 1 then
      util.buf_diagnostics_signs(bufnr, result.diagnostics)
    end
    if vim.api.nvim_get_var('diagnostic_enable_virtual_text') == 1 then
      util.buf_diagnostics_virtual_text(bufnr, result.diagnostics)
    end
    vim.api.nvim_command("doautocmd User LspDiagnosticsChanged")
    -- util.set_loclist(result.diagnostics)
    M.diagnostics_loclist(bufnr)
    local loc = require 'jumpLoc'
    -- loc.init will be set to false when BufEnter
    if loc.init == false then
      loc.initLocation()
    else
      loc.updateLocation()
    end
  end
end

function M.diagnostics_loclist(bufnr)
  local local_result = M.bufferDiagnostic[bufnr]
  if local_result and local_result.diagnostics then
    for _, v in ipairs(local_result.diagnostics) do
      v.uri = v.uri or local_result.uri
    end
  end
  vim.lsp.util.set_loclist(vim.lsp.util.locations_to_items(local_result.diagnostics))
end

function M.publish_diagnostics()
  local default_callback = vim.lsp.callbacks["textDocument/publishDiagnostics"]
  default_callback(err, method, result, client_id)
end

M.on_attach = function(_, _)
  -- Setup autocmd
  vim.api.nvim_command [[augroup DiagnosticRefresh]]
    vim.api.nvim_command [[autocmd!]]
    vim.api.nvim_command [[autocmd InsertLeave <buffer> lua require'jumpLoc'.initLocation()]]
    vim.api.nvim_command [[autocmd BufEnter <buffer> lua require'jumpLoc'.refreshBufEnter()]]
  vim.api.nvim_command [[augroup end]]

  if vim.api.nvim_get_var('diagnostic_insert_delay') == 1 then
    vim.api.nvim_command [[augroup DiagnosticInsertDelay]]
      vim.api.nvim_command [[autocmd!]]
      vim.api.nvim_command [[autocmd InsertLeave <buffer> lua require'diagnostic'.publish_diagnostics()]]
    vim.api.nvim_command [[augroup end]]
  end
end

return M

