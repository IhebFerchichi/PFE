package iheb_ferchichi.batterypack_backend.service;

import iheb_ferchichi.batterypack_backend.auth.entity.CustomerPackage;
import iheb_ferchichi.batterypack_backend.auth.entity.PackType;
import iheb_ferchichi.batterypack_backend.auth.entity.PackageDevice;
import iheb_ferchichi.batterypack_backend.auth.entity.Role;
import iheb_ferchichi.batterypack_backend.auth.entity.User;
import iheb_ferchichi.batterypack_backend.auth.repository.CustomerPackageRepository;
import iheb_ferchichi.batterypack_backend.auth.repository.PackageDeviceRepository;
import iheb_ferchichi.batterypack_backend.auth.repository.UserRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class TelemetryAccessService {

    private final UserRepository userRepository;
    private final CustomerPackageRepository customerPackageRepository;
    private final PackageDeviceRepository packageDeviceRepository;

    public TelemetryAccessService(
            UserRepository userRepository,
            CustomerPackageRepository customerPackageRepository,
            PackageDeviceRepository packageDeviceRepository
    ) {
        this.userRepository = userRepository;
        this.customerPackageRepository = customerPackageRepository;
        this.packageDeviceRepository = packageDeviceRepository;
    }

    public boolean isAdmin(String email) {
        return getUserByEmail(email).getRole() == Role.ADMIN;
    }

    public List<String> getAccessibleBmsIds(String email, PackType packType) {
        User user = getUserByEmail(email);
        if (user.getRole() == Role.ADMIN) {
            return List.of();
        }

        List<CustomerPackage> customerPackages = customerPackageRepository.findByOwnerUserOrderByCreatedAtDesc(user);
        List<String> bmsIds = new ArrayList<>();

        for (CustomerPackage customerPackage : customerPackages) {
            List<PackageDevice> devices = packageDeviceRepository.findByCustomerPackageOrderByIdAsc(customerPackage);
            for (PackageDevice device : devices) {
                if (device.getPackType() == packType && Boolean.TRUE.equals(device.getEnabled())) {
                    bmsIds.add(device.getBmsId());
                }
            }
        }

        return bmsIds;
    }

    public User getUserByEmail(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
    }
}
