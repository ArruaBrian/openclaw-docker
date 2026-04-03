#!/bin/sh
# Generate Word documents (.docx) from markdown or structured content
# Usage: generate-docx.sh <output.docx> [input.md | input.json]
#
# Examples:
#   generate-docx.sh report.docx content.md
#   generate-docx.sh report.docx data.json
#   echo "# Title\nSome content" | generate-docx.sh report.docx

OUTPUT="$1"
INPUT="$2"

if [ -z "$OUTPUT" ]; then
  echo "Usage: generate-docx.sh <output.docx> [input.md | input.json]"
  exit 1
fi

python3 << 'PYEOF'
import sys, os, json, re

from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH

output = sys.argv[1] if len(sys.argv) > 1 else "/tmp/output.docx"
input_file = sys.argv[2] if len(sys.argv) > 2 else None

doc = Document()

# Style defaults
style = doc.styles["Normal"]
font = style.font
font.name = "Calibri"
font.size = Pt(11)

def add_markdown_content(doc, text):
    """Parse basic markdown and add to docx."""
    for line in text.split("\n"):
        line = line.rstrip()
        if not line:
            doc.add_paragraph("")
        elif line.startswith("# "):
            doc.add_heading(line[2:], level=1)
        elif line.startswith("## "):
            doc.add_heading(line[3:], level=2)
        elif line.startswith("### "):
            doc.add_heading(line[4:], level=3)
        elif line.startswith("- ") or line.startswith("* "):
            doc.add_paragraph(line[2:], style="List Bullet")
        elif re.match(r"^\d+\. ", line):
            doc.add_paragraph(re.sub(r"^\d+\. ", "", line), style="List Number")
        elif line.startswith("> "):
            p = doc.add_paragraph(line[2:])
            p.style = doc.styles["Intense Quote"] if "Intense Quote" in [s.name for s in doc.styles] else doc.styles["Normal"]
        elif line.startswith("---"):
            doc.add_paragraph("─" * 50)
        else:
            doc.add_paragraph(line)

def add_json_content(doc, data):
    """Build docx from structured JSON."""
    if isinstance(data, dict):
        if "title" in data:
            doc.add_heading(data["title"], level=0)
        if "subtitle" in data:
            p = doc.add_paragraph(data["subtitle"])
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        if "sections" in data:
            for section in data["sections"]:
                if "heading" in section:
                    doc.add_heading(section["heading"], level=section.get("level", 1))
                if "content" in section:
                    doc.add_paragraph(section["content"])
                if "bullets" in section:
                    for b in section["bullets"]:
                        doc.add_paragraph(b, style="List Bullet")
                if "table" in section:
                    table_data = section["table"]
                    if len(table_data) > 0:
                        headers = list(table_data[0].keys())
                        table = doc.add_table(rows=1, cols=len(headers), style="Light Grid Accent 1")
                        for i, h in enumerate(headers):
                            table.rows[0].cells[i].text = str(h)
                        for row_data in table_data:
                            row = table.add_row()
                            for i, h in enumerate(headers):
                                row.cells[i].text = str(row_data.get(h, ""))

# Read input
if input_file and os.path.exists(input_file):
    with open(input_file) as f:
        content = f.read()
    if input_file.endswith(".json"):
        add_json_content(doc, json.loads(content))
    else:
        add_markdown_content(doc, content)
elif not sys.stdin.isatty():
    content = sys.stdin.read()
    try:
        add_json_content(doc, json.loads(content))
    except (json.JSONDecodeError, ValueError):
        add_markdown_content(doc, content)
else:
    doc.add_heading("Document", level=0)
    doc.add_paragraph("Generated document — add content via markdown or JSON input.")

doc.save(output)
print(f"✅ DOCX generated: {output}")
PYEOF
