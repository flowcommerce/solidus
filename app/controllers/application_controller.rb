class ApplicationController < ActionController::Base
  FLOW_SESSION_KEY = :_f60_session
  @@semaphore      = Mutex.new

  private

  protect_from_forgery with: :exception
  before_action        :flow_set_experience, :flow_before_filters

  # we will rescue and log all erorrs
  # idea is to not have any errors in the future, but
  # if they happen we will show hopefully meaning full info
  # if we have bad cc number, that is an error we can't avoid
  rescue_from StandardError do |exception|
    if defined?(Bugsnag)
      Bugsnag.notify(exception)
    else
      # hard log error
      Flow::Error.log exception, request
    end

    # raise exception
    error = Flow::Error.format_message exception

    # show simple errors inline and other errors in separate page
    if ['invalid_number'].include?(error['code'])
      flash[:error] = '%{message} (%{title})' % error
      redirect_to :back
    else
      render text: Rails.root.join('app/views/flow/_error.html').read % error
    end
  end

  # rescue_from Io::Flow::V0::HttpClient::ServerError do |exception|
  # end

  # we want to run filter just before the render
  before_render_filter do
    if @flow_session.try(:experience)
      flow_sync_order
      flow_filter_and_restrict_products
      flow_debug
    end
  end

  # tries to get vunique vistor id, based on user agent and ip
  def flow_get_visitor_id
    uid = if wu = session['warden.user.spree_user.key']
      wu[0] ? 'uid-%d' % wu[0][0] : wu[1]
    else
      Digest::SHA1.hexdigest request.ip + request.user_agent
    end

    'session-%s' % uid
  end

  # checks current experience (defined by parameter) and sets default one unless one preset
  def flow_set_experience
    # get uniq visitor id
    visitor = flow_get_visitor_id

    # create session from cache if possible
    if cached = FlowSettings[visitor]
      session = Flow::Session.restore Base64.decode64(cached)
      session = nil if session.session.visit.expires_at < DateTime.now
    end

    # create session if needed
    unless session
      session = Flow::Session.new ip: request.ip, visitor: visitor
      session.create
      @save_session = true
    end

    # allow changing between experiences by key
    if flow_exp_key = params[:flow_experience]
      session.update flow_exp_key == 'null' ?
        { country: Flow.base_country } :
        { experience: flow_exp_key }

      redirect_to request.url.sub /.flow_experience=.*/, ''
      @save_session = true
    end

    # save session if needed
    FlowSettings[visitor] = Base64.encode64(session.dump) if @save_session

    # expose flow session object
    @flow_session   = session

    unless @flow_session
      @flow_session ||= Hashie::Mash.new
      flash.now[:error] = 'Flow session not initiazized (Flow erorr)'
    end
  rescue
    # clear session
    FlowSettings.delete visitor

    # and safe redirect
    redirect_to '?redirected=true' unless params[:redirected]
  end

  def flow_before_filters
    # if we are somewhere in checkout and there is no session, force user to login
    # that will remove few Solidus native bugs
    if request.path.start_with?('/checkout') && !@current_spree_user
      session['spree_user_return_to'] = '/cart'
      flash[:error] = 'You need to be registred to continue with shopping'
      redirect_to '/login'
    end

    # for some reason, Solidus 2.4.2 is not updateing payment
    if current_order && request.path == '/checkout/payment'
      payment = current_order.payments.first

      if payment && !payment.payment_method_id
        payment.update_column :payment_method_id, current_order.available_payment_methods.first.id
      end
    end
  end

  # ###

  # we need to prepare @order and sync to flow.io before render because we need
  def flow_sync_order
    order = @order if @order.try :id
    order ||= current_order if respond_to?(:current_order) && current_order.try(:id)

    return unless order
    return if order.line_items.length == 0
    return if request.path.include?('/admin/')
    return if @flow_order

    # we need to clear any cached flow order data if we do not use flow
    return Flow::Order.clear_cache(order) unless @flow_session.localized?

    @flow_order = Flow::Order.new(experience: @flow_session.experience, order: order, customer: @current_spree_user)
    @flow_order.synchronize!

    if @flow_order.error?
      if @flow_order.error.include?('been submitted')
        order.finalize!
        redirect_to '/'
      else
        flash.now[:error] = Flow::Error.format_order_message @flow_order.response, @flow_session.experience
      end
    end
  end

  # if using flow, filter any list of products to include only ones available in current experience
  def flow_filter_and_restrict_products
    # filter out excluded product for particular experience
    # https://console.flow.io/:organization/restrictions
    @products &&= @products.where("coalesce(spree_products.flow_data->'%s.excluded', '0') = '0'" % @flow_session.experience.key)

    # altert and redirect when restricted or exclued product found
    if @product && !@product.flow_included?(@flow_session.experience)
      flash[:error] = 'Product "%s" is not included in "%s" catalog' % [@product.name, @flow_session.experience.key]
      redirect_to '/'
    end
  end

  # debug flow specific requests
  def flow_debug
    return unless params[:debug] == 'flow'

    if @product
      flow_item = Flow.api(:get, '/:organization/experiences/items/%s' % @product.variants.first.id, experience: @flow_session.experience.key)
      render json: JSON.pretty_generate(flow_item)
    elsif @flow_order
      render json: JSON.pretty_generate(@flow_order.response) if params[:debug] == 'flow'
    end
  end

  # safe run process in the background
  def background &block
    Thread.new do
      yield
      ActiveRecord::Base.connection.close
    end
  end
end
