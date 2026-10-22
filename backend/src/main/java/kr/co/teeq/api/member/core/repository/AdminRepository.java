package kr.co.teeq.api.member.core.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.member.core.constant.AdminRole;
import kr.co.teeq.api.member.core.entity.Admin;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AdminRepository extends JpaRepository<Admin, UUID> {

    Optional<Admin> findByUsernameAndDeletedFalse(String username);

    Optional<Admin> findByIdAndDeletedFalse(UUID id);

    boolean existsByUsernameAndDeletedFalse(String username);

    long countByRoleAndDeletedFalse(AdminRole role);

    List<Admin> findAllByDeletedFalseOrderByCreatedAtAsc();

}
