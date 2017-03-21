Flow.api :post, '/:organization/cards', BODY:{"cvv":"737","expiration_month":8,"expiration_year":2018,"name":"Joe Smith","number":"4111111111111111"}
{
  "expiration": {
    "month": 8,
    "year": 2018
  },
  "id": "crd-0ee4a7e933144bc4bcbf9d66a7fe6469",
  "iin": "411111",
  "last4": "1111",
  "name": "Joe Smith",
  "token": "F96RVdyRSLI7ERQiJCLdygZCorlcr1jwyCrzGEB50Vxp0JtfFiltNdo9Owu0suEF",
  "type": "visa"
}

#

Flow.api :post, '/:organization/authorizations', BODY:{"token":"F96RVdyRSLI7ERQiJCLdygZCorlcr1jwyCrzGEB50Vxp0JtfFiltNdo9Owu0suEF","order_number":"s-o-c405b885b7e25ab26a819921a0ff182c333a0b95","discriminator":"merchant_of_record_authorization_form"}

#

ActionController::Parameters -> &lt;ActionController::Parameters
{
  "utf8": "✓",
  "_method": "patch",
  "authenticity_token": "wEKJ/J6OXsx2QwpZJ8JUyeQbyxVwq0sFXryeC+jh4OzUrGL3RCQerTzaHiH3rI47p5ZXYQ8o9xz+vDJyk8P4xQ==",
  "order": {
    "payments_attributes": [
      {
        "payment_method_id": "2"
      }
    ],
    "coupon_code": ""
  },
  "payment_source": {
    "2": {
      "name": "Dino Reic",
      "number": "4111 1111 1111 1111",
      "expiry": "08 / 18",
      "verification_value": "737",
      "address_attributes": {
        "firstname": "Dino",
        "lastname": "Reic",
        "company": "",
        "address1": "Horvacanska 39",
        "address2": "",
        "city": "Zagreb",
        "country_id": "98",
        "state_id": "1322",
        "state_name": "",
        "zipcode": "10000",
        "phone": "00385 91 3466 111",
        "alternative_phone": ""
      },
      "cc_type": "visa"
    }
  },
  "controller": "spree/checkout",
  "action": "update",
  "state": "payment"
}

#

Spree::Order.last.credit_cards

DemoShop::Application.config.spree.payment_methods