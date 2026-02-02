#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
将原始文本文件转换为 JSON 格式的数据导入脚本
用法: python3 convert-to-json.py
"""

import json
import sys

def convert_text_to_json(input_file, output_file):
    """
    将文本文件转换为 JSON 格式

    Args:
        input_file: 输入的原始文本文件路径
        output_file: 输出的 JSON 文件路径
    """
    try:
        # 读取原始文本文件
        with open(input_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        # 过滤空行并转换为字符串数组
        data = []
        for line in lines:
            line = line.strip()
            if line:  # 跳过空行
                # 将 \r 和 \n 转换为真正的换行符
                line = line.replace('\\r', '\r').replace('\\n', '\n')
                data.append(line)

        # 写入 JSON 文件
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        print(f'✅ 成功转换 {len(data)} 条数据')
        print(f'📁 输入文件: {input_file}')
        print(f'📁 输出文件: {output_file}')

        return True

    except FileNotFoundError:
        print(f'❌ 错误: 找不到文件 {input_file}')
        return False
    except Exception as e:
        print(f'❌ 转换失败: {e}')
        return False


if __name__ == '__main__':
    # 假设原始文件名为 data-raw.txt（你需要把原始文件重命名）
    # 输出文件为 data.json

    input_file = 'data-raw.txt'
    output_file = 'data.json'

    print('🚀 开始转换数据格式...\n')

    if convert_text_to_json(input_file, output_file):
        print('\n✨ 转换完成！现在可以运行 npm run import 导入数据了')
    else:
        print('\n💥 转换失败，请检查错误信息')
        sys.exit(1)
