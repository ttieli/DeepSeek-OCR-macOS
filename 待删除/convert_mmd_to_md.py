#!/usr/bin/env python3
"""
将 DeepSeek-OCR 输出的 .mmd 文件转换为标准 Markdown 格式
"""

import sys
import re
from pathlib import Path
from datetime import datetime

def convert_html_table_to_markdown(html_content):
    """
    将 HTML 表格转换为 Markdown 表格
    简化版本：提取表格内容并格式化
    """
    # 提取表格内容
    table_pattern = r'<table>(.*?)</table>'
    tables = re.findall(table_pattern, html_content, re.DOTALL)

    if not tables:
        return html_content

    result = html_content

    for table_html in tables:
        # 提取所有行
        rows = re.findall(r'<tr>(.*?)</tr>', table_html, re.DOTALL)

        if not rows:
            continue

        markdown_rows = []

        for row in rows:
            # 提取单元格（th 或 td）
            cells = re.findall(r'<t[dh](?:\s+[^>]*)?>(.*?)</t[dh]>', row, re.DOTALL)

            # 清理单元格内容
            cleaned_cells = []
            for cell in cells:
                # 移除 HTML 标签
                cell = re.sub(r'<[^>]+>', ' ', cell)
                # 清理空白
                cell = ' '.join(cell.split())
                cleaned_cells.append(cell)

            if cleaned_cells:
                markdown_rows.append(cleaned_cells)

        # 生成 Markdown 表格
        if markdown_rows:
            # 找出每列的最大宽度
            max_cols = max(len(row) for row in markdown_rows)

            # 补齐所有行
            for row in markdown_rows:
                while len(row) < max_cols:
                    row.append('')

            # 生成表格
            md_table = []

            # 表头
            header = '| ' + ' | '.join(markdown_rows[0]) + ' |'
            separator = '|' + '|'.join([' --- ' for _ in range(max_cols)]) + '|'

            md_table.append(header)
            md_table.append(separator)

            # 数据行
            for row in markdown_rows[1:]:
                md_table.append('| ' + ' | '.join(row) + ' |')

            # 替换原表格
            result = result.replace(f'<table>{table_html}</table>', '\n' + '\n'.join(md_table) + '\n')

    return result

def convert_mmd_to_md(mmd_file):
    """
    转换 .mmd 文件为 .md 文件
    """
    mmd_path = Path(mmd_file)

    if not mmd_path.exists():
        print(f"❌ 文件不存在: {mmd_file}")
        return False

    # 读取 .mmd 文件
    with open(mmd_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 转换 HTML 表格
    converted_content = convert_html_table_to_markdown(content)

    # 添加文档头部
    header = f"""# OCR 识别结果 - 标准 Markdown 版本

**转换时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
**原始文件**: {mmd_path.name}
**转换工具**: DeepSeek-OCR mmd2md converter

---

"""

    # 添加文档尾部
    footer = f"""

---

*本文档由 DeepSeek-OCR 自动识别，并转换为标准 Markdown 格式。*
"""

    final_content = header + converted_content + footer

    # 保存为 .md 文件
    output_path = mmd_path.parent / f"{mmd_path.stem}_converted.md"

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(final_content)

    print(f"✓ 转换完成")
    print(f"  输入: {mmd_path}")
    print(f"  输出: {output_path}")

    return True

def batch_convert(directory):
    """
    批量转换目录中的所有 .mmd 文件
    """
    dir_path = Path(directory)

    if not dir_path.exists():
        print(f"❌ 目录不存在: {directory}")
        return

    # 查找所有 .mmd 文件
    mmd_files = list(dir_path.rglob("*.mmd"))

    if not mmd_files:
        print(f"❌ 在 {directory} 中未找到 .mmd 文件")
        return

    print(f"找到 {len(mmd_files)} 个 .mmd 文件")
    print()

    success = 0
    failed = 0

    for mmd_file in mmd_files:
        print(f"[{success + failed + 1}/{len(mmd_files)}] 转换: {mmd_file.name}")
        if convert_mmd_to_md(mmd_file):
            success += 1
        else:
            failed += 1
        print()

    print("=" * 60)
    print(f"转换完成: 成功 {success}，失败 {failed}")
    print("=" * 60)

if __name__ == "__main__":
    print("=" * 60)
    print("DeepSeek-OCR .mmd 到 .md 转换工具")
    print("=" * 60)
    print()

    if len(sys.argv) < 2:
        print("用法:")
        print("  1. 转换单个文件:")
        print("     python3 convert_mmd_to_md.py result.mmd")
        print()
        print("  2. 批量转换目录:")
        print("     python3 convert_mmd_to_md.py ocr_output/")
        print()
        sys.exit(1)

    target = sys.argv[1]
    target_path = Path(target)

    if target_path.is_file() and target_path.suffix == '.mmd':
        # 转换单个文件
        convert_mmd_to_md(target)
    elif target_path.is_dir():
        # 批量转换
        batch_convert(target)
    else:
        print(f"❌ 无效的输入: {target}")
        print("请提供 .mmd 文件或包含 .mmd 文件的目录")
