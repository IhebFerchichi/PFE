package iheb_ferchichi.batterypack_backend.auth.service;

import iheb_ferchichi.batterypack_backend.auth.dto.VisiblePackResponse;
import iheb_ferchichi.batterypack_backend.auth.entity.CustomerPackage;
import iheb_ferchichi.batterypack_backend.auth.entity.PackType;
import iheb_ferchichi.batterypack_backend.auth.entity.PackageDevice;
import iheb_ferchichi.batterypack_backend.auth.entity.Role;
import iheb_ferchichi.batterypack_backend.auth.entity.User;
import iheb_ferchichi.batterypack_backend.auth.repository.CustomerPackageRepository;
import iheb_ferchichi.batterypack_backend.auth.repository.PackageDeviceRepository;
import iheb_ferchichi.batterypack_backend.auth.repository.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class VisiblePackService {

    private final CustomerPackageRepository customerPackageRepository;
    private final PackageDeviceRepository packageDeviceRepository;
    private final UserRepository userRepository;

    public VisiblePackService(
            CustomerPackageRepository customerPackageRepository,
            PackageDeviceRepository packageDeviceRepository,
            UserRepository userRepository
    ) {
        this.customerPackageRepository = customerPackageRepository;
        this.packageDeviceRepository = packageDeviceRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public List<VisiblePackResponse> getVisiblePacks(String userEmail) {
        User user = userRepository.findByEmail(userEmail)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        List<CustomerPackage> packages = user.getRole() == Role.ADMIN
                ? customerPackageRepository.findAll(Sort.by(Sort.Direction.DESC, "createdAt"))
                : customerPackageRepository.findByOwnerUserOrderByCreatedAtDesc(user);

        if (packages.isEmpty()) {
            return List.of();
        }

        List<Long> packageIds = packages.stream()
                .map(CustomerPackage::getId)
                .toList();

        Map<Long, String> lfpByPackageId = new HashMap<>();
        Map<Long, String> supercapByPackageId = new HashMap<>();

        for (PackageDevice device : packageDeviceRepository.findByCustomerPackageIdInOrderByCustomerPackageIdAscIdAsc(packageIds)) {
            if (device.getPackType() == PackType.LFP) {
                lfpByPackageId.put(device.getCustomerPackage().getId(), device.getBmsId());
            } else if (device.getPackType() == PackType.SUPERCAP) {
                supercapByPackageId.put(device.getCustomerPackage().getId(), device.getBmsId());
            }
        }

        return packages.stream()
                .map(customerPackage -> new VisiblePackResponse(
                        customerPackage.getId(),
                        customerPackage.getPackageCode(),
                        customerPackage.getLabel(),
                        customerPackage.getStatus().name(),
                        customerPackage.getOwnerUser().getId(),
                        customerPackage.getOwnerUser().getFullName(),
                        customerPackage.getOwnerUser().getEmail(),
                        lfpByPackageId.get(customerPackage.getId()),
                        supercapByPackageId.get(customerPackage.getId()),
                        customerPackage.getCreatedAt()
                ))
                .toList();
    }
}
