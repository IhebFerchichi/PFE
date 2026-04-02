param(
    [Parameter(Mandatory = $true)]
    [string]$PackName,
    [Parameter(Mandatory = $true)]
    [string]$LfpBmsId,
    [Parameter(Mandatory = $true)]
    [string]$SupercapBmsId,
    [Parameter(Mandatory = $true)]
    [double]$LfpBaseCellV,
    [Parameter(Mandatory = $true)]
    [double]$SupercapBaseCellV,
    [Parameter(Mandatory = $true)]
    [double]$BaseCurrentA,
    [Parameter(Mandatory = $true)]
    [double]$BaseTempC,
    [Parameter(Mandatory = $true)]
    [int]$Soc,
    [string]$MosquittoPub = "C:\Users\User\Desktop\Folders\mosquitto\mosquitto_pub.exe",
    [string]$BrokerHost = "10.0.30.14",
    [int]$BrokerPort = 1883,
    [int]$Iterations = 20,
    [int]$IntervalSeconds = 5,
    [ValidateSet("normal", "hot", "imbalance", "fault")]
    [string]$Scenario = "normal"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $MosquittoPub)) {
    throw "mosquitto_pub.exe not found at '$MosquittoPub'"
}

function Get-RandomOffset {
    param([double]$Amplitude)
    return ((Get-Random -Minimum -1000 -Maximum 1001) / 1000.0) * $Amplitude
}

function New-VoltageSeries {
    param(
        [double]$BaseVoltage,
        [string]$Scenario,
        [string]$PackType
    )

    $values = New-Object System.Collections.Generic.List[double]
    for ($i = 0; $i -lt 16; $i++) {
        $noise = if ($PackType -eq "LFP") { Get-RandomOffset -Amplitude 0.012 } else { Get-RandomOffset -Amplitude 0.008 }
        $values.Add([math]::Round($BaseVoltage + $noise, 3))
    }

    if ($Scenario -eq "imbalance") {
        if ($PackType -eq "LFP") {
            $values[0] = [math]::Round($BaseVoltage - 0.070, 3)
            $values[15] = [math]::Round($BaseVoltage + 0.035, 3)
        } else {
            $values[0] = [math]::Round($BaseVoltage - 0.030, 3)
            $values[15] = [math]::Round($BaseVoltage + 0.012, 3)
        }
    }

    return $values
}

function New-BalanceFlags {
    param([string]$Scenario)

    $flags = New-Object System.Collections.Generic.List[int]
    for ($i = 0; $i -lt 16; $i++) {
        $flags.Add(0)
    }

    if ($Scenario -eq "normal") {
        $flags[(Get-Random -Minimum 0 -Maximum 16)] = 1
    }

    if ($Scenario -eq "imbalance") {
        $flags[0] = 1
        $flags[15] = 1
    }

    return $flags
}

function New-Temperatures {
    param(
        [double]$BaseTemp,
        [string]$Scenario
    )

    $temps = @(
        [math]::Round($BaseTemp + (Get-RandomOffset -Amplitude 0.8), 1),
        [math]::Round($BaseTemp + (Get-RandomOffset -Amplitude 1.0), 1),
        [math]::Round($BaseTemp + (Get-RandomOffset -Amplitude 0.7), 1),
        [math]::Round($BaseTemp + (Get-RandomOffset -Amplitude 0.9), 1),
        [math]::Round($BaseTemp + (Get-RandomOffset -Amplitude 0.6), 1)
    )

    if ($Scenario -eq "hot") {
        $temps[0] = 67.5
        $temps[1] = 64.2
    }

    return $temps
}

function New-ProtBlock {
    param([string]$Scenario)

    $prot = @{
        alert_triggered = 0
        alarm_triggered = 0
        protections_triggered = 0
        x_protections_triggered = 0
        uv_alert = 0
        ov_alert = 0
        occ_alert = 0
        ocd1_alert = 0
        scd_alert = 0
        uv_fault = 0
        ov_fault = 0
        ocd1_fault = 0
        scd_fault = 0
    }

    if ($Scenario -eq "fault") {
        $prot.alert_triggered = 1
        $prot.protections_triggered = 1
        $prot.ov_alert = 1
        $prot.ov_fault = 1
    }

    return $prot
}

