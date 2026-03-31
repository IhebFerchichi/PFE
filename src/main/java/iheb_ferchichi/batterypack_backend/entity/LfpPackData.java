package iheb_ferchichi.batterypack_backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.Map;
@Data
@Entity
@Table(name = "lfp_pack_data", schema = "app")
public class LfpPackData {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private OffsetDateTime ts = OffsetDateTime.now();

    private BigDecimal packVoltage;
    private BigDecimal packCurrent;
    private BigDecimal temperature;
    private Integer statusFlags;


    @Column(name = "safety_alert_a")
    private Integer safetyAlertA;

    @Column(name = "safety_alert_b")
    private Integer safetyAlertB;

    @Column(name = "safety_alert_c")
    private Integer safetyAlertC;

    @Column(name = "safety_status_a")
    private Integer safetyStatusA;

    @Column(name = "safety_status_b")
    private Integer safetyStatusB;

    @Column(name = "safety_status_c")
    private Integer safetyStatusC;

    @Column(name = "pf_alert_a")
    private Integer pfAlertA;

    @Column(name = "pf_alert_b")
    private Integer pfAlertB;

    @Column(name = "pf_alert_c")
    private Integer pfAlertC;

    @Column(name = "pf_alert_d")
    private Integer pfAlertD;

    @Column(name = "pf_status_a")
    private Integer pfStatusA;

    @Column(name = "pf_status_b")
    private Integer pfStatusB;

    @Column(name = "pf_status_c")
    private Integer pfStatusC;

    @Column(name = "pf_status_d")
    private Integer pfStatusD;

    @Column(name = "alarm_status")
    private Integer alarmStatus;

    @Column(name = "battery_status")
    private Integer batteryStatus;

    @Column(name = "fet_status")
    private Integer fetStatus;

    @Column(name = "bms_id", length = 100)
    private String bmsId;



    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "raw_payload", columnDefinition = "jsonb", nullable = false)
    private Map<String, Object> rawPayload;

    public LfpPackData() {
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

    public Map<String, Object> getRawPayload() {
        return rawPayload;
    }

    public void setRawPayload(Map<String, Object> rawPayload) {
        this.rawPayload = rawPayload;
    }

    public void setBmsId(String bmsId) {
        this.bmsId = bmsId;
    }
    public String getBmsId() {
        return bmsId;
    }
}