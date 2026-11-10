package kr.co.teeq.api.call.infrastructure.adapter;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.header;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.method;
import static org.springframework.test.web.client.match.MockRestRequestMatchers.requestTo;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withServerError;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withStatus;
import static org.springframework.test.web.client.response.MockRestResponseCreators.withSuccess;

import java.math.BigDecimal;
import java.time.LocalDate;
import kr.co.teeq.api.call.core.constant.CallUsageUnit;
import kr.co.teeq.api.call.core.port.AiCallMetrics;
import kr.co.teeq.api.common.core.exception.CustomException;
import kr.co.teeq.api.common.core.exception.ErrorCode;
import kr.co.teeq.api.common.infrastructure.properties.AiServerProperties;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.client.MockRestServiceServer;
import org.springframework.test.web.client.ResponseCreator;
import org.springframework.web.client.RestClient;

class AiServerCallMetricsAdapterTest {

    private static final String BASE_URL = "http://ai-server.test";
    private static final String HEADER_NAME = "X-Teeq-Server-Key";
    private static final String HEADER_VALUE = "dummy-server-key";
    private static final String FULL_RESPONSE = """
        {"unit":"DAY","from":"2026-10-20","to":null,
         "periods":[{"periodStart":"2026-11-02","callCount":4,"measuredCallCount":4,"turnCount":96,
          "p50LatencyMillis":810,"p95LatencyMillis":1740,"estimatedCostUsd":0.31}],
         "totals":{"callCount":128,"measuredCallCount":121,"turnCount":2304,
          "p50LatencyMillis":790,"p95LatencyMillis":1910,"estimatedCostUsd":5.37}}
        """;

    private MockRestServiceServer server;
    private AiServerCallMetricsAdapter adapter;

    @BeforeEach
    void setUp() {
        RestClient.Builder builder = RestClient.builder().baseUrl(BASE_URL);
        server = MockRestServiceServer.bindTo(builder).build();
        AiServerProperties properties = new AiServerProperties(BASE_URL, HEADER_NAME, HEADER_VALUE);
        adapter = new AiServerCallMetricsAdapter(builder.build(), properties);
    }

    @Test
    void 전체_기간이면_from_to_없이_unit만_보낸다() {
        server.expect(requestTo(BASE_URL + "/metrics/calls?unit=DAY"))
            .andExpect(method(HttpMethod.GET))
            .andRespond(withSuccess(FULL_RESPONSE, MediaType.APPLICATION_JSON));

        adapter.find(null, null, CallUsageUnit.DAY);

        server.verify();
    }

    @Test
    void 기간과_단위를_쿼리로_보낸다() {
        server.expect(requestTo(BASE_URL + "/metrics/calls?from=2026-10-20&to=2026-11-10&unit=MONTH"))
            .andExpect(method(HttpMethod.GET))
            .andExpect(header(HEADER_NAME, HEADER_VALUE))
            .andRespond(withSuccess(FULL_RESPONSE, MediaType.APPLICATION_JSON));

        adapter.find(LocalDate.of(2026, 10, 20), LocalDate.of(2026, 11, 10), CallUsageUnit.MONTH);

        server.verify();
    }

    @Test
    void 응답을_기간과_합계로_변환한다() {
        server.expect(requestTo(BASE_URL + "/metrics/calls?unit=DAY"))
            .andRespond(withSuccess(FULL_RESPONSE, MediaType.APPLICATION_JSON));

        AiCallMetrics metrics = adapter.find(null, null, CallUsageUnit.DAY);

        assertThat(metrics.periods()).hasSize(1);
        assertThat(metrics.periods().get(0).periodStart()).isEqualTo(LocalDate.of(2026, 11, 2));
        assertThat(metrics.periods().get(0).callCount()).isEqualTo(4);
        assertThat(metrics.periods().get(0).measuredCallCount()).isEqualTo(4);
        assertThat(metrics.periods().get(0).turnCount()).isEqualTo(96);
        assertThat(metrics.periods().get(0).p50LatencyMillis()).isEqualTo(810);
        assertThat(metrics.periods().get(0).p95LatencyMillis()).isEqualTo(1740);
        assertThat(metrics.periods().get(0).estimatedCostUsd()).isEqualTo(new BigDecimal("0.31"));
        assertThat(metrics.totals().callCount()).isEqualTo(128);
        assertThat(metrics.totals().measuredCallCount()).isEqualTo(121);
        assertThat(metrics.totals().turnCount()).isEqualTo(2304);
        assertThat(metrics.totals().p50LatencyMillis()).isEqualTo(790);
        assertThat(metrics.totals().p95LatencyMillis()).isEqualTo(1910);
        assertThat(metrics.totals().estimatedCostUsd()).isEqualTo(new BigDecimal("5.37"));
    }

