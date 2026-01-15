import sys
import subprocess
from pathlib import Path
from rich.console import Console
import fitz  # PyMuPDF
from PIL import Image
import io

console = Console()

def docx_to_pdf(input_path):
    """
    Convert DOCX to PDF.
    Strategy:
    1. Try docx2pdf (Requires MS Word on macOS).
    2. Try pypandoc (Requires pandoc).
    3. Fail.
    """
    input_path = Path(input_path).absolute()
    output_path = input_path.with_suffix('.pdf')
    
    # Strategy 1: docx2pdf
    if sys.platform == 'darwin':
        try:
            from docx2pdf import convert
            console.print("[dim]Converting DOCX to PDF using docx2pdf (MS Word)...[/dim]")
            convert(str(input_path), str(output_path))
            if output_path.exists():
                return output_path
        except Exception as e:
            console.print(f"[yellow]docx2pdf failed: {e}. Trying fallback...[/yellow]")
    
    # Strategy 2: pypandoc
    try:
        import pypandoc
        # Check if pandoc is installed
        try:
            pypandoc.get_pandoc_version()
        except OSError:
            raise RuntimeError("Pandoc not found. Please install via 'brew install pandoc'.")

        console.print("[dim]Converting DOCX to PDF using pypandoc...[/dim]")
        # pypandoc conversion to pdf usually requires a pdf engine (wkhtmltopdf or pdflatex)
        # But simpler fallback is converting to text if visual layout isn't critical?
        # Re-reading requirement: "Start with Option 1 (Visual)... preserving layout".
        # Pandoc to PDF via LaTeX is heavy. 
        # Alternative: Use libreoffice if available.
        
        # Trying subprocess for LibreOffice (headless)
        cmd = [
            "/Applications/LibreOffice.app/Contents/MacOS/soffice",
            "--headless",
            "--convert-to", "pdf",
            "--outdir", str(input_path.parent),
            str(input_path)
        ]
        if Path(cmd[0]).exists():
             subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
             if output_path.exists():
                 return output_path
    
    except Exception as e:
         console.print(f"[red]Conversion failed: {e}[/red]")
    
    if not output_path.exists():
        raise RuntimeError("Could not convert DOCX to PDF. Please install Microsoft Word or LibreOffice.")
    
    return output_path

def pdf_to_images(pdf_path, dpi=200):
    """
    Render PDF pages to PIL Images using PyMuPDF.
    Yields (index, PIL.Image).
    """
    doc = fitz.open(pdf_path)
    for i in range(len(doc)):
        page = doc.load_page(i)
        pix = page.get_pixmap(dpi=dpi)
        img_data = pix.tobytes("png")
        image = Image.open(io.BytesIO(img_data))
        yield i, image
    doc.close()