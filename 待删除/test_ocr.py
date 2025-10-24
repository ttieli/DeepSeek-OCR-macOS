from transformers import AutoModel, AutoTokenizer
import torch
import os

# 配置MacOS ARM优化
if torch.backends.mps.is_available():
    print("✓ MPS (Metal Performance Shaders) 可用")
    device = "mps"
else:
    print("⚠ MPS 不可用，使用 CPU")
    device = "cpu"

os.environ["PYTORCH_MPS_HIGH_WATERMARK_RATIO"] = "0.0"

# 加载模型和分词器
model_name = 'deepseek-ai/DeepSeek-OCR'
print(f"正在加载模型: {model_name}")
print("首次运行会从 Hugging Face 下载模型，可能需要较长时间...")

tokenizer = AutoTokenizer.from_pretrained(
    model_name,
    trust_remote_code=True
)

model = AutoModel.from_pretrained(
    model_name,
    _attn_implementation='flash_attention_2',
    trust_remote_code=True,
    use_safetensors=True
)

model = model.eval().to(torch.bfloat16).to(device)

print(f"✓ 模型加载成功，使用设备: {device}")
print("")
print("使用示例:")
print("  prompt = '<image>\\n<|grounding|>Convert the document to markdown.'")
print("  image_file = 'your_image.jpg'")
print("  output_path = 'output/'")
print("")
print("  res = model.infer(")
print("      tokenizer,")
print("      prompt=prompt,")
print("      image_file=image_file,")
print("      output_path=output_path,")
print("      base_size=1024,")
print("      image_size=640,")
print("      crop_mode=True,")
print("      save_results=True,")
print("      test_compress=True")
print("  )")
