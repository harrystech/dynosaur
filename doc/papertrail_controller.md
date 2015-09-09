# Papertrail Addon Autoscaling

Dynosaur can provision a higher class of service in Papertrail for those busy days.

<pre>
controller_plugins
  -
    name: papertrail
    type: Dynosaur::Controllers::PapertrailControllerPlugin
    min_resource_name: papertrail:liatorp
    max_resource_name: papertrail:galant
    input_plugins:
        -
            name: papertrail_input
            type: Dynosaur::Inputs::PapertrailInputPlugin
            max_percentage_threshold: 95
            papertrail_api_key: <%= ENV['PAPERTRAIL_API_KEY'] %>
</pre>

- `min_resource_name` (string): name of the minimum Papertrail addon level you want to scale down to.
- `max_resource_name` (string): name of the max papertrail addon level you want to scale up to.
