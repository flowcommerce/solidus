  # flow specific controller

class FlowController < ApplicationController
  layout 'flow'
  skip_before_action :verify_authenticity_token, only: [:handle_flow_web_hook_event, :schedule_refresh]

  # forward all incoming requests to Flow Webhook service object
  # /flow/event-target
  def handle_flow_web_hook_event
    # return render plain: 'Source is not allowed to make requests', status: 403 unless requests.ip == '52.86.80.125'

    string_data = request.body.read

    # log web hook post to separate log file
    Flow::Webhook.logger.info string_data

    data     = JSON.parse string_data
    response = Flow::Webhook.process data

    render plain: response
  rescue ArgumentError => e
    render plain: e.message, status: 400
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
    return unless user_is_admin?

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
          return render plain: 'Ation %s not supported' % action
      end

      render json: response
    else
      @orders = Spree::Order.order('id desc').page(params[:page]).per(20)
    end
  rescue
    render plain: '%s: %s' % [$!.class.to_s, $!.message]
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

    render plain: '%s - %s' % [name, value]
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

  def schedule_refresh
    background do
      FolwApiRefresh.schedule_refresh!
      FolwApiRefresh.sync_products_if_needed!
    end

    render plain: 'Scheduled'
  end

  def last_order_put
    return unless user_is_admin?

    data = FlowSettings.get 'flow-order-put-body-%s' % params[:number]

    render json: JSON.load(data)
  end

  def webhooks
    return unless user_is_admin?

    @event_num = 200
    @events    = []

    Flow::Webhook.logger_read_lines(@event_num).each do |line|
      parts = line.split('INFO -- : ', 2)

      next unless parts[1]

      parts[0] = DateTime.parse parts[0].split('[', 2).last.split('#').first
      parts[1] = JSON.load(parts[1])

      @events.unshift parts
    end
  end

  def version
    return unless user_is_admin?

    render plain: `git log --max-count=1`
  end

  def products
    variants = Spree::Variant.select('id, product_id').all

    data = { products: {} }
    data[:product_ids] = Spree::Product.select('id').map(&:id).sort
    data[:variant_ids] = variants.map(&:id).sort

    for el in variants
      data[:products][el.product_id] ||= []
      data[:products][el.product_id].push el.id
      data[:products][el.product_id] = data[:products][el.product_id].sort
    end

    render json: data
  end

  def products_csv
    # https://support.google.com/merchants/answer/7052112
    # in /admin/taxonomies in meta_description add keyword google_product_category

    brands = ["AG Adriano", "ALPHAKILO", "Alternative Apparel", "Andrew Marc", "Australia Luxe", "Badgley Mischka",
      "Baggins", "Ballin", "Bally", "Barney Cool", "Beirn", "Belpearl", "Ben Sherman",
      "Bravery", "Breed", "Bulova", "Butter", "CHAPTER", "Charlie Jade", "Chelsea Paris", "Corey Lynn",
      "Cynthia Rowley", "Katie Rowland", "L.A.M.B.", "L.K.Bennett", "Life After", "Link Up", "Loree",
      "Lori Kassin", "M2", "Mallary Marks", "Marabelle", "Matiere", "Meira", "Mizuki", "Nanis", "Nephora",
      "Nick Point", "Nudie", "OURCASTE", "Original Penguin", "PURE NAVY", "Paolo Costagli", "Paul & Joe Sister",
      "Piranesi of Aspen", "Prism Small Kyoto Crossbody", "Rebecca Taylor", "Relwen", "Robert Graham", "Rogue",
      "Ron Hami", "Rush", "Ryder", "SO&CO", "Seiko", "Sergio Rossi", "Shay", "She + Lo", "Standard Issue",
      "Star Wars", "Stuhrling", "Superfine", "Swiss Legend", "Tara Pearls", "Tateossian", "Thakoon", "Time's Arrow",
      "Timo Weiland", "Tocca", "Tom Binns", "Tsovet", "Vanishing Elephant", "Victorinox", "Vivienne Westwood", "Young Fabulous"]

    csv = SimpleCsvWriter.new

    for product in Spree::Product.all
      brand = 'Flow'
      brands.each { |brand_name| brand = brand_name if product.name.start_with?(brand_name) }

      google_category_id = product.taxons.first.try(:google_category_id) || 166 # Apparel & Accessories

      host = 'https://www.shopflowfashion.com' # ENV.fetch('APP_URL')
      link = [host, product.slug].join('/products/').split('&').first

      next unless product.slug

      data = {
        "id"                      => product.id,
        "title"                   => product.name,
        "description"             => product.description,
        "link"                    => link,
        "image link"              => 'https://flowcdn.io/assets/solidus' + product.images.first.attachment.url(:large),
        "availability"            => 'in stock',
        "price"                   => product.variants.first.flow_spree_price,
        "unit ​pricing measure"    => 'ct',
        "brand"                   => brand,
        "google product category" => google_category_id,
        "identifier exists"       => 'no',
        "condition"               => 'new',
        "adult"                   => 'no',
        "is bundle"               => 'no',
        "gender"                  => 'unisex',
        "shipping"                => 'US:::0.00 USD',
        "tax"                     => 'US::6.49:yes',
        "age group"               => 'adult',
        "condition"               => 'new',
        "identifier exists"       => 'yes',
      }

      csv.add data
    end

    data = csv.to_s

    csv_dir = Rails.root.join('tmp/csv').to_s
    Dir.mkdir(csv_dir) unless Dir.exists?(csv_dir)
    File.write("#{csv_dir}/google-merchant-#{Time.now.to_i}.csv", data)

    render plain: data
  end

  private

  def paypal_get_order_from_param
    order_number = params[:order]              || raise('Order parameter not defined')
    Spree::Order.find_by(number: order_number) || raise('Order not found')
  end

  def user_is_admin?
    return true if spree_current_user && spree_current_user.admin?

    render plain: 'You must be admin to access this action'

    false
  end
end