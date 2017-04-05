# Flow, ActiveMerchant and Solidus integration

Integration of Solidus with Flow, how it is done.

I plan to be concise as possible, but cover all important topics.

## Instalation

In ```./config/application.rb``` this is only peace of code that is needed to
init complete flow app

```
  config.to_prepare do
    # add all flow libs
    overload = Dir.glob('./app/flow/**/*.rb')
    overload.reverse.each { |c| require(c) }
  end

  config.after_initialize do |app|
    # init Flow payments as an option
    app.config.spree.payment_methods << Spree::Gateway::Flow

    # define defaults
    Flow.organization = ENV.fetch('FLOW_ORGANIZATION')
    Flow.base_country = ENV.fetch('FLOW_BASE_COUNTRY')
    Flow.api_key      = ENV.fetch('FLOW_API_KEY')
  end
```

## Things to take into account

Flow supports many modes of payments, with or without payments, in many currencies, etc.

One of better, more infomative ways of working with Flow API is using Sessions and Orders. Solidus and
probably any other online shop can support this features. I assume that Worst way of working with is
to charge this amount from that credit card, but we support that as well.

The thing is that ActiveMerchent is not supporting sessions and orders, natively. If one wants
to maintain sessions and orders in Flow, you have to do it outside the ActiveMerchant
terminology which focuses around purchases, voids and refunds.

Another thing to have in mind is that Solidus/Spree can't work with ActiveMerchent directly, it has to have
an adapter. Adapter can be "stupid" and light, and can forward all the "heavy lifting" to ActiveMerchant gem.

In http://guides.spreecommerce.org/developer/payments.html at the bottom of the page Spree authors say

"better_spree_paypal_express and spree-adyen are good examples of standalone
custom gateways. No dependency on spree_gateway or activemerchant required."

Reading that we can see this is even considered good approach. What came to my undestanding,
is that is is also preffered mode for us.

## ActiveMerchant gem into more detail

https://github.com/flowcommerce/active_merchant

Sopporst stanard public ActiveMerchant actions which are
purchase, authorize, capture, void, store and refund.

It depends on following gems

* flowcommerce   - api calls
* flow-reference - we use currency validations

It is not aware of Solidus or any other shopping lib or framework.

### ActiveMerchant::Flow supported actions in detail

* purchase  - shortcut for authorize and then capture
* authorize - authorize the cc and funds.
* capture   - capture the funds
* void      - cancel the transaction
* store     - store credit card (gets credit card flow token)
* refund    - refund the funds

## Solidus/Spree Implementation in more detail

Not present as standalone gem, yet. I will do that once we agree on implementation details.

From product list to purchase, complete chain v1

1. customer has to prepare data, migrate db and connect to Flow. In general
  * create experiences in Flow console, add tiers, shipping methods, etc.
  * add flow_cache (jsonb) fields to this models
    * Spree::Variant - we cache localized product prices
    * Spree::Order   - we cache flow order state details, shipping method
  * create and sync product catalog via rake tasks
1. now site users can browse prooducts and add them to cart.
1. when user comes to shop, FlowSession is created
1. once product is in cart
  * spree order is created and linked to Experience that we get from FlowSession
  * it is captured and synced with flow, realtime
    * we do this all the time because we want to have 100% accurate prices.
      Product prices that are shown in cart come directly from Flow API.
  * in checkout, when customer address is added or shipping method defined,
    all is synced with flow order.
  * when order is complete, we trigger flow-cc-authorize or flow-cc-capture
    * this can be done in two ways
      * directly on Spree::Order object instance. This is good because all actions
        are functions of the order object anyway
      * using ActiveMerchant adapter. possible, but not so elegant

What it is important to say here is that we do not use ActiveMerchant::Flow directly,
because Solidus/Spree is not sending localized prices. We have to capture the request to
ActiveMerchant and follow with our own localized total amount and currency.

## What can be better

We need a way to access the order in Rails. Access it after it is created in
controller but before it hits the render.
Current implementation is -> "overload" ApplicationController render
If we detect @spree_order object or debug flags, we react.

* good    - elegant solution, all need code is in one file in few lines of code
* bad     - somehow intrusive, we overload render, somw people will not like that.
* alternatives: gem that allows before_render bethod, call explicitly when needed

## Aditional notes - view and frontend

I see many Solidus/Spree merchant gems carry frontend code, js, coffe, views etc.
I thing that this is bad practise and that shop frontend has to be 100% customer code.

What I did not see but thing is great idea is to have custom light Flow admin present at

/admin/flow

that will ease the way of working with Flow. Code can be made to be Rails 4 and Rails 5 compatibile.
Part of that is allready done as can be seen here https://i.imgur.com/FXbPrwK.png

By default flow Admin is anybody that is Solidus admin.

This way we provide good frontend info, some integration notes in realtime as opposed to running
rake tests to check for integrity of Flow integration.

I suggest we make it part of flow-solidus gem



