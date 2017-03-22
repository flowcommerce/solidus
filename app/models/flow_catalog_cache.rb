# stores cached data from flow.io
# uses sku and country as primary keys to access data

class FlowCatalogCache < ApplicationRecord

  class << self
    # country - string 3 chars
    # sku     - single sku or list
    def load_by_country_and_sku(country, sku)
      raise ArgumentError, 'SKU is not a string' unless sku.is_a?(String)

      # so we can send experience object
      country = country.country if country.respond_to?(:country)
      country = country.downcase

      raise ArgumentError, 'country "%s" has to have exactly 3 characters' % country if country.length != 3

      # sku and country has to be in downcase
      sku = sku.kind_of?(Array) ? sku.map(&:downcase) : sku.downcase
      cache = find_or_initialize_by(country: country, sku: sku)

      # localized product not found in cache, get it
      unless cache.id
        item = FlowRoot.api(:get, '/:organization/experiences/items', country: country, number: sku).first
        cache.data = item
        cache.save
      end

      cache.get_data
    end

    def update_price_by_country_and_sku(country:, sku:, price:)
      # so we can send experience object
      country = country.country if country.respond_to?(:country)

      cached_product = find_by sku: sku.downcase, country: country.downcase
      return unless cached_product

      # we update only price and I think this is only thing we should cache from floe wast data
      # when all goes well with checkout, I will fix this model to use only needed data
      root = cached_product.data['prices'] || cached_product.data['local']['prices']
      root[0]['amount'] = price
      cached_product.save!
    end
  end

  ###

  # unified access to important catalog stuff
  # put junk to db but allways access trough this proxt
  def get_data
     h = Hashie::Mash.new
     root = data['prices'] || data['local']['prices']
     h[:amount]   = root[0]['amount']
     h[:currency] = root[0]['currency']
     h
  end

  # disable public access
  # not possible for some reason in AR??? it touches data method on object load
  # def data
  #   raise StandardError, 'Please use method "get_data" to get data from cache'
  # end
end