# Flow (2017)

Spree::Api::OrdersController.class_eval do

  def flow_render_coupon_error message
    render({
      status: 400,
      json: {
        successful:  false,
        success:     nil,
        status_code: 'coupon_code_not_found',
        error:       message
      }
    })
  end

  # /flow/promotion_set_option?id=3&type=experience&name=canada&value=1
  # alias :apply_coupon_code_pointer :apply_coupon_code
  def apply_coupon_code
    # find promotion code
    coupon_code    = params[:coupon_code].to_s.gsub(/\s+/, '').downcase
    promotion_code = Spree::PromotionCode.find_by value: coupon_code

    unless promotion_code
      return flow_render_coupon_error('Coupon code not found')
    end

    promotion       = Spree::Promotion.find promotion_code.promotion_id
    experience_key  = @order.flow_order.dig('experience', 'key')
    forbiden_keys   = promotion.flow_data.dig('filter', 'experience') || []

    if experience_key.present? && !forbiden_keys.include?(experience_key)
      return flow_render_coupon_error('Promotion is not available in current country')
    end

    # authorize! :update, @order, order_token
    # all good, apply coupon to Solidus as Flow is not present

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
