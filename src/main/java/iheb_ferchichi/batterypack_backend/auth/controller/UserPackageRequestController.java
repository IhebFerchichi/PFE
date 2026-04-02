package iheb_ferchichi.batterypack_backend.auth.controller;

import iheb_ferchichi.batterypack_backend.auth.dto.CreatePackageRequestDto;
import iheb_ferchichi.batterypack_backend.auth.dto.PackageRequestResponse;
import iheb_ferchichi.batterypack_backend.auth.service.PackageRequestService;
import org.springframework.security.core.Authentication;
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
    public PackageRequestResponse createRequest(
            Authentication authentication,
            @RequestBody CreatePackageRequestDto dto
    ) {
        return packageRequestService.createRequest(authentication.getName(), dto);
    }

    @GetMapping
    public List<PackageRequestResponse> getMyRequests(Authentication authentication) {
        return packageRequestService.getUserRequests(authentication.getName());
    }
}
