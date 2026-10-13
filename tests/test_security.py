
import io
import os
import unittest
from unittest.mock import patch

from PIL import Image

# Configure test environment before importing Flask
os.environ["UPLOAD_API_TOKEN"] = "ci-test-token"
os.environ.setdefault("AWS_DEFAULT_REGION", "ap-southeast-2")
os.environ.setdefault("AWS_EC2_METADATA_DISABLED", "true")

from app import app


class TestUploadSecurity(unittest.TestCase):

    def setUp(self):
        self.client = app.test_client()

    @patch("app.s3.upload_fileobj")
    def test_missing_token(self, mock_s3):
        response = self.client.post("/upload")

        self.assertEqual(response.status_code, 401)
        mock_s3.assert_not_called()

    @patch("app.s3.upload_fileobj")
    def test_invalid_token(self, mock_s3):
        response = self.client.post(
            "/upload",
            headers={"Authorization": "Bearer wrong-token"}
        )

        self.assertEqual(response.status_code, 401)
        mock_s3.assert_not_called()

    @patch("app.s3.upload_fileobj")
    def test_invalid_image(self, mock_s3):
        response = self.client.post(
            "/upload",
            headers={"Authorization": "Bearer ci-test-token"},
            data={
                "file": (
                    io.BytesIO(b"not a real image"),
                    "fake.jpg"
                )
            },
            content_type="multipart/form-data"
        )

        self.assertEqual(response.status_code, 400)
        mock_s3.assert_not_called()

    @patch("app.s3.upload_fileobj")
    def test_valid_png_upload(self, mock_s3):
        image_data = io.BytesIO()

        Image.new("RGB", (2, 2), color="white").save(
            image_data,
            format="PNG"
        )
        image_data.seek(0)

        response = self.client.post(
            "/upload",
            headers={"Authorization": "Bearer ci-test-token"},
            data={
                "file": (image_data, "profile.png")
            },
            content_type="multipart/form-data"
        )

        self.assertEqual(response.status_code, 200)
        mock_s3.assert_called_once()

        filename = response.get_json()["filename"]

        self.assertTrue(filename.endswith(".png"))
        self.assertNotEqual(filename, "profile.png")
        self.assertEqual(mock_s3.call_args.args[2], filename)


if __name__ == "__main__":
    unittest.main()

