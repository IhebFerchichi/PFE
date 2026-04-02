package iheb_ferchichi.batterypack_backend.auth.service;

import iheb_ferchichi.batterypack_backend.auth.dto.CreatePackageRequestDto;
import iheb_ferchichi.batterypack_backend.auth.dto.PackageRequestResponse;
import iheb_ferchichi.batterypack_backend.auth.dto.ReviewPackageRequestDto;
import iheb_ferchichi.batterypack_backend.auth.entity.*;
import iheb_ferchichi.batterypack_backend.auth.repository.CustomerPackageRepository;
import iheb_ferchichi.batterypack_backend.auth.repository.PackageDeviceRepository;
import iheb_ferchichi.batterypack_backend.auth.repository.PackageRequestRepository;
import iheb_ferchichi.batterypack_backend.auth.repository.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;
import java.util.List;

@Service
//@RequiredArgsConstructor
public class PackageRequestService {

    private final PackageRequestRepository packageRequestRepository;
    private final CustomerPackageRepository customerPackageRepository;
    private final PackageDeviceRepository packageDeviceRepository;
    private final UserRepository userRepository;

    public PackageRequestService(
            PackageRequestRepository packageRequestRepository,
            CustomerPackageRepository customerPackageRepository,
            PackageDeviceRepository packageDeviceRepository,
            UserRepository userRepository
    ) {
        this.packageRequestRepository = packageRequestRepository;
        this.customerPackageRepository = customerPackageRepository;
        this.packageDeviceRepository = packageDeviceRepository;
        this.userRepository = userRepository;
    }
    @Transactional
    public PackageRequestResponse createRequest(String userEmail, CreatePackageRequestDto dto) {
        User user = getUserByEmail(userEmail);

        PackageRequest request = new PackageRequest();
        request.setUser(user);
        request.setRequestedLabel(dto.getRequestedLabel());
        request.setReason(dto.getReason());
        request.setStatus(PackageRequestStatus.PENDING);
        request.setRequestedAt(OffsetDateTime.now());

        return PackageRequestResponse.fromEntity(packageRequestRepository.save(request));
    }

    @Transactional
    public List<PackageRequestResponse> getUserRequests(String userEmail) {
        User user = getUserByEmail(userEmail);

        return packageRequestRepository.findByUserOrderByRequestedAtDesc(user).stream()
                .map(PackageRequestResponse::fromEntity)
                .toList();
    }

    @Transactional
    public List<PackageRequestResponse> getPendingRequests() {
        return packageRequestRepository.findByStatusOrderByRequestedAtAsc(PackageRequestStatus.PENDING).stream()
                .map(PackageRequestResponse::fromEntity)
                .toList();
    }

    @Transactional
    public PackageRequestResponse approveRequest(Long requestId, String adminEmail, ReviewPackageRequestDto dto) {
        PackageRequest request = packageRequestRepository.findById(requestId)
                .orElseThrow(() -> new IllegalArgumentException("Package request not found"));

        if (request.getStatus() != PackageRequestStatus.PENDING) {
            throw new IllegalStateException("Request already reviewed");
        }

        User admin = getAdminByEmail(adminEmail);

        if (dto.getLfpBmsId() == null || dto.getLfpBmsId().isBlank()) {
            throw new IllegalArgumentException("LFP BMS ID is required");
        }

        if (dto.getSupercapBmsId() == null || dto.getSupercapBmsId().isBlank()) {
            throw new IllegalArgumentException("Supercap BMS ID is required");
        }

        String lfpBmsId = dto.getLfpBmsId().trim();
        String supercapBmsId = dto.getSupercapBmsId().trim();

        if (lfpBmsId.equalsIgnoreCase(supercapBmsId)) {
            throw new IllegalArgumentException("LFP BMS ID and Supercap BMS ID must be different");
        }

        if (packageDeviceRepository.findByBmsId(lfpBmsId).isPresent()) {
            throw new IllegalArgumentException("LFP BMS ID already assigned");
        }

        if (packageDeviceRepository.findByBmsId(supercapBmsId).isPresent()) {
            throw new IllegalArgumentException("Supercap BMS ID already assigned");
        }

        CustomerPackage customerPackage = new CustomerPackage();
        customerPackage.setPackageCode(generatePackageCode());
        customerPackage.setOwnerUser(request.getUser());
        customerPackage.setLabel(request.getRequestedLabel());
        customerPackage.setStatus(PackageStatus.ACTIVE);
        customerPackage.setCreatedAt(OffsetDateTime.now());
        customerPackage.setCreatedBy(admin);

        customerPackage = customerPackageRepository.save(customerPackage);

        PackageDevice lfpDevice = new PackageDevice();
        lfpDevice.setCustomerPackage(customerPackage);
        lfpDevice.setPackType(PackType.LFP);
        lfpDevice.setBmsId(lfpBmsId);
        lfpDevice.setEnabled(true);
        packageDeviceRepository.save(lfpDevice);

        PackageDevice supercapDevice = new PackageDevice();
        supercapDevice.setCustomerPackage(customerPackage);
        supercapDevice.setPackType(PackType.SUPERCAP);
        supercapDevice.setBmsId(supercapBmsId);
        supercapDevice.setEnabled(true);
        packageDeviceRepository.save(supercapDevice);

        request.setStatus(PackageRequestStatus.APPROVED);
        request.setReviewedAt(OffsetDateTime.now());
        request.setReviewedBy(admin);
        request.setAdminComment(dto.getAdminComment());

        return PackageRequestResponse.fromEntity(packageRequestRepository.save(request));
    }

    @Transactional
    public PackageRequestResponse rejectRequest(Long requestId, String adminEmail, String adminComment) {
        PackageRequest request = packageRequestRepository.findById(requestId)
                .orElseThrow(() -> new IllegalArgumentException("Package request not found"));

        if (request.getStatus() != PackageRequestStatus.PENDING) {
            throw new IllegalStateException("Request already reviewed");
        }

        User admin = getAdminByEmail(adminEmail);

        request.setStatus(PackageRequestStatus.REJECTED);
        request.setReviewedAt(OffsetDateTime.now());
        request.setReviewedBy(admin);
        request.setAdminComment(adminComment);

        return PackageRequestResponse.fromEntity(packageRequestRepository.save(request));
    }

    private String generatePackageCode() {
        long count = customerPackageRepository.count() + 1;
        return String.format("PKG-%05d", count);
    }

    private User getUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
    }

    private User getAdminByEmail(String email) {
        User user = getUserByEmail(email);
        if (user.getRole() != Role.ADMIN) {
            throw new IllegalArgumentException("Admin privileges required");
        }
        return user;
    }
}
