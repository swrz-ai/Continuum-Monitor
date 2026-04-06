# ============================================
# CONTINUUM - ENTERPRISE MONITORING SYSTEM
# Enhanced Edition | PowerShell-native | Multi-type monitoring
# ============================================

# ========== CONFIGURATION ==========
$Port = 18095
$UpdateInterval = 5
$BackupEnabled = $true

# ========== TELEGRAM CONFIGURATION (FREE) ==========
$TelegramConfig = @{
    Enabled = $false
    BotToken = "YOUR_BOT_TOKEN_HERE"
    ChatId = "YOUR_CHAT_ID_HERE"
}

# ========== WEBHOOK CONFIGURATION ==========
$WebhookConfig = @{
    Enabled = $false
    SlackUrl = ""
    TeamsUrl = ""
    DiscordUrl = ""
}

# ========== GLOBAL VARIABLES ==========
$Global:TenantNodeData = @{}
$Global:AlertQueue = [System.Collections.Queue]::new()
$Global:StartTime = Get-Date
$Global:MaintenanceWindows = @{}
$Global:MetricsCache = @{}

# ========== TENANTS ==========
$Tenants = @{
    "Production" = @{
        Key = "prod-123"
        Nodes = @{
            "Google DNS" = @{ Target = "8.8.8.8"; Type = "ping" }
            "Cloudflare" = @{ Target = "1.1.1.1"; Type = "ping" }
            "Local Machine" = @{ Target = "127.0.0.1"; Type = "ping" }
            "My Website" = @{ Target = "google.com"; Type = "http" }
        }
        Plan = "Enterprise"
    }
    "Demo" = @{
        Key = "demo-123"
        Nodes = @{
            "Web Server" = @{ Target = "sim"; Type = "sim" }
            "Database" = @{ Target = "sim"; Type = "sim" }
            "Cache Server" = @{ Target = "sim"; Type = "sim" }
            "Load Balancer" = @{ Target = "sim"; Type = "sim" }
        }
        Plan = "Free"
    }
    "ClientABC" = @{
        Key = "client-abc-456"
        Nodes = @{
            "Main-Server" = @{ Target = "192.168.1.100"; Type = "ping" }
            "Backup-Server" = @{ Target = "192.168.1.101"; Type = "ping" }
            "Database-Server" = @{ Target = "192.168.1.102"; Type = "ping" }
        }
        Plan = "Professional"
    }
}

# ========== CORE FUNCTIONS ==========

# Multi-Type Monitoring
function Test-Server {
    param(
        $Target,
        $Type = "ping",
        $Port = $null,
        $ExpectedStatus = 200,
        $ServiceName = $null
    )
    
    switch ($Type.ToLower()) {
        "ping" {
            try {
                $ping = New-Object System.Net.NetworkInformation.Ping
                $result = $ping.Send($Target, 3000)
                return $result.Status -eq "Success"
            }
            catch { return $false }
        }
        "http" {
            try {
                $url = if ($Target -match "^http") { $Target } else { "http://$Target" }
                $request = [System.Net.WebRequest]::Create($url)
                $request.Timeout = 5000
                $request.Method = "HEAD"
                $response = $request.GetResponse()
                $status = [int]$response.StatusCode
                $response.Close()
                return $status -eq $ExpectedStatus
            }
            catch { return $false }
        }
        "https" {
            try {
                $url = if ($Target -match "^https") { $Target } else { "https://$Target" }
                $request = [System.Net.WebRequest]::Create($url)
                $request.Timeout = 5000
                $request.Method = "HEAD"
                $response = $request.GetResponse()
                $status = [int]$response.StatusCode
                $response.Close()
                return $status -eq $ExpectedStatus
            }
            catch { return $false }
        }
        "port" {
            if (-not $Port) { return $false }
            try {
                $tcp = New-Object System.Net.Sockets.TcpClient
                $result = $tcp.ConnectAsync($Target, $Port).Wait(3000)
                if ($result) { $tcp.Close() }
                return $result
            }
            catch { return $false }
        }
        "service" {
            if (-not $ServiceName) { $ServiceName = $Target }
            try {
                $service = Get-Service -Name $ServiceName -ErrorAction Stop
                return $service.Status -eq "Running"
            }
            catch { return $false }
        }
        "sim" {
            $rand = Get-Random -Minimum 1 -Maximum 101
            if ($rand -le 70) { return "Healthy" }
            elseif ($rand -le 90) { return "Warning" }
            else { return "Error" }
        }
        default { return $false }
    }
}

