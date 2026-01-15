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
    2. Try LibreOffice (headless).
    3. Try pypandoc (Requires pandoc + latex/wkhtmltopdf, often fails for complex docs).
    """
    input_path = Path(input_path).absolute()
    output_path = input_path.with_suffix('.pdf')
    
    # Strategy 1: docx2pdf (MS Word)
    if sys.platform == 'darwin':
        try:
            from docx2pdf import convert
            console.print("[dim]Attempt 1: Converting DOCX to PDF using docx2pdf (MS Word)...[/dim]")
            convert(str(input_path), str(output_path))
            if output_path.exists():
                return output_path
        except Exception as e:
            console.print(f"[yellow]docx2pdf failed: {e}. Trying fallback...[/yellow]")

    # Strategy 2: LibreOffice
    # Common paths for LibreOffice on macOS
    soffice_paths = [
        "/Applications/LibreOffice.app/Contents/MacOS/soffice",
        "/usr/bin/soffice",
        "/usr/local/bin/soffice"
    ]
    soffice_cmd = None
    for p in soffice_paths:
        if Path(p).exists():
            soffice_cmd = p
            break
            
    if soffice_cmd:
        try:
            console.print("[dim]Attempt 2: Converting DOCX to PDF using LibreOffice...[/dim]")
            cmd = [
                soffice_cmd,
                "--headless",
                "--convert-to", "pdf",
                "--outdir", str(input_path.parent),
                str(input_path)
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if output_path.exists():
                return output_path
        except Exception as e:
             console.print(f"[yellow]LibreOffice conversion failed: {e}.[/yellow]")
    else:
        console.print("[dim]LibreOffice not found, skipping.[/dim]")

    # Strategy 3: pypandoc (Last resort, likely to fail if no latex engine)
    try:
        import pypandoc
        # Check if pandoc is installed
        try:
            pypandoc.get_pandoc_version()
            console.print("[dim]Attempt 3: Converting DOCX to PDF using pypandoc...[/dim]")
            # Note: This often requires pdf-engine like pdflatex installed
            pypandoc.convert_file(str(input_path), 'pdf', outputfile=str(output_path))
            if output_path.exists():
                return output_path
        except OSError:
            console.print("[yellow]Pandoc not installed.[/yellow]")
        except Exception as e:
            console.print(f"[yellow]pypandoc conversion failed: {e}[/yellow]")
            
    except ImportError:
        pass
    
    if not output_path.exists():
        raise RuntimeError(
            "Could not convert DOCX to PDF. Please install Microsoft Word, LibreOffice, or Pandoc+PDFEngine."
        )
    
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