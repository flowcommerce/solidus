# Integration Solidus with Flow.io

## Setup:

1. `gem install 'flowcommerce'`

   - install custom flow libs for Spree::Variant, Spree::Order, Spree::User and other as FlowOrder

2. Install flow database migrations

  - DONE TODO: Add rake task named [`flow:migrate`](https://github.com/flowcommerce/solidus/blob/master/lib/tasks/flow.rake)

  * run rake task `rake flow:migrate`

  * or manually run migrations
    - https://github.com/flowcommerce/solidus/blob/master/db/migrate/20170302153604_add_flow_number_to_spree_order.rb
    - https://github.com/flowcommerce/solidus/blob/master/db/migrate/20170303102052_add_flow_data_to_spree_variants.rb
    - https://github.com/flowcommerce/solidus/blob/master/db/migrate/20170306223619_add_flow_data_to_spree_order.rb

3. Setup environment variables for your flow organization_id and flow API key

   - FLOW_TOKEN
   - FLOW_ORG
   - FLOW_BASE_COUNTRY
   - Setup api keys at: https://console.flow.io/:organization/organization/api-keys

4. Verify that connection is valid with tests by running
  * `rake flow:check`
  * `rspec`

5. rake flow:upload_catalog

   - DONE: TODO: Remove variant.flow_number - use variant.id directly
   - DONE: TODO: remove `.limit` incodes
   - DONE:? TODO: Move image_base to environment variable or remove
    flow_api_item is Spree::Variant method that can and should be replaced by clients.
    image_base is variabe present inside that method.

   - DONE TODO: add attributes to upload_catalog
       :attributes => {
         :weight =>
         :height =>
         :width =>
         :depth =>
         :is_master =>
         :product_id =>
         :tax_category =>
         :product_description =>
         :product_shipping_category =>
         :product_meta_title =>
         :product_meta_description =>
         :product_meta_keywords =>
         :product_slug =>
       }

6. Verify that your catalog is uploaded by visiting https://console.flow.io/:organization/catalog/items

In production system, schedule job to run rake:upload_catalog -
ideally picking up incremental changes so that job can be run
frequently

## Configure Flow

  1. Login to https://console.flow.io
  2. Create 1 or more experiences
  3. Define at least one tier per experience

## Add a flag to your UI

Flags are a common UI element used to highlight the currently selected
experience, and to allow users to change their country.

  1. When a user lands on the website, need to ensure there is a Flow
  session. we do this with a before filter in the application
  controller.

  2. Add UI to display the flag, and set a `flow_exp` query
  parameter to change


## Displaying local pricing

  DONE TODO: Remove rake  get_experiences
  DONE TODO: Rename precache_catalog_items => sync_localized_items
  DONE TODO: Remove args[:clean]

  DONE TODO: Fix this as item.number is now the variant.id
   - sku        = item.number.downcase
   - variant    = Spree::Variant.find sku.split('-').last.to_i

  DONE TODO:
    Fix: variant.import_flow_item - should be flow_import_item

  1. run rake flow:sync_localized_items

Other:
  * DONE: replace all calls in frontend templates from "link_to_cart" to "flow_link_to_cart"
  * DONE: replace all calls in frontend templates from "order.display_item_total.to_html" to "flow_cart_total"

