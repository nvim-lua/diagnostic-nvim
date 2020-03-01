local vim = vim
local M = {}
local err, method, result, client_id


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

  if vim.api.nvim_get_var('diagnostic_show_sign') == 1 then
    vim.api.nvim_command [[augroup DiagnosticSign]]
      vim.api.nvim_command [[autocmd!]]
      vim.api.nvim_command [[autocmd InsertLeave,CursorHold <buffer> lua require'sign'.updateSign()]]
    vim.api.nvim_command [[augroup end]]
  end

  if vim.api.nvim_get_var('diagnostic_insert_delay') == 1 then
    vim.api.nvim_command [[augroup DiagnosticInsertDelay]]
      vim.api.nvim_command [[autocmd!]]
      vim.api.nvim_command [[autocmd InsertLeave, CursorHold <buffer> lua require'diagnostic'.publish_diagnostics()]]
    vim.api.nvim_command [[augroup end]]
  end
end

return M

