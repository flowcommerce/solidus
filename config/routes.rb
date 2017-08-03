Rails.application.routes.draw do

  # This line mounts Spree's routes at the root of your application.
  # This means, any requests to URLs such as /products, will go to Spree::ProductsController.
  # If you would like to change where this engine is mounted, simply change the :at option to something different.
  #
  # We ask that you don't use the :as option here, as Spree relies on it being the default of "spree"
  mount Spree::Core::Engine, :at => '/'

  namespace :flow do
    post '/event-target',         to: '/flow#handle_flow_web_hook_event'
    post '/paypal_id',            to: '/flow#paypal_get_id'
    post '/paypal_finish',        to: '/flow#paypal_finish'
    post '/promotion_set_option', to: '/flow#promotion_set_option'
  end

  get '/about', to: 'flow#about'
  get '/admin/flow', to:'flow#index'

  get '/sale', to: 'spree/home#sale'
end
