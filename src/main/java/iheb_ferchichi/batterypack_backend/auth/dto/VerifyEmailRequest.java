package iheb_ferchichi.batterypack_backend.auth.dto;

public class VerifyEmailRequest {
    private String token;

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }
}
