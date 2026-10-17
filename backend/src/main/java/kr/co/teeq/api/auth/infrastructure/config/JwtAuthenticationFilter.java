package kr.co.teeq.api.auth.infrastructure.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.UUID;
import kr.co.teeq.api.auth.core.port.TokenProvider;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.principal.AuthenticatedMember;
import kr.co.teeq.api.member.core.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

// 요청마다 회원을 조회해 삭제된 회원과 role 변경을 즉시 반영한다. 실패해도 컨텍스트를 비운 채 체인을 계속하고
// 401 응답은 entry point가 맡는다(공개 경로는 토큰이 잘못되어도 통과해야 하므로 여기서 응답하지 않는다)
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    public static final String ERROR_CODE_ATTRIBUTE = JwtAuthenticationFilter.class.getName() + ".ERROR_CODE";

    private static final String BEARER_PREFIX = "Bearer ";

    private final TokenProvider tokenProvider;
    private final MemberRepository memberRepository;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
        FilterChain filterChain) throws ServletException, IOException {
        String authorization = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (authorization != null && authorization.startsWith(BEARER_PREFIX)) {
            authenticate(request, authorization.substring(BEARER_PREFIX.length()).trim());
        }
        filterChain.doFilter(request, response);
    }

    private void authenticate(HttpServletRequest request, String token) {
        try {
            UUID memberId = tokenProvider.parseAccessToken(token);
            Member member = memberRepository.findByIdAndDeletedFalse(memberId)
                .orElseThrow(() -> new CustomException(ErrorCode.UNAUTHENTICATED));
            var authentication = new UsernamePasswordAuthenticationToken(
                new AuthenticatedMember(member), null,
                List.of(new SimpleGrantedAuthority("ROLE_" + member.getRole().name())));
            SecurityContextHolder.getContext().setAuthentication(authentication);
        } catch (CustomException exception) {
            SecurityContextHolder.clearContext();
            request.setAttribute(ERROR_CODE_ATTRIBUTE, exception.getErrorCode());
        }
    }

}
