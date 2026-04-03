package iheb_ferchichi.batterypack_backend.dto;

import java.time.OffsetDateTime;

public class ChartMarkerResponse {

    private Long id;
    private String packType;
    private String bmsId;
    private String chartKey;
    private Integer cellIndex;
    private OffsetDateTime markedAt;
    private String createdBy;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
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

    public String getChartKey() {
        return chartKey;
    }

    public void setChartKey(String chartKey) {
        this.chartKey = chartKey;
    }

    public Integer getCellIndex() {
        return cellIndex;
    }

    public void setCellIndex(Integer cellIndex) {
        this.cellIndex = cellIndex;
    }

    public OffsetDateTime getMarkedAt() {
        return markedAt;
    }

    public void setMarkedAt(OffsetDateTime markedAt) {
        this.markedAt = markedAt;
    }

    public String getCreatedBy() {
        return createdBy;
    }

    public void setCreatedBy(String createdBy) {
        this.createdBy = createdBy;
    }
}
