package com.chuseok22.aifriend.common.core.exception;

/**
 * 도메인별 에러 코드 enum이 구현하는 공통 인터페이스.
 * 각 도메인은 자신의 core 패키지에 {@code XxxErrorCode} enum을 두고 이 인터페이스를 구현한다.
 */
public interface ErrorCode {

    int httpStatus();

    /**
     * 클라이언트가 분기에 사용하는 기계 판독용 코드. enum 상수 이름을 그대로 사용한다.
     */
    String name();

    String message();

}
