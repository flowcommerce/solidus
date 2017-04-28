class ApplicationController < ActionController::Base
  FLOW_SESSION_KEY = :_f60_session

  protect_from_forgery    with: :exception
  before_action           :flow_set_experience, :flow_update_selection

  # before render trigger
  # rails does not have before_render filter so we create it like this
  # to make things simple
  def render(*args)
    # call method if one defined
    target        = '%s#%s' % [params[:controller], params[:action]]
    filter_method = ('flow_filter_' + target.gsub!(/[^\w]/,'_')).to_sym
    send(filter_method) if self.class.private_instance_methods.include?(filter_method)

    # call all this methods
    flow_sync_order
    flow_filter_products

    # return our data or call super render
    if @flow_render
      return redirect_to @flow_render[:redirect_to] if @flow_render[:redirect_to]
      super(@flow_render)
    else
      super
    end
  end

  private

  # filter out restricted products, defined in flow console
  # https://console.flow.io/:organization/restrictions
  def flow_filter_products
    return unless @products

    experience = Flow::Experience.get @flow_exp.key
    restricted = FlowOption.where(experience_region_id: experience.region.id).first
    restricted = restricted ? restricted.restricted_ids : []
    return if restricted.length == 0

    # filter out excluded product for particular experience
    @products = @products.where("coalesce(spree_products.flow_cache->'%s.excluded', '0') = '0'" % @flow_exp.key) if @flow_exp
  end

  # checks current experience (defined by parameter) and sets default one unless one preset
  def flow_set_experience
    if value = session[FLOW_SESSION_KEY]
      begin
        @flow_session = Flow::Session.new(hash: JSON.load(value))
      rescue JSON::ParserError
        session.delete(FLOW_SESSION_KEY)
      end
    end

    # get by IP unless we got it from session
    @flow_session ||= Flow::Session.new ip: request.ip unless @flow_session

    if flow_exp_key = params[:flow_experience]
      @flow_session.change_experience(flow_exp_key)
      redirect_to request.path
    end

    # try to get experience
    @flow_exp = @flow_session.local.try(:experience)

    # construct dummy objecy unless exp found, to make code work
    @flow_exp ||= Struct.new(:id, :key, :country).new('world', 'world', 'World')

    # save flow session ID for client side usage
    cookies.permanent[FLOW_SESSION_KEY] = @flow_session.session.id

    # save full cache for server side usage
    session[FLOW_SESSION_KEY] = @flow_session.to_json
  end

  ###

  # update selection (delivery options) on /checkout/update/delivery
  def flow_update_selection
    if params[:flow_order_id] && params[:flow_selection]
      # empty array is nil, so we allways send placeholder
      params[:flow_selection].delete('placeholder')

      order_id = EasyCrypt.decrypt(params[:flow_order_id])
      order = Spree::Order.find(order_id)
      order.update_column :flow_cache, order.flow_cache.merge('selection'=>params[:flow_selection])
    end
  end

  # we need to prepare @order and sync to flow.io before render because we need
  # flow total price
  def flow_sync_order
    return unless @order && @order.id
    return if @order.line_items.length == 0

    # tmp solution for demo (really)
    @order.clear_zero_amount_payments!

    return if request.path.include?('/admin/')

    @flow_order = Flow::Order.new(experience: @flow_exp, order: @order, customer: @current_spree_user)
    @flow_order.synchronize!

    if @flow_order.error?
      if @flow_order.error.include?('been submitted')
        @order.finalize!
        @flow_render = { redirect_to: '/'}
      else
        @flow_render =  { text: 'Flow error: %s' % @flow_order.error }
      end
    elsif params[:debug] == 'flow'
      @flow_render = { json: JSON.pretty_generate(@flow_order.response) }
    end
  end

  def flow_filter_spree_products_show
    @flow_render = { json: JSON.pretty_generate(@flow_exp.get_item(@product).to_hash) } if params[:debug] == 'flow'
  end

  def flow_filter_spree_checkout_edit

  end

end
