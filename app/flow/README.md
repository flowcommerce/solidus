<img align="right" src="http://i.imgur.com/tov8bTw.png">

# Flow.io adapter Solidus/Spree

Work in progress. This will be converted to gem.

All flow libs are located in ./app/flow folder with exception of two controllers
ApplicationController and FlowController that are present in ./app/controllers folder.


## Instalation

Define this additional ENV variables. You will find them in [Flow console](https://console.flow.io)

```
FLOW_API_KEY='SUPERsecretTOKEN'
FLOW_ORGANIZATION='solidus-app-sandbox'
FLOW_BASE_COUNTRY='usa'
```

Add

```
  config.after_initialize do |app|
    app.config.spree.payment_methods << Spree::Gateway::Flow
  end
```

in ./config/application.rb to enable payments with Flow.

## Flow API specific

Classes that begin with Flow are responsible for comunicating with flow API.

### FlowExperience

Responsible for selecting current experience. You have to define available experiences in flow console.

### FlowOrder

Maintain and synchronizes Spree::Order with Flow API.

### FlowSession

Every shop user has a session. This class helps in creating and maintaining session with Flow.

### FlowRoot

Helper class that will be removed in gem.

## Decorators

Decorators are found in ./app/flow/decorators folders and they decorate Solidus/Spree models with Flow specific methods.

All methods are prefixed with ```flow_```.

## Helper lib

### EasyCrypt

Uses ```ActiveSupport::MessageEncryptor``` to provide easy access to encryption with salt.

### Spree::Flow::Gateway

Adapter for Solidus/Spree, that allows using [Flow.io](https://www.flow.io) as payment gateway. Flow is PCI compliant payment processor.



