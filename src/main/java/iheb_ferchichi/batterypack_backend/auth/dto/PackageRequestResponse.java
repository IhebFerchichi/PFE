package iheb_ferchichi.batterypack_backend.auth.dto;

import iheb_ferchichi.batterypack_backend.auth.entity.PackageRequest;

import java.time.OffsetDateTime;

public record PackageRequestResponse(
        Long id,
        String requestedLabel,
        String reason,
        String status,
        OffsetDateTime requestedAt,
        OffsetDateTime reviewedAt,
        String adminComment,
        UserSummary user,
        UserSummary reviewedBy
) {
    public static PackageRequestResponse fromEntity(PackageRequest request) {
        return new PackageRequestResponse(
                request.getId(),
                request.getRequestedLabel(),
                request.getReason(),
                request.getStatus() != null ? request.getStatus().name() : null,
                request.getRequestedAt(),
                request.getReviewedAt(),
                request.getAdminComment(),
                request.getUser() != null ? UserSummary.fromEntity(request.getUser()) : null,
                request.getReviewedBy() != null ? UserSummary.fromEntity(request.getReviewedBy()) : null
        );
    }

    public record UserSummary(
            Long id,
            String fullName,
            String email,
            String role
    ) {
        public static UserSummary fromEntity(iheb_ferchichi.batterypack_backend.auth.entity.User user) {
            return new UserSummary(
                    user.getId(),
                    user.getFullName(),
                    user.getEmail(),
                    user.getRole() != null ? user.getRole().name() : null
            );
        }
    }
}