# Telegram Alerts (FREE)
function Send-TelegramAlert {
    param($Message)
    if (-not $TelegramConfig.Enabled) { return }
    if ([string]::IsNullOrEmpty($TelegramConfig.BotToken)) { return }
    
    try {
        $url = "https://api.telegram.org/bot$($TelegramConfig.BotToken)/sendMessage"
        $body = @{
            chat_id = $TelegramConfig.ChatId
            text = $Message
            parse_mode = "HTML"
        }
        Invoke-RestMethod -Uri $url -Method Post -Body $body -ErrorAction Stop
        Write-Host "  📱 Telegram alert sent" -ForegroundColor Cyan
    }
    catch {
        Write-Host "  ❌ Telegram failed: $_" -ForegroundColor Red
    }
}

# Webhook Alerts
function Send-WebhookAlert {
    param($Message, $WebhookUrl)
    if (-not $WebhookConfig.Enabled) { return }
    if ([string]::IsNullOrEmpty($WebhookUrl)) { return }
    
    try {
        $payload = @{ text = $Message } | ConvertTo-Json
        Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $payload -ContentType "application/json" -ErrorAction Stop
        Write-Host "  🔗 Webhook alert sent" -ForegroundColor Cyan
    }
    catch {
        Write-Host "  ❌ Webhook failed: $_" -ForegroundColor Red
    }
}

function Send-SlackAlert { param($Message) Send-WebhookAlert -Message $Message -WebhookUrl $WebhookConfig.SlackUrl }
function Send-TeamsAlert { param($Message) Send-WebhookAlert -Message $Message -WebhookUrl $WebhookConfig.TeamsUrl }
function Send-DiscordAlert { param($Message) Send-WebhookAlert -Message $Message -WebhookUrl $WebhookConfig.DiscordUrl }

# Maintenance Windows
function Set-MaintenanceWindow {
    param($Tenant, $Node, $StartTime, $EndTime)
    $key = "$Tenant/$Node"
    $Global:MaintenanceWindows[$key] = @{
        Start = $StartTime.ToString("yyyy-MM-dd HH:mm:ss")
        End = $EndTime.ToString("yyyy-MM-dd HH:mm:ss")
    }
    Write-Host "🔧 Maintenance scheduled for $key" -ForegroundColor Yellow
}

function Is-InMaintenance {
    param($Tenant, $Node)
    $key = "$Tenant/$Node"
    if ($Global:MaintenanceWindows.ContainsKey($key)) {
        $now = Get-Date
        $start = [datetime]::Parse($Global:MaintenanceWindows[$key].Start)
        $end = [datetime]::Parse($Global:MaintenanceWindows[$key].End)
        if ($now -ge $start -and $now -le $end) { return $true }
        elseif ($now -gt $end) { $Global:MaintenanceWindows.Remove($key) }
    }
    return $false
}

# Multi-Channel Alert
function Send-MultiAlert {
    param($Tenant, $Node, $OldStatus, $NewStatus)
    $message = "🚨 ALERT: $Tenant/$Node changed from $OldStatus to $NewStatus at $(Get-Date)"
    if ($NewStatus -eq "Error") { Write-Host $message -ForegroundColor Red }
    elseif ($NewStatus -eq "Warning") { Write-Host $message -ForegroundColor Yellow }
    Send-EmailAlert -Message $message
    Send-TelegramAlert -Message $message
    Send-SlackAlert -Message $message
    Send-TeamsAlert -Message $message
    Send-DiscordAlert -Message $message
}

function Send-EmailAlert {
    param($Message, $Subject = "Continuum Alert")
    Write-Host "  📧 Email would send: $Subject" -ForegroundColor DarkGray
}

