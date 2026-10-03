import os
import boto3
from flask import Flask, jsonify, request
import mysql.connector
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

# Boto3 uses the IAM role attached to the EC2 instance.
s3 = boto3.client("s3")
S3_BUCKET = "cloudops-customer-images-kareem"


def get_db_connection():
    return mysql.connector.connect(
        host=os.environ["DB_HOST"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        database=os.environ["DB_NAME"],
        port=int(os.environ.get("DB_PORT", 3306))
    )


@app.route("/")
def home():
    return "CloudOps Backend is ONLINE"


@app.route("/health")
def health():
    return jsonify({"status": "healthy"})


@app.route("/users")
def users():
    connection = get_db_connection()
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute("SELECT id, name, email, created_at FROM users")
        rows = cursor.fetchall()
        return jsonify(rows)
    finally:
        cursor.close()
        connection.close()


@app.route("/upload", methods=["POST"])
def upload_file():
    if "file" not in request.files:
        return jsonify({"error": "No file provided"}), 400

    file = request.files["file"]

    if file.filename == "":
        return jsonify({"error": "No file selected"}), 400

    s3.upload_fileobj(file, S3_BUCKET, file.filename)

    return jsonify({
        "message": "File uploaded successfully",
        "filename": file.filename
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

