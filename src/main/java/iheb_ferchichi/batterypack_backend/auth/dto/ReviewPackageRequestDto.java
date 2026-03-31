package iheb_ferchichi.batterypack_backend.auth.dto;

import lombok.Data;


public class ReviewPackageRequestDto {
    private String adminComment;
    private String lfpBmsId;
    private String supercapBmsId;
    public String getAdminComment() {
        return adminComment;
    }

    public void setAdminComment(String adminComment) {
        this.adminComment = adminComment;
    }

    public String getLfpBmsId() {
        return lfpBmsId;
    }

    public void setLfpBmsId(String lfpBmsId) {
        this.lfpBmsId = lfpBmsId;
    }

    public String getSupercapBmsId() {
        return supercapBmsId;
    }

    public void setSupercapBmsId(String supercapBmsId) {
        this.supercapBmsId = supercapBmsId;
    }
}