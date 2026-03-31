package iheb_ferchichi.batterypack_backend.dto;

public class SourceDto {
    private String bms_id;
    private String fw;

    public SourceDto() {}

    public String getBms_id() { return bms_id; }
    public void setBms_id(String bms_id) { this.bms_id = bms_id; }

    public String getFw() { return fw; }
    public void setFw(String fw) { this.fw = fw; }
}