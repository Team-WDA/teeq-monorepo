package kr.teeq.api.member.core.port;

// 프로필 사진 파일 저장소 port. 저장소(볼륨, S3 등)를 바꿔도 서비스가 영향받지 않도록 둔다
public interface ProfileImageStoragePort {

    void store(String key, byte[] content);

    // DB 저장에 실패했을 때 방금 쓴 파일을 정리하는 용도. 정리 실패는 호출한 쪽으로 전파하지 않는다
    void delete(String key);

    // 클라이언트가 사진을 요청할 URL. 저장 키로부터 계산하며 DB에는 저장하지 않는다
    String urlFor(String key);

}
