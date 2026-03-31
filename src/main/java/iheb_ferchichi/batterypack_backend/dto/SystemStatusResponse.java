package iheb_ferchichi.batterypack_backend.dto;


import java.time.OffsetDateTime;

public class SystemStatusResponse {

    private OffsetDateTime serverTime;
    private PackStatusResponse lfp;
    private PackStatusResponse supercap;
    private Boolean bothOnline;

    public SystemStatusResponse() {
    }

    public OffsetDateTime getServerTime() {
        return serverTime;
    }

    public void setServerTime(OffsetDateTime serverTime) {
        this.serverTime = serverTime;
    }

    public PackStatusResponse getLfp() {
        return lfp;
    }

    public void setLfp(PackStatusResponse lfp) {
        this.lfp = lfp;
    }

    public PackStatusResponse getSupercap() {
        return supercap;
    }

    public void setSupercap(PackStatusResponse supercap) {
        this.supercap = supercap;
    }

    public Boolean getBothOnline() {
        return bothOnline;
    }

    public void setBothOnline(Boolean bothOnline) {
        this.bothOnline = bothOnline;
    }
}
