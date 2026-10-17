package kr.co.teeq.api.setting.core.constant;

import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;

/**
 * 설정 값의 타입. 값은 문자열로 저장하고, 수정 시 타입에 맞는지 검증한다.
 * 위반하면 {@link ErrorCode#INVALID_SETTING_VALUE}로 거부한다.
 */
public enum SettingValueType {

    INT {
        @Override
        public void validate(String raw, Long minimum, Long maximum) {
            long parsed;
            try {
                parsed = Long.parseLong(raw);
            } catch (NumberFormatException exception) {
                throw new CustomException(ErrorCode.INVALID_SETTING_VALUE, exception);
            }
            if (minimum != null && parsed < minimum) {
                throw new CustomException(ErrorCode.INVALID_SETTING_VALUE);
            }
            if (maximum != null && parsed > maximum) {
                throw new CustomException(ErrorCode.INVALID_SETTING_VALUE);
            }
        }
    },

    BOOLEAN {
        @Override
        public void validate(String raw, Long minimum, Long maximum) {
            if (!"true".equals(raw) && !"false".equals(raw)) {
                throw new CustomException(ErrorCode.INVALID_SETTING_VALUE);
            }
        }
    },

    STRING {
        @Override
        public void validate(String raw, Long minimum, Long maximum) {
            if (raw == null || raw.isBlank()) {
                throw new CustomException(ErrorCode.INVALID_SETTING_VALUE);
            }
        }
    };

    /** 최소·최대는 INT에서만 쓰며, 없으면 null이다. */
    public abstract void validate(String raw, Long minimum, Long maximum);

}
