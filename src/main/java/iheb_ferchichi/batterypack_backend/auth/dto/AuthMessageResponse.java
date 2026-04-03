package iheb_ferchichi.batterypack_backend.auth.dto;

public class AuthMessageResponse {
    private String message;
    private String email;

    public AuthMessageResponse() {
    }

    public AuthMessageResponse(String message, String email) {
        this.message = message;
        this.email = email;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
}
