package kr.co.teeq.api.architecture;

import static org.assertj.core.api.Assertions.assertThat;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;
import java.util.stream.Collectors;
import com.tngtech.archunit.core.domain.JavaClass;
import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import org.junit.jupiter.api.Test;
import org.springframework.core.annotation.AnnotatedElementUtils;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

/**
 * 컨트롤러끼리 같은 HTTP 메서드와 경로를 중복 매핑하지 않는지 확인한다.
 * 컨트롤러 테스트가 슬라이스 단위라 두 컨트롤러가 함께 올라가는 상황을 보지 못하므로, 중복 매핑이 운영 기동에서야
 * {@code Ambiguous mapping}으로 드러나는 것을 빌드에서 막는다. 스프링 컨텍스트를 띄우지 않고 선언만 검사한다.
 */
class ControllerMappingUniquenessTest {

    private static final String BASE_PACKAGE = "kr.co.teeq.api";
    private static final String ANY_METHOD = "ANY";
    private static final String PATH_VARIABLE_PLACEHOLDER = "{}";

    @Test
    void controllerMappings_haveNoDuplicatedMethodAndPath() {
        Map<String, List<String>> handlersByMapping = collectHandlersByMapping();

        Map<String, List<String>> duplicated = handlersByMapping.entrySet().stream()
            .filter(entry -> entry.getValue().size() > 1)
            .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue, (first, second) -> first, TreeMap::new));

        assertThat(duplicated)
            .as("같은 HTTP 메서드와 경로를 둘 이상의 핸들러가 매핑하면 기동에 실패한다")
            .isEmpty();
    }

    private Map<String, List<String>> collectHandlersByMapping() {
        // 테스트 소스의 임시 컨트롤러는 운영 기동에 올라가지 않으므로 제외한다
        JavaClasses productionClasses = new ClassFileImporter()
            .withImportOption(new ImportOption.DoNotIncludeTests())
            .importPackages(BASE_PACKAGE);

        Map<String, List<String>> handlersByMapping = new TreeMap<>();
        for (JavaClass controllerClass : productionClasses) {
            if (!controllerClass.isMetaAnnotatedWith(Controller.class)) {
                continue;
            }
            Class<?> controllerType = controllerClass.reflect();
            RequestMapping classMapping =
                AnnotatedElementUtils.findMergedAnnotation(controllerType, RequestMapping.class);
            for (Method method : controllerType.getDeclaredMethods()) {
                RequestMapping methodMapping =
                    AnnotatedElementUtils.findMergedAnnotation(method, RequestMapping.class);
                if (methodMapping == null) {
                    continue;
                }
                for (String key : mappingKeys(classMapping, methodMapping)) {
                    handlersByMapping.computeIfAbsent(key, ignored -> new ArrayList<>())
                        .add(controllerType.getSimpleName() + "#" + method.getName());
                }
            }
        }
        return handlersByMapping;
    }

    private List<String> mappingKeys(RequestMapping classMapping, RequestMapping methodMapping) {
        Set<String> httpMethods = Arrays.stream(methodMapping.method())
            .map(RequestMethod::name)
            .collect(Collectors.toCollection(TreeSet::new));
        if (httpMethods.isEmpty()) {
            httpMethods.add(ANY_METHOD);
        }
        List<String> classPaths = pathsOf(classMapping);
        List<String> methodPaths = pathsOf(methodMapping);

        List<String> keys = new ArrayList<>();
        for (String httpMethod : httpMethods) {
            for (String classPath : classPaths) {
                for (String methodPath : methodPaths) {
                    keys.add(httpMethod + " " + normalize(classPath + methodPath));
                }
            }
        }
        return keys;
    }

    // 매핑에 경로가 없으면 빈 경로 하나로 취급해 조합이 사라지지 않게 한다
    private List<String> pathsOf(RequestMapping mapping) {
        if (mapping == null || mapping.path().length == 0) {
            return List.of("");
        }
        return Arrays.asList(mapping.path());
    }

    // 경로 변수 이름만 다른 매핑도 같은 경로로 본다
    private String normalize(String path) {
        return path.replaceAll("\\{[^/}]+}", PATH_VARIABLE_PLACEHOLDER);
    }

}
