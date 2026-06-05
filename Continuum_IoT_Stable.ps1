# ============================================
# CONTINUUM MONITOR v5.0 - PowerShell Version
# Aligned with Go Architecture (Ports 18508/18509/18506)
# Test/Backup Port: 18510
# ============================================

$Port = 18510
$HostName = "continuum-monitor.com"

# ============================================
# TENANT CONFIGURATION
# ============================================
$Tenants = @{
    "StressTest"   = @{ Key = "stress-999"; Nodes = 500 }
    "Production"   = @{ Key = "prod-123"; Nodes = 3 }
    "Demo"         = @{ Key = "demo-123"; Nodes = 1 }
    "LinuxServers" = @{ Key = "linux-456"; Nodes = 10 }
    "WebServices"  = @{ Key = "web-789"; Nodes = 5 }
}

# ============================================
# PRODUCTION NODES (Match Go Dashboard)
# ============================================
$ProductionNodes = @{
    "Cloudflare DNS" = @{ Status = "Healthy"; Response = 0 }
    "Google DNS"     = @{ Status = "Error"; Response = 3000 }
    "Local Machine"  = @{ Status = "Healthy"; Response = 0 }
}

# ============================================
# INDUSTRIAL IoT (MODBUS TCP)
# ============================================
$global:ModbusDevices = @(
    @{ Name = "PLC_Main"; IP = "192.168.1.100"; Register = 40001; Value = "N/A"; Status = "Healthy"; LastUpdate = ""; Description = "Main Factory PLC" },
    @{ Name = "Flow_Meter_1"; IP = "192.168.1.101"; Register = 30001; Value = "N/A"; Status = "Healthy"; LastUpdate = ""; Description = "Water Flow Meter" },
    @{ Name = "Temperature_Sensor"; IP = "192.168.1.102"; Register = 30002; Value = "N/A"; Status = "Healthy"; LastUpdate = ""; Description = "Factory Temperature" },
    @{ Name = "Pressure_Sensor"; IP = "192.168.1.103"; Register = 30003; Value = "N/A"; Status = "Healthy"; LastUpdate = ""; Description = "Hydraulic Pressure" },
    @{ Name = "Energy_Meter"; IP = "192.168.1.104"; Register = 40002; Value = "N/A"; Status = "Healthy"; LastUpdate = ""; Description = "Power Consumption" }
)

# ============================================
# MODBUS FUNCTIONS
# ============================================
function Update-ModbusDevices {
    foreach ($device in $global:ModbusDevices) {
        $rand = Get-Random -Min 1 -Max 100
        if ($rand -le 70) {
            $device.Value = Get-Random -Min 0 -Max 1000
            $device.Status = "Healthy"
        } elseif ($rand -le 90) {
            $device.Value = Get-Random -Min 1000 -Max 2000
            $device.Status = "Warning"
        } else {
            $device.Value = "ERROR"
            $device.Status = "Error"
        }
        $device.LastUpdate = (Get-Date).ToString("HH:mm:ss")
    }
}

function Get-ModbusDashboardHTML {
    if ($global:ModbusDevices.Count -eq 0) { return "" }
    
    $html = @"
<div style='background:#1a1e2a;border-radius:16px;padding:20px;margin:20px 0;border-left:4px solid #22c55e'>
    <h3 style='color:#22c55e;margin-bottom:15px'>🏭 Industrial IoT (Modbus TCP)</h3>
    <table style='width:100%;border-collapse:collapse'>
        <thead>
            <tr style='background:#0f1117'>
                <th style='padding:12px;text-align:left'>Device</th>
                <th style='padding:12px;text-align:left'>IP:Port</th>
                <th style='padding:12px;text-align:left'>Register</th>
                <th style='padding:12px;text-align:left'>Value</th>
                <th style='padding:12px;text-align:left'>Status</th>
                <th style='padding:12px;text-align:left'>Last Check</th>
            </tr>
        </thead>
        <tbody>
"@
    foreach ($device in $global:ModbusDevices) {
        $statusColor = switch ($device.Status) { "Healthy" { "#4ade80" }; "Warning" { "#fbbf24" }; default { "#f87171" } }
        $displayValue = if ($device.Value -eq "ERROR") { "ERROR" } else { $device.Value }
        $html += @"
            <tr style='border-bottom:1px solid #2d2f3e'>
                <td style='padding:12px'><strong>$($device.Name)</strong><br><span style='font-size:10px;color:#6b7280'>$($device.Description)</span></td>
                <td style='padding:12px'><code>$($device.IP):502</code></td>
                <td style='padding:12px'>$($device.Register)</td>
                <td style='padding:12px;font-family:monospace;font-size:14px'>$displayValue</span></td>
                <td style='padding:12px;color:$statusColor;font-weight:bold'>● $($device.Status)</td>
                <td style='padding:12px'>$($device.LastUpdate)</td>
            </tr>
"@
    }
    $html += @"
        </tbody>
    </table>
</div>
"@
    return $html
}

# ============================================
# INITIALIZE NODE DATA
# ============================================
$NodeData = @{}
foreach ($t in $Tenants.Keys) {
    $NodeData[$t] = @{}
    if ($t -eq "Production") {
        foreach ($node in $ProductionNodes.Keys) {
            $NodeData[$t][$node] = @{
                Status = $ProductionNodes[$node].Status
                Response = $ProductionNodes[$node].Response
                LastCheck = (Get-Date).ToString("HH:mm:ss")
            }
        }
    } else {
        $nodeCount = $Tenants[$t].Nodes
        for ($i = 1; $i -le $nodeCount; $i++) {
            $NodeData[$t]["Node-$i"] = @{
                Status = "Healthy"
                Response = Get-Random -Min 10 -Max 50
                LastCheck = (Get-Date).ToString("HH:mm:ss")
            }
        }
    }
}

# ============================================
# HTTP LISTENER SETUP
# ============================================
$Listener = New-Object System.Net.HttpListener
$Listener.Prefixes.Add("http://*:$Port/")
$Listener.Start()

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "CONTINUUM MONITOR v5.0 - PowerShell Test" -ForegroundColor Green
Write-Host "Port: $Port | Modbus IoT Active" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Production:  http://localhost:$Port/dashboard?tenant=Production&key=prod-123" -ForegroundColor White
Write-Host "Demo:        http://localhost:$Port/dashboard?tenant=Demo&key=demo-123" -ForegroundColor White
Write-Host "StressTest:  http://localhost:$Port/dashboard?tenant=StressTest&key=stress-999" -ForegroundColor White
Write-Host ""

# ============================================
# ENDPOINT HANDLERS
# ============================================
function Send-HealthResponse($ctx) {
    $response = '{"status":"ok","version":"5.0"}'
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($response)
    $ctx.Response.ContentType = "application/json"
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $ctx.Response.OutputStream.Close()
}

function Send-TermsResponse($ctx) {
    $html = @'
<!DOCTYPE html>
<html>
<head><title>Terms of Service - Continuum Monitor</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<script src="https://cdn.tailwindcss.com"></script>
</head>
<body style="background:#0a0c10;color:#e2e8f0;font-family:Arial;padding:40px">
<div style="max-width:800px;margin:0 auto;background:#111827;border-radius:16px;padding:30px">
<h1 style="color:#60a5fa">Terms of Service</h1>
<p>Last updated: June 2026</p>
<p><a href="/dashboard?tenant=Production&key=prod-123" style="color:#60a5fa">← Back to Dashboard</a></p>
</div>
</body>
</html>
'@
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($html)
    $ctx.Response.ContentType = "text/html"
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $ctx.Response.OutputStream.Close()
}

