-- Try to overwrite some util function

local protocol = require 'vim.lsp.protocol'
local vim = vim
local validate = vim.validate
local api = vim.api
-- TODO change all_buffer_diagnostics to built-in
local all_buffer_diagnostics = {}
local M ={}
local split = vim.split
local function split_lines(value)
  return split(value, '\n', true)
end

local function highlight_range(bufnr, ns, hiname, start, finish)
  if start[2] < 0 or finish[2] < start[2] then return end
  if start[1] == finish[1] then
    api.nvim_buf_add_highlight(bufnr, ns, hiname, start[1], start[2], finish[2])
  else
    api.nvim_buf_add_highlight(bufnr, ns, hiname, start[1], start[2], -1)
    for line = start[1] + 1, finish[1] - 1 do
      api.nvim_buf_add_highlight(bufnr, ns, hiname, line, 0, -1)
    end
    api.nvim_buf_add_highlight(bufnr, ns, hiname, finish[1], 0, finish[2])
  end
end

-- Get the built-in namespace and highlight
local diagnostic_ns = api.nvim_create_namespace("vim_lsp_diagnostics")
local sign_ns = 'vim_lsp_signs'
local underline_highlight_name = "LspDiagnosticsUnderline"

local severity_highlights = {
  [protocol.DiagnosticSeverity.Error] = "LspDiagnosticsError";
  [protocol.DiagnosticSeverity.Warning] = "LspDiagnosticsWarning";
  [protocol.DiagnosticSeverity.Information] = "LspDiagnosticsInformation";
  [protocol.DiagnosticSeverity.Hint] = "LspDiagnosticsHint";
}

function M.buf_diagnostics_save_positions(bufnr, diagnostics)
  validate {
    bufnr = {bufnr, 'n', true};
    diagnostics = {diagnostics, 't', true};
  }
  if not diagnostics then return end
  bufnr = bufnr == 0 and api.nvim_get_current_buf() or bufnr

  if not all_buffer_diagnostics[bufnr] then
    -- Clean up our data when the buffer unloads.
    api.nvim_buf_attach(bufnr, false, {
      on_detach = function(b)
        all_buffer_diagnostics[b] = nil
      end
    })
  end
  all_buffer_diagnostics[bufnr] = {}
  local buffer_diagnostics = all_buffer_diagnostics[bufnr]

  for _, diagnostic in ipairs(diagnostics) do
    local start = diagnostic.range.start
    -- local mark_id = api.nvim_buf_set_extmark(bufnr, diagnostic_ns, 0, start.line, 0, {})
    -- buffer_diagnostics[mark_id] = diagnostic
    local line_diagnostics = buffer_diagnostics[start.line]
    if not line_diagnostics then
      line_diagnostics = {}
      buffer_diagnostics[start.line] = line_diagnostics
    end
    table.insert(line_diagnostics, diagnostic)
  end
end

function M.buf_diagnostics_virtual_text(bufnr, diagnostics)
  local buffer_line_diagnostics = all_buffer_diagnostics[bufnr]
  local prefix = api.nvim_get_var('diagnostic_virtual_text_prefix')
  local spaces = string.rep(" ", api.nvim_get_var('space_before_virtual_text'))
  if not buffer_line_diagnostics then
    M.buf_diagnostics_save_positions(bufnr, diagnostics)
  end
  buffer_line_diagnostics = all_buffer_diagnostics[bufnr]
  if not buffer_line_diagnostics then
    return
  end
  for line, line_diags in pairs(buffer_line_diagnostics) do
    local virt_texts = {}
    table.insert(virt_texts, {spaces})
    for i = 1, #line_diags - 1 do
      table.insert(virt_texts, {prefix, severity_highlights[line_diags[i].severity]})
    end
    local last = line_diags[#line_diags]
    -- TODO(ashkan) use first line instead of subbing 2 spaces?
    if api.nvim_get_var('diagnostic_trimmed_virtual_text') ~= nil then
      local trimmed_text = last.message:gsub("\r", ""):gsub("\n", "  ")
      trimmed_text = string.sub(trimmed_text, 1, api.nvim_get_var('diagnostic_trimmed_virtual_text'))
      if #trimmed_text == api.nvim_get_var('diagnostic_trimmed_virtual_text') and vim.g.diagnostic_trimmed_virtual_text ~= 0 then
        trimmed_text = trimmed_text.."..."
      end
      table.insert(virt_texts, {prefix.." "..trimmed_text, severity_highlights[last.severity]})
    else
      table.insert(virt_texts, {prefix.." "..last.message:gsub("\r", ""):gsub("\n", "  "), severity_highlights[last.severity]})
    end
    api.nvim_buf_set_virtual_text(bufnr, diagnostic_ns, line, virt_texts, {})
  end
end

function M.buf_diagnostics_signs(bufnr, diagnostics)
  for _, diagnostic in ipairs(diagnostics) do
    local diagnostic_severity_map = {
      [protocol.DiagnosticSeverity.Error] = "LspDiagnosticsErrorSign";
      [protocol.DiagnosticSeverity.Warning] = "LspDiagnosticsWarningSign";
      [protocol.DiagnosticSeverity.Information] = "LspDiagnosticsInformationSign";
      [protocol.DiagnosticSeverity.Hint] = "LspDiagnosticsHintSign";
    }
    vim.fn.sign_place(0, sign_ns, diagnostic_severity_map[diagnostic.severity], bufnr, {lnum=(diagnostic.range.start.line+1), priority=vim.g.diagnostic_sign_priority})
  end
end

return M