    @Test
    void 지연이_null이면_null로_읽는다() {
        server.expect(requestTo(BASE_URL + "/metrics/calls?unit=DAY"))
            .andRespond(withSuccess("""
                {"periods":[{"periodStart":"2026-11-02","callCount":1,"measuredCallCount":0,"turnCount":0,
                  "p50LatencyMillis":null,"p95LatencyMillis":null,"estimatedCostUsd":0.0}],
                 "totals":{"callCount":1,"measuredCallCount":0,"turnCount":0,
                  "p50LatencyMillis":null,"p95LatencyMillis":null,"estimatedCostUsd":0.0}}
                """, MediaType.APPLICATION_JSON));

        AiCallMetrics metrics = adapter.find(null, null, CallUsageUnit.DAY);

        assertThat(metrics.periods().get(0).p50LatencyMillis()).isNull();
        assertThat(metrics.periods().get(0).p95LatencyMillis()).isNull();
        assertThat(metrics.totals().p50LatencyMillis()).isNull();
        assertThat(metrics.totals().p95LatencyMillis()).isNull();
    }

    @Test
    void 오류_응답과_이상한_응답은_AI_SERVER_UNAVAILABLE이다() {
        assertUnavailable(withServerError());
        assertUnavailable(withStatus(HttpStatus.NOT_FOUND));
        assertUnavailable(withStatus(HttpStatus.UNAUTHORIZED));
        assertUnavailable(withSuccess());
        assertUnavailable(withSuccess("""
            {"periods":[]}
            """, MediaType.APPLICATION_JSON));
        assertUnavailable(withSuccess("""
            {"totals":{"callCount":0,"measuredCallCount":0,"turnCount":0,"estimatedCostUsd":0.0}}
            """, MediaType.APPLICATION_JSON));
        assertUnavailable(withSuccess("""
            {"periods":[{"periodStart":"not-a-date","callCount":1,"measuredCallCount":1,"turnCount":1,
              "estimatedCostUsd":0.0}],
             "totals":{"callCount":1,"measuredCallCount":1,"turnCount":1,"estimatedCostUsd":0.0}}
            """, MediaType.APPLICATION_JSON));
    }

    @Test
    void 필수_숫자_필드가_없거나_숫자가_아니면_AI_SERVER_UNAVAILABLE이다() {
        String validTotals = "{\"callCount\":1,\"measuredCallCount\":1,\"turnCount\":1,\"estimatedCostUsd\":0.1}";
        String validPeriod = "{\"periodStart\":\"2026-11-02\",\"callCount\":1,\"measuredCallCount\":1,"
            + "\"turnCount\":1,\"estimatedCostUsd\":0.1}";
        String periodWithoutTurnCount = validPeriod.replace("\"turnCount\":1,", "");
        String periodWithoutCost = validPeriod.replace(",\"estimatedCostUsd\":0.1", "");
        String totalsWithoutTurnCount = validTotals.replace("\"turnCount\":1,", "");
        String totalsWithoutCost = validTotals.replace(",\"estimatedCostUsd\":0.1", "");
        String periodWithStringCount = validPeriod.replace("\"callCount\":1", "\"callCount\":\"4\"");
        String totalsWithStringCount = validTotals.replace("\"callCount\":1", "\"callCount\":\"4\"");

        assertUnavailable(metricsBody(periodWithoutTurnCount, validTotals));
        assertUnavailable(metricsBody(periodWithoutCost, validTotals));
        assertUnavailable(metricsBody(validPeriod, totalsWithoutTurnCount));
        assertUnavailable(metricsBody(validPeriod, totalsWithoutCost));
        assertUnavailable(metricsBody(periodWithStringCount, validTotals));
        assertUnavailable(metricsBody(validPeriod, totalsWithStringCount));
    }

    private ResponseCreator metricsBody(String period, String totals) {
        return withSuccess("{\"periods\":[" + period + "],\"totals\":" + totals + "}",
            MediaType.APPLICATION_JSON);
    }

    private void assertUnavailable(ResponseCreator response) {
        server.reset();
        server.expect(requestTo(BASE_URL + "/metrics/calls?unit=DAY")).andRespond(response);

        assertThatThrownBy(() -> adapter.find(null, null, CallUsageUnit.DAY))
            .isInstanceOfSatisfying(CustomException.class,
                exception -> assertThat(exception.getErrorCode()).isEqualTo(ErrorCode.AI_SERVER_UNAVAILABLE));
    }

}
