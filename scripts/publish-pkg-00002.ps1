param(
    [string]$MosquittoPub = "C:\Users\User\Desktop\Folders\mosquitto\mosquitto_pub.exe",
    [string]$BrokerHost = "10.0.30.14",
    [int]$BrokerPort = 1883,
    [int]$Iterations = 20,
    [int]$IntervalSeconds = 5,
    [ValidateSet("normal", "hot", "imbalance", "fault")]
    [string]$Scenario = "normal"
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

& (Join-Path $scriptDir "publish-single-pack-telemetry.ps1") `
    -PackName "PKG-00002" `
    -LfpBmsId "4" `
    -SupercapBmsId "6" `
    -LfpBaseCellV 3.287 `
    -SupercapBaseCellV 2.664 `
    -BaseCurrentA -2.1 `
    -BaseTempC 29.4 `
    -Soc 64 `
    -MosquittoPub $MosquittoPub `
    -BrokerHost $BrokerHost `
    -BrokerPort $BrokerPort `
    -Iterations $Iterations `
    -IntervalSeconds $IntervalSeconds `
    -Scenario $Scenario