function New-BqBlock {
    param([string]$Scenario)

    if ($Scenario -eq "fault") {
        return @{
            safety_status_a = 8
            safety_status_b = 0
            pf_status_a = 1
            pf_status_b = 0
        }
    }

    return @{
        safety_status_a = 0
        safety_status_b = 0
        pf_status_a = 0
        pf_status_b = 0
    }
}

function New-Payload {
    param(
        [string]$PackType,
        [string]$BmsId,
        [double]$BaseCellVoltage,
        [double]$CurrentA,
        [double]$TempC,
        [int]$SocValue,
        [string]$Scenario
    )

    $cells = New-VoltageSeries -BaseVoltage $BaseCellVoltage -Scenario $Scenario -PackType $PackType
    $balance = New-BalanceFlags -Scenario $Scenario
    $temps = New-Temperatures -BaseTemp $TempC -Scenario $Scenario
    $stackV = [math]::Round((($cells | Measure-Object -Sum).Sum), 3)
    $currentAWithNoise = [math]::Round($CurrentA + (Get-RandomOffset -Amplitude 1.1), 2)

    return @{
        pack_type = $PackType
        source = @{
            bms_id = $BmsId
            fw = "demo-fw-2026.04"
        }
        meas = @{
            cell_v = $cells
            stack_v = $stackV
            pack_v = $stackV
            ld_v = 12.4
            current_a = $currentAWithNoise
            temp_c = $temps
            soc_pct = $SocValue
        }
        balance = @{
            cell_bal = $balance
            active_cells_mask = 0
        }
        fet = @{
            chg = 1
            dsg = 1
        }
        prot = (New-ProtBlock -Scenario $Scenario)
        bq = (New-BqBlock -Scenario $Scenario)
    }
}

function Publish-Payload {
    param(
        [string]$Topic,
        [hashtable]$Payload
    )

    $json = $Payload | ConvertTo-Json -Depth 8 -Compress
    $tempFile = [System.IO.Path]::GetTempFileName()

    try {
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($tempFile, $json, $utf8NoBom)
        & $MosquittoPub -h $BrokerHost -p $BrokerPort -t $Topic -f $tempFile | Out-Null
    }
    finally {
        Remove-Item -LiteralPath $tempFile -ErrorAction SilentlyContinue
    }
}

Write-Host "Publishing '$PackName' scenario '$Scenario' to mqtt://$BrokerHost`:$BrokerPort"

for ($iteration = 1; $iteration -le $Iterations; $iteration++) {
    $lfpPayload = New-Payload `
        -PackType "LFP" `
        -BmsId $LfpBmsId `
        -BaseCellVoltage $LfpBaseCellV `
        -CurrentA $BaseCurrentA `
        -TempC $BaseTempC `
        -SocValue $Soc `
        -Scenario $Scenario

    $supercapPayload = New-Payload `
        -PackType "SUPERCAP" `
        -BmsId $SupercapBmsId `
        -BaseCellVoltage $SupercapBaseCellV `
        -CurrentA (-1 * $BaseCurrentA) `
        -TempC ($BaseTempC + 1.2) `
        -SocValue $Soc `
        -Scenario $Scenario

    Publish-Payload -Topic "packs/lfp/telemetry" -Payload $lfpPayload
    Publish-Payload -Topic "packs/supercap/telemetry" -Payload $supercapPayload

    Write-Host ("[{0}/{1}] Published {2}: LFP={3}, SUPERCAP={4}" -f $iteration, $Iterations, $PackName, $LfpBmsId, $SupercapBmsId)

    if ($iteration -lt $Iterations) {
        Start-Sleep -Seconds $IntervalSeconds
    }
}

Write-Host "Done."
