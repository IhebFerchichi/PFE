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
    -PackName "PKG-00001" `
    -LfpBmsId "1" `
    -SupercapBmsId "2" `
    -LfpBaseCellV 3.301 `
    -SupercapBaseCellV 2.681 `
    -BaseCurrentA 4.2 `
    -BaseTempC 27.8 `
    -Soc 82 `
    -MosquittoPub $MosquittoPub `
    -BrokerHost $BrokerHost `
    -BrokerPort $BrokerPort `
    -Iterations $Iterations `
    -IntervalSeconds $IntervalSeconds `
    -Scenario $Scenario
