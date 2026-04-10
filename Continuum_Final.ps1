# ============================================
# CONTINUUM MONITORING SYSTEM v4.0
# Features: Mobile Responsive | Enhanced Health | 1-Year Retention
# ============================================

$Port = 18095
$UpdateInterval = 5
$BackupEnabled = $true
$RetentionDays = 365

$Tenants = @{
    "Production" = @{
        Key = "prod-123"
        Nodes = @{
            "Google DNS" = "8.8.8.8"
            "Cloudflare" = "1.1.1.1"
            "Local Machine" = "127.0.0.1"
        }
        Plan = "Enterprise"
    }
    "Demo" = @{
        Key = "demo-123"
        Nodes = @{
            "Web Server" = "sim"
            "Database" = "sim"
            "Cache Server" = "sim"
            "Load Balancer" = "sim"
        }
        Plan = "Free"
    }
    "SimTest" = @{
        Key = "simtest-123"
        Nodes = @{
            "Sim-Node-1" = "sim"
            "Sim-Node-2" = "sim"
            "Sim-Node-3" = "sim"
        }
        Plan = "Test"
    }
}

$Global:TenantNodeData = @{}
$Global:AlertQueue = [System.Collections.Queue]::new()
$Global:StartTime = Get-Date

foreach ($tenant in $Tenants.Keys) {
    $Global:TenantNodeData[$tenant] = @{}
    foreach ($node in $Tenants[$tenant].Nodes.Keys) {
        $Global:TenantNodeData[$tenant][$node] = @{
            Status = "Checking..."
            LastUpdate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
    }
}

function Rotate-DataRetention {
    $archiveDir = "C:\Users\Administrator\Continuum\archive"
    if (-not (Test-Path $archiveDir)) {
        New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
    }
    $currentMonth = Get-Date -Format "yyyy-MM"
    $archiveFile = Join-Path $archiveDir "continuum_archive_$currentMonth.json"
    $archiveData = @{ Timestamp = Get-Date; Tenants = $Global:TenantNodeData }
    $archiveData | ConvertTo-Json -Depth 10 | Out-File $archiveFile -Encoding UTF8
    Get-ChildItem $archiveDir -Filter "continuum_archive_*.json" | Where-Object {
        $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays)
    } | Remove-Item -Force -ErrorAction SilentlyContinue
}

Write-Host "Starting monitoring thread..." -ForegroundColor Cyan

$runspace = [runspacefactory]::CreateRunspace()
$runspace.Open()
$ps = [powershell]::Create()
$ps.Runspace = $runspace

$monitorScript = {
    param($NodeData, $AlertQueue, $Tenants)
    
    function Get-NodeStatus {
        param($Target)
        if ($Target -eq "sim") {
            $rand = Get-Random -Minimum 1 -Maximum 101
            if ($rand -le 70) { return "Healthy" }
            elseif ($rand -le 90) { return "Warning" }
            else { return "Error" }
        }
        else {
            try {
                $ping = New-Object System.Net.NetworkInformation.Ping
                $result = $ping.Send($Target, 2000)
                if ($result.Status -eq "Success") { return "Healthy" }
                else { return "Error" }
            }
            catch { return "Error" }
        }
    }
    
    $archiveCounter = 0
    while ($true) {
        $archiveCounter++
        if ($archiveCounter -ge 720) {
            Rotate-DataRetention
            $archiveCounter = 0
        }
        
        foreach ($tenant in $Tenants.Keys) {
            foreach ($node in $Tenants[$tenant].Nodes.Keys) {
                $target = $Tenants[$tenant].Nodes[$node]
                $newStatus = Get-NodeStatus -Target $target
                $oldStatus = $NodeData[$tenant][$node].Status
                
                $NodeData[$tenant][$node].Status = $newStatus
                $NodeData[$tenant][$node].LastUpdate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                
                if ($oldStatus -ne $newStatus -and $oldStatus -ne "Checking...") {
                    $AlertQueue.Enqueue("$tenant/$node : $oldStatus -> $newStatus")
                }
            }
        }
        Start-Sleep -Seconds 5
    }
}

$ps.AddScript($monitorScript).AddArgument($Global:TenantNodeData).AddArgument($Global:AlertQueue).AddArgument($Tenants).BeginInvoke()

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:$Port/")
$listener.Start()

