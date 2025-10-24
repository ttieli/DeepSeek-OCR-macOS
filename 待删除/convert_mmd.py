#!/usr/bin/env python3
"""批量转换 .mmd 为 .md 格式（嵌入式版本）"""
import sys
import re
from pathlib import Path
from datetime import datetime

def convert_table(html):
    """简化的 HTML 表格转 Markdown"""
    tables = re.findall(r'<table>(.*?)</table>', html, re.DOTALL)
    result = html

    for table_html in tables:
        rows = re.findall(r'<tr>(.*?)</tr>', table_html, re.DOTALL)
        md_rows = []

        for row in rows:
            cells = re.findall(r'<t[dh](?:\s+[^>]*)?>(.*?)</t[dh]>', row, re.DOTALL)
            cleaned = [' '.join(re.sub(r'<[^>]+>', ' ', c).split()) for c in cells]
            if cleaned:
                md_rows.append(cleaned)

        if md_rows:
            max_cols = max(len(r) for r in md_rows)
            for row in md_rows:
                while len(row) < max_cols:
                    row.append('')

            md_table = ['| ' + ' | '.join(md_rows[0]) + ' |']
            md_table.append('|' + '|'.join([' --- ' for _ in range(max_cols)]) + '|')
            for row in md_rows[1:]:
                md_table.append('| ' + ' | '.join(row) + ' |')

            result = result.replace(f'<table>{table_html}</table>', '\n' + '\n'.join(md_table) + '\n')

    return result

if __name__ == "__main__":
    target = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("ocr_output")

    if target.is_file() and target.suffix == '.mmd':
        mmd_files = [target]
    elif target.is_dir():
        mmd_files = list(target.rglob("*.mmd"))
    else:
        sys.exit(0)

    for mmd_file in mmd_files:
        with open(mmd_file, 'r', encoding='utf-8') as f:
            content = f.read()

        converted = convert_table(content)
        header = f"# OCR 识别结果\n\n**转换时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n---\n\n"
        footer = "\n\n---\n\n*转换自 DeepSeek-OCR 输出*\n"

        output = mmd_file.parent / f"{mmd_file.stem}_标准格式.md"
        with open(output, 'w', encoding='utf-8') as f:
            f.write(header + converted + footer)

    if mmd_files:
        print(f"✓ 已转换 {len(mmd_files)} 个文件")
