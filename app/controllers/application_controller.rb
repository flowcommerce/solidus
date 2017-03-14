class ApplicationController < ActionController::Base
  protect_from_forgery    with: :exception
  before_action           :flow_check_and_set_country, :flow_update_selection

  # before render trigger
  # rails does not have before_render filter so we create it like this
  # to make things simple
  def render(*args)
    # call method if one defined
    target        = '%s#%s' % [params[:controller], params[:action]]
    filter_method = ('flow_filter_' + target.gsub!(/[^\w]/,'_')).to_sym
    send(filter_method) if self.class.private_instance_methods.include?(filter_method)

    # call all this methods
    sync_flow_order

    # return our data or call super render
    @flow_render ? super(@flow_render) : super
  end

  private

  # update selection (delivery options) on /checkout/update/delivery
  def flow_update_selection
    if params[:flow_order_id] && params[:flow_selection]
      # empty array is nil, so we allways send placeholder
      params[:flow_selection].delete('placeholder')

      order_id = Flow::Crypt.decrypt(params[:flow_order_id])
      order = Spree::Order.find(order_id)
      order.update_column :flow_cache, order.flow_cache.merge('selection'=>params[:flow_selection])
    end
  end

  # If we have a flow session, return an instance of Io::Flow::V0::Models::Session
  def flow_session
    if value = cookies.permanent[flow_session_cookie_name]
      begin
        Io::Flow::V0::Models::Session.new(JSON.parse(value))
      rescue Exception => e
        # TODO: Log warning
      end
    else
      nil
    end
  end

  def flow_session=(session)
    cookies.permanent[flow_session_cookie_name] = session.to_json
  end

  def flow_session_cookie_name
    :_f60_session
  end
  
  # checks current experience (defined by parameter) and sets default one unless one preset
  def flow_check_and_set_country
    session = flow_session
    if session.nil? && request.ip
      ## Create session from IP address
      flow_session = Flow.instance(ENV['ORG_ID']).sessions.post(
        Io::Flow::V0::Models::SessionForm(:ip => request.ip)
      )
    end
      
    if session
      if country = params[:flow_country]
        ## User is changing country. Update sesssion
        session = flow_session = Flow.instance(ENV['ORG_ID']).sessions.put_by_session(
          session.id,
          Io::Flow::V0::Models::SessionPutForm(:country => country)
        )
      end
    end

    if session && session.local
      @flow_exp = session.local.experience
    end
  end

  ###

  # we need to prepare @order and sync to flow.io before render because we need
  # flow total price
  def sync_flow_order
    return unless @order

    @flow_order = FlowOrder.sync_from_spree_order(experience: @flow_exp, order: @order, customer: @current_spree_user)
    @flow_render = { json: JSON.pretty_generate(@flow_order.response) } if params[:debug] == 'flow'
  end

  def flow_filter_spree_products_show
    # r @product.variants.first.flow_cache
    @flow_render = { json: JSON.pretty_generate(@flow_exp.get_item(@product).to_hash) } if params[:debug] == 'flow'
    # @product.variants.first.update_column :flow_cache, nil
  end

  def flow_filter_spree_checkout_edit
    # r @flow_order.deliveries
  end

end
