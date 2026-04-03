package iheb_ferchichi.batterypack_backend.entity;

import jakarta.persistence.*;

import java.time.OffsetDateTime;

@Entity
@Table(name = "chart_marker", schema = "app")
public class ChartMarker {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 20)
    private String packType;

    @Column(name = "bms_id", nullable = false, length = 100)
    private String bmsId;

    @Column(name = "chart_key", nullable = false, length = 80)
    private String chartKey;

    @Column(name = "cell_index")
    private Short cellIndex;

    @Column(name = "marked_at", nullable = false)
    private OffsetDateTime markedAt = OffsetDateTime.now();

    @Column(name = "created_by", nullable = false, length = 255)
    private String createdBy;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    public Long getId() {
        return id;
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

    public Short getCellIndex() {
        return cellIndex;
    }

    public void setCellIndex(Short cellIndex) {
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

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
