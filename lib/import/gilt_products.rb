# imports products from Gilt
# should parse this large files
# https://github.com/flowcommerce/catalog-scripts/tree/master/gilt
#
# example
# csv = GiltProductsImporter.new(csv_source)
# csv.get_row
# csv.get_uniq

require 'csv'
require 'awesome_print'

module Import
  class GiltProducts

    # source can be local or remote
    def initialize(csv_source)
      source = uri?(csv_source) ? download_file(csv_source) : csv_source
      @rows = CSV.parse File.read source
      @row_names = {}
    end

    def count
      @rows.length
    end

    def get_row
      row = @rows.shift

      # ap row; exit

      return nil unless row

      name = row[3].split(':', 2)
      {
        name:         trim(name.first.split('*').first),
        description:  trim(row[3].split(':', 2)[1]),
        uid:          row[1],
        vendor:       row[17],
        category:     row[14],
        image:        row[11],
        sex:          row[28],
        size:         row[29],
        price:        row[7],
        old_price:    row[6],
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

    def download_file(url)
      csv_path = './tmp/_tmp_csv.txt'

      # curl if reliable downloader
      `curl '#{url}' > '#{csv_path}'`

      csv_path
    end
  end
end
