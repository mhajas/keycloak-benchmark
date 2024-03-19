package org.keycloak.benchmark.crossdc.client;

import java.io.IOException;
import java.net.URISyntaxException;
import java.util.Set;

public interface InfinispanClient {
    interface Cache {
        long size();
        void clear();
        boolean contains(String key);

        Set<String> keys();

        default Set<Integer> startConcurrentUpdates(int iterations) throws URISyntaxException, IOException, InterruptedException {
            throw new UnsupportedOperationException();
        }
    }


    public Cache cache(String name);
}
