package iheb_ferchichi.batterypack_backend.auth.repository;

import iheb_ferchichi.batterypack_backend.auth.entity.CustomerPackage;
import iheb_ferchichi.batterypack_backend.auth.entity.PackType;
import iheb_ferchichi.batterypack_backend.auth.entity.PackageDevice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PackageDeviceRepository extends JpaRepository<PackageDevice, Long> {
    List<PackageDevice> findByCustomerPackageOrderByIdAsc(CustomerPackage customerPackage);
    List<PackageDevice> findByCustomerPackageId(Long customerPackageId);
    List<PackageDevice> findByCustomerPackageIdInOrderByCustomerPackageIdAscIdAsc(List<Long> customerPackageIds);
    List<PackageDevice> findByPackTypeAndEnabledTrueOrderByBmsIdAsc(PackType packType);
    Optional<PackageDevice> findByBmsId(String bmsId);
    Optional<PackageDevice> findByCustomerPackageAndPackType(CustomerPackage customerPackage, PackType packType);
}
