package iheb_ferchichi.batterypack_backend.auth.service;

import iheb_ferchichi.batterypack_backend.auth.dto.CreatePackageRequestDto;
import iheb_ferchichi.batterypack_backend.auth.dto.ReviewPackageRequestDto;
import iheb_ferchichi.batterypack_backend.auth.entity.*;
import iheb_ferchichi.batterypack_backend.auth.repository.CustomerPackageRepository;
import iheb_ferchichi.batterypack_backend.auth.repository.PackageDeviceRepository;
import iheb_ferchichi.batterypack_backend.auth.repository.PackageRequestRepository;
import iheb_ferchichi.batterypack_backend.auth.repository.UserRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
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



    public PackageRequest createRequest(Long userId, CreatePackageRequestDto dto) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        PackageRequest request = new PackageRequest();
        request.setUser(user);
        request.setRequestedLabel(dto.getRequestedLabel());
        request.setReason(dto.getReason());
        request.setStatus(PackageRequestStatus.PENDING);
        request.setRequestedAt(OffsetDateTime.now());

        return packageRequestRepository.save(request);
    }

    public List<PackageRequest> getUserRequests(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        return packageRequestRepository.findByUserOrderByRequestedAtDesc(user);
    }

    public List<PackageRequest> getPendingRequests() {
        return packageRequestRepository.findByStatusOrderByRequestedAtAsc(PackageRequestStatus.PENDING);
    }

    @Transactional
    public PackageRequest approveRequest(Long requestId, Long adminId, ReviewPackageRequestDto dto) {
        PackageRequest request = packageRequestRepository.findById(requestId)
                .orElseThrow(() -> new IllegalArgumentException("Package request not found"));

        if (request.getStatus() != PackageRequestStatus.PENDING) {
            throw new IllegalStateException("Request already reviewed");
        }

        User admin = userRepository.findById(adminId)
                .orElseThrow(() -> new IllegalArgumentException("Admin not found"));

        if (dto.getLfpBmsId() == null || dto.getLfpBmsId().isBlank()) {
            throw new IllegalArgumentException("LFP BMS ID is required");
        }

        if (dto.getSupercapBmsId() == null || dto.getSupercapBmsId().isBlank()) {
            throw new IllegalArgumentException("Supercap BMS ID is required");
        }

        if (packageDeviceRepository.findByBmsId(dto.getLfpBmsId()).isPresent()) {
            throw new IllegalArgumentException("LFP BMS ID already assigned");
        }

        if (packageDeviceRepository.findByBmsId(dto.getSupercapBmsId()).isPresent()) {
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
        lfpDevice.setBmsId(dto.getLfpBmsId().trim());
        lfpDevice.setEnabled(true);
        packageDeviceRepository.save(lfpDevice);

        PackageDevice supercapDevice = new PackageDevice();
        supercapDevice.setCustomerPackage(customerPackage);
        supercapDevice.setPackType(PackType.SUPERCAP);
        supercapDevice.setBmsId(dto.getSupercapBmsId().trim());
        supercapDevice.setEnabled(true);
        packageDeviceRepository.save(supercapDevice);

        request.setStatus(PackageRequestStatus.APPROVED);
        request.setReviewedAt(OffsetDateTime.now());
        request.setReviewedBy(admin);
        request.setAdminComment(dto.getAdminComment());

        return packageRequestRepository.save(request);
    }

    public PackageRequest rejectRequest(Long requestId, Long adminId, String adminComment) {
        PackageRequest request = packageRequestRepository.findById(requestId)
                .orElseThrow(() -> new IllegalArgumentException("Package request not found"));

        if (request.getStatus() != PackageRequestStatus.PENDING) {
            throw new IllegalStateException("Request already reviewed");
        }

        User admin = userRepository.findById(adminId)
                .orElseThrow(() -> new IllegalArgumentException("Admin not found"));

        request.setStatus(PackageRequestStatus.REJECTED);
        request.setReviewedAt(OffsetDateTime.now());
        request.setReviewedBy(admin);
        request.setAdminComment(adminComment);

        return packageRequestRepository.save(request);
    }

    private String generatePackageCode() {
        long count = customerPackageRepository.count() + 1;
        return String.format("PKG-%05d", count);
    }
}