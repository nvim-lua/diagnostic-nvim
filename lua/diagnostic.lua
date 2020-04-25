local vim = vim
local util = require 'diagnostic.util'
local M = {}

M.bufferDiagnostic = {}
local diagnosticTable = {}

local remove_diagnostics = function(diagnostics)
  -- Remove Index
  local remove = {}
  local level = vim.lsp.protocol.DiagnosticSeverity[vim.api.nvim_get_var('diagnostic_level')]
  for idx, diagnostic in ipairs(diagnostics) do
    if diagnostic.severity > level then
      remove[idx] = true
    else
      remove[idx] = false
    end
  end
  for i = #diagnostics, 1, -1 do
    if remove[i] then
      table.remove(diagnostics, i)
    end
  end
  return diagnostics
end

local get_diagnostics_count = function(diagnostics, bufnr)
  diagnosticTable.bufnr = {0, 0, 0, 0}
  for idx, diagnostic in pairs(diagnostics) do
    diagnosticTable.bufnr[diagnostic.severity] = diagnosticTable.bufnr[diagnostic.severity] + 1
  end
end

function M.modifyCallback()
  local callback = 'textDocument/publishDiagnostics'
  vim.lsp.callbacks[callback] = function(_, _, result, _)
    if not result then
      return
    end
    local uri = result.uri
    local bufnr = vim.uri_to_bufnr(uri)
    if not bufnr then
      vim.lsp.err_message("LSP.publishDiagnostics: Couldn't find buffer for ", uri)
      return
    end
    get_diagnostics_count(result.diagnostics, bufnr)
    if vim.api.nvim_get_var('diagnostic_level') ~= nil then
      result.diagnostics = remove_diagnostics(result.diagnostics)
    end
    M.bufferDiagnostic[bufnr] = result
    if vim.api.nvim_get_var('diagnostic_insert_delay') == 1 then
      if vim.api.nvim_get_mode()['mode'] == "i" or vim.api.nvim_get_mode()['mode'] == "ic" then
        return
      end
    end
    M.publish_diagnostics(bufnr)
  end
end

function M.diagnostics_loclist(local_result)
  if local_result and local_result.diagnostics then
    for _, v in ipairs(local_result.diagnostics) do
      v.uri = v.uri or local_result.uri
    end
  end
  vim.lsp.util.set_loclist(vim.lsp.util.locations_to_items(local_result.diagnostics))
end

function M.publish_diagnostics(bufnr)
  if #vim.lsp.buf_get_clients() == 0 then return end
  local result = M.bufferDiagnostic[bufnr]
  if result == nil then return end
  util.buf_clear_diagnostics(bufnr)
  util.buf_diagnostics_save_positions(bufnr, result.diagnostics)
  util.buf_diagnostics_underline(bufnr, result.diagnostics)
  if vim.api.nvim_get_var('diagnostic_show_sign') == 1 then
    util.buf_diagnostics_signs(bufnr, result.diagnostics)
  end
  if vim.api.nvim_get_var('diagnostic_enable_virtual_text') == 1 then
    util.buf_diagnostics_virtual_text(bufnr, result.diagnostics)
  end
  M.diagnostics_loclist(result)
  vim.api.nvim_command("doautocmd User LspDiagnosticsChanged")
end

function M.refresh_diagnostics()
  local bufnr = vim.api.nvim_win_get_buf(0)
  M.publish_diagnostics(bufnr)
end

function M.on_InsertLeave()
  M.refresh_diagnostics()
end

function M.getDiagnosticCount(level, bufnr)
  if diagnosticTable.bufnr == nil then
    return 0
  end
  return diagnosticTable.bufnr[level]
end


M.on_attach = function(_, _)
  -- Setup autocmd
  vim.api.nvim_command [[augroup DiagnosticRefresh]]
    vim.api.nvim_command [[autocmd BufWinEnter,TabEnter <buffer> lua require'diagnostic'.refresh_diagnostics()]]
  vim.api.nvim_command [[augroup end]]

  if vim.api.nvim_get_var('diagnostic_insert_delay') == 1 then
    vim.api.nvim_command [[augroup DiagnosticInsertDelay]]
      vim.api.nvim_command [[autocmd InsertLeave <buffer> lua require'diagnostic'.on_InsertLeave()]]
    vim.api.nvim_command [[augroup end]]
  end
end

return M
