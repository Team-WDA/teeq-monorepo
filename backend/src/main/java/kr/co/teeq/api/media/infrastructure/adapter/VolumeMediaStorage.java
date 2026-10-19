package kr.co.teeq.api.media.infrastructure.adapter;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.media.core.constant.MediaCategory;
import kr.co.teeq.api.media.core.port.MediaStoragePort;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

/**
 * 컨테이너에 마운트된 볼륨 디렉터리에 미디어를 종류별 하위 디렉터리로 저장한다.
 * 웹 서버가 같은 디렉터리를 {@link #PUBLIC_PATH_PREFIX} 경로로 서빙한다.
 */
@Slf4j
@Component
public class VolumeMediaStorage implements MediaStoragePort {

    private static final String BASE_DIRECTORY = "/mnt/teeq";
    private static final String PUBLIC_PATH_PREFIX = "/media/";
    private static final String TEMPORARY_SUFFIX = ".tmp";

    private final Path baseDirectory;

    public VolumeMediaStorage() {
        this(Path.of(BASE_DIRECTORY));
    }

    VolumeMediaStorage(Path baseDirectory) {
        this.baseDirectory = baseDirectory;
    }

    // 임시 이름으로 쓴 뒤 옮겨, 쓰는 도중의 파일이 서빙되거나 중간에 끊긴 파일이 남지 않게 한다
    @Override
    public void store(MediaCategory category, String key, byte[] content) {
        Path directory = baseDirectory.resolve(category.directoryName());
        Path temporary = directory.resolve(key + TEMPORARY_SUFFIX);
        try {
            Files.createDirectories(directory);
            Files.write(temporary, content);
            Files.move(temporary, directory.resolve(key), StandardCopyOption.ATOMIC_MOVE);
        } catch (IOException exception) {
            deleteQuietly(temporary);
            log.error("미디어 파일 저장 실패: category={}, key={}", category, key, exception);
            throw new CustomException(ErrorCode.INTERNAL_SERVER_ERROR, exception);
        }
    }

    @Override
    public void delete(MediaCategory category, String key) {
        deleteQuietly(baseDirectory.resolve(category.directoryName()).resolve(key));
    }

    @Override
    public String publicPath(MediaCategory category, String key) {
        return PUBLIC_PATH_PREFIX + category.directoryName() + "/" + key;
    }

    private void deleteQuietly(Path path) {
        try {
            Files.deleteIfExists(path);
        } catch (IOException exception) {
            log.warn("미디어 파일 정리 실패: path={}", path, exception);
        }
    }

}
