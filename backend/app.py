from flask import Flask, request, send_file
from merge_pdfs import merge_pdfs
from flask_cors import CORS
import io
import os
import tempfile

app = Flask(__name__)
CORS(app)

@app.route('/merge_pdfs', methods=['POST'])
def merge_pdfs_endpoint():
    uploaded_files = request.files.getlist('files')
    print("Files received:", [f.filename for f in uploaded_files])  # DEBUG

    if not uploaded_files:
        return {"error": "No files uploaded"}, 400

    # Save uploaded PDFs to a temporary directory
    with tempfile.TemporaryDirectory() as tmpdir:
        input_paths = []
        for f in uploaded_files:
            path = os.path.join(tmpdir, f.filename)
            f.save(path)
            input_paths.append(path)

        # Merge PDFs to a temporary in-memory buffer
        output_stream = io.BytesIO()
        merge_pdfs(input_paths, output_stream)
        output_stream.seek(0)

        # Return merged PDF as download
        return send_file(
            output_stream,
            as_attachment=True,
            download_name="merged.pdf",
            mimetype="application/pdf"
        )

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)
