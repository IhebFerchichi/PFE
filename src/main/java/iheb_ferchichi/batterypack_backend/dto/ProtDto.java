package iheb_ferchichi.batterypack_backend.dto;


public class ProtDto {

    private Integer alert_triggered;
    private Integer alarm_triggered;
    private Integer protections_triggered;
    private Integer x_protections_triggered;

    private Integer uv_alert;
    private Integer ov_alert;
    private Integer occ_alert;
    private Integer ocd1_alert;
    private Integer scd_alert;

    private Integer uv_fault;
    private Integer ov_fault;
    private Integer ocd1_fault;
    private Integer scd_fault;

    public ProtDto() {}

    public Integer getAlert_triggered() { return alert_triggered; }
    public void setAlert_triggered(Integer alert_triggered) { this.alert_triggered = alert_triggered; }

    public Integer getAlarm_triggered() { return alarm_triggered; }
    public void setAlarm_triggered(Integer alarm_triggered) { this.alarm_triggered = alarm_triggered; }

    public Integer getProtections_triggered() { return protections_triggered; }
    public void setProtections_triggered(Integer protections_triggered) { this.protections_triggered = protections_triggered; }

    public Integer getX_protections_triggered() { return x_protections_triggered; }
    public void setX_protections_triggered(Integer x_protections_triggered) { this.x_protections_triggered = x_protections_triggered; }

    public Integer getUv_alert() { return uv_alert; }
    public void setUv_alert(Integer uv_alert) { this.uv_alert = uv_alert; }

    public Integer getOv_alert() { return ov_alert; }
    public void setOv_alert(Integer ov_alert) { this.ov_alert = ov_alert; }

    public Integer getOcc_alert() { return occ_alert; }
    public void setOcc_alert(Integer occ_alert) { this.occ_alert = occ_alert; }

    public Integer getOcd1_alert() { return ocd1_alert; }
    public void setOcd1_alert(Integer ocd1_alert) { this.ocd1_alert = ocd1_alert; }

    public Integer getScd_alert() { return scd_alert; }
    public void setScd_alert(Integer scd_alert) { this.scd_alert = scd_alert; }

    public Integer getUv_fault() { return uv_fault; }
    public void setUv_fault(Integer uv_fault) { this.uv_fault = uv_fault; }

    public Integer getOv_fault() { return ov_fault; }
    public void setOv_fault(Integer ov_fault) { this.ov_fault = ov_fault; }

    public Integer getOcd1_fault() { return ocd1_fault; }
    public void setOcd1_fault(Integer ocd1_fault) { this.ocd1_fault = ocd1_fault; }

    public Integer getScd_fault() { return scd_fault; }
    public void setScd_fault(Integer scd_fault) { this.scd_fault = scd_fault; }
}
