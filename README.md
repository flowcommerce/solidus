# Flow Fashion
An example Solidus website for Flow.io to demonstrate to clients.

https://www.shopflowfashion.com/

## Dev Set-up
How to set up a dev environment for this project:

1. Clone the project
2. Create a `database.yml` file and place it in config/ (You can probably just copy the `config/database.sample.yml` sample file.)
3. Run `bundle install` to grab the gems.
4. Set up env variables:
   - DEV_SECRET_KEY_BASE
   - TEST_SECRET_KEY_BASE
   - DEVISE_SECRET
   You may prefer to add these to a .env file for convenience (see https://github.com/bkeepers/dotenv)
5. Run `bundle exec rails g spree:install` to set up seed and sample data
6. Log in to /admin with the default admin account. By default, user is `spree@example.com` and password `spree123`.

## Working Protocols
### Branches
* The `master` branch contains the state of the site on the production server
* The `staging` branch contains the state of the site on the staging server
* All other branches should start with `fix/` or `feature/` and a number that matches a corresponding open issue on Github
* Rebase off of `master` often, and especially before submitting a pull request to make sure your feature branch has the latest hotness.
* [Issues](https://github.com/resolve/flow_solidus_demo/issues) should be created for all major features, bugs, discussions and other reasonably sized bits to work on. When possible, reference issue numbers in your commits and close issues with commits.
* When a branch is ready for either staging or master, send a [Pull Request](https://github.com/resolve/flow_solidus_demo/pull/new/master) detailing the changes made, any dependency updates, screenshots of updates if needed, and any other information to help with the merge.

### Code Standards
#### Ruby
In general, try and follow the guidelines in the [Ruby Style Guide](https://github.com/bbatsov/ruby-style-guide).
* Soft tabs, two spaces.
* Use ruby 1.9 style hash syntax. `attr: value` not `:attr => value`
* Keep external dependencies to a minimum. Only add gems if you must.
* Create small, simple classes that have a single responsibility when at all possible.
* Factories, not fixtures for data tests.
* Aim to write good tests for all classes. Testing is not as necessary for views, but use good judgement.
* Set your text editor to remove trailing spaces, etc..
* Use locales for text, even if the project will only ever be in English
* Separate code that overrides Solidus from code the implements new features.
  * Use spree subdirectories (`app/controllers/spree`, `app/models/spree` etc.) only for overriding files that also exist in Solidus.
  * Use Deface to insert new admin view code.
### Tests
Models, services and other general classes should be tested. Helpers and views can be tested if possible, but not required.
After running tests, code coverage will be available in the `coverage/index.html` file. Try and keep coverage above 95%.

## Using the Solidus API
You'll need an admin user account with an API token. All requests should include the header
`X-Spree-Token: [YOUR TOKEN]`

Find your token by running `rails console` and then query for it:

```ruby
Spree::User.find_by_email("admin@example.com").spree_api_key
```

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
