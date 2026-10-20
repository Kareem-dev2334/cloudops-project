import io
import os
import unittest
from unittest.mock import patch

from PIL import Image

# Configure test environment before importing Flask.
os.environ["UPLOAD_API_TOKEN"] = "ci-test-token"
os.environ.setdefault("AWS_DEFAULT_REGION", "ap-southeast-2")
os.environ.setdefault("AWS_EC2_METADATA_DISABLED", "true")

from app import app


class TestUploadSecurity(unittest.TestCase):

    def setUp(self):
        self.client = app.test_client()
        self.env_patch = patch.dict(
            os.environ,
            {
                "UPLOAD_API_TOKEN": "ci-test-token",
                "S3_BUCKET": "ci-test-bucket",
            },
        )
        self.env_patch.start()
        self.addCleanup(self.env_patch.stop)

    @patch("app.s3.upload_fileobj")
    def test_missing_token(self, mock_s3):
        response = self.client.post("/upload")

        self.assertEqual(response.status_code, 401)
        mock_s3.assert_not_called()

    @patch("app.s3.upload_fileobj")
    def test_invalid_token(self, mock_s3):
        response = self.client.post(
            "/upload",
            headers={"Authorization": "Bearer wrong-token"},
        )

        self.assertEqual(response.status_code, 401)
        mock_s3.assert_not_called()

    @patch("app.s3.upload_fileobj")
    def test_missing_bucket(self, mock_s3):
        os.environ.pop("S3_BUCKET", None)

        response = self.client.post(
            "/upload",
            headers={"Authorization": "Bearer ci-test-token"},
        )

        self.assertEqual(response.status_code, 503)
        self.assertEqual(
            response.get_json(),
            {"error": "Storage not configured"},
        )
        mock_s3.assert_not_called()

    @patch("app.s3.upload_fileobj")
    def test_blank_bucket(self, mock_s3):
        os.environ["S3_BUCKET"] = "   "

        response = self.client.post(
            "/upload",
            headers={"Authorization": "Bearer ci-test-token"},
        )

        self.assertEqual(response.status_code, 503)
        self.assertEqual(
            response.get_json(),
            {"error": "Storage not configured"},
        )
        mock_s3.assert_not_called()

    @patch("app.s3.upload_fileobj")
    def test_invalid_image(self, mock_s3):
        response = self.client.post(
            "/upload",
            headers={"Authorization": "Bearer ci-test-token"},
            data={
                "file": (
                    io.BytesIO(b"not a real image"),
                    "fake.jpg",
                )
            },
            content_type="multipart/form-data",
        )

        self.assertEqual(response.status_code, 400)
        mock_s3.assert_not_called()

    @patch("app.s3.upload_fileobj")
    def test_valid_png_upload(self, mock_s3):
        image_data = io.BytesIO()
        Image.new("RGB", (2, 2), color="white").save(
            image_data, format="PNG"
        )
        image_data.seek(0)

        response = self.client.post(
            "/upload",
            headers={"Authorization": "Bearer ci-test-token"},
            data={"file": (image_data, "profile.png")},
            content_type="multipart/form-data",
        )

        self.assertEqual(response.status_code, 200)
        mock_s3.assert_called_once()
        self.assertEqual(
            mock_s3.call_args.args[1], "ci-test-bucket"
        )

        filename = response.get_json()["filename"]
        self.assertTrue(filename.endswith(".png"))
        self.assertNotEqual(filename, "profile.png")
        self.assertEqual(mock_s3.call_args.args[2], filename)

    @patch("app.s3.upload_fileobj")
    def test_valid_image_upload(self, mock_s3):
        image_data = io.BytesIO()
        Image.new("RGB", (20, 20), "blue").save(
            image_data, format="PNG"
        )
        image_data.seek(0)

        response = self.client.post(
            "/upload",
            headers={"Authorization": "Bearer ci-test-token"},
            data={"file": (image_data, "customer.png")},
            content_type="multipart/form-data",
        )

        self.assertEqual(response.status_code, 200)
        mock_s3.assert_called_once()
        self.assertEqual(
            mock_s3.call_args.args[1], "ci-test-bucket"
        )

        filename = response.get_json()["filename"]
        self.assertTrue(filename.endswith(".png"))

    @patch("app.s3.upload_fileobj")
    def test_oversized_upload(self, mock_s3):
        response = self.client.post(
            "/upload",
            headers={"Authorization": "Bearer ci-test-token"},
            data={
                "file": (
                    io.BytesIO(b"x" * (6 * 1024 * 1024)),
                    "large.jpg",
                )
            },
            content_type="multipart/form-data",
        )

        self.addCleanup(response.close)
        self.addCleanup(response.request.input_stream.close)

        self.assertEqual(response.status_code, 413)
        mock_s3.assert_not_called()

class TestUsersSecurity(unittest.TestCase):

    def setUp(self):
        self.client = app.test_client()
        self.env_patch = patch.dict(
            os.environ, {"USERS_API_TOKEN": "ci-users-token"}
        )
        self.env_patch.start()
        self.addCleanup(self.env_patch.stop)

    @patch("app.get_db_connection")
    def test_missing_token(self, mock_db):
        response = self.client.get("/users")

        self.assertEqual(response.status_code, 401)
        mock_db.assert_not_called()

    @patch("app.get_db_connection")
    def test_invalid_token(self, mock_db):
        response = self.client.get(
            "/users",
            headers={"Authorization": "Bearer wrong-token"},
        )

        self.assertEqual(response.status_code, 401)
        mock_db.assert_not_called()

    @patch("app.get_db_connection")
    def test_missing_configuration(self, mock_db):
        os.environ.pop("USERS_API_TOKEN", None)

        response = self.client.get("/users")

        self.assertEqual(response.status_code, 503)
        mock_db.assert_not_called()

    @patch("app.get_db_connection")
    def test_valid_token(self, mock_db):
        connection = mock_db.return_value
        cursor = connection.cursor.return_value
        cursor.fetchall.return_value = [
            {"id": 1, "name": "Test User"}
        ]

        response = self.client.get(
            "/users",
            headers={"Authorization": "Bearer ci-users-token"},
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.get_json(),
            [{"id": 1, "name": "Test User"}],
        )
        mock_db.assert_called_once_with()
        cursor.execute.assert_called_once_with(
            "SELECT id, name, email, created_at FROM users"
        )
        cursor.close.assert_called_once_with()
        connection.close.assert_called_once_with()


if __name__ == "__main__":
    unittest.main()
