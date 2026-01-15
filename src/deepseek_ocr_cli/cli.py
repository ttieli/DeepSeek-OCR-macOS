import click
from rich.console import Console
from .core import process_file

console = Console()

@click.command()
@click.argument('input_path', type=click.Path(exists=False, dir_okay=False, readable=True), required=False)
@click.option('--url', help='URL to download file from')
@click.option('--mode', default='document', type=click.Choice(['document', 'standard', 'format-free', 'chart', 'detail'], case_sensitive=False), help='OCR Mode')
@click.option('--output', '-o', type=click.Path(file_okay=False, writable=True), help='Output directory')
@click.option('--device', type=click.Choice(['cpu', 'mps']), help='Force specific device')
def main(input_path, url, mode, output, device):
    """DeepSeek-OCR Local CLI

    Parse local images, PDFs, or DOCX files to Markdown.
    """
    if not input_path and not url:
        console.print("[red]Error: Please provide an INPUT_PATH or --url[/red]")
        click.echo(main.get_help(click.get_current_context()))
        return

    # Check input_path existence only if url is not provided
    if input_path and not url:
        import os
        if not os.path.exists(input_path):
             console.print(f"[red]Error: File '{input_path}' does not exist.[/red]")
             return

    process_file(input_path, url, mode, output, device)

if __name__ == '__main__':
    main()