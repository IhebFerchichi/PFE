package iheb_ferchichi.batterypack_backend.auth.controller;

import iheb_ferchichi.batterypack_backend.auth.dto.ReviewPackageRequestDto;
import iheb_ferchichi.batterypack_backend.auth.entity.PackageRequest;
import iheb_ferchichi.batterypack_backend.auth.service.PackageRequestService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
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
    public List<PackageRequest> getPendingRequests() {
        return packageRequestService.getPendingRequests();
    }

    @PostMapping("/{requestId}/approve")
    public PackageRequest approve(
            @PathVariable Long requestId,
            @RequestParam Long adminId,
            @RequestBody ReviewPackageRequestDto dto
    ) {
        return packageRequestService.approveRequest(requestId, adminId, dto);
    }

    @PostMapping("/{requestId}/reject")
    public PackageRequest reject(
            @PathVariable Long requestId,
            @RequestParam Long adminId,
            @RequestBody RejectRequestBody body
    ) {
        return packageRequestService.rejectRequest(requestId, adminId, body.getAdminComment());
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