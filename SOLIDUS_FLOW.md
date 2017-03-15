# Integration Solidus with Flow.io

## Setup:

1. Install flow database migrations

   - https://github.com/flowcommerce/solidus/blob/master/db/migrate/20170302153604_add_flow_number_to_spree_order.rb
   - https://github.com/flowcommerce/solidus/blob/master/db/migrate/20170303102052_add_flow_cache_to_spree_variants.rb
   - https://github.com/flowcommerce/solidus/blob/master/db/migrate/20170306223619_add_flow_cache_to_spree_order.rb

   - TODO: Add rake task named [`flow:migrate`](https://github.com/flowcommerce/solidus/blob/master/lib/tasks/flow.rake)

2. Setup environment variables for your flow organization_id and flow API key

   - FLOW_TOKEN=xxx

   - Setup api keys at: https://console.flow.io/:organization/organization/api-keys

3. `gem install 'flowcommerce'`

4. Verify that connection is valid with tests by running `rspec`

5. rake flow:upload_catalog

   - TODO: Remove variant.flow_number - use variant.id directly
   - TODO: remove `.limit` incodes
   - TODO: Move image_base to environment variable or remove
   - TODO: https://github.com/flowcommerce/solidus/blob/master/lib/tasks/flow.rake#L20
   - TODO:
      - REMOVE 'force'

   - TODO: add attributes to upload_catalog
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

## Add a flag to your UI

Flags are a common UI element used to highlight the currently selected
experience, and to allow users to change their country.

  1. When a user lands on the website, need to ensure there is a Flow
  session. we do this with a before filter in the application
  controller.

    -- TODO fix code :)

  2. Add UI to display the flag, and set a `flow_country` query
  parameter to change

    https://github.com/flowcommerce/solidus/blob/master/app/views/spree/shared/_nav_bar.html.erb

## Displaying local pricing

  TODO: Remove rake  get_experiences
  TODO: Rename precache_catalog_items => sync_localized_items
  TODO: Remove args[:clean]

  TODO: Fix this as item.number is now the variant.id
   - sku        = item.number.downcase
   - variant    = Spree::Variant.find sku.split('-').last.to_i

  TODO:
    Fix: variant.import_flow_item - should be flow_import_item

  1. run rake flow:sync_localized_items


Other:
  * replace all calls in frontend templates from "link_to_cart" to "flow_link_to_cart"
  * replace all calls in frontend templates from "order.display_item_total.to_html" to "flow_cart_total"

## Create at least one shipping method

  * /admin/shipping_methods
  * if you do not, you will not be able to proceed to step 2 in Checkout process