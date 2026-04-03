package iheb_ferchichi.batterypack_backend.auth.dto;

public class MeResponse {
    private Long userId;
    private String email;
    private String fullName;
    private String role;
    private Boolean emailVerified;

    public MeResponse() {
    }

    public MeResponse(Long userId, String email, String fullName, String role, Boolean emailVerified) {
        this.userId = userId;
        this.email = email;
        this.fullName = fullName;
        this.role = role;
        this.emailVerified = emailVerified;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public Boolean getEmailVerified() {
        return emailVerified;
    }

    public void setEmailVerified(Boolean emailVerified) {
        this.emailVerified = emailVerified;
    }
}
