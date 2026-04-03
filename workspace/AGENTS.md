# AGENTS.md — OpenClaw Document Tools

## Available Document Generation Tools

You have shell scripts in `/usr/local/bin/` for generating and sending documents. Use them whenever the user asks for a document, report, spreadsheet, or file.

### generate-excel.sh — Create Excel files (.xlsx)

```bash
# From JSON data
generate-excel.sh /home/node/workspace/output.xlsx data.json

# From piped JSON (array of objects)
echo '[{"Producto":"Widget","Cantidad":50,"Precio":9.99},{"Producto":"Gadget","Cantidad":30,"Precio":19.99}]' | generate-excel.sh /home/node/workspace/report.xlsx
```

- Input: JSON array of objects (each object = row, keys = column headers)
- Output: Formatted .xlsx with styled headers, borders, auto-width columns
- Use `pandas` + `xlsxwriter` for complex cases (pivot tables, multiple sheets, charts)

### generate-docx.sh — Create Word documents (.docx)

```bash
# From markdown
generate-docx.sh /home/node/workspace/report.docx content.md

# From structured JSON
echo '{"title":"Monthly Report","sections":[{"heading":"Summary","content":"All good.","bullets":["Revenue up 15%","Costs down 3%"]},{"heading":"Data","table":[{"Month":"Jan","Revenue":1000},{"Month":"Feb","Revenue":1150}]}]}' | generate-docx.sh /home/node/workspace/report.docx

# From piped markdown
echo "# Report\n## Section 1\nSome content\n- Bullet 1\n- Bullet 2" | generate-docx.sh /home/node/workspace/report.docx
```

- Input: Markdown text OR JSON with `title`, `subtitle`, `sections` (each section can have `heading`, `content`, `bullets`, `table`)
- Output: Formatted .docx with headings, lists, tables, proper styles

### generate-pdf.sh — Create PDF documents

```bash
# From markdown
generate-pdf.sh /home/node/workspace/report.pdf content.md

# From structured JSON (same format as docx)
echo '{"title":"Invoice","sections":[...]}' | generate-pdf.sh /home/node/workspace/invoice.pdf

# From piped markdown
echo "# Title\nContent here" | generate-pdf.sh /home/node/workspace/doc.pdf
```

- Input: Markdown text OR JSON (same structure as docx)
- Output: Styled PDF with page numbers, colored table headers, proper typography

### send-to-discord.sh — Send files to Discord

```bash
send-to-discord.sh /home/node/workspace/report.pdf CHANNEL_ID "Here's your report"
```

- Requires `DISCORD_BOT_TOKEN` env var (already configured)
- The bot must have Send Messages + Attach Files permissions in the target channel

---

## Workflow: When user asks for a document

1. Gather/generate the data (from conversation, web search, calculations, etc.)
2. Create a JSON or markdown temp file with the content
3. Run the appropriate `generate-*.sh` script to create the document
4. If user wants it on Discord: use `send-to-discord.sh` to send it
5. Always tell the user the file path so they can also download it

## Python Libraries Available

For complex documents beyond what the scripts handle, write inline Python:

- **Excel**: `xlsxwriter` (formatting), `openpyxl` (read/write), `pandas` (data manipulation)
- **Word**: `python-docx` (full control over styles, images, headers/footers)
- **PDF**: `fpdf2` (lightweight), `reportlab` (advanced layouts), `weasyprint` (HTML→PDF), `pypdf` (merge/split)
- **Charts**: `matplotlib` (graphs, charts for embedding in documents)
- **Templates**: `jinja2` (template-based document generation)
- **Markdown**: `markdown` (convert md to HTML for weasyprint)

## Important Notes

- Always save generated files to `/home/node/workspace/` so they persist across restarts
- For large Excel files with charts, use Python directly with `xlsxwriter` or `matplotlib`
- For complex PDF layouts (invoices, contracts), use `reportlab` or `weasyprint` with HTML templates
- LibreOffice is also installed — use `libreoffice --headless --convert-to pdf` to convert between formats
