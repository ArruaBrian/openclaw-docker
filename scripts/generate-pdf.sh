#!/bin/sh
# Generate PDF documents from markdown, HTML, or structured JSON
# Usage: generate-pdf.sh <output.pdf> [input.md | input.html | input.json]
#
# Examples:
#   generate-pdf.sh report.pdf content.md
#   generate-pdf.sh invoice.pdf data.json
#   echo "<h1>Hello</h1>" | generate-pdf.sh output.pdf

OUTPUT="$1"
INPUT="$2"

if [ -z "$OUTPUT" ]; then
  echo "Usage: generate-pdf.sh <output.pdf> [input.md | input.html | input.json]"
  exit 1
fi

python3 << 'PYEOF'
import sys, os, json

output = sys.argv[1] if len(sys.argv) > 1 else "/tmp/output.pdf"
input_file = sys.argv[2] if len(sys.argv) > 2 else None

from fpdf import FPDF
import markdown

class PDFReport(FPDF):
    def header(self):
        self.set_font("Helvetica", "B", 10)
        self.set_text_color(100, 100, 100)
        self.cell(0, 8, "", ln=True)

    def footer(self):
        self.set_y(-15)
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(128, 128, 128)
        self.cell(0, 10, f"Page {self.page_no()}/{{nb}}", align="C")

    def add_title(self, title):
        self.set_font("Helvetica", "B", 22)
        self.set_text_color(30, 30, 30)
        self.cell(0, 15, title, ln=True)
        self.ln(5)

    def add_heading(self, text, level=1):
        sizes = {1: 18, 2: 15, 3: 13}
        self.set_font("Helvetica", "B", sizes.get(level, 13))
        self.set_text_color(50, 50, 50)
        self.cell(0, 10, text, ln=True)
        self.ln(2)

    def add_body(self, text):
        self.set_font("Helvetica", "", 11)
        self.set_text_color(30, 30, 30)
        self.multi_cell(0, 6, text)
        self.ln(3)

    def add_bullet(self, text):
        self.set_font("Helvetica", "", 11)
        self.set_text_color(30, 30, 30)
        self.cell(8)
        self.cell(5, 6, chr(8226))
        self.multi_cell(0, 6, text)

    def add_table(self, headers, rows):
        self.set_font("Helvetica", "B", 10)
        self.set_fill_color(68, 114, 196)
        self.set_text_color(255, 255, 255)
        col_w = (self.w - 20) / len(headers)
        for h in headers:
            self.cell(col_w, 8, str(h), border=1, fill=True, align="C")
        self.ln()
        self.set_font("Helvetica", "", 10)
        self.set_text_color(30, 30, 30)
        for row in rows:
            for val in row:
                self.cell(col_w, 7, str(val), border=1)
            self.ln()
        self.ln(3)


def build_from_markdown(pdf, text):
    import re
    for line in text.split("\n"):
        line = line.rstrip()
        if not line:
            pdf.ln(3)
        elif line.startswith("# "):
            pdf.add_title(line[2:])
        elif line.startswith("## "):
            pdf.add_heading(line[3:], 2)
        elif line.startswith("### "):
            pdf.add_heading(line[4:], 3)
        elif line.startswith("- ") or line.startswith("* "):
            pdf.add_bullet(line[2:])
        elif line.startswith("---"):
            pdf.set_draw_color(200, 200, 200)
            pdf.line(10, pdf.get_y(), pdf.w - 10, pdf.get_y())
            pdf.ln(5)
        else:
            pdf.add_body(line)


def build_from_json(pdf, data):
    if "title" in data:
        pdf.add_title(data["title"])
    if "subtitle" in data:
        pdf.add_body(data["subtitle"])
    if "sections" in data:
        for s in data["sections"]:
            if "heading" in s:
                pdf.add_heading(s["heading"], s.get("level", 1))
            if "content" in s:
                pdf.add_body(s["content"])
            if "bullets" in s:
                for b in s["bullets"]:
                    pdf.add_bullet(b)
            if "table" in s:
                rows_data = s["table"]
                if rows_data:
                    headers = list(rows_data[0].keys())
                    rows = [[r.get(h, "") for h in headers] for r in rows_data]
                    pdf.add_table(headers, rows)


pdf = PDFReport()
pdf.alias_nb_pages()
pdf.add_page()
pdf.set_auto_page_break(auto=True, margin=15)

if input_file and os.path.exists(input_file):
    with open(input_file) as f:
        content = f.read()
    if input_file.endswith(".json"):
        build_from_json(pdf, json.loads(content))
    else:
        build_from_markdown(pdf, content)
elif not sys.stdin.isatty():
    content = sys.stdin.read()
    try:
        build_from_json(pdf, json.loads(content))
    except (json.JSONDecodeError, ValueError):
        build_from_markdown(pdf, content)
else:
    pdf.add_title("Generated Document")
    pdf.add_body("Pass markdown, HTML, or JSON to generate content.")

pdf.output(output)
print(f"✅ PDF generated: {output}")
PYEOF
