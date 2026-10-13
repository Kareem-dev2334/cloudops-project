import os
import hmac
import boto3
import uuid
from PIL import Image, UnidentifiedImageError
from flask import Flask, jsonify, request
import mysql.connector
from dotenv import load_dotenv


load_dotenv()

app = Flask(__name__)

# Reject HTTP request bodies larger than 5 MiB
app.config["MAX_CONTENT_LENGTH"] = 5 * 1024 * 1024

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
expected_token = os.environ.get("UPLOAD_API_TOKEN")
authorization = request.headers.get("Authorization", "")

    if not expected_token:
        return jsonify({"error": "Authentication not configured"}), 503

    supplied_token = (
        authorization[7:]
        if authorization.startswith("Bearer ")
        else ""
    )
    if not hmac.compare_digest(supplied_token, expected_token):
        return jsonify({"error": "Unauthorized"}), 401

    if "file" not in request.files:
        return jsonify({"error": "No file provided"}), 400

    file = request.files["file"]

    if file.filename == "":
        return jsonify({"error": "No file selected"}), 400

        # NEW CODE STARTS HERE
    try:
        image = Image.open(file.stream)

        if image.format not in ("JPEG", "PNG"):
            return jsonify({"error": "Only JPEG and PNG allowed"}), 400

        image.verify()

    except (UnidentifiedImageError, OSError, SyntaxError, ValueError):
        return jsonify({"error": "Invalid image file"}), 400

    file.stream.seek(0)
    # NEW CODE ENDS HERE

    # Generate a unique S3 object key
    extension = ".jpg" if image.format == "JPEG" else ".png"
    unique_filename = f"{uuid.uuid4()}{extension}"

    s3.upload_fileobj(file, S3_BUCKET, unique_filename)

    return jsonify({
        "message": "File uploaded successfully",
        "filename": unique_filename
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

