import os
import torch
from pathlib import Path
from transformers import AutoModel, AutoTokenizer
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn
from .utils import check_model_exists, download_model, patch_transformers, download_file
from .converters import docx_to_pdf, pdf_to_images
from PIL import Image

console = Console()

def get_device(requested_device=None):
    if requested_device:
        return requested_device
    if torch.backends.mps.is_available():
        return "mps"
    return "cpu"

def load_model(device, model_cache=None):
    """
    Load the DeepSeek-OCR model.
    """
    # 1. Patch transformers
    patch_transformers()
    
    # 2. Check/Download Model
    model_path = check_model_exists(model_cache)
    if not model_path:
        model_path = download_model(model_cache)
    
    console.print(f"[dim]Loading model from {model_path}...[/dim]")
    
    tokenizer = AutoTokenizer.from_pretrained(
        model_path, 
        trust_remote_code=True
    )
    
    model = AutoModel.from_pretrained(
        model_path,
        trust_remote_code=True,
        use_safetensors=True
    )
    
    # Fallback logic for bfloat16 on older CPUs
    dtype = torch.bfloat16
    if device == "cpu":
        try:
            # Test if bfloat16 is supported for a simple operation
            torch.tensor([1.0], dtype=torch.bfloat16).to("cpu")
        except Exception:
            console.print("[yellow]bfloat16 not fully supported on this CPU, falling back to float32.[/yellow]")
            dtype = torch.float32

    model = model.eval().to(dtype=dtype).to(device)
    
    return tokenizer, model

def get_prompt(mode):
    """
    Map mode to prompt.
    """
    prompts = {
        'document': "<image>\n<|grounding|>Convert the document to markdown.",
        'standard': "<image>\n<|grounding|>OCR this image.",
        'format-free': "<image>\nFree OCR.",
        'chart': "<image>\nParse the figure.",
        'detail': "<image>\nDescribe this image in detail."
    }
    return prompts.get(mode, prompts['document'])

def run_inference(model, tokenizer, image, prompt, output_dir):
    """
    Run inference on a single image (PIL Image object or path).
    """
    # If image is PIL, save it temporarily because model.infer usually expects a path
    # Checking model code source (from generic knowledge of DeepSeek-VL/OCR):
    # Usually `image_file` arg expects a path.
    
    temp_img_path = None
    if isinstance(image, Image.Image):
        temp_img_path = output_dir / "temp_page.png"
        image.save(temp_img_path)
        image_path = str(temp_img_path)
    else:
        image_path = str(image)
        
    try:
        # Note: model.infer signature might vary slightly based on the specific remote code version
        # We assume the standard signature used in the original script
        result = model.infer(
            tokenizer,
            prompt=prompt,
            image_file=image_path,
            output_path=str(output_dir), # Model might save assets here
            base_size=1024,
            image_size=640,
            crop_mode=True,
            save_results=False, # We want the text back, not just files
            test_compress=True
        )
        return result
    finally:
        if temp_img_path and temp_img_path.exists():
            temp_img_path.unlink()

def process_file(input_path, url, mode, output_dir, device_arg, model_cache=None):
    """
    Main processing pipeline.
    """
    # 0. Setup
    if url:
        # Create a temp dir for download if not provided
        # Or just download to CWD? Let's download to output_dir to keep it clean
        if output_dir:
            out_path = Path(output_dir)
            out_path.mkdir(parents=True, exist_ok=True)
            input_path = download_file(url, out_path)
        else:
            # If no output dir, use temp
            import tempfile
            tmp = Path(tempfile.mkdtemp())
            input_path = download_file(url, tmp)
            # Default output dir logic needs input path, so set it later
            
    if not input_path:
        console.print("[red]No input file provided or download failed.[/red]")
        return

    input_path = Path(input_path)
    
    if not output_dir:
        output_dir = input_path.parent / "ocr_output" / input_path.stem
    else:
        output_dir = Path(output_dir)
        
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # 1. Load Model
    device = get_device(device_arg)
    console.print(f"[bold green]Using device: {device}[/bold green]")
    
    try:
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            transient=True,
        ) as progress:
            progress.add_task(description="Loading DeepSeek-OCR Model...", total=None)
            tokenizer, model = load_model(device, model_cache)
    except Exception as e:
        console.print(f"[red]Failed to load model: {e}[/red]")
        return

    # 2. Pre-process Input (Convert to Images)
    images_to_process = [] # List of (page_num, image_path_or_obj) 
    
    suffix = input_path.suffix.lower()
    console.print(f"Processing {input_path.name}...")
    
    if suffix in ['.pdf']:
        console.print("Rendering PDF pages...")
        for idx, img in pdf_to_images(input_path):
            images_to_process.append((idx, img))
            
    elif suffix in ['.docx']:
        console.print("Converting DOCX to PDF...")
        pdf_path = docx_to_pdf(input_path)
        console.print("Rendering PDF pages...")
        for idx, img in pdf_to_images(pdf_path):
            images_to_process.append((idx, img))
            
    elif suffix in ['.png', '.jpg', '.jpeg', '.webp', '.bmp']:
        images_to_process.append((0, input_path))
        
    else:
        console.print(f"[red]Unsupported format: {suffix}[/red]")
        return

    # 3. Inference Loop
    full_markdown = f"# {input_path.name}\n\n"
    prompt = get_prompt(mode)
    
    total_pages = len(images_to_process)
    
    with Progress(
        TextColumn("[progress.description]{task.description}"),
        transient=False,
    ) as progress:
        task = progress.add_task("[green]OCR Processing...", total=total_pages)
        
        for idx, image_obj in images_to_process:
            progress.update(task, description=f"Processing page {idx+1}/{total_pages}")
            
            # Sub-folder for assets of this page if needed, but model handles it via output_path
            # We pass the main output dir. The model usually saves images if instructed.
            # Here we just want text.
            
            result = run_inference(model, tokenizer, image_obj, prompt, output_dir)
            
            # Append result
            full_markdown += f"## Page {idx+1}\n\n"
            full_markdown += str(result) + "\n\n"
            
            progress.advance(task)

    # 4. Save Result
    result_file = output_dir / f"{input_path.stem}.md"
    with open(result_file, 'w', encoding='utf-8') as f:
        f.write(full_markdown)
        
    console.print(f"[bold green]Success![/bold green] Results saved to: {result_file}")