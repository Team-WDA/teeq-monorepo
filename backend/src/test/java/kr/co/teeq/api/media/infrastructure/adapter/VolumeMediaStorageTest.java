package kr.co.teeq.api.media.infrastructure.adapter;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.stream.Stream;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.media.core.constant.MediaCategory;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

class VolumeMediaStorageTest {

    private static final MediaCategory CATEGORY = MediaCategory.PROFILE_IMAGE;

    @TempDir
    Path baseDirectory;

    private VolumeMediaStorage storage;

    @BeforeEach
    void setUp() {
        storage = new VolumeMediaStorage(baseDirectory);
    }

    @Test
    void store_writesFileUnderCategoryDirectory() throws IOException {
        byte[] content = {1, 2, 3};

        storage.store(CATEGORY, "abc.jpg", content);

        assertThat(Files.readAllBytes(baseDirectory.resolve("profile-images").resolve("abc.jpg")))
            .isEqualTo(content);
    }

    @Test
    void store_leavesNoTemporaryFile() throws IOException {
        storage.store(CATEGORY, "abc.jpg", new byte[] {1});

        try (Stream<Path> files = Files.list(baseDirectory.resolve("profile-images"))) {
            assertThat(files.map(path -> path.getFileName().toString())).containsExactly("abc.jpg");
        }
    }

    @Test
    void delete_removesFile() {
        storage.store(CATEGORY, "abc.jpg", new byte[] {1});

        storage.delete(CATEGORY, "abc.jpg");

        assertThat(baseDirectory.resolve("profile-images").resolve("abc.jpg")).doesNotExist();
    }

    @Test
    void delete_missingFile_doesNotThrow() {
        assertThatCode(() -> storage.delete(CATEGORY, "missing.jpg")).doesNotThrowAnyException();
    }

    @Test
    void publicPath_returnsMediaPrefixedPath() {
        assertThat(storage.publicPath(CATEGORY, "abc.jpg")).isEqualTo("/media/profile-images/abc.jpg");
    }

    @Test
    void store_moveFails_throwsInternalServerErrorAndCleansTemporaryFile() throws IOException {
        Path categoryDirectory = baseDirectory.resolve("profile-images");
        Files.createDirectories(categoryDirectory.resolve("abc.jpg"));
        Files.writeString(categoryDirectory.resolve("abc.jpg").resolve("occupied"), "x");

        assertThatThrownBy(() -> storage.store(CATEGORY, "abc.jpg", new byte[] {1}))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INTERNAL_SERVER_ERROR));
        assertThat(categoryDirectory.resolve("abc.jpg.tmp")).doesNotExist();
    }

    @Test
    void store_cannotCreateDirectory_throwsInternalServerError() throws IOException {
        Path regularFile = Files.createFile(baseDirectory.resolve("not-a-directory"));
        VolumeMediaStorage brokenStorage = new VolumeMediaStorage(regularFile);

        assertThatThrownBy(() -> brokenStorage.store(CATEGORY, "abc.jpg", new byte[] {1}))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.INTERNAL_SERVER_ERROR));
    }

}
