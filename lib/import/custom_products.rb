# imports products from Custom CSV
# should parse this large files
# https://github.com/flowcommerce/catalog-scripts/tree/master
#
# example
# csv = CustomProductsImporter.new(csv_source)
# csv.get_row
# csv.get_uniq

require 'csv'
require 'awesome_print'

module Import
  class CustomProducts

    # source can be local or remote
    def initialize(csv_source)
      source   = uri?(csv_source) ? download_file(csv_source) : csv_source
      csv_data = File.read(source).encode('UTF-8', :invalid => :replace)
      @rows    = CSV.parse(csv_data)
      @row_names = {}
    end

    def count
      @rows.length
    end

    def get_row
      row = @rows.shift

      return nil unless row

      name = row[3].split(':', 2)

      product_name = trim(name.first.split('*').first)

      # if we dont have a neme, fetch next
      return get_row if product_name.blank?

      {
        name:         product_name,
        description:  trim(name[1]),
        id:           row[0],
        group_id:     row[1],
        category:     row[4],
        old_price:    row[6],
        price:        row[7],
        live_url:     row[10].split('?').first,
        image:        row[11],
        vendor:       row[17],
        size:         row[27],
        sex:          row[28],
      }
    end

    # avoid products with the same name
    def get_uniq
      row = get_row

      return nil unless row
      return get_uniq if @row_names[row[:name]]

      @row_names[row[:name]] = true

      row
    end

    private

    def uri?(string)
      string.downcase[0,4] == 'http'
    end

    def trim(data=nil)
      data.to_s.gsub(/^\s+|\s+$/,'')
    rescue
      nil
    end

    # prepare file for import, download it localy
    # if you dont delete cache, subsquencial downloads will be faster
    def download_file(url)
      csv_path = './tmp/_tmp_csv.txt'

      # curl if reliable downloader
      `wget -O '#{csv_path}' '#{url}'`

      csv_path
    end
  end
end
