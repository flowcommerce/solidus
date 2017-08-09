# flow specific controller

class FlowController < ApplicationController
  layout 'flow'
  skip_before_filter :verify_authenticity_token, only: :handle_flow_web_hook_event

  # forward all incoming requests to Flow Webhook service object
  # /flow/event-target
  def handle_flow_web_hook_event
    # return render text: 'Source is not allowed to make requests', status: 403 unless requests.ip == '52.86.80.125'

    data     = JSON.parse request.body.read
    response = Flow::Webhook.process data

    render text: response
  rescue ArgumentError => e
    render text: e.message, status: 400
  end

  def paypal_get_id
    order     = paypal_get_order_from_param
    response  = Flow::PayPal.get_id order

    render json: response.to_hash
  rescue Io::Flow::V0::HttpClient::ServerError => e
    render json: { code: e.code, message: e.message }, status: 500
  end

  def paypal_finish
    order         = paypal_get_order_from_param
    gateway_order = Flow::SimpleGateway.new order
    response      = gateway_order.cc_authorization

    opts = if response.success?
      order.update_column :flow_data, order.flow_data.merge({ payment_type: 'paypal' })
      order.flow_finalize!

      flash[:success] = 'PayPal order is placed successufuly.'

      { order_number:  order.number }
    else
      { error: response.message }
    end

    render json: opts
  end

  def index
    # solidus method
    return unless user_is_admin

    if action = params[:flow]
      order = Spree::Order.find(params[:o_id])

      case action
        when 'order'
          # response = FlowCommerce.instance.orders.get_by_number(Flow.organization, order.flow_number)
          response = Flow.api :get, '/:organization/orders/%s' % order.flow_number, expand: 'experience'
        when 'raw'
          response = order.attributes
        when 'auth'
          flow_response = Flow::SimpleGateway.new(order).cc_authorization
          response      = flow_response.success? ? flow_response.params['response'].to_hash : flow_response.message
        when 'capture'
          flow_response = Flow::SimpleGateway.new(order).cc_capture
          response      = flow_response.success? ? flow_response.params['response'].to_hash : flow_response.message
        when 'refund'
          response = order.flow_data['refund']

          unless response
            flow_response = Flow::SimpleGateway.new(order).cc_refund
            response = flow_response.success? ? order.flow_data['refund'] : flow_response.message
          end
        else
          return render text: 'Ation %s not supported' % action
      end

      render json: response
    else
      @orders = Spree::Order.order('id desc').page(params[:page]).per(20)
    end
  rescue
    render text: '%s: %s' % [$!.class.to_s, $!.message]
  end

  def update_current_order
    order = Spree::Order.find_by number: params[:number]
    name  = params[:name]
    value = params[:value]

    raise ArgumentError.new('Order not found') unless order
    raise ArgumentError.new('Name parameter not allowed') unless [:selection, :delivered_duty].include?(name.to_sym)
    raise ArgumentError.new('Value not defined') unless value

    order.flow_data[name] = value
    order.update_column :flow_data, order.flow_data

    render text: '%s - %s' % [name, value]
  end

  def promotion_set_option
    param_type  = params[:type]  || raise(ArgumentError.new('Parameter "type" not defined'))
    param_name  = params[:name]  || raise(ArgumentError.new('Parameter "name" not defined'))
    param_value = params[:value] || raise(ArgumentError.new('Value not defined'))

    unless ['experience'].include?(param_type)
      raise(ArgumentError.new('Parameter name not alowed'))
    end

    # prepare array
    promotion = Spree::Promotion.find params[:id]
    promotion.flow_data['filter'] ||= {}
    promotion.flow_data['filter'][param_type] ||= []

    # set or remove value
    if param_value == '0'
      promotion.flow_data['filter'][param_type] -= [param_name]
    elsif !promotion.flow_data['filter'][param_type].include? param_name
      promotion.flow_data['filter'][param_type].push param_name
    end

    # remove array if empty
    promotion.flow_data['filter'].delete(param_type) if promotion.flow_data['filter'][param_type].length == 0

    promotion.save!

    render json: promotion.flow_data
  end

  def about

  end

  def restrictions
    @list = {}
  end

  private

  def paypal_get_order_from_param
    order_number = params[:order]              || raise('Order parameter not defined')
    Spree::Order.find_by(number: order_number) || raise('Order not found')
  end

  def user_is_admin
    return true if spree_current_user && spree_current_user.admin?
    render text: 'You must be admin to access flow admin'
    false
  end

end