# Scheduled Reports
function Generate-DailyReport {
    $healthyCount = 0; $warningCount = 0; $errorCount = 0; $totalNodes = 0
    foreach ($tenant in $Global:TenantNodeData.Keys) {
        foreach ($node in $Global:TenantNodeData[$tenant].Keys) {
            $totalNodes++
            switch ($Global:TenantNodeData[$tenant][$node].Status) {
                "Healthy" { $healthyCount++ }
                "Warning" { $warningCount++ }
                "Error" { $errorCount++ }
            }
        }
    }
    $report = @"
========================================
CONTINUUM DAILY REPORT
$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
========================================

SUMMARY
----------------------------------------
Total Tenants: $($Tenants.Count)
Total Nodes: $totalNodes
Healthy Nodes: $healthyCount
Warning Nodes: $warningCount
Error Nodes: $errorCount

UPTIME: $(if ($totalNodes -gt 0) { [math]::Round(($healthyCount / $totalNodes) * 100, 2) } else { 0 })%

DASHBOARD ACCESS
http://localhost:$Port/dashboard?tenant=Production&key=prod-123

---
Continuum Monitoring System
"@
    return $report
}

function Send-DailyReport {
    $report = Generate-DailyReport
    Write-Host "📊 Daily report generated" -ForegroundColor Cyan
}

# Multi-Format Export
function Export-Report {
    param($Tenant, $Format = "CSV")
    $data = $Global:TenantNodeData[$Tenant]
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = "C:\Users\Administrator\Continuum\backups"
    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
    $filename = "continuum_report_${Tenant}_${timestamp}.$($Format.ToLower())"
    $filepath = Join-Path $backupDir $filename
    
    switch ($Format.ToUpper()) {
        "CSV" {
            $csv = "Node,Status,LastUpdate`n"
            foreach ($node in $data.Keys) { $csv += "$node,$($data[$node].Status),$($data[$node].LastUpdate)`n" }
            $csv | Out-File -FilePath $filepath -Encoding UTF8
        }
        "JSON" { $data | ConvertTo-Json -Depth 5 | Out-File -FilePath $filepath -Encoding UTF8 }
        "HTML" {
            $html = "<!DOCTYPE html><html><head><title>Continuum Report - $Tenant</title></head><body style='font-family:Arial;margin:20px;'><h1>Continuum Report - $Tenant</h1><p>Generated: $(Get-Date)</p><table border='1' cellpadding='8'><tr><th>Node</th><th>Status</th><th>Last Update</th></tr>"
            foreach ($node in $data.Keys | Sort-Object) {
                $color = switch ($data[$node].Status) { "Healthy" { "green" } "Warning" { "orange" } "Error" { "red" } default { "gray" } }
                $html += "<tr><td>$node</td><td style='color:$color'>$($data[$node].Status)</td><td>$($data[$node].LastUpdate)</td></tr>"
            }
            $html += "</table></body></html>"
            $html | Out-File -FilePath $filepath -Encoding UTF8
        }
        default { return $null }
    }
    return $filepath
}

function Backup-Data {
    if (-not $BackupEnabled) { return }
    $backupDir = "C:\Users\Administrator\Continuum\backups"
    if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
    $date = (Get-Date).ToString("yyyyMMdd_HHmmss")
    $backupFile = Join-Path $backupDir "continuum_data_$date.json"
    try {
        $Global:TenantNodeData | ConvertTo-Json -Depth 10 | Set-Content $backupFile -Encoding UTF8
        Get-ChildItem $backupDir -Filter "continuum_data_*.json" | Sort-Object LastWriteTime -Descending | Select-Object -Skip 30 | Remove-Item -Force -ErrorAction SilentlyContinue
    }
    catch {}
}

# ========== INITIALIZE DATA ==========
foreach ($tenant in $Tenants.Keys) {
    $Global:TenantNodeData[$tenant] = @{}
    foreach ($node in $Tenants[$tenant].Nodes.Keys) {
        $Global:TenantNodeData[$tenant][$node] = @{
            Status = "Checking..."
            LastUpdate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            History = @()
        }
        for ($i = 0; $i -lt 10; $i++) { $Global:TenantNodeData[$tenant][$node].History += "Checking..." }
    }
}

# ========== MONITORING THREAD ==========
Write-Host "Starting enhanced monitoring thread..." -ForegroundColor Cyan

$runspace = [runspacefactory]::CreateRunspace()
$runspace.Open()
$ps = [powershell]::Create()
$ps.Runspace = $runspace

