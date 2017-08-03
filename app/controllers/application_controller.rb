class ApplicationController < ActionController::Base
  FLOW_SESSION_KEY = :_f60_session

  protect_from_forgery    with: :exception
  before_action           :flow_before_filters, :flow_set_experience, :flow_update_order_attrbibutes

  # we will rescue and log all erorrs
  # idea is to not have any errors in the future, but
  # if they happen we will show hopefully meaning full info
  rescue_from StandardError do |exception|
    # hard log error
    Flow::Error.log exception, request

    if Rails.env.production?
      # render small error template with basic info for the user
      info_hash = { message: exception.message, klass: exception.class }

      # show customized error only in production
      render text: Rails.root.join('app/views/flow/_error.html').read % info_hash
    else
      raise exception
    end
  end

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
    flow_restrict_product

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

    # filter out excluded product for particular experience
    @products = @products.where("coalesce(spree_products.flow_data->'%s.excluded', '0') = '0'" % @flow_exp.key) if @flow_exp
  end

  # checks current experience (defined by parameter) and sets default one unless one preset
  def flow_set_experience
    if value = session[FLOW_SESSION_KEY]
      begin
        @flow_session = Flow::Session.new(hash: JSON.load(value))
      rescue
        session.delete(FLOW_SESSION_KEY)
      end
    end

    # get by IP unless we got it from session
    @flow_session ||= Flow::Session.new ip: request.ip unless @flow_session

    if flow_exp_key = params[:flow_experience]
      @flow_session.change_experience(flow_exp_key)
      redirect_to request.path
    end

    if @flow_session.use_flow?
      # try to get experience
      @flow_exp = @flow_session.local.experience
    end

    # save flow session ID for client side usage
    cookies.permanent[FLOW_SESSION_KEY] = @flow_session.session.id

    # save full cache for server side usage
    session[FLOW_SESSION_KEY] = @flow_session.to_json
  end

  ###

  # update selection (delivery options) on /checkout/update/delivery
  def flow_update_order_attrbibutes
    [:selection, :delivered_duty].each do |el|
      value = params["flow_#{el}".to_sym]
      if value.present?
        simple_current_order.flow_data[el.to_s] = value
        @order_update = true
      end
    end

    if @order_update
      simple_current_order.update_column :flow_data, simple_current_order.flow_data
    end
  end

  # we need to prepare @order and sync to flow.io before render because we need
  # flow total price
  def flow_sync_order
    order = @order if @order.try :id
    order ||= simple_current_order if respond_to?(:simple_current_order) && simple_current_order.try(:id)

    return unless order

    return if request.path.include?('/admin/')

    if @flow_session.use_flow?
      @flow_order = Flow::Order.new(experience: @flow_exp, order: order, customer: @current_spree_user)
      @flow_order.synchronize!
    else
      if order.flow_data['order']
        order.flow_data.delete('order')
        order.update_column :flow_data, order.flow_data.dup
      end

      return
    end

    return if order.line_items.length == 0

    if @flow_order.error?
      if @flow_order.error.include?('been submitted')
        order.finalize!
        @flow_render = { redirect_to: '/'}
      else
        @has_order_error  = true
        error_description = Flow::Error.format_message @flow_order.response
        order.flow_data   = {}

        if request.path.start_with?('/checkout')
          @flow_render = { redirect_to: '/cart'}
          flash[:error] = error_description
        else
          flash.now[:error] = error_description
        end
      end
    elsif params[:debug] == 'flow'
      @flow_render = { json: JSON.pretty_generate(@flow_order.response) }
    end
  end

  def flow_restrict_product
    return unless @product

    unless @product.flow_included?(@flow_exp)
      flash[:error] = 'Product "%s" is not included in "%s" catalog' % [@product.name, @flow_exp.key]
      @flow_render  = { redirect_to: '/' }
    end
  end

  def flow_filter_spree_products_show
    # r @product.variants.first.id.to_s
    if params[:debug] == 'flow' && @flow_exp
      flow_item = Flow.api(:get, '/:organization/experiences/items/%s' % @product.variants.first.id, experience: @flow_exp.key)
      @flow_render = { json: JSON.pretty_generate(flow_item) }
    end
  end

  def flow_before_filters
    # if we are somewhere in checkout and there is no session, force user to login
    if request.path.start_with?('/checkout') && !@current_spree_user
      flash[:error] = 'You need to be registred to continue with shopping'
      redirect_to '/login'
    end
  end

end
