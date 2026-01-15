import os
import sys
import site
import shutil
import requests
from pathlib import Path
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn
from huggingface_hub import snapshot_download
import torch
import re

console = Console()

DEEPSEEK_REPO = "deepseek-ai/DeepSeek-OCR"
DEFAULT_CACHE_DIR = Path.home() / ".cache" / "huggingface" / "hub"

def check_model_exists(custom_dir=None):
    """
    Check if the DeepSeek-OCR model exists locally.
    Prioritizes:
    1. custom_dir (CLI arg)
    2. DSOCR_MODEL_DIR (Env var)
    3. HF_HOME (Env var)
    4. Default HF cache
    Returns the path to the model if found, else None.
    """
    # 0. Check Env Var Override
    env_model_dir = os.environ.get("DSOCR_MODEL_DIR")
    if env_model_dir:
        path = Path(env_model_dir)
        if path.exists() and (path / "config.json").exists():
             console.print(f"[dim]Found model in DSOCR_MODEL_DIR: {path}[/dim]")
             return path

    # 1. Check Custom Directory (CLI arg)
    if custom_dir:
        path = Path(custom_dir)
        if path.exists() and (path / "config.json").exists():
            return path
            
    # 2. Check Hugging Face Cache (Standard Structure)
    # The standard HF cache structure is models--<org>--<repo>/snapshots/<commit_hash>
    # We look for the folder structure.
    
    hf_home = os.environ.get("HF_HOME", DEFAULT_CACHE_DIR)
    repo_dir = Path(hf_home) / f"models--{DEEPSEEK_REPO.replace('/', '--')}"
    
    if repo_dir.exists():
        # Check inside snapshots
        snapshots_dir = repo_dir / "snapshots"
        if snapshots_dir.exists():
            # Get latest snapshot (usually there's only one or we pick the recent)
            snapshots = sorted(snapshots_dir.iterdir(), key=os.path.getmtime, reverse=True)
            for snapshot in snapshots:
                if (snapshot / "config.json").exists():
                    return snapshot
                    
    return None

def download_model(target_dir=None):
    """
    Download the model using huggingface_hub if not present.
    Respects DSOCR_OFFLINE env var.
    """
    if os.environ.get("DSOCR_OFFLINE") == "1":
        console.print("[bold red]DSOCR_OFFLINE is set. Model not found locally and download is disabled.[/bold red]")
        sys.exit(1)

    console.print(f"[bold blue]Model not found locally.[/bold blue]")
    console.print(f"Downloading {DEEPSEEK_REPO} (approx. 10GB)...")
    
    try:
        path = snapshot_download(
            repo_id=DEEPSEEK_REPO,
            local_dir=target_dir, # If None, uses default HF cache
            repo_type="model",
            resume_download=True
        )
        console.print(f"[green]Model downloaded to: {path}[/green]")
        return Path(path)
    except Exception as e:
        console.print(f"[bold red]Download failed: {e}[/bold red]")
        sys.exit(1)

def disable_cuda(device: str):
    """
    Force-disable CUDA paths when running on CPU/MPS by monkeypatching torch cuda helpers.
    The upstream DeepSeek-OCR infer call uses `.cuda()` directly; on macOS/CPU we redirect
    to `.to(device)` instead of crashing.
    Also handles dtype conversion since MPS doesn't support bfloat16.
    """
    if device == "cuda":
        return
    os.environ["CUDA_VISIBLE_DEVICES"] = "-1"
    # Monkeypatch torch.cuda.is_available
    torch.cuda.is_available = lambda: False
    # Monkeypatch Tensor.cuda to avoid hard-coded .cuda() in remote code
    # Also convert bfloat16 to float16 for MPS compatibility
    def _noop_cuda(self, *args, **kwargs):
        tensor = self
        # MPS doesn't support bfloat16, convert to float16
        if device == "mps" and tensor.dtype == torch.bfloat16:
            tensor = tensor.to(dtype=torch.float16)
        return tensor.to(device)
    torch.Tensor.cuda = _noop_cuda

