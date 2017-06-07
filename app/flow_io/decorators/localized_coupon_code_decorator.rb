# Flow (2017)

Spree::Api::OrdersController.class_eval do

  alias :apply_coupon_code_pointer :apply_coupon_code
  def apply_coupon_code
    if allowed = @order.flow_data['promotion_exp_keys']
      experience_data = JSON.load(session[ApplicationController::FLOW_SESSION_KEY] || '{}')
      experience_key  = experience_data.dig 'local', 'experience', 'key'

      allowed = allowed.include? experience_key

      return render(status: 400, json: {
        successful:  false,
        success:     nil,
        status_code: 'coupon_code_not_found',
        error:       'Promotion is not available in current country'
      }) unless allowed
    end

    apply_coupon_code_pointer
  end
end
