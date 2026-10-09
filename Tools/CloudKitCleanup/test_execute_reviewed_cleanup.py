import unittest
from subprocess import CompletedProcess
from unittest.mock import patch

from execute_reviewed_cleanup import AuthenticationError, clean_group, cktool


class ReviewedCleanupTests(unittest.TestCase):
    def test_rejects_any_unreviewed_record_before_deleting(self):
        entries = [{"recordName": "approved", "threshold": 100}]
        with patch("execute_reviewed_cleanup.matching_names", return_value={"approved", "new"}), patch(
            "execute_reviewed_cleanup.cktool"
        ) as command:
            with self.assertRaisesRegex(RuntimeError, "unreviewed"):
                clean_group("CD_BigORecord", "example", entries, "token")
        command.assert_not_called()

    def test_verifies_empty_group_after_successful_deletion(self):
        entries = [{"recordName": "approved", "threshold": 100}]
        with patch("execute_reviewed_cleanup.matching_names", side_effect=[{"approved"}, set()]), patch(
            "execute_reviewed_cleanup.cktool", return_value="Deleted 1 matching record. (0 errors)"
        ):
            self.assertEqual(clean_group("CD_BigORecord", "example", entries, "token"), ("example", 1))

    def test_requeries_after_ambiguous_cloudkit_failure(self):
        entries = [{"recordName": "approved", "threshold": 100}]
        with patch("execute_reviewed_cleanup.matching_names", side_effect=[{"approved"}, set()]), patch(
            "execute_reviewed_cleanup.cktool", side_effect=RuntimeError("retry-needed")
        ), patch("execute_reviewed_cleanup.time.sleep"):
            self.assertEqual(clean_group("CD_BigORecord", "example", entries, "token"), ("example", 0))

    def test_expired_token_is_a_fatal_error(self):
        response = CompletedProcess([], 1, "", "Authentication failed. User token has expired.")
        with patch("execute_reviewed_cleanup.subprocess.run", return_value=response):
            with self.assertRaises(AuthenticationError):
                cktool("query-records", "secret", "--record-type", "CD_BigORecord")


if __name__ == "__main__":
    unittest.main()
