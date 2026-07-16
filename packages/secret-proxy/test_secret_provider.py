import subprocess
import tempfile
import unittest
from pathlib import Path

from secret_provider import (
    EnvironmentFileProvider,
    OnePasswordServiceAccountProvider,
    SecretProviderError,
    parse_env_content,
)


class ParseEnvContentTests(unittest.TestCase):
    def test_parses_dotenv_content_without_losing_equals_signs(self):
        content = """
        # comment
        SIMPLE=value
        QUOTED="quoted value"
        SINGLE='single value'
        TOKEN=abc=def==
        EMPTY=
        MALFORMED
        """

        self.assertEqual(
            parse_env_content(content),
            {
                "SIMPLE": "value",
                "QUOTED": "quoted value",
                "SINGLE": "single value",
                "TOKEN": "abc=def==",
                "EMPTY": "",
            },
        )


class EnvironmentFileProviderTests(unittest.TestCase):
    def test_reads_default_and_named_namespace_with_a_timeout(self):
        calls = []

        def runner(command, **kwargs):
            calls.append((command, kwargs))
            return subprocess.CompletedProcess(command, 0, "TOKEN=value\n", "")

        provider = EnvironmentFileProvider(
            default_env_file=Path("/config/secrets.env"),
            namespace_dir=Path("/config/namespaces"),
            read_timeout_seconds=7,
            runner=runner,
        )

        self.assertEqual(provider.load(None), {"TOKEN": "value"})
        self.assertEqual(provider.load("scherzo"), {"TOKEN": "value"})
        self.assertEqual(calls[0][0], ["/bin/cat", "/config/secrets.env"])
        self.assertEqual(
            calls[1][0],
            ["/bin/cat", "/config/namespaces/scherzo/secrets.env"],
        )
        self.assertEqual(calls[0][1]["timeout"], 7)
        self.assertTrue(calls[0][1]["capture_output"])
        self.assertTrue(calls[0][1]["text"])

    def test_timeout_raises_safe_error(self):
        def runner(command, **kwargs):
            raise subprocess.TimeoutExpired(
                command,
                kwargs["timeout"],
                output="partial-secret",
                stderr="private-diagnostic",
            )

        provider = EnvironmentFileProvider(
            default_env_file=Path("/config/secrets.env"),
            namespace_dir=Path("/config/namespaces"),
            runner=runner,
        )

        with self.assertRaisesRegex(SecretProviderError, "timed out") as raised:
            provider.load(None)

        message = str(raised.exception)
        self.assertNotIn("partial-secret", message)
        self.assertNotIn("private-diagnostic", message)


