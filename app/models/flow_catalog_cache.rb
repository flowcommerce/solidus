# stores cached data from flow.io
# uses sku and country as primary keys to access data

class FlowCatalogCache < ApplicationRecord

  class << self
    # country - string 3 chars
    # sku     - single sku or list
    def load_by_country_and_sku(country, sku)
      data = where(country: country, sku: sku).all

      # return single row if single row reqested
      return data[0].get_data unless sku.kind_of?(Array)

      data.inject({}) do |hash, row|
        hash[row[:sku]] = row.get_data
        hash
      end
    end
  end

  ###

  # unified access to important catalog stuff
  # put junk to db but allways access trough this proxt
  def get_data
     h = Hashie::Mash.new
     h[:amount]   = self[:data]['prices'][0]['amount']
     h[:currency] = self[:data]['prices'][0]['currency']
     h
  end

  # disable public access
  def data
    raise StandardError, 'Please use method "get_data" to get data from cache'
  end
end