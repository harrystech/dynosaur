# Rediscloud Addon Autoscaling

Dynosaur can autoscale your RedisCloud addons for those busy days. It can scale based on memory usage and/or number of connections, taking the maximum addon level. The data is fed from NewRelic.

<pre>
controller_plugins
    - name: redis
        type: Dynosaur::Controllers::RediscloudControllerPlugin
        min_resource_name: rediscloud:100
        max_resource_name: rediscloud:5000
        input_plugins:
            -
                name: redis_memory
                type: Dynosaur::Inputs::RediscloudMemoryUsageInputPlugin
                max_percentage_threshold: 90.0
                component_id: 1234567
                new_relic_api_key: <%= ENV['NEW_RELIC_API_KEY'] %>
            -
                name: redis_connections
                type:  Dynosaur::Inputs::RediscloudConnectionUsageInputPlugin
                max_percentage_threshold: 90.0
                component_id: 1234568
                new_relic_api_key: <%= ENV['NEW_RELIC_API_KEY'] %>
</pre>

- `min_resource_name` (string): name of the minimum addon level to scale down to
- `max_resource_name` (string): name of the max rediscloud addon level to scale up to
- `component_id` (int): ID of the Rediscloud instance (find via Rediscloud web interface)
-  `max_percentage_threshold` (float): Scale up when we hit this usage percentage in current addon level.
