package kr.teeq.testsupport;

import kr.teeq.api.common.core.entity.BaseEntity;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

/**
 * BaseEntity 동작 검증 전용 엔티티. 애플리케이션 패키지(kr.teeq.api) 밖에 두어
 * 다른 테스트의 엔티티 스캔에 잡히지 않게 한다.
 */
@Entity
@Table(name = "sample")
public class SampleEntity extends BaseEntity {

}
