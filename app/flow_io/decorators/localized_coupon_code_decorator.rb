# Flow (2017)

Spree::Api::OrdersController.class_eval do

  # /flow/promotion_set_option?id=3&type=experience&name=canada&value=1
  # alias :apply_coupon_code_pointer :apply_coupon_code
  def apply_coupon_code
    # find promotion code
    coupon_code    = params[:coupon_code]
    promotion_code = Spree::PromotionCode.find_by value: coupon_code

    if promotion_code
      # promotion code found
      promotion       = Spree::Promotion.find promotion_code.promotion_id

      # get experience key from session
      experience_data = JSON.load(session[ApplicationController::FLOW_SESSION_KEY] || '{}')

      experience_key  = experience_data.dig 'local', 'experience', 'key'
      forbiden_keys   = promotion.flow_data.dig 'filter', 'experience'

      # Rails.logger.error 'experience_key: %s' % experience_key
      # Rails.logger.error 'forbiden_keys: %s' % forbiden_keys.join(', ')

      allowed = true
      allowed = false if experience_key && forbiden_keys.is_a?(Array) && !forbiden_keys.include?(experience_key)

      return render(status: 400, json: {
        successful:  false,
        success:     nil,
        status_code: 'coupon_code_not_found',
        error:       'Promotion is not available in current country'
      }) unless allowed
    end

    # call original coupon handler
    # apply_coupon_code_pointer

    authorize! :update, @order, order_token
    @order.coupon_code = params[:coupon_code]
    @handler = Spree::PromotionHandler::Coupon.new(@order).apply
    if @handler.successful?
      render "spree/api/promotions/handler", status: 200
    else
      logger.error("apply_coupon_code_error=#{@handler.error.inspect}")
      render "spree/api/promotions/handler", status: 422
    end
  end
end
