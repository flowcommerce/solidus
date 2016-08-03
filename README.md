# flow_solidus_demo
Demo Solidus Store for Flow

## Using the API
You'll need an admin user account with an API token. All requests should include the header
`X-Spree-Token: [YOUR TOKEN]`

### Products
#### List products
`GET http://site.example.com/api/products`

#### Show product
`GET http://site.example.com/api/products/product_id_or_slug`

#### Create product (minimal required data)
`POST http://site.example.com/api/products
{
  "product": {
    "price": "10.99",
    "name": "Example Product",
    "shipping_category_id": "1"
  }
}
`
- Shipping categories are used to tag products that have particular shipping requirements e.g. "Flammable", "Oversized". In our demo store we initially have a single shipping category "Default" with ID 1.
- Shipping categories can also be referenced by name e.g. `"shipping_category": "Flammable"`. If no such category exists, it will be created.
- Note that with this minimal data, Solidus will assign the current time as the product's `available_on` date, so the product will immediately be visible on the front end.

#### Create product (maximal data with no variants)
`POST http://site.example.com/api/products
{
  "product": {
    "price": "10.99",
    "name": "Simple T-Shirt",
    "shipping_category_id": "1",
    "description": "Simple no-frills T-Shirt",
    "available_on": "2016-08-03T03:23:45.538Z",
    "meta_description": "Simple T-Shirt",
    "meta_keywords": "t-shirt, simple",
    "taxon_ids": "1,2,3",
    "sku": "STS001",
    "weight": "12.34",
    "height": "12.34",
    "depth": "12.34",
    "tax_category_id": "1",
  }
}
`
- The slug will be generated from the product name and SKU
- Tax categories are used similarly to shipping categories, to tag products with particular tax characteristics. In our demo store we initially have a single shipping category "Default" with ID 1.
- A `prototype_id` can be included to populate a pre-defined set of properties, options and taxons

#### Delete product
`DELETE http://site.example.com/api/products/product_id_or_slug`
