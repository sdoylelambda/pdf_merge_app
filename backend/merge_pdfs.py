from PyPDF2 import PdfMerger
import io

def merge_pdfs(input_paths, output):
    merger = PdfMerger()
    for path in input_paths:
        merger.append(path)

    if isinstance(output, (io.BytesIO, io.BufferedIOBase)):
        merger.write(output)
    else:
        with open(output, "wb") as f:
            merger.write(f)

    merger.close()
