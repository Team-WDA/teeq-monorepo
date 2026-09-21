package com.chuseok22.aifriend.common.core.exception;

public enum CommonErrorCode implements ErrorCode {

    INVALID_REQUEST(400, "잘못된 요청입니다."),
    INTERNAL_SERVER_ERROR(500, "서버 내부 오류가 발생했습니다.");

    private final int httpStatus;
    private final String message;

    CommonErrorCode(int httpStatus, String message) {
        this.httpStatus = httpStatus;
        this.message = message;
    }

    @Override
    public int httpStatus() {
        return httpStatus;
    }

    @Override
    public String message() {
        return message;
    }

}
