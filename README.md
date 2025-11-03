# pdf_merge_app

Run with Docker

docker build -t pdf-merge-backend .
docker run -d -p 5000:5000 --name pdf-merge pdf-merge-backend
docker compose up


Without Docker

BE folder
python backend/app.py

FE folder
flutter run -d chrome

