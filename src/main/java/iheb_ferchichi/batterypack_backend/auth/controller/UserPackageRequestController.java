package iheb_ferchichi.batterypack_backend.auth.controller;

import iheb_ferchichi.batterypack_backend.auth.dto.CreatePackageRequestDto;
import iheb_ferchichi.batterypack_backend.auth.entity.PackageRequest;
import iheb_ferchichi.batterypack_backend.auth.service.PackageRequestService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/user/package-requests")
//@RequiredArgsConstructor
public class UserPackageRequestController {

    private final PackageRequestService packageRequestService;
    public UserPackageRequestController(PackageRequestService packageRequestService) {
        this.packageRequestService = packageRequestService;
    }

    @PostMapping
    public PackageRequest createRequest(
            @RequestParam Long userId,
            @RequestBody CreatePackageRequestDto dto
    ) {
        return packageRequestService.createRequest(userId, dto);
    }

    @GetMapping
    public List<PackageRequest> getMyRequests(@RequestParam Long userId) {
        return packageRequestService.getUserRequests(userId);
    }
}