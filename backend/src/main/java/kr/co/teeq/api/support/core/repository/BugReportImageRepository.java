package kr.co.teeq.api.support.core.repository;

import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.support.core.entity.BugReportImage;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BugReportImageRepository extends JpaRepository<BugReportImage, UUID> {

    List<BugReportImage> findAllByBugReportIdAndDeletedFalseOrderBySortOrderAsc(UUID bugReportId);

}
