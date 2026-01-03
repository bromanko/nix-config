# Dealmail Monitoring Skill

You are tasked with monitoring the health and status of the Dealmail scheduled jobs on this macOS system.

## Background

Dealmail consists of two launchd-managed services:
1. **dealmail-process-deals** - Processes deals, scheduled to run every 15 minutes (at :00, :15, :30, :45)
2. **dealmail-emails-to-feed** - Converts emails to RSS feed, scheduled hourly at :30

Both services:
- Run as background launchd agents
- Write logs to `~/Library/Logs/dealmail-*.log` and `~/Library/Logs/dealmail-*-error.log`
- Use lock files in `~/Library/Application Support/dealmail/` to prevent concurrent runs
- Require secrets from homeage mount point
- Use system Chrome via Puppeteer at `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`

## Your Task

Perform a comprehensive health check and report findings with remediation suggestions.

### 1. Service Status Check

Check if the launchd agents are loaded and running:

```bash
launchctl list | grep dealmail
```

For each service (dealmail-process-deals, dealmail-emails-to-feed):
- Verify it appears in launchctl list
- Note the PID (if running) and exit code (last run status)
- Check if they're properly enabled

**Red Flags:**
- Service not found in launchctl list
- Non-zero exit code
- Service repeatedly failing to start

### 2. Schedule Verification

Verify the configured schedule matches expectations:

```bash
launchctl print gui/$(id -u)/com.user.dealmail-process-deals 2>/dev/null
launchctl print gui/$(id -u)/com.user.dealmail-emails-to-feed 2>/dev/null
```

**Expected:**
- process-deals: Every 15 minutes
- emails-to-feed: Hourly at minute 30

### 3. Execution History (Last 24 Hours)

Analyze the standard output logs for execution patterns:

```bash
# Get logs from last 24 hours
find ~/Library/Logs -name "dealmail-*.log" -mtime -1 -exec echo "=== {} ===" \; -exec tail -100 {} \;
```

For each service:
- Identify timestamps of recent executions
- Calculate average execution frequency
- Determine last successful run time
- Check if schedule is being followed (e.g., process-deals should run ~96 times/day)

**Red Flags:**
- Missing expected executions (gaps > scheduled interval)
- Jobs running too frequently (lock file issues)
- No runs in last hour
- "already running" messages (stuck processes)

### 4. Error Detection

Check error logs for failures:

```bash
# Check error logs from last 24 hours
find ~/Library/Logs -name "dealmail-*-error.log" -mtime -1 -exec echo "=== {} ===" \; -exec tail -50 {} \;
```

Look for common issues:
- "ERROR: Dealmail secrets file not found"
- Chrome/Puppeteer errors
- Network timeouts
- JavaScript/Node errors
- Lock file conflicts
- Script execution failures

**Warning Signs:**
- Any ERROR messages
- Repeated warnings (>5 in 24h)
- Stack traces
- Exit code != 0 patterns

### 5. System Prerequisites

Verify dependencies are in place:

```bash
# Chrome installation
ls -la "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Check for lock files
ls -la ~/Library/Application\ Support/dealmail/*.lock 2>/dev/null

# Note: secrets check will fail due to permissions, that's expected
ls -la ~/.homeage/ 2>/dev/null
```

**Red Flags:**
- Chrome not found
- Stale lock files (>1 hour old with no corresponding process)
- Working directory missing

### 6. Feed Output Verification

Check if the RSS feed is being updated:

```bash
curl -s -I https://youmightlikethis.site/feed.xml | grep -i "last-modified"
curl -s https://youmightlikethis.site/feed.xml | head -50
```

**Red Flags:**
- Feed not accessible (4xx/5xx errors)
- Last-Modified header is >2 hours old
- Feed appears empty or malformed
- No recent items in feed

### 7. Analysis and Reporting

Synthesize findings into a clear report with:

#### Overall Health Status
- ✅ **HEALTHY** - All checks passed, jobs running on schedule
- ⚠️  **WARNING** - Minor issues detected, needs attention
- ❌ **CRITICAL** - Major issues, jobs not functioning

#### Detailed Findings

For each check category, report:
- Status (✅/⚠️/❌)
- Key metrics
- Any anomalies found
- Relevant log excerpts

#### Remediation Suggestions

Based on issues found, suggest specific remedies:

**Common Remedies:**

- **Service not loaded:**
  ```bash
  # Reload home-manager configuration
  home-manager switch --flake .#gray-area
  ```

- **Stale lock file:**
  ```bash
  # Remove stale locks (ensure no process is actually running first)
  rm ~/Library/Application\ Support/dealmail/*.lock
  ```

- **Service crashed/stuck:**
  ```bash
  # Restart the service
  launchctl kickstart -k gui/$(id -u)/com.user.dealmail-process-deals
  launchctl kickstart -k gui/$(id -u)/com.user.dealmail-emails-to-feed
  ```

- **Chrome missing:**
  ```bash
  # Install Chrome via Homebrew
  brew install --cask google-chrome
  ```

- **Configuration issues:**
  ```bash
  # Check configuration in nix file
  cat ~/nix-config/modules/darwin/desktop/apps/dealmail.nix

  # Verify host enables dealmail
  grep -r "dealmail.enable" ~/nix-config/hosts/
  ```

- **Logs show errors but need investigation:**
  ```bash
  # Run manually to see real-time output
  launchctl kickstart -p gui/$(id -u)/com.user.dealmail-process-deals

  # Check full error log
  tail -100 ~/Library/Logs/dealmail-process-deals-error.log
  ```

## Output Format

Present findings in this structure:

```
# Dealmail Health Check Report
Generated: [timestamp]

## 🎯 Overall Status: [HEALTHY/WARNING/CRITICAL]

## 📊 Service Status
- process-deals: [status, last run, exit code]
- emails-to-feed: [status, last run, exit code]

## ⏰ Execution History (24h)
- process-deals: [X runs, last: timestamp, frequency: Xm]
- emails-to-feed: [X runs, last: timestamp, frequency: Xm]

## ⚠️ Issues Found
[List any problems, or "None" if all clear]

## 🌐 Feed Status
- URL: https://youmightlikethis.site/feed.xml
- Last Modified: [timestamp]
- Status: [accessible/updated/issues]

## 🔧 Recommended Actions
[Specific commands or steps to resolve issues, or "None required"]

## 📝 Recent Log Excerpts
[Relevant snippets if issues found]
```

## Important Notes

- Focus on actionable insights
- Distinguish between warnings (non-critical) and errors (critical)
- Flag any anomalies even if unclear
- Provide context with log excerpts
- Make remediation steps copy-pasteable
- If unclear about schedule expectations, check: `~/nix-config/modules/darwin/desktop/apps/dealmail.nix`
