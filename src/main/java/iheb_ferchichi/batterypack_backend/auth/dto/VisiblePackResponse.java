package iheb_ferchichi.batterypack_backend.auth.dto;

import java.time.OffsetDateTime;

public class VisiblePackResponse {
    private Long id;
    private String packageCode;
    private String label;
    private String status;
    private Long ownerUserId;
    private String ownerFullName;
    private String ownerEmail;
    private String lfpBmsId;
    private String supercapBmsId;
    private OffsetDateTime createdAt;

    public VisiblePackResponse() {
    }

    public VisiblePackResponse(
            Long id,
            String packageCode,
            String label,
            String status,
            Long ownerUserId,
            String ownerFullName,
            String ownerEmail,
            String lfpBmsId,
            String supercapBmsId,
            OffsetDateTime createdAt
    ) {
        this.id = id;
        this.packageCode = packageCode;
        this.label = label;
        this.status = status;
        this.ownerUserId = ownerUserId;
        this.ownerFullName = ownerFullName;
        this.ownerEmail = ownerEmail;
        this.lfpBmsId = lfpBmsId;
        this.supercapBmsId = supercapBmsId;
        this.createdAt = createdAt;
    }

    public Long getId() {
        return id;
    }

    public String getPackageCode() {
        return packageCode;
    }

    public String getLabel() {
        return label;
    }

    public String getStatus() {
        return status;
    }

    public Long getOwnerUserId() {
        return ownerUserId;
    }

    public String getOwnerFullName() {
        return ownerFullName;
    }

    public String getOwnerEmail() {
        return ownerEmail;
    }

    public String getLfpBmsId() {
        return lfpBmsId;
    }

    public String getSupercapBmsId() {
        return supercapBmsId;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }
}
