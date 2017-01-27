# Flow Fashion
An example Solidus website for Flow.io to demonstrate to clients.

https://www.shopflowfashion.com/

## Dev Set-up
How to set up a dev environment for this project:

1. Clone the project
2. Create a .env file in root and include keys
   - RACK_ENV=development
   - DB_URL='postgres://localhost/flow_solidus_demo_development' file and place it in config/ (You can probably just copy the `config/database.sample.yml` sample file.)
   - SECRET_TOKEN='big-hash'
   - SECRET_KEY_BASE='other-big-hash'

   bash one liner to generate big hash
   ruby -e 'require "securerandom"; puts SecureRandom.hex(64)'
3. Run `bundle install` to grab the gems.
4. Run `bundle exec rails g spree:install` to set up seed and sample data
5. Log in to /admin with the default admin account. By default, user is `spree@example.com` and password `spree123`.

## Working Protocols
### Branches
* The `master` branch contains the state of the site on the production server
* The `staging` branch contains the state of the site on the staging server
* All other branches should start with `fix/` or `feature/` and a number that matches a corresponding open issue on Codebase or Github

### Code Standards
#### Ruby
In general, try and follow the guidelines in the [Ruby Style Guide](https://github.com/bbatsov/ruby-style-guide).
* Soft tabs, two spaces.
* Use ruby 1.9 style hash syntax. `attr: value` not `:attr => value`
* Use spree subdirectories (`app/controllers/spree`, `app/models/spree` etc.) for frontend overrides
* Use Deface to insert new admin view code.

## Using the Solidus API
You'll need an admin user account with an API token. All requests should include the header
`X-Spree-Token: [YOUR TOKEN]`

Find your token by running `rails console` and then query for it:

```ruby
Spree::User.find_by_email("admin@example.com").spree_api_key
```

## Customizeing frontend templates
find the location of solidus gems
```bash
bundle show solidus
```

frontend is here
```bash
bundle show solidus_frontend

subl `bundle show solidus_frontend`
```

then go to app/views/spree and copy them to local app/views/spress. names have to match
or
https://github.com/solidusio/solidus/tree/master/frontend/app/views/spree

### Products
#### List products

```bash
curl \
-H "X-Spree-Token: YOUR_TOKEN" \
http://localhost:3000/api/products
```

#### Show product

```bash
curl \
-H "X-Spree-Token: YOUR_TOKEN" \
http://localhost:3000/api/products/PRODUCT_ID_OR_SLUG
```

#### Create product (minimal required data)

```bash
curl \
-H "Content-Type: application/json" \
-H "X-Spree-Token: YOUR_TOKEN" \
-X POST \
-d '
{
  "product": {
    "price": "10.99",
    "name": "Example Product",
    "shipping_category_id": "1"
  }
}' http://localhost:3000/api/products
```

- Shipping categories are used to tag products that have particular shipping requirements e.g. "Flammable", "Oversized". In our demo store we initially have a single shipping category "Default" with ID 1.
- Shipping categories can also be referenced by name e.g. `"shipping_category": "Flammable"`. If no such category exists, it will be created.
- Note that with this minimal data, Solidus will assign the current time as the product's `available_on` date, so the product will immediately be visible on the front end.

#### Create product (maximal data with no variants)
```bash
curl \
-H "Content-Type: application/json" \
-H "X-Spree-Token: YOUR_TOKEN" \
-X POST \
-d '
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
    "tax_category_id": "1"
  }
}' http://localhost:3000/api/products
```

- The slug will be generated from the product name and SKU
- Taxons need to exist with the specified ids
- Tax categories are used similarly to shipping categories, to tag products with particular tax characteristics. In our demo store we initially have a single shipping category "Default" with ID 1.
- A `prototype_id` can be included to populate a pre-defined set of properties, options and taxons

#### Delete product
```bash
curl \
-H "X-Spree-Token: YOUR_TOKEN" \
-X DELETE \
http://localhost:3000/api/products/PRODUCT_ID_OR_SLUG
```

## How to...
## Run the test suite
From the command line:
```bash
bundle exec rspec
```
## Grant a User Access to Spree Admin
From the Rails console:
```ruby
u = User.find(5)
u.spree_roles << Spree::Role.where(name:"admin").first
```
## Import Products and Variants from CSV
From the command line:
```bash
rake import:csv:products path_to_product_csv_file.csv
rake import:csv:variants path_to_product_csv_file.csv
```
Example CSV files are in `lib/tasks`.
