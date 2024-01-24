package org.keycloak.benchmark.crossdc;

import org.junit.jupiter.api.Test;
import org.keycloak.benchmark.crossdc.client.KeycloakClient;
import org.keycloak.benchmark.crossdc.util.HttpClientUtils;
import org.keycloak.benchmark.crossdc.util.KeycloakUtils;
import org.keycloak.common.util.Time;
import org.keycloak.representations.idm.ClientRepresentation;

import java.io.IOException;
import java.net.CookieManager;
import java.net.HttpCookie;
import java.net.URISyntaxException;
import java.net.http.HttpResponse;
import java.util.List;
import java.util.Map;
import java.util.Queue;
import java.util.Random;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.IntStream;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.keycloak.benchmark.crossdc.util.InfinispanUtils.SESSIONS;


public class LoginLogoutTest extends AbstractCrossDCTest {
    @Test
    public void loginLogoutTest() throws URISyntaxException, IOException, InterruptedException {
        //Login and exchange code in DC1
        String code = LOAD_BALANCER_KEYCLOAK.usernamePasswordLogin(REALM_NAME, USERNAME, MAIN_PASSWORD, CLIENTID);
        Map<String, Object> tokensMap = LOAD_BALANCER_KEYCLOAK.exchangeCode(REALM_NAME, CLIENTID, CLIENT_SECRET, 200, code);

        //Making sure the code cannot be reused in any of the DCs
        DC_2.kc().exchangeCode(REALM_NAME, CLIENTID, CLIENT_SECRET, 400, code, LOAD_BALANCER_KEYCLOAK.getRedirectUri(REALM_NAME));
        DC_1.kc().exchangeCode(REALM_NAME, CLIENTID, CLIENT_SECRET, 400, code, LOAD_BALANCER_KEYCLOAK.getRedirectUri(REALM_NAME));

        //Verify if the user session UUID in code, we fetched from Keycloak exists in session cache key of external ISPN in DC1
        String sessionId = code.split("[.]")[1];
        assertTrue(DC_1.ispn().cache(SESSIONS).contains(sessionId),
                () -> "External session cache in DC1 should contain session id [" + sessionId + "] but contains " + DC_1.ispn().cache(SESSIONS).keys());

        //Verify session cache size in external ISPN DC1
        //Contains 2 sessions because admin client creates one and the test the other
        assertEquals(1, DC_1.ispn().cache(SESSIONS).size(),
                () -> "External session cache in DC1 should contain 2 sessions " + sessionId + " but contains " + DC_1.ispn().cache(SESSIONS).keys());

        //Verify session cache size in embedded ISPN DC1
        //Contains 2 sessions because admin client creates one and the test the other
        assertEquals(1, DC_1.kc().embeddedIspn().cache(SESSIONS).size());

        //Verify if the user session UUID in code, we fetched from Keycloak exists in session cache key of external ISPN in DC2
        assertTrue(DC_2.ispn().cache(SESSIONS).contains(sessionId),
                () -> "External session cache in DC2 should contains session id [" + sessionId + "] but contains " + DC_2.ispn().cache(SESSIONS).keys());
        //Verify session cache size in external ISPN DC2
        assertEquals(1, DC_2.ispn().cache(SESSIONS).size());
        //Verify session cache size in embedded ISPN DC2
        assertEquals(1, DC_2.kc().embeddedIspn().cache(SESSIONS).size());

        //Logout from DC1
        LOAD_BALANCER_KEYCLOAK.logout(REALM_NAME, (String) tokensMap.get("id_token"), CLIENTID);

        //Verify session cache size in external ISPN DC1 post logout
        assertEquals(0, DC_1.ispn().cache(SESSIONS).size());
        //Verify session cache size in embedded ISPN DC1 post logout
        assertEquals(0, DC_1.kc().embeddedIspn().cache(SESSIONS).size());

        //Verify session cache size in external ISPN  DC2 post logout
        assertEquals(0, DC_2.ispn().cache(SESSIONS).size());
        //Verify session cache size in embedded ISPN DC2
        assertEquals(0, DC_2.kc().embeddedIspn().cache(SESSIONS).size());
    }

