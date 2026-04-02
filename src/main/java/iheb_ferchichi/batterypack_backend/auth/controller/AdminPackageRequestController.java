package iheb_ferchichi.batterypack_backend.auth.controller;

import iheb_ferchichi.batterypack_backend.auth.dto.PackageRequestResponse;
import iheb_ferchichi.batterypack_backend.auth.dto.ReviewPackageRequestDto;
import iheb_ferchichi.batterypack_backend.auth.service.PackageRequestService;
import lombok.Data;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/admin/package-requests")
//@RequiredArgsConstructor
public class AdminPackageRequestController {

    private final PackageRequestService packageRequestService;
    public AdminPackageRequestController(PackageRequestService packageRequestService) {
        this.packageRequestService = packageRequestService;
    }

    @GetMapping("/pending")
    public List<PackageRequestResponse> getPendingRequests() {
        return packageRequestService.getPendingRequests();
    }

    @PostMapping("/{requestId}/approve")
    public PackageRequestResponse approve(
            @PathVariable Long requestId,
            Authentication authentication,
            @RequestBody ReviewPackageRequestDto dto
    ) {
        return packageRequestService.approveRequest(requestId, authentication.getName(), dto);
    }

    @PostMapping("/{requestId}/reject")
    public PackageRequestResponse reject(
            @PathVariable Long requestId,
            Authentication authentication,
            @RequestBody RejectRequestBody body
    ) {
        return packageRequestService.rejectRequest(requestId, authentication.getName(), body.getAdminComment());
    }

    @Data
    public static class RejectRequestBody {
        private String adminComment;

        public String getAdminComment() {
            return adminComment;
        }
        public void setAdminComment(String adminComment) {
            this.adminComment = adminComment;
        }
}}
