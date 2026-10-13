import os
import unittest
from unittest.mock import patch

os.environ["UPLOAD_API_TOKEN"] = "ci-test-token"

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


if __name__ == "__main__":
    unittest.main()
