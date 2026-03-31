package iheb_ferchichi.batterypack_backend.auth.dto;

import lombok.Data;


public class CreatePackageRequestDto {
    private String requestedLabel;
    private String reason;

    public String getRequestedLabel() {
        return requestedLabel;
    }

    public void setRequestedLabel(String requestedLabel) {
        this.requestedLabel = requestedLabel;
    }

    public String getReason() {
        return reason;
    }

    public void setReason(String reason) {
        this.reason = reason;
    }
}