$monitorScript = {
    param($NodeData, $AlertQueue, $Tenants)
    $backupCounter = 0
    while ($true) {
        Start-Sleep -Seconds 5
        $backupCounter++
        if ($backupCounter -ge 720) { Backup-Data; $backupCounter = 0 }
        foreach ($tenant in $Tenants.Keys) {
            foreach ($node in $Tenants[$tenant].Nodes.Keys) {
                $nodeConfig = $Tenants[$tenant].Nodes[$node]
                $target = $nodeConfig.Target
                $type = if ($nodeConfig.Type) { $nodeConfig.Type } else { "ping" }
                $port = if ($nodeConfig.Port) { $nodeConfig.Port } else { $null }
                $result = Test-Server -Target $target -Type $type -Port $port
                $newStatus = if ($type -eq "sim") { $result } else { if ($result) { "Healthy" } else { "Error" } }
                $oldStatus = $NodeData[$tenant][$node].Status
                $NodeData[$tenant][$node].Status = $newStatus
                $NodeData[$tenant][$node].LastUpdate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                $history = $NodeData[$tenant][$node].History
                $history += $newStatus
                if ($history.Count -gt 20) { $history = $history[1..20] }
                $NodeData[$tenant][$node].History = $history
                if ($oldStatus -ne $newStatus -and $oldStatus -ne "Checking...") {
                    $AlertQueue.Enqueue("$tenant/$node : $oldStatus -> $newStatus")
                    Send-MultiAlert -Tenant $tenant -Node $node -OldStatus $oldStatus -NewStatus $newStatus
                }
            }
        }
    }
}

$ps.AddScript($monitorScript).AddArgument($Global:TenantNodeData).AddArgument($Global:AlertQueue).AddArgument($Tenants).BeginInvoke()

# ========== HTTP SERVER ==========
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$Port/")
$listener.Start()

# Schedule daily report
$reportTimer = New-Object System.Timers.Timer
$reportTimer.Interval = 24 * 60 * 60 * 1000
$reportTimer.Add_Elapsed({ Send-DailyReport })
$reportTimer.Start()

Write-Host "========================================" -ForegroundColor Green
Write-Host "CONTINUUM MONITORING SYSTEM" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Port: $Port" -ForegroundColor Cyan
Write-Host "Update: Every ${UpdateInterval}s" -ForegroundColor Cyan
Write-Host "Tenants: $($Tenants.Count)" -ForegroundColor Cyan
Write-Host "Total Nodes: $(($Tenants.Values.Nodes.Keys | Measure-Object).Count)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green
foreach ($tenant in $Tenants.Keys) {
    Write-Host "  $tenant : http://localhost:$Port/dashboard?tenant=$tenant&key=$($Tenants[$tenant].Key)" -ForegroundColor Gray
}
Write-Host "========================================" -ForegroundColor Green
Write-Host "Health: http://localhost:$Port/health" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Green

