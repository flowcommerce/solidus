# Flow.io (2017)
# communicates with flow api, responds to webhook events

class Flow::PayPal
  def get_id(order)
    if order.flow_order
      # get PayPal ID using Flow api
      body = {
        discriminator: 'merchant_of_record_payment_form',
        method:        'paypal',
        order_number:  order.number,
        amount:        order.flow_order.total.amount,
        currency:      order.flow_order.total.currency,
      }

      Flow.api :post, '/:organization/payments', {}, body
    else
      # to do
      raise 'PayPal only supported while using flow'
    end
  end
end
