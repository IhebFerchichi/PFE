package iheb_ferchichi.batterypack_backend.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity
@Data
@Table(name = "lfp_cell_data", schema = "app")
public class LfpCellData {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private OffsetDateTime ts;

    @Column(nullable = false)
    private Short cellIndex;

    private BigDecimal cellVoltage;

    private Boolean balancingOn;

    @ManyToOne(optional = false)
    @JoinColumn(name = "pack_data_id")
    private LfpPackData pack;

    public LfpCellData() {
    }

    public Long getId() {
        return id;
    }

    public OffsetDateTime getTs() {
        return ts;
    }

    public void setTs(OffsetDateTime ts) {
        this.ts = ts;
    }

    public Short getCellIndex() {
        return cellIndex;
    }

    public void setCellIndex(Short cellIndex) {
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

    public LfpPackData getPack() {
        return pack;
    }

    public void setPack(LfpPackData pack) {
        this.pack = pack;
    }
}