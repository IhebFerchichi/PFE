package iheb_ferchichi.batterypack_backend.dto;


import java.math.BigDecimal;
import java.time.OffsetDateTime;

public class PackStatusResponse {

    private String packType;
    private String bmsId;
    private OffsetDateTime ts;
    private BigDecimal packVoltage;
    private BigDecimal packCurrent;
    private BigDecimal temperature;
    private Integer statusFlags;

    private BigDecimal minCellVoltage;
    private BigDecimal maxCellVoltage;
    private BigDecimal avgCellVoltage;
    private BigDecimal imbalance;

    private Integer balancingCount;
    private Long ageSeconds;
    private Boolean online;

    public PackStatusResponse() {
    }

    public String getPackType() {
        return packType;
    }

    public void setPackType(String packType) {
        this.packType = packType;
    }

    public String getBmsId() {
        return bmsId;
    }

    public void setBmsId(String bmsId) {
        this.bmsId = bmsId;
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

    public BigDecimal getMinCellVoltage() {
        return minCellVoltage;
    }

    public void setMinCellVoltage(BigDecimal minCellVoltage) {
        this.minCellVoltage = minCellVoltage;
    }

    public BigDecimal getMaxCellVoltage() {
        return maxCellVoltage;
    }

    public void setMaxCellVoltage(BigDecimal maxCellVoltage) {
        this.maxCellVoltage = maxCellVoltage;
    }

    public BigDecimal getAvgCellVoltage() {
        return avgCellVoltage;
    }

    public void setAvgCellVoltage(BigDecimal avgCellVoltage) {
        this.avgCellVoltage = avgCellVoltage;
    }

    public BigDecimal getImbalance() {
        return imbalance;
    }

    public void setImbalance(BigDecimal imbalance) {
        this.imbalance = imbalance;
    }

    public Integer getBalancingCount() {
        return balancingCount;
    }

    public void setBalancingCount(Integer balancingCount) {
        this.balancingCount = balancingCount;
    }

    public Long getAgeSeconds() {
        return ageSeconds;
    }

    public void setAgeSeconds(Long ageSeconds) {
        this.ageSeconds = ageSeconds;
    }

    public Boolean getOnline() {
        return online;
    }

    public void setOnline(Boolean online) {
        this.online = online;
    }
}
