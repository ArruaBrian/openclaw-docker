#!/bin/sh
# Generate Excel files from JSON data or inline
# Usage: generate-excel.sh <output.xlsx> [json-data-file]
#
# Examples:
#   generate-excel.sh report.xlsx data.json
#   echo '[{"name":"John","age":30}]' | generate-excel.sh report.xlsx

OUTPUT="$1"
JSON_FILE="$2"

if [ -z "$OUTPUT" ]; then
  echo "Usage: generate-excel.sh <output.xlsx> [json-data-file]"
  echo "  Or pipe JSON: echo '[{...}]' | generate-excel.sh output.xlsx"
  exit 1
fi

python3 << 'PYEOF'
import json, sys, os

try:
    import xlsxwriter
except ImportError:
    import openpyxl

output = sys.argv[1] if len(sys.argv) > 1 else "/tmp/output.xlsx"
json_file = sys.argv[2] if len(sys.argv) > 2 else None

# Read data from file or stdin
if json_file and os.path.exists(json_file):
    with open(json_file) as f:
        data = json.load(f)
elif not sys.stdin.isatty():
    data = json.load(sys.stdin)
else:
    # Demo data
    data = [
        {"Column A": "Value 1", "Column B": 100},
        {"Column A": "Value 2", "Column B": 200},
    ]

# Generate with xlsxwriter (better formatting)
wb = xlsxwriter.Workbook(output)
ws = wb.add_worksheet("Sheet1")

# Styles
header_fmt = wb.add_format({"bold": True, "bg_color": "#4472C4", "font_color": "white", "border": 1})
cell_fmt = wb.add_format({"border": 1})
number_fmt = wb.add_format({"border": 1, "num_format": "#,##0.00"})

if isinstance(data, list) and len(data) > 0:
    headers = list(data[0].keys())
    for col, h in enumerate(headers):
        ws.write(0, col, h, header_fmt)
        ws.set_column(col, col, max(len(h) + 4, 15))

    for row_idx, row_data in enumerate(data, 1):
        for col, h in enumerate(headers):
            val = row_data.get(h, "")
            fmt = number_fmt if isinstance(val, (int, float)) else cell_fmt
            ws.write(row_idx, col, val, fmt)

wb.close()
print(f"✅ Excel generated: {output}")
PYEOF
