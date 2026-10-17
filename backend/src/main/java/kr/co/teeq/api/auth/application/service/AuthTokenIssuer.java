package kr.co.teeq.api.auth.application.service;

import kr.co.teeq.api.auth.application.dto.response.AuthResponse;
import kr.co.teeq.api.auth.core.entity.RefreshToken;
import kr.co.teeq.api.auth.core.port.IssuedRefreshToken;
import kr.co.teeq.api.auth.core.port.TokenProvider;
import kr.co.teeq.api.auth.core.repository.RefreshTokenRepository;
import kr.co.teeq.api.member.core.entity.Member;
import kr.co.teeq.api.member.core.port.AiCharacterExistencePort;
import kr.co.teeq.api.member.core.port.ProfileImageStoragePort;
import kr.co.teeq.api.member.core.repository.ProfileImageRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

/**
 * Access Token과 Refresh Token을 발급하고 Refresh Token을 저장한다. 호출한 쪽의 트랜잭션에 참여한다.
 */
@Component
@RequiredArgsConstructor
public class AuthTokenIssuer {

    private final RefreshTokenRepository refreshTokenRepository;
    private final TokenProvider tokenProvider;
    private final AiCharacterExistencePort aiCharacterExistencePort;
    private final ProfileImageRepository profileImageRepository;
    private final ProfileImageStoragePort profileImageStoragePort;

    public AuthResponse issue(Member member) {
        String accessToken = tokenProvider.issueAccessToken(member.getId());
        IssuedRefreshToken issued = tokenProvider.issueRefreshToken(member.getId());
        refreshTokenRepository.findByMemberId(member.getId()).ifPresentOrElse(
            existing -> existing.rotate(issued.token(), issued.expiresAt()),
            () -> refreshTokenRepository.save(RefreshToken.builder()
                .memberId(member.getId())
                .token(issued.token())
                .expiresAt(issued.expiresAt())
                .build()));
        String profileImageUrl = profileImageRepository.findByMemberIdAndDeletedFalse(member.getId())
            .map(image -> profileImageStoragePort.urlFor(image.getStorageKey()))
            .orElse(null);
        return AuthResponse.of(accessToken, issued.token(), member,
            aiCharacterExistencePort.existsByMemberId(member.getId()), profileImageUrl);
    }

}