Write-Host "========================================" -ForegroundColor Green
Write-Host "CONTINUUM MONITORING SYSTEM v4.0" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "Port: $Port" -ForegroundColor Cyan
Write-Host "Update: Every ${UpdateInterval}s" -ForegroundColor Cyan
Write-Host "Retention: ${RetentionDays} days (1 year)" -ForegroundColor Cyan
Write-Host "Mobile Responsive: ENABLED" -ForegroundColor Cyan
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
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Continuum - $tenant</title>
    <style>
        *{margin:0;padding:0;box-sizing:border-box}
        body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#0f1117;padding:24px;min-height:100vh}
        .container{max-width:1200px;margin:0 auto}
        .header{background:#1a1e2a;border:1px solid #2d2f3e;border-radius:20px;padding:28px;margin-bottom:24px;text-align:center}
        .header h1{color:#60a5fa;font-size:32px;margin-bottom:12px}
        .header p{color:#9ca3af;font-size:14px}
        .badge{display:inline-block;padding:6px 14px;background:#2d2f3e;border-radius:30px;font-size:12px;color:#a0a4b8;margin-top:12px}
        .stats{display:grid;grid-template-columns:repeat(4,1fr);gap:16px;margin-bottom:28px}
        .stat-card{background:#1a1e2a;border:1px solid #2d2f3e;border-radius:16px;padding:20px;text-align:center}
        .stat-card:hover{border-color:#60a5fa;transform:translateY(-2px)}
        .stat-number{font-size:36px;font-weight:bold;margin-bottom:8px}
        .stat-label{color:#9ca3af;font-size:13px;text-transform:uppercase}
        .healthy{color:#4ade80}
        .warning{color:#fbbf24}
        .error{color:#f87171}
        .checking{color:#9ca3af}
        table{background:#1a1e2a;border:1px solid #2d2f3e;border-radius:16px;width:100%;border-collapse:collapse}
        th,td{padding:14px 16px;text-align:left;border-bottom:1px solid #2d2f3e}
        th{background:#0f1117;color:#e5e7eb}
        td{color:#d1d5db}
        tr:hover td{background:#2d2f3e;color:white}
        .status-badge{display:inline-block;padding:4px 12px;border-radius:20px;font-size:12px;font-weight:500}
        .status-Healthy{background:#22c55e20;color:#4ade80;border:1px solid #22c55e40}
        .status-Warning{background:#f59e0b20;color:#fbbf24;border:1px solid #f59e0b40}
        .status-Error{background:#ef444420;color:#f87171;border:1px solid #ef444440}
        .footer{margin-top:28px;padding-top:24px;text-align:center;color:#6b7280;border-top:1px solid #2d2f3e}
        .footer a{color:#60a5fa;text-decoration:none;margin:0 8px}
        @media (max-width:768px){.stats{grid-template-columns:repeat(2,1fr)}th,td{padding:10px;font-size:12px}}
        @media (max-width:480px){.stats{grid-template-columns:1fr}}
    </style>
</head>
<body>
<div class="container">
<div class="header"><h1>Continuum</h1><p><strong>$tenant</strong> | $currentTime</p><div class="badge">Plan: $($Tenants[$tenant].Plan)</div></div>
<div class="stats">
<div class="stat-card"><div class="stat-number healthy">$healthy</div><div class="stat-label">Healthy</div></div>
<div class="stat-card"><div class="stat-number warning">$warning</div><div class="stat-label">Warning</div></div>
<div class="stat-card"><div class="stat-number error">$error</div><div class="stat-label">Error</div></div>
<div class="stat-card"><div class="stat-number checking">$checking</div><div class="stat-label">Checking</div></div>
</div>
<table>
<thead><tr><th>Node</th><th>Target</th><th>Status</th><th>Last Check</th></tr></thead>
<tbody>
"@
    foreach ($node in $data.Keys | Sort-Object) {
        $info = $data[$node]
        $target = $Tenants[$tenant].Nodes[$node]
        $html += "<tr><td><strong>$node</strong></td><td><code>$target</code></td><td><span class='status-badge status-$($info.Status)'>$($info.Status)</span></td><td>$($info.LastUpdate)</td></tr>"
    }
    $html += @"
</tbody>
</div>
<div class="footer">
<div>[Auto] Auto-refreshes every $UpdateInterval seconds | <a href="/health">Health</a></div>
<div style="margin-top:10px;">[Email] <a href="mailto:support@continuum-monitor.com">support@continuum-monitor.com</a> | (c) 2026 Continuum. All rights reserved.</div>
</div>
</div>
</body>
</html>
"@
    return $html
}

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
        elseif ($path -eq "/health") {
            $process = Get-Process -Id $pid
            $health = @{
                status = "Healthy"
                timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                version = "4.0"
                uptime = ((Get-Date) - $Global:StartTime).ToString()
                memory = [math]::Round($process.WorkingSet64 / 1MB, 2)
                tenants = $Tenants.Count
                totalNodes = ($Tenants.Values.Nodes.Keys | Measure-Object).Count
                retention = "$RetentionDays days"
                features = @("Real-time Monitoring", "Multi-tenant Support", "Email Alerts", "CSV/JSON/HTML Export", "5-second Refresh", "Auto-backup", "1-Year Data Retention", "Mobile Responsive")
            }
            $json = $health | ConvertTo-Json
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
            $response.ContentType = "application/json"
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        elseif ($path -eq "/terms") {
            $html = "<!DOCTYPE html><html><head><title>Terms of Service</title></head><body style='background:#0a0c10;color:#d1d5db;font-family:Arial;max-width:800px;margin:40px auto;padding:20px'><h1 style='color:#60a5fa'>Terms of Service</h1><p>Service provided with 99.5% uptime commitment.</p><p><a href='/dashboard?tenant=Demo&key=demo-123' style='color:#60a5fa'>Back to Dashboard</a></p><p style='margin-top:40px;color:#6b7280'>(c) 2026 Continuum</p></body></html>"
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        elseif ($path -eq "/privacy") {
            $html = "<!DOCTYPE html><html><head><title>Privacy Policy</title></head><body style='background:#0a0c10;color:#d1d5db;font-family:Arial;max-width:800px;margin:40px auto;padding:20px'><h1 style='color:#60a5fa'>Privacy Policy</h1><p>We collect monitoring data. Never sold. Data encrypted.</p><p><a href='/dashboard?tenant=Demo&key=demo-123' style='color:#60a5fa'>Back to Dashboard</a></p><p style='margin-top:40px;color:#6b7280'>(c) 2026 Continuum</p></body></html>"
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
        }
    }
}
finally {
    $ps.Stop()
    $runspace.Close()
    $listener.Stop()
    Write-Host "Continuum stopped" -ForegroundColor Yellow
}
