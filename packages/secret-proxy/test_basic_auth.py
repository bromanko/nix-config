import base64
import unittest
from types import SimpleNamespace
from unittest.mock import Mock, patch

from mitmproxy import http
from secret_proxy import SecretProxy


def basic(value):
    return "Basic " + base64.b64encode(value.encode()).decode()


class BasicPlaceholderTests(unittest.TestCase):
    def setUp(self):
        self.proxy = SecretProxy()
        self.proxy._load_namespace = Mock(return_value=(
            {"GITHUB_TOKEN": "fake-test-token"},
            {"GITHUB_TOKEN": {"github.com"}}, {},
        ))
        self.logs = patch("secret_proxy.ctx").start()
        self.addCleanup(patch.stopall)

    def request(self, authorization, host="github.com", **headers):
        flow = SimpleNamespace(
            request=http.Request.make("GET", f"https://{host}/repo.git/info/refs",
                                      headers={"Authorization": authorization, **headers}),
            response=None,
        )
        self.proxy.request(flow)
        return flow

    def test_git_password_placeholder_is_resolved_without_logging_credentials(self):
        flow = self.request(basic("x-access-token:{{scherzo:GITHUB_TOKEN}}"))
        self.assertIsNone(flow.response)
        self.assertEqual(flow.request.headers["authorization"], basic("x-access-token:fake-test-token"))
        self.proxy._load_namespace.assert_called_once_with("scherzo")
        self.assertNotIn("fake-test-token", str(self.logs.mock_calls))
        self.assertNotIn(basic("x-access-token:fake-test-token"), str(self.logs.mock_calls))

    def test_disallowed_destination_and_missing_secret_leave_original_header(self):
        original = basic("x-access-token:{{scherzo:GITHUB_TOKEN}}")
        for host, secrets in [("attacker.example", {"GITHUB_TOKEN": "fake-test-token"}),
                              ("github.com", {})]:
            with self.subTest(host=host, missing=not secrets):
                self.proxy._load_namespace.return_value = (secrets, {"GITHUB_TOKEN": {"github.com"}}, {})
                flow = self.request(original, host)
                self.assertEqual(flow.response.status_code, 403)
                self.assertEqual(flow.request.headers["authorization"], original)
                self.assertNotIn("fake-test-token", flow.response.get_text())

    def test_visible_and_encoded_placeholders_are_validated_together(self):
        original = basic("x-access-token:{{scherzo:GITHUB_TOKEN}}")
        flow = self.request(original, **{"X-Other": "{{scherzo:MISSING}}"})
        self.assertEqual(flow.response.status_code, 403)
        self.assertEqual(flow.request.headers["authorization"], original)

    def test_nonplaceholder_and_malformed_basic_headers_are_not_rewritten(self):
        for value in [basic("user:password"), "Basic invalid!", basic("missing-colon"),
                      "Basic /w==", "Bearer ordinary-token"]:
            with self.subTest(header=value):
                flow = self.request(value)
                self.assertIsNone(flow.response)
                self.assertEqual(flow.request.headers["authorization"], value)
        self.proxy._load_namespace.assert_not_called()


if __name__ == "__main__":
    unittest.main()
