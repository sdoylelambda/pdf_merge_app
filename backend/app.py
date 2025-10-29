from flask import Flask, request, send_file
from merge_pdfs import merge_pdfs
import tempfile
import os

app = Flask(__name__)

@app.route('/merge_pdfs', methods=['POST'])
def merge_pdfs_endpoint():
    uploaded_files = request.files.getlist('files')
    if not uploaded_files:
        return {"error": "No files uploaded"}, 400

    with tempfile.TemporaryDirectory() as tmpdir:
        input_paths = []
        for f in uploaded_files:
            path = os.path.join(tmpdir, f.filename)
            f.save(path)
            input_paths.append(path)

        output_path = os.path.join(tmpdir, "merged.pdf")
        merge_pdfs(input_paths, output_path)
        return send_file(output_path, as_attachment=True)

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)