    @Test
    public void testConcurrentClientSessionAddition() throws IOException, URISyntaxException, InterruptedException {
        // Create clients in DC1
        for (int i = 0; i < 10; i++) {
            // Create client
            ClientRepresentation client = new ClientRepresentation();
            client.setEnabled(Boolean.TRUE);
            client.setClientId("client-" + i);
            client.setSecret(CLIENT_SECRET);
            client.setRedirectUris(List.of("*"));
            client.setDirectAccessGrantsEnabled(true);
            client.setProtocol("openid-connect");
            DC_1.kc().adminClient().realm(REALM_NAME).clients().create(client);
        }

        // Create user session with the main client in DC1
        String code = LOAD_BALANCER_KEYCLOAK.usernamePasswordLogin(REALM_NAME, USERNAME, MAIN_PASSWORD, CLIENTID);
        String userSessionId = code.split("[.]")[1];

        Map<String, Object> tokensMap = LOAD_BALANCER_KEYCLOAK.exchangeCode(REALM_NAME, CLIENTID, CLIENT_SECRET, 200, code);

        // Create cookies also for the other DCs URLS so we can login to the same user session from DC_1 and DC_2 Urls
        CookieManager mockCookieManager = HttpClientUtils.MOCK_COOKIE_MANAGER;
        List<HttpCookie> copy = List.copyOf(mockCookieManager.getCookieStore().getCookies());
        copy.forEach(cookie -> {
            if (cookie.getDomain().startsWith("client.")) {
                mockCookieManager.getCookieStore().add(null, createCookie(cookie, DC_1.kc().getKeycloakServerUrl().substring("https://".length())));
                mockCookieManager.getCookieStore().add(null, createCookie(cookie, DC_2.kc().getKeycloakServerUrl().substring("https://".length())));
            }
        });

        AtomicInteger counter = new AtomicInteger(0);
        AtomicInteger failureCounter = new AtomicInteger(0);
        Queue<Long> times = new ConcurrentLinkedQueue<>();

        Random rand = new Random();
        System.out.println("Starting with the concurrent requests");

        try {
            // Create new client session with each client in DC1
            IntStream.range(0, 3).parallel().forEach(i -> {
                // Create new client session with each client in DC1
                HttpResponse<String> stringHttpResponse = null;
                KeycloakClient keycloakClient = rand.nextBoolean() ? DC_1.kc() : DC_2.kc();
                String clientId = "client-" + counter.getAndIncrement() % 10;
                long start = Time.currentTimeMillis();
                try {
                    stringHttpResponse = keycloakClient.openLoginForm(REALM_NAME, clientId);

                    String code2 = KeycloakUtils.extractCodeFromResponse(stringHttpResponse);
                    String userSessionId2 = code2.split("[.]")[1];
                    assertEquals(userSessionId, userSessionId2);
                    Map<String, Object> stringObjectMap = keycloakClient.exchangeCode(REALM_NAME, clientId, CLIENT_SECRET, 200, code2);
                    System.out.println(((keycloakClient == DC_1.kc()) ? "dc1 - " : "dc2 - ") + stringObjectMap.get("access_token"));
                } catch (Throwable e) {
                    failureCounter.incrementAndGet();
                    System.out.println("---------------------------------------------------------------");
                    e.printStackTrace();
                    if (stringHttpResponse != null) {
                        System.out.println(stringHttpResponse.body());
                    }
                    System.out.println("---------------------------------------------------------------");
                } finally {
                    times.add(Time.currentTimeMillis() - start);
                }
            });
        } finally {
            times.forEach(System.out::println);
            System.out.println("Failure count: " + failureCounter.get());
        }

        assertEquals(0, failureCounter.get());
        Thread.sleep(1000);
    }

    private HttpCookie createCookie(HttpCookie oldCookie, String domain) {
        HttpCookie cookie = new HttpCookie(oldCookie.getName(), oldCookie.getValue());
        cookie.setDomain(domain);
        cookie.setPath(oldCookie.getPath());
        cookie.setVersion(oldCookie.getVersion());
        cookie.setSecure(oldCookie.getSecure());
        cookie.setHttpOnly(oldCookie.isHttpOnly());
        return cookie;
    }
}