def clean_ocr_output(text: str) -> str:
    """
    Remove model-specific markers (<|ref|>, <|det|>, compression stats) for cleaner output.
    """
    if not text:
        return text
    # Strip ref/det blocks
    text = re.sub(r"<\|ref\|>.*?<\|/ref\|>", "", text, flags=re.DOTALL)
    text = re.sub(r"<\|det\|>.*?<\|/det\|>", "", text, flags=re.DOTALL)
    # Drop lines with heavy diagnostics
    cleaned_lines = []
    for line in text.splitlines():
        if line.startswith("=") or line.startswith("BASE:") or "compression ratio" in line:
            continue
        cleaned_lines.append(line)
    # Collapse excessive blank lines
    cleaned = "\n".join(cleaned_lines)
    cleaned = re.sub(r"\n{3,}", "\n\n", cleaned).strip()
    return cleaned

def patch_transformers():
    """
    Apply runtime patches for transformers compatibility with DeepSeek-OCR.
    1. Patch vision_feature_layer default from -1 to -2
    2. Add stub for LlamaFlashAttention2 if missing (removed in newer transformers)
    """
    try:
        import transformers
        from transformers.models.llama import modeling_llama

        # Patch 1: Add LlamaFlashAttention2 stub if missing
        if not hasattr(modeling_llama, 'LlamaFlashAttention2'):
            # Create a dummy class that the model code can import
            # The actual flash attention won't be used on MPS/CPU anyway
            class LlamaFlashAttention2:
                pass
            modeling_llama.LlamaFlashAttention2 = LlamaFlashAttention2
            console.print("[dim]Added LlamaFlashAttention2 stub for compatibility.[/dim]")
    except Exception as e:
        console.print(f"[yellow]Warning: Could not patch LlamaFlashAttention2: {e}[/yellow]")

    # Patch 2: vision_feature_layer default
    try:
        from transformers.models.llava_next import modeling_llava_next

        # Locate the file on disk
        target_file = Path(modeling_llava_next.__file__)

        # Check if we need to patch
        with open(target_file, 'r', encoding='utf-8') as f:
            content = f.read()

        old_str = 'vision_feature_layer = kwargs.get("vision_feature_layer", -1)'
        new_str = 'vision_feature_layer = kwargs.get("vision_feature_layer", -2)'

        if old_str in content:
            console.print("[yellow]Patching transformers library for DeepSeek-OCR compatibility...[/yellow]")
            content = content.replace(old_str, new_str)

            # Backup
            backup_file = target_file.with_suffix('.py.bak')
            if not backup_file.exists():
                shutil.copy2(target_file, backup_file)

            # Write Patch
            with open(target_file, 'w', encoding='utf-8') as f:
                f.write(content)
            console.print("[green]Patch applied successfully.[/green]")

        elif new_str in content:
            # Already patched
            pass
        else:
            # Code structure might have changed in newer transformers
            console.print("[dim]Transformers library seems to have a different structure, skipping patch.[/dim]")

    except Exception as e:
        console.print(f"[red]Warning: Failed to patch transformers: {e}[/red]")

def download_file(url, target_dir):
    """
    Download a file from a URL to the target directory.
    """
    filename = url.split('/')[-1]
    if not filename:
        filename = "downloaded_file"
        
    target_path = target_dir / filename
    
    with Progress(
        SpinnerColumn(),
        TextColumn("[progress.description]{task.description}"),
        transient=True,
    ) as progress:
        progress.add_task(description=f"Downloading {filename}...", total=None)
        try:
            response = requests.get(url, stream=True)
            response.raise_for_status()
            with open(target_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
            return target_path
        except Exception as e:
            console.print(f"[red]Failed to download {url}: {e}[/red]")
            return None
