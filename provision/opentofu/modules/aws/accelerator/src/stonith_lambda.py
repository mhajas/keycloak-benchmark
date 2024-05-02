import boto3
import jmespath
import json


def handle_site_offline(labels):
    aClient = boto3.client('globalaccelerator', region_name='us-west-2')

    accelerator = jmespath.search("Accelerators[?DnsName=='%s']" % labels['accelerator'], aClient.list_accelerators())
    if not accelerator:
        raise Exception("Unable to find Global Accelerator with DNS '%s'" % labels['accelerator'])

    acceleratorArn = accelerator[0]['AcceleratorArn']
    listenerArn = aClient.list_listeners(AcceleratorArn=acceleratorArn)['Listeners'][0]['ListenerArn']

    endpointGroup = aClient.list_endpoint_groups(ListenerArn=listenerArn)['EndpointGroups'][0]
    endpoints = endpointGroup['EndpointDescriptions']

    # Only update accelerator endpoints if two entries exist
    if len(endpoints) > 1:
        offlineSite = labels['site']
        endpoints = [e for e in endpoints if not endpoint_belongs_to_site(e, offlineSite)]
        del endpoints[0]['HealthState']
        aClient.update_endpoint_group(
            EndpointGroupArn=endpointGroup['EndpointGroupArn'],
            EndpointConfigurations=endpoints
        )


def endpoint_belongs_to_site(endpoint, site):
    lbArn = endpoint['EndpointId']
    region = lbArn.split(":")[3]
    client = boto3.client('elbv2', region_name=region)
    tags = client.describe_tags(ResourceArns=[lbArn])['TagDescriptions'][0]['Tags']
    for tag in tags:
        if tag['Key'] == 'site':
            return tag['Value'] == site
    return false


def handler(event, context):
    # TODO add basic token based authentication
    # If request doesn't contain expected token than reject
    print(json.dumps(event, indent=4))

    body = event.get('body')
    if body is None:
        raise Exception("Empty request body")

    body = json.loads(body)
    print(json.dumps(body, indent=4))
    for alert in body['alerts']:
        labels = alert['labels']
        if labels['alertname'] == "SiteOffline":
            handle_site_offline(labels)

    res = {
        "statusCode": 200,
        "headers": {
            "Content-Type": "*/*"
        },
        "body": "Hello World!"
    }
    return res
