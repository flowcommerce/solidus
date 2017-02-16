# Integration Solidus with Flow.io - notes

Integration is "hard" because we are not converting all values in one currency to another.


## Basic requirements

* Ruby 2.2 +
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


### ...