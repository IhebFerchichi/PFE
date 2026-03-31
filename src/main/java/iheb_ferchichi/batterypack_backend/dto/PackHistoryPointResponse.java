package iheb_ferchichi.batterypack_backend.dto;


import java.math.BigDecimal;
import java.time.OffsetDateTime;

public class PackHistoryPointResponse {

    private OffsetDateTime ts;
    private BigDecimal packVoltage;
    private BigDecimal packCurrent;
    private BigDecimal temperature;
    private Integer statusFlags;

    public PackHistoryPointResponse() {
    }

    public OffsetDateTime getTs() {
        return ts;
    }

    public void setTs(OffsetDateTime ts) {
        this.ts = ts;
    }

    public BigDecimal getPackVoltage() {
        return packVoltage;
    }

    public void setPackVoltage(BigDecimal packVoltage) {
        this.packVoltage = packVoltage;
    }

    public BigDecimal getPackCurrent() {
        return packCurrent;
    }

    public void setPackCurrent(BigDecimal packCurrent) {
        this.packCurrent = packCurrent;
    }

    public BigDecimal getTemperature() {
        return temperature;
    }

    public void setTemperature(BigDecimal temperature) {
        this.temperature = temperature;
    }

    public Integer getStatusFlags() {
        return statusFlags;
    }

    public void setStatusFlags(Integer statusFlags) {
        this.statusFlags = statusFlags;
    }
}
