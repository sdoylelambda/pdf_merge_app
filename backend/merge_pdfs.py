from PyPDF2 import PdfMerger

def merge_pdfs(input_paths, output_path):
    merger = PdfMerger()
    for pdf in input_paths:
        merger.append(pdf)
    merger.write(output_path)
    merger.close()
