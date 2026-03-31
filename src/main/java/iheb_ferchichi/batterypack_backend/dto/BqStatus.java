package iheb_ferchichi.batterypack_backend.dto;


public class BqStatus {

    private Integer safety_alert_a;
    private Integer safety_alert_b;
    private Integer safety_alert_c;

    private Integer safety_status_a;
    private Integer safety_status_b;
    private Integer safety_status_c;

    private Integer pf_alert_a;
    private Integer pf_alert_b;
    private Integer pf_alert_c;
    private Integer pf_alert_d;

    private Integer pf_status_a;
    private Integer pf_status_b;
    private Integer pf_status_c;
    private Integer pf_status_d;

    private Integer alarm_status;
    private Integer battery_status;
    private Integer fet_status;

    public BqStatus() {}

    // getters/setters (manual like you’re doing now)
}
