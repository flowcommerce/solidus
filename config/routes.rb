Rails.application.routes.draw do

  # This line mounts Spree's routes at the root of your application.
  # This means, any requests to URLs such as /products, will go to Spree::ProductsController.
  # If you would like to change where this engine is mounted, simply change the :at option to something different.
  #
  # We ask that you don't use the :as option here, as Spree relies on it being the default of "spree"
  mount Spree::Core::Engine, :at => '/'

  # local api targets
  namespace :flow do
    post '/event-target',         to: '/flow#handle_flow_web_hook_event'
    post '/paypal_id',            to: '/flow#paypal_get_id'
    post '/paypal_finish',        to: '/flow#paypal_finish'
    post '/promotion_set_option', to: '/flow#promotion_set_option'
    post '/update_current_order', to: '/flow#update_current_order'
    post '/schedule_refresh',     to: '/flow#schedule_refresh'
  end

  # custom from Flow for Solidus frontend
  get '/about', to: 'flow#about'
  get '/sale', to: 'spree/home#sale'

  # health check ping
  get '/_internal_/healthcheck', to: lambda { |env| [200, {}, ['alive']] }

  # sigle page for flow specific admin
  get '/admin/flow', to:'flow#index'

  # 404
  get '*all', to: 'spree/home#not_found'
end
