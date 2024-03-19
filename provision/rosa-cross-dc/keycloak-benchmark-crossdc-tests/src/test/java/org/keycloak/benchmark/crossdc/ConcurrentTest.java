package org.keycloak.benchmark.crossdc;

import org.junit.jupiter.api.Test;
import org.keycloak.benchmark.crossdc.client.DatacenterInfo;
import org.keycloak.benchmark.crossdc.util.InfinispanUtils;

import java.io.IOException;
import java.net.URISyntaxException;
import java.util.HashSet;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.keycloak.benchmark.crossdc.AbstractCrossDCTest.HTTP_CLIENT;
import static org.keycloak.benchmark.crossdc.AbstractCrossDCTest.MAIN_PASSWORD;

public class ConcurrentTest {

    protected static final DatacenterInfo DC_1, DC_2;

    static {
        assertNotNull(MAIN_PASSWORD, "Main password must be set");
        DC_1 = new DatacenterInfo(HTTP_CLIENT, System.getProperty("keycloak.dc1.url"), System.getProperty("infinispan.dc1.url"));
        DC_2 = new DatacenterInfo(HTTP_CLIENT, System.getProperty("keycloak.dc2.url"), System.getProperty("infinispan.dc2.url"));
    }

    private static <T> Set<T>
    findDuplicateInStream(Stream<T> stream)
    {

        // Set to store the duplicate elements
        Set<T> items = new HashSet<>();

        // Return the set of duplicate elements
        return stream

                // Set.add() returns false
                // if the element was
                // already present in the set.
                // Hence filter such elements
                .filter(n -> !items.add(n))

                // Collect duplicate elements
                // in the set
                .collect(Collectors.toSet());
    }

    @Test
    void testConcurrent() {
        Stream<Integer> updatedVersion = Stream.of(DC_1, DC_2).parallel()
                .flatMap((dc) -> {
                    Set<Integer> result;
                    try {
                        result = dc.kc().embeddedIspn().cache(InfinispanUtils.SESSIONS).startConcurrentUpdates(100);
                    } catch (InterruptedException | IOException | URISyntaxException var3) {
                        throw new RuntimeException(var3);
                    }

                    return result.stream();
                });

        Set<Integer> duplicates = findDuplicateInStream(updatedVersion);
        assertTrue(duplicates.isEmpty(), "There are duplicates in the updated version of the session cache. Duplicates: " + duplicates);
    }
}
