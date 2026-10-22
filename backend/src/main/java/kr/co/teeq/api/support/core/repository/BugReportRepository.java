package kr.co.teeq.api.support.core.repository;

import java.util.Optional;
import java.util.UUID;
import kr.co.teeq.api.support.core.entity.BugReport;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface BugReportRepository extends JpaRepository<BugReport, UUID>, JpaSpecificationExecutor<BugReport> {

    // 목록에서 제보자(회원)를 함께 조회한다. 탈퇴한 회원의 제보도 포함한다
    @Override
    @EntityGraph(attributePaths = "member")
    Page<BugReport> findAll(Specification<BugReport> specification, Pageable pageable);

    // 상세 조회용. 제보자(회원)를 함께 가져온다
    @Query("select r from BugReport r join fetch r.member where r.id = :id and r.deleted = false")
    Optional<BugReport> findDetailByIdAndDeletedFalse(@Param("id") UUID id);

}
