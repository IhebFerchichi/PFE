package iheb_ferchichi.batterypack_backend.dto;


public class BqDto {

    private Integer safety_status_a;
    private Integer safety_status_b;
    private Integer pf_status_a;
    private Integer pf_status_b;

    public BqDto() {}

    public Integer getSafety_status_a() { return safety_status_a; }
    public void setSafety_status_a(Integer safety_status_a) { this.safety_status_a = safety_status_a; }

    public Integer getSafety_status_b() { return safety_status_b; }
    public void setSafety_status_b(Integer safety_status_b) { this.safety_status_b = safety_status_b; }

    public Integer getPf_status_a() { return pf_status_a; }
    public void setPf_status_a(Integer pf_status_a) { this.pf_status_a = pf_status_a; }

    public Integer getPf_status_b() { return pf_status_b; }
    public void setPf_status_b(Integer pf_status_b) { this.pf_status_b = pf_status_b; }
}