class OnePasswordServiceAccountProviderTests(unittest.TestCase):
    def make_token_file(self, directory: str, content: str = "service-token\n") -> Path:
        token_file = Path(directory) / "token"
        token_file.write_text(content)
        token_file.chmod(0o400)
        return token_file

    def test_maps_namespaces_and_passes_token_only_in_child_environment(self):
        with tempfile.TemporaryDirectory() as directory:
            calls = []

            def runner(command, **kwargs):
                calls.append((command, kwargs))
                return subprocess.CompletedProcess(command, 0, "TOKEN=value\n", "")

            provider = OnePasswordServiceAccountProvider(
                op_cli="/nix/store/op/bin/op",
                token_file=self.make_token_file(directory),
                environment_ids={
                    "default": "env-default",
                    "scherzo": "env-scherzo",
                },
                command_timeout_seconds=11,
                runner=runner,
                base_environment={
                    "SAFE_VARIABLE": "preserved",
                    "OP_CONNECT_HOST": "https://connect.invalid",
                    "OP_CONNECT_TOKEN": "connect-secret",
                },
            )

            self.assertEqual(provider.load(None), {"TOKEN": "value"})
            self.assertEqual(provider.load("scherzo"), {"TOKEN": "value"})

            self.assertEqual(
                calls[0][0],
                ["/nix/store/op/bin/op", "environment", "read", "env-default"],
            )
            self.assertEqual(
                calls[1][0],
                ["/nix/store/op/bin/op", "environment", "read", "env-scherzo"],
            )
            child_environment = calls[0][1]["env"]
            self.assertEqual(
                child_environment["OP_SERVICE_ACCOUNT_TOKEN"], "service-token"
            )
            self.assertEqual(child_environment["SAFE_VARIABLE"], "preserved")
            self.assertNotIn("OP_CONNECT_HOST", child_environment)
            self.assertNotIn("OP_CONNECT_TOKEN", child_environment)
            self.assertEqual(calls[0][1]["timeout"], 11)
            self.assertNotIn("service-token", " ".join(calls[0][0]))

    def test_caches_each_namespace_until_ttl_expires(self):
        with tempfile.TemporaryDirectory() as directory:
            calls = []
            now = [100.0]

            def runner(command, **kwargs):
                calls.append(command)
                value = len(calls)
                return subprocess.CompletedProcess(
                    command, 0, f"TOKEN=value-{value}\n", ""
                )

            provider = OnePasswordServiceAccountProvider(
                op_cli="op",
                token_file=self.make_token_file(directory),
                environment_ids={"default": "env-default"},
                cache_ttl_seconds=10,
                runner=runner,
                clock=lambda: now[0],
            )

            self.assertEqual(provider.load(None), {"TOKEN": "value-1"})
            now[0] = 109.0
            self.assertEqual(provider.load(None), {"TOKEN": "value-1"})
            self.assertEqual(len(calls), 1)

            now[0] = 111.0
            self.assertEqual(provider.load(None), {"TOKEN": "value-2"})
            self.assertEqual(len(calls), 2)

    def test_missing_namespace_fails_without_running_cli(self):
        with tempfile.TemporaryDirectory() as directory:
            calls = []
            provider = OnePasswordServiceAccountProvider(
                op_cli="op",
                token_file=self.make_token_file(directory),
                environment_ids={"default": "env-default"},
                runner=lambda *args, **kwargs: calls.append((args, kwargs)),
            )

            with self.assertRaisesRegex(
                SecretProviderError, "No Environment ID configured"
            ):
                provider.load("scherzo")

            self.assertEqual(calls, [])

    def test_missing_and_empty_token_files_fail_without_running_cli(self):
        with tempfile.TemporaryDirectory() as directory:
            calls = []
            missing = Path(directory) / "missing"
            empty = self.make_token_file(directory, " \n")

            for token_file in (missing, empty):
                provider = OnePasswordServiceAccountProvider(
                    op_cli="op",
                    token_file=token_file,
                    environment_ids={"default": "env-default"},
                    runner=lambda *args, **kwargs: calls.append((args, kwargs)),
                )
                with self.assertRaises(SecretProviderError):
                    provider.load(None)

            self.assertEqual(calls, [])

    def test_insecure_token_file_permissions_fail_without_running_cli(self):
        with tempfile.TemporaryDirectory() as directory:
            calls = []
            token_file = self.make_token_file(directory)
            token_file.chmod(0o644)
            provider = OnePasswordServiceAccountProvider(
                op_cli="op",
                token_file=token_file,
                environment_ids={"default": "env-default"},
                runner=lambda *args, **kwargs: calls.append((args, kwargs)),
            )

            with self.assertRaisesRegex(SecretProviderError, "permissions are unsafe"):
                provider.load(None)

            self.assertEqual(calls, [])

    def test_cli_failure_and_timeout_do_not_leak_captured_values(self):
        with tempfile.TemporaryDirectory() as directory:
            token_file = self.make_token_file(directory, "service-token")

            def failed_runner(command, **kwargs):
                return subprocess.CompletedProcess(
                    command,
                    1,
                    "stdout-secret",
                    "stderr-private-diagnostic",
                )

            def timed_out_runner(command, **kwargs):
                raise subprocess.TimeoutExpired(
                    command,
                    kwargs["timeout"],
                    output="timeout-secret",
                    stderr="timeout-private-diagnostic",
                )

            for runner in (failed_runner, timed_out_runner):
                provider = OnePasswordServiceAccountProvider(
                    op_cli="op",
                    token_file=token_file,
                    environment_ids={"default": "env-default"},
                    runner=runner,
                )
                with self.assertRaises(SecretProviderError) as raised:
                    provider.load(None)

                message = str(raised.exception)
                for private_value in (
                    "service-token",
                    "stdout-secret",
                    "stderr-private-diagnostic",
                    "timeout-secret",
                    "timeout-private-diagnostic",
                ):
                    self.assertNotIn(private_value, message)


if __name__ == "__main__":
    unittest.main()