# ========== DASHBOARD HTML ==========
function Get-DashboardHTML {
    param($tenant, $data)
    $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $healthy = 0; $warning = 0; $error = 0; $checking = 0
    foreach ($node in $data.Keys) {
        switch ($data[$node].Status) {
            "Healthy" { $healthy++ }
            "Warning" { $warning++ }
            "Error" { $error++ }
            default { $checking++ }
        }
    }
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv='refresh' content='$UpdateInterval'>
    <meta charset='UTF-8'>
    <title>Continuum - $tenant</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f1117; padding: 24px; min-height: 100vh; }
        .container { max-width: 1200px; margin: 0 auto; }
        .header { background: #1a1e2a; border: 1px solid #2d2f3e; border-radius: 20px; padding: 28px; margin-bottom: 24px; text-align: center; }
        .header h1 { color: #60a5fa; font-size: 32px; margin-bottom: 12px; font-weight: 600; }
        .header p { color: #9ca3af; font-size: 14px; }
        .badge { display: inline-block; padding: 6px 14px; background: #2d2f3e; border-radius: 30px; font-size: 12px; color: #a0a4b8; margin-top: 12px; }
        .stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 28px; }
        .stat-card { background: #1a1e2a; border: 1px solid #2d2f3e; border-radius: 16px; padding: 20px; text-align: center; transition: all 0.2s; }
        .stat-card:hover { border-color: #60a5fa; transform: translateY(-2px); }
        .stat-number { font-size: 36px; font-weight: bold; margin-bottom: 8px; }
        .stat-label { color: #9ca3af; font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px; }
        .healthy { color: #4ade80; }
        .warning { color: #fbbf24; }
        .error { color: #f87171; }
        .checking { color: #9ca3af; }
        table { background: #1a1e2a; border: 1px solid #2d2f3e; border-radius: 16px; width: 100%; border-collapse: collapse; }
        th, td { padding: 14px 16px; text-align: left; border-bottom: 1px solid #2d2f3e; }
        th { background: #0f1117; color: #e5e7eb; font-weight: 600; }
        td { color: #d1d5db; }
        tr:hover td { background: #2d2f3e; color: #ffffff; }
        .status-badge { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 500; }
        .status-Healthy { background: #22c55e20; color: #4ade80; border: 1px solid #22c55e40; }
        .status-Warning { background: #f59e0b20; color: #fbbf24; border: 1px solid #f59e0b40; }
        .status-Error { background: #ef444420; color: #f87171; border: 1px solid #ef444440; }
        .status-Checking { background: #64748b20; color: #9ca3af; border: 1px solid #64748b40; }
        code { background: #0f1117; padding: 4px 8px; border-radius: 8px; font-size: 12px; color: #cbd5e1; font-family: monospace; }
        .footer { margin-top: 28px; padding-top: 24px; text-align: center; font-size: 12px; color: #6b7280; border-top: 1px solid #2d2f3e; }
        .footer a { color: #60a5fa; text-decoration: none; margin: 0 8px; }
        .footer a:hover { text-decoration: underline; }
        .btn-export { display: inline-block; margin-bottom: 20px; margin-right: 10px; padding: 10px 15px; background: #1a1e2a; border: 1px solid #2d2f3e; border-radius: 8px; color: #60a5fa; text-decoration: none; font-size: 13px; }
        .btn-export:hover { background: #2d2f3e; border-color: #60a5fa; }
        @media (max-width: 768px) { .stats { grid-template-columns: repeat(2, 1fr); } th, td { padding: 10px; font-size: 12px; } .btn-export { padding: 6px 10px; font-size: 11px; } }
    </style>
</head>
<body>
<div class="container">
<div class="header"><h1>Continuum</h1><p><strong>$tenant</strong> | Last Updated: $currentTime</p><div class="badge">Plan: $($Tenants[$tenant].Plan)</div></div>
<div class="stats">
<div class="stat-card"><div class="stat-number healthy">$healthy</div><div class="stat-label">Healthy</div></div>
<div class="stat-card"><div class="stat-number warning">$warning</div><div class="stat-label">Warning</div></div>
<div class="stat-card"><div class="stat-number error">$error</div><div class="stat-label">Error</div></div>
<div class="stat-card"><div class="stat-number checking">$checking</div><div class="stat-label">Checking</div></div>
</div>
<div style="margin-bottom:20px;">
<a href="/api/export?tenant=$tenant&key=$($Tenants[$tenant].Key)&format=CSV" class="btn-export">📥 Export CSV</a>
<a href="/api/export?tenant=$tenant&key=$($Tenants[$tenant].Key)&format=JSON" class="btn-export">📥 Export JSON</a>
<a href="/api/export?tenant=$tenant&key=$($Tenants[$tenant].Key)&format=HTML" class="btn-export">📥 Export HTML</a>
</div>
<table><thead><tr><th>Node</th><th>Target</th><th>Status</th><th>Last Check</th></tr></thead><tbody>
"@
    foreach ($node in $data.Keys | Sort-Object) {
        $info = $data[$node]
        $nodeConfig = $Tenants[$tenant].Nodes[$node]
        $target = if ($nodeConfig.Target) { $nodeConfig.Target } else { $nodeConfig }
        $type = if ($nodeConfig.Type -and $nodeConfig.Type -ne "ping") { " ($($nodeConfig.Type))" } else { "" }
        $html += "<tr><td><strong>$node</strong>$type</td><td><code>$target</code></td><td><span class='status-badge status-$($info.Status)'>$($info.Status)</span></td><td>$($info.LastUpdate)</td></tr>"
    }
    $html += @"
</tbody></table>
<div class="footer">
<div>🔄 Auto-refreshes every $UpdateInterval seconds | <a href="/health">Health</a></div>
<div style="margin-top:10px;">📧 <a href="mailto:support@continuum-monitor.com">support@continuum-monitor.com</a> | © 2026 Continuum. All rights reserved.</div>
</div>
</div>
</body>
</html>
"@
    return $html
}

# ========== REQUEST HANDLER ==========
try {
    while ($true) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $path = $request.Url.AbsolutePath
        $tenant = $request.QueryString["tenant"]
        $key = $request.QueryString["key"]
        
        if ($path -eq "/dashboard") {
            if ($tenant -and $Tenants.ContainsKey($tenant) -and $Tenants[$tenant].Key -eq $key) {
                $html = Get-DashboardHTML -tenant $tenant -data $Global:TenantNodeData[$tenant]
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            } else {
                $response.StatusCode = 403
                $buffer = [System.Text.Encoding]::UTF8.GetBytes("Access Denied")
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
        }
        elseif ($path -eq "/api/export") {
            if ($tenant -and $Tenants.ContainsKey($tenant) -and $Tenants[$tenant].Key -eq $key) {
                $format = $request.QueryString["format"]
                if (-not $format) { $format = "CSV" }
                $filepath = Export-Report -Tenant $tenant -Format $format
                $responseString = "Report exported to: $filepath"
            } else {
                $response.StatusCode = 403
                $responseString = "Access Denied"
            }
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseString)
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        elseif ($path -eq "/api/maintenance") {
            $tenant = $request.QueryString["tenant"]
            $node = $request.QueryString["node"]
            $action = $request.QueryString["action"]
            $duration = $request.QueryString["duration"]
            if ($action -eq "enable" -and $tenant -and $node -and $duration) {
                $startTime = Get-Date; $endTime = $startTime.AddMinutes([int]$duration)
                Set-MaintenanceWindow -Tenant $tenant -Node $node -StartTime $startTime -EndTime $endTime
                $responseString = "Maintenance mode enabled for $tenant/$node for $duration minutes"
            } elseif ($action -eq "disable" -and $tenant -and $node) {
                $Global:MaintenanceWindows.Remove("$tenant/$node")
                $responseString = "Maintenance mode disabled for $tenant/$node"
            } else {
                $responseString = "Usage: /api/maintenance?tenant=X&node=Y&action=enable&duration=30"
            }
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseString)
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        elseif ($path -eq "/health") {
            $process = Get-Process -Id $pid
            $health = @{
                status = "Healthy"
                timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                version = "Enhanced 2.0"
                uptime = ((Get-Date) - $Global:StartTime).ToString()
                memory = [math]::Round($process.WorkingSet64 / 1MB, 2)
                tenants = $Tenants.Count
                totalNodes = ($Tenants.Values.Nodes.Keys | Measure-Object).Count
                features = @("Multi-type monitoring", "Multi-channel alerts", "Maintenance windows", "Scheduled reports", "Multi-format export")
            }
            $json = $health | ConvertTo-Json
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
            $response.ContentType = "application/json"
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        elseif ($path -eq "/terms") {
            $html = "<!DOCTYPE html><html><head><title>Terms of Service</title></head><body style='background:#0a0c10;color:#d1d5db;font-family:Arial;max-width:800px;margin:40px auto;padding:20px'><h1 style='color:#60a5fa'>Terms of Service</h1><p>Service provided with 99.5% uptime commitment.</p><p><a href='/dashboard?tenant=Demo&key=demo-123' style='color:#60a5fa'>Back to Dashboard</a></p><p style='margin-top:40px;color:#6b7280'>© 2026 Continuum</p></body></html>"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        elseif ($path -eq "/privacy") {
            $html = "<!DOCTYPE html><html><head><title>Privacy Policy</title></head><body style='background:#0a0c10;color:#d1d5db;font-family:Arial;max-width:800px;margin:40px auto;padding:20px'><h1 style='color:#60a5fa'>Privacy Policy</h1><p>We collect monitoring data. Never sold. Data encrypted.</p><p><a href='/dashboard?tenant=Demo&key=demo-123' style='color:#60a5fa'>Back to Dashboard</a></p><p style='margin-top:40px;color:#6b7280'>© 2026 Continuum</p></body></html>"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        else {
            $response.StatusCode = 404
            $buffer = [System.Text.Encoding]::UTF8.GetBytes("Not Found")
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        $response.OutputStream.Close()
        
        while ($Global:AlertQueue.Count -gt 0) {
            $msg = $Global:AlertQueue.Dequeue()
            if ($msg -like "*Error*") { Write-Host "ALERT: $msg" -ForegroundColor Red }
            elseif ($msg -like "*Warning*") { Write-Host "WARNING: $msg" -ForegroundColor Yellow }
            else { Write-Host "INFO: $msg" -ForegroundColor Gray }
        }
    }
}
finally {
    $ps.Stop()
    $runspace.Close()
    $listener.Stop()
    Write-Host "Continuum stopped" -ForegroundColor Yellow
}
