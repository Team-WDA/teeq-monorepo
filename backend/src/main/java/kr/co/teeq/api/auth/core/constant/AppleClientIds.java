package kr.co.teeq.api.auth.core.constant;

import java.util.Set;

/**
 * Apple identity token의 audience로 허용하는 클라이언트 식별자.
 * iOS 네이티브는 번들 ID, Android 웹 흐름은 Services ID가 audience로 들어온다.
 */
public final class AppleClientIds {

    public static final String BUNDLE_IDENTIFIER = "kr.co.teeq.app";
    public static final String SERVICES_IDENTIFIER = "kr.co.teeq.app.service";
    public static final Set<String> AUDIENCES = Set.of(BUNDLE_IDENTIFIER, SERVICES_IDENTIFIER);

    private AppleClientIds() {
    }

}
