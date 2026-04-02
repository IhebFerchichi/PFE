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
    -PackName "PKG-00003" `
    -LfpBmsId "7" `
    -SupercapBmsId "3" `
    -LfpBaseCellV 3.315 `
    -SupercapBaseCellV 2.701 `
    -BaseCurrentA 1.3 `
    -BaseTempC 26.2 `
    -Soc 91 `
    -MosquittoPub $MosquittoPub `
    -BrokerHost $BrokerHost `
    -BrokerPort $BrokerPort `
    -Iterations $Iterations `
    -IntervalSeconds $IntervalSeconds `
    -Scenario $Scenario
