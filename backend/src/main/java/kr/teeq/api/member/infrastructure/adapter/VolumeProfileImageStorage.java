package kr.teeq.api.member.infrastructure.adapter;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import kr.teeq.api.common.core.exception.CustomException;
import kr.teeq.api.common.core.exception.ErrorCode;
import kr.teeq.api.member.core.port.ProfileImageStoragePort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 컨테이너에 마운트된 볼륨 디렉터리에 프로필 사진을 저장한다. 웹 서버가 같은 디렉터리를 {@link #URL_PREFIX} 경로로 서빙한다.
 */
@Slf4j
@Component
public class VolumeProfileImageStorage implements ProfileImageStoragePort {

    private static final String DIRECTORY = "/mnt/teeq/profile-images";
    private static final String URL_PREFIX = "/media/profile-images/";
    private static final String TEMPORARY_SUFFIX = ".tmp";

    private final Path directory;

    public VolumeProfileImageStorage() {
        this(Path.of(DIRECTORY));
    }

    VolumeProfileImageStorage(Path directory) {
        this.directory = directory;
    }

    // 임시 이름으로 쓴 뒤 옮겨, 쓰는 도중의 파일이 서빙되거나 중간에 끊긴 파일이 남지 않게 한다
    @Override
    public void store(String key, byte[] content) {
        Path temporary = directory.resolve(key + TEMPORARY_SUFFIX);
        try {
            Files.createDirectories(directory);
            Files.write(temporary, content);
            Files.move(temporary, directory.resolve(key), StandardCopyOption.ATOMIC_MOVE);
        } catch (IOException exception) {
            deleteQuietly(temporary);
            log.error("프로필 사진 파일 저장 실패: key={}", key, exception);
            throw new CustomException(ErrorCode.INTERNAL_SERVER_ERROR, exception);
        }
    }

    @Override
    public void delete(String key) {
        deleteQuietly(directory.resolve(key));
    }

    @Override
    public String urlFor(String key) {
        return URL_PREFIX + key;
    }

    private void deleteQuietly(Path path) {
        try {
            Files.deleteIfExists(path);
        } catch (IOException exception) {
            log.warn("프로필 사진 파일 정리 실패: path={}", path, exception);
        }
    }

}