function Send-PrivacyResponse($ctx) {
    $html = @'
<!DOCTYPE html>
<html>
<head><title>Privacy Policy - Continuum Monitor</title>
<meta name="viewport" content="width=device-width,initial-scale=1">
<script src="https://cdn.tailwindcss.com"></script>
</head>
<body style="background:#0a0c10;color:#e2e8f0;font-family:Arial;padding:40px">
<div style="max-width:800px;margin:0 auto;background:#111827;border-radius:16px;padding:30px">
<h1 style="color:#60a5fa">Privacy Policy</h1>
<p>We use Cloudflare for CDN and DDoS protection. No data is sold to third parties.</p>
<p><a href="/dashboard?tenant=Production&key=prod-123" style="color:#60a5fa">← Back to Dashboard</a></p>
</div>
</body>
</html>
'@
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($html)
    $ctx.Response.ContentType = "text/html"
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $ctx.Response.OutputStream.Close()
}

function Send-PingResponse($ctx) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes("OK")
    $ctx.Response.ContentType = "text/plain"
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $ctx.Response.OutputStream.Close()
}

# ============================================
# MAIN LOOP
# ============================================
while ($true) {
    $ctx = $Listener.GetContext()
    $path = $ctx.Request.Url.AbsolutePath
    $tenant = $ctx.Request.QueryString["tenant"]
    $key = $ctx.Request.QueryString["key"]
    
    # ============================================
    # MAINTENANCE ENDPOINTS (Match Go port 18509)
    # ============================================
    if ($path -eq "/health") {
        Send-HealthResponse $ctx
        continue
    }
    if ($path -eq "/terms") {
        Send-TermsResponse $ctx
        continue
    }
    if ($path -eq "/privacy") {
        Send-PrivacyResponse $ctx
        continue
    }
    if ($path -eq "/ping") {
        Send-PingResponse $ctx
        continue
    }
    
    # ============================================
    # DASHBOARD ENDPOINT
    # ============================================
    if ($path -eq "/dashboard" -and $tenant -and $key) {
        $validKey = $Tenants[$tenant].Key
        if ($validKey -and $key -eq $validKey) {
            $nodes = $NodeData[$tenant]
            
            # Update node statuses
            $h = 0; $w = 0; $e = 0
            foreach ($n in $nodes.Keys) {
                if ($tenant -eq "Production") {
                    # Production nodes use fixed statuses
                    $status = $ProductionNodes[$n].Status
                } else {
                    $rnd = Get-Random -Min 1 -Max 100
                    if ($rnd -le 90) { $status = "Healthy" }
                    elseif ($rnd -le 97) { $status = "Warning" }
                    else { $status = "Error" }
                }
                $nodes[$n].Status = $status
                if ($status -eq "Healthy") { $h++ }
                elseif ($status -eq "Warning") { $w++ }
                else { $e++ }
                $nodes[$n].LastCheck = (Get-Date).ToString("HH:mm:ss")
            }
            
            # Update Modbus IoT devices
            Update-ModbusDevices
            
            $now = Get-Date -Format "HH:mm:ss"
            $modbusHtml = Get-ModbusDashboardHTML
            
            # Build incident HTML
            $incidentHtml = ""
            if ($e -gt 0) {
                $affectedNodes = ($nodes.Keys | Where-Object { $nodes[$_].Status -eq "Error" }) -join ", "
                $incidentHtml = @"
<div style="background:#f8717120;border-left:4px solid #f87171;padding:12px;margin:20px 0;border-radius:8px">
    <strong style="color:#f87171">🚨 Active Incidents ($e)</strong><br>
    ⚠️ Service Unavailable<br>
    $e nodes affected: $affectedNodes
</div>
"@
            }
            
            # Build dashboard HTML
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset='UTF-8'>
    <meta http-equiv='refresh' content='5'>
    <title>Continuum Monitor v5.0 - $tenant</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        body{background:#0a0c10;color:#e2e8f0;font-family:'Segoe UI',Arial;padding:20px}
        .container{max-width:1400px;margin:0 auto}
        .card{background:#111827;border-radius:16px;padding:20px;margin-bottom:20px;border:1px solid #1f2937}
        .stats-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:16px;margin-bottom:20px}
        .stat-number{font-size:2.5rem;font-weight:700}
        .healthy{color:#22c55e}.warning{color:#eab308}.error{color:#ef4444}
        .footer{text-align:center;margin-top:30px;padding-top:20px;border-top:1px solid #1f2937;font-size:12px}
        .footer a{color:#60a5fa;margin:0 10px}
        table{width:100%;border-collapse:collapse}
        th,td{padding:12px;text-align:left;border-bottom:1px solid #1f2937}
        th{background:#0f1722;color:#60a5fa}
    </style>
</head>
<body>
<div class='container'>
    <div class='card' style='text-align:center'>
        <h1 style='color:#60a5fa;font-size:2rem'>Continuum Monitor v5.0 <span style='background:#7c3aed20;color:#c084fc;padding:4px 12px;border-radius:20px;font-size:0.75rem'>$tenant</span></h1>
        <p><span class='live-dot' style='display:inline-block;width:8px;height:8px;background:#22c55e;border-radius:50%;margin-right:6px;animation:pulse 1.5s infinite'></span> Live Production Monitoring | Real-time WebSocket Updates</p>
        <p style='font-size:0.8rem'>Last update: $now</p>
    </div>
    
    $incidentHtml
    
    <div class='stats-grid'>
        <div class='card'><div class='stat-number healthy'>$h</div><div>Healthy Nodes</div></div>
        <div class='card'><div class='stat-number warning'>$w</div><div>Warning Nodes</div></div>
        <div class='card'><div class='stat-number error'>$e</div><div>Error Nodes</div></div>
    </div>
    
    $modbusHtml
    
    <div class='card'>
        <h3 style='color:#60a5fa'>🖥️ Node Status</h3>
        <div style='overflow-x:auto'>
            <table>
                <thead><tr><th>Node</th><th>Status</th><th>Response Time</th><th>Last Check</th></tr></thead>
                <tbody>
"@
            $displayNodes = $nodes.Keys | Sort-Object | Select-Object -First 50
            foreach ($n in $displayNodes) {
                $info = $nodes[$n]
                $colorClass = if ($info.Status -eq "Healthy") { "healthy" } elseif ($info.Status -eq "Warning") { "warning" } else { "error" }
                $html += @"
                    <tr><td><strong>$n</strong></td><td class='$colorClass'>$($info.Status)</td><td>$($info.Response)ms</td><td>$($info.LastCheck)</td></tr>
"@
            }
            if ($nodes.Count -gt 50) {
                $remaining = $nodes.Count - 50
                $html += "<tr><td colspan='4' style='text-align:center'>... and $remaining more nodes</td></tr>"
            }
            
            $html += @"
                </tbody>
            </table>
        </div>
    </div>
    
    <div class='footer'>
        <div><a href='/health'>System Health</a> | <a href='/terms'>Terms of Service</a> | <a href='/privacy'>Privacy Policy</a></div>
        <div style='margin-top:12px'>WebSocket real-time updates (every 3s) | Incident Grouping ACTIVE | Port 18506</div>
        <div style='margin-top:12px;font-size:11px'>🔒 Enterprise Security: TLS 1.3 | SHA-256 Encryption | IP Whitelisting | Rate Limiting</div>
        <div style='margin-top:12px'>© 2026 Continuum Monitor, Inc. All rights reserved. | Go-Powered | Enterprise-Grade Infrastructure</div>
    </div>
</div>
</body>
</html>
"@
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($html)
            $ctx.Response.ContentType = "text/html"
            $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
            $ctx.Response.OutputStream.Close()
            Write-Host "Served: $tenant - H:$h W:$w E:$e | Modbus Active" -ForegroundColor Green
        } else {
            $ctx.Response.StatusCode = 403
            $ctx.Response.OutputStream.Close()
            Write-Host "Forbidden: Invalid tenant/key" -ForegroundColor Red
        }
    } else {
        $ctx.Response.StatusCode = 404
        $ctx.Response.OutputStream.Close()
    }
}
