require './app/flow/before_render'

class ApplicationController < ActionController::Base
  FLOW_SESSION_KEY = :_f60_session

  protect_from_forgery with: :exception
  before_filter        :flow_set_experience, :flow_before_filters

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

  before_render do
    flow_sync_order
    flow_filter_products
    flow_restrict_product
    flow_debug_product
  end

  private

  def flow_visitor_id
    if wu = session['warden.user.spree_user.key']
      wu[0] ? 'uid-%d' % wu[0][0] : wu[1]
    else
      Digest::SHA1.hexdigest request.ip
    end
  end

  # checks current experience (defined by parameter) and sets default one unless one preset
  def flow_set_experience
    # get by IP unless we got it from session
    @flow_session = Flow::Session.new ip: request.ip, json: session[FLOW_SESSION_KEY], visitor: flow_visitor_id

    # we will allow live change of experience by key
    if flow_exp_key = params[:flow_experience]
      @flow_session.change_experience(flow_exp_key)
      redirect_to request.path
    end

    # puts JSON.pretty_generate JSON.load ''

    # save full cache for server side usage
    session[FLOW_SESSION_KEY] = @flow_session.to_json

    # save flow session ID for client side usage
    cookies.permanent[FLOW_SESSION_KEY] = @flow_session.session.id
  end

  def flow_before_filters
    # if we are somewhere in checkout and there is no session, force user to login
    if request.path.start_with?('/checkout') && !@current_spree_user
      flash[:error] = 'You need to be registred to continue with shopping'
      redirect_to '/login'
    end
  end

  # ###

  # we need to prepare @order and sync to flow.io before render because we need
  def flow_sync_order
    order = @order if @order.try :id
    order ||= simple_current_order if respond_to?(:simple_current_order) && simple_current_order.try(:id)

    return unless order
    return if request.path.include?('/admin/')

    # we need to clear any cached flow order data if we do not use flow
    return Flow::Order.clear_cache(order) unless @flow_session.localized?

    @flow_order = Flow::Order.new(experience: @flow_session.experience, order: order, customer: @current_spree_user)
    @flow_order.synchronize!

    return if order.line_items.length == 0

    render json: JSON.pretty_generate(@flow_order.response) if params[:debug] == 'flow'

    if @flow_order.error?
      if @flow_order.error.include?('been submitted')
        order.finalize!
        redirect_to '/'
      else
        flash.now[:error] = Flow::Error.format_message @flow_order.response, @flow_session.experience
      end
    end
  end

  # filter out restricted products, defined in flow console
  # https://console.flow.io/:organization/restrictions
  def flow_filter_products
    return unless @products

    # filter out excluded product for particular experience
    @products = @products.where("coalesce(spree_products.flow_data->'%s.excluded', '0') = '0'" % @flow_session.experience.key) if @flow_session.experience
  end

  # altert and redirect when restricted or exclued product found
  def flow_restrict_product
    return unless @product

    unless @product.flow_included?(@flow_session.experience)
      flash[:error] = 'Product "%s" is not included in "%s" catalog' % [@product.name, @flow_session.experience.key]
      redirect_to '/'
    end
  end

  def flow_debug_product
    if params[:debug] == 'flow' && @flow_session.experience && @product
      flow_item = Flow.api(:get, '/:organization/experiences/items/%s' % @product.variants.first.id, experience: @flow_session.experience.key)
      render json: JSON.pretty_generate(flow_item)
    end
  end

end
