package iheb_ferchichi.batterypack_backend.dto;


import java.math.BigDecimal;
import java.time.OffsetDateTime;

public class CellHistoryPointResponse {

    private OffsetDateTime ts;
    private String bmsId;
    private Integer cellIndex;
    private BigDecimal cellVoltage;
    private Boolean balancingOn;

    public CellHistoryPointResponse() {
    }

    public OffsetDateTime getTs() {
        return ts;
    }

    public void setTs(OffsetDateTime ts) {
        this.ts = ts;
    }

    public String getBmsId() {
        return bmsId;
    }

    public void setBmsId(String bmsId) {
        this.bmsId = bmsId;
    }

    public Integer getCellIndex() {
        return cellIndex;
    }

    public void setCellIndex(Integer cellIndex) {
        this.cellIndex = cellIndex;
    }

    public BigDecimal getCellVoltage() {
        return cellVoltage;
    }

    public void setCellVoltage(BigDecimal cellVoltage) {
        this.cellVoltage = cellVoltage;
    }

    public Boolean getBalancingOn() {
        return balancingOn;
    }

    public void setBalancingOn(Boolean balancingOn) {
        this.balancingOn = balancingOn;
    }
}
