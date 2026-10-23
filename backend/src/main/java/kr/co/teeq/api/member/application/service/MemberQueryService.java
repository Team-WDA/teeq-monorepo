package kr.co.teeq.api.member.application.service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.application.dto.request.MemberSearchRequest;
import kr.co.teeq.api.member.application.dto.response.MemberPageResponse;
import kr.co.teeq.api.member.application.dto.response.MemberSummaryResponse;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import kr.co.teeq.api.member.core.repository.MemberSpecifications;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * 관리자용 회원 목록 검색과 상세 조회.
 */
@Service
@RequiredArgsConstructor
public class MemberQueryService {

    // 요청의 정렬은 무시하고 항상 최근 가입 회원이 먼저 오게 한다
    private static final Sort MEMBER_SORT = Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("id"));

    private final MemberRepository memberRepository;

    @Transactional(readOnly = true)
    public MemberPageResponse search(MemberSearchRequest request, Pageable pageable) {
        Pageable fixedSortPageable = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize(), MEMBER_SORT);
        Page<Member> page = memberRepository.findAll(toSpecification(request), fixedSortPageable);
        List<MemberSummaryResponse> members = page.getContent().stream().map(MemberSummaryResponse::from).toList();
        return new MemberPageResponse(members, page.getNumber(), page.getSize(), page.getTotalElements());
    }

    @Transactional(readOnly = true)
    public MemberSummaryResponse getSummary(UUID memberId) {
        Member member = memberRepository.findByIdAndDeletedFalse(memberId)
            .orElseThrow(() -> new CustomException(ErrorCode.MEMBER_NOT_FOUND));
        return MemberSummaryResponse.from(member);
    }

    private Specification<Member> toSpecification(MemberSearchRequest request) {
        List<Specification<Member>> specifications = new ArrayList<>();
        specifications.add(MemberSpecifications.notDeleted());
        if (request.keyword() != null && !request.keyword().isBlank()) {
            specifications.add(MemberSpecifications.emailOrNicknameContaining(request.keyword().trim()));
        }
        if (request.loginType() != null) {
            specifications.add(MemberSpecifications.ofLoginType(request.loginType()));
        }
        return Specification.allOf(specifications);
    }

}
