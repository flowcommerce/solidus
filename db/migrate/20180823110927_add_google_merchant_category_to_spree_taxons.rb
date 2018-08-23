class AddGoogleMerchantCategoryToSpreeTaxons < ActiveRecord::Migration[5.1]
  def change
    add_column :spree_taxons, :google_category_id, :integer
  end
end
