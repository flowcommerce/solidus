# Integration Solidus with Flow.io - notes

Integration is easy :)

## basic steps

1. ensure all your products in spree have valid sku / number / unique id
1. in flow
  * create desired experiences
  * create at least one distribution method in each experience (contact flow)
1. upload local spreee catalog to flow (rake task)
1. Get localized catalog items
1. set up web hooks to point to https://YOUR_SITE/flow-event-target
1. define distribution centers for expericences
1. in spree allow global delivery to all products, because delivery is handled by flow now
1. ...


## Basic requirements

* Ruby 2.2 + - 2.4 recommended
* Rails 5.0 +
* Solidus/Spree v2.1 + (for Rails 5)
* Database


### Install gem

* Migrate database and create cache tables in your shop
* replace all calls in frontend templates from "link_to_cart" to "flow_link_to_cart"
* replace all calls in frontend templates from "order.display_item_total.to_html" to "flow_cart_total"


### flow.io requirements

* create catalog
* create experiences in flow.io
* create at least one distribution center in every experience
* defined flow ENV variables, FLOW_API_KEY and FLOW_ORG


### Sync your catalog to and from Flow.io

Products in solidus are automatically refreshed from flow,
but it is good practise to refresh all products at least once a week.

Reason for that is that products in cache are refreshed only when they are in cart.
If you have products that where not in a cart for long time, it is possible that
their price in listing will not match one in cart.

Of course, once product is in cart we will get fresh prices and show only fresh data.


### Methods to manualy upload and download products from flow

* "rake flow:upload_catalog" will upload local catalog to flow
* "rake flow:get_catalog_items" will localy cache all flow catalog items

## Create at least one shipping method

* /admin/shipping_methods
* if you do not, you will not be able to proceed to step 2 in Checkout process


## Centers

Docs state that "Organizations are required to set up at least one center in order to generate quotes."
`https://docs.flow.io/#/module/logistics/resource/centers`

To Create a center;
`https://docs.flow.io/#/module/logistics/resource/centers`

Based on docs for Order Estimates:
`https://docs.flow.io/#/module/localization/resource/order-estimates`

code should determine the geolocation (i.e. using IP or explicit country), then we can request the estimate:
```curl -X POST -H "Content-Type: application/json" -H "Authorization: Basic <encrypted_api_key>" -d '{
    "items": [
        {
            "number": "GILT-M-3587157",
            "quantity": 2,
            "center": ENV['FLOW_ORG']
        }
    ]
}' "https://api.flow.io/solidus-demo-sandbox/order-estimates?experience=canada"```

### New client

we have to set up a `ratecard` - its an internal between flow and the carrier (i.e. DHL) that specifies shipping costs for a particular option.
Since this is always a manual step, since its based on client contract - we have a way to create “mock” ratecards in demo orgs right now at:

https://github.com/flowcommerce/misc/tree/master/ratecards

Run `ruby card.rb $FLOW_ORG` and it will create all the ratecards for org

[3:35]
then, I was able to go into your shipping tiers, in console at set one like:
https://console.flow.io/solidus-demo-sandbox/experience/canada/logistics


### Order and checkout flow

This is tmp reminder no how to organize checkout process

* localize all the prices all the time
* get real time data from flow_api, once in cart
* if flow realtime data is not matching local cache, hot update local cache

this all happens in FlowHelper.flow_line_item_price