class ApplicationController < ActionController::Base
  FLOW_SESSION_KEY = :_f60_session
  @@session_cache  = {}
  @@semaphore      = Mutex.new

  private

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

  before_render_filter do
    if @flow_session.experience
      flow_sync_order
      flow_filter_products
      flow_restrict_product
      flow_debug
    end
  end

  def flow_get_visitor_id
    if wu = session['warden.user.spree_user.key']
      wu[0] ? 'uid-%d' % wu[0][0] : wu[1]
    else
      Digest::SHA1.hexdigest request.ip
    end
  end

  # checks current experience (defined by parameter) and sets default one unless one preset
  def flow_set_experience
    flow_visitor_id = flow_get_visitor_id

    @flow_session = @@session_cache[flow_visitor_id] || Flow::Session.new(ip: request.ip, visitor: flow_visitor_id)

    # we will allow live change of experience by key
    if flow_exp_key = params[:flow_experience]
      @flow_session.change_experience(flow_exp_key)
      redirect_to request.path
    end

    @@semaphore.synchronize { @@session_cache[flow_visitor_id] = @flow_session }

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

    if @flow_order.error?
      if @flow_order.error.include?('been submitted')
        order.finalize!
        redirect_to '/'
      else
        flash.now[:error] = Flow::Error.format_message @flow_order.response, @flow_session.experience
      end
    end
  end

  # https://console.flow.io/:organization/restrictions
  # filter out excluded product for particular experience
  def flow_filter_products
    @products &&= @products.where("coalesce(spree_products.flow_data->'%s.excluded', '0') = '0'" % @flow_session.experience.key)
  end

  # altert and redirect when restricted or exclued product found
  def flow_restrict_product
    return unless @product

    unless @product.flow_included?(@flow_session.experience)
      flash[:error] = 'Product "%s" is not included in "%s" catalog' % [@product.name, @flow_session.experience.key]
      redirect_to '/'
    end
  end

  def flow_debug
    return unless params[:debug] == 'flow'

    if @product
      flow_item = Flow.api(:get, '/:organization/experiences/items/%s' % @product.variants.first.id, experience: @flow_session.experience.key)
      render json: JSON.pretty_generate(flow_item)
    elsif @flow_order
      render json: JSON.pretty_generate(@flow_order.response) if params[:debug] == 'flow'
    end
  end

end
