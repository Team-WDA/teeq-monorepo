package kr.co.teeq.api.auth.application.controller;

import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import kr.co.teeq.api.auth.core.constant.AppleClientIds;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.util.UriUtils;

/**
 * Android의 Apple 웹 로그인 콜백 중계.
 * Apple이 form_post로 보낸 결과를 앱이 받을 수 있도록 intent URI로 302 리다이렉트한다.
 * 토큰과 사용자 JSON은 로그에 남기지 않는다.
 */
@RestController
@RequestMapping("/api/auth/apple")
public class AppleCallbackController implements AppleCallbackControllerDocs {

    private static final List<String> FORWARDED_PARAMETER_NAMES = List.of("code", "id_token", "state", "user", "error");
    private static final String INTENT_FRAGMENT = "#Intent;package=" + AppleClientIds.BUNDLE_IDENTIFIER
        + ";scheme=signinwithapple;end";

    @PostMapping(value = "/callback", consumes = MediaType.APPLICATION_FORM_URLENCODED_VALUE)
    public ResponseEntity<Void> callback(@RequestParam Map<String, String> parameters) {
        String query = FORWARDED_PARAMETER_NAMES.stream()
            .filter(parameters::containsKey)
            .map(name -> name + "=" + UriUtils.encode(parameters.get(name), StandardCharsets.UTF_8))
            .collect(Collectors.joining("&"));
        return ResponseEntity.status(HttpStatus.FOUND)
            .location(URI.create("intent://callback?" + query + INTENT_FRAGMENT))
            .build();
    }

}
