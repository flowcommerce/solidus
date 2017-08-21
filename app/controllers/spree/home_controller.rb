module Spree
  class HomeController < Spree::StoreController
    helper 'spree/products'
    respond_to :html

    def index
      @title      = 'New arrivals'
      @searcher   = build_searcher(params.merge(include_images: true))
      @products   = @searcher.retrieve_products
      @taxonomies = Spree::Taxonomy.includes(root: :children)
    end

    # to add items to sale, just define meta_keywords field to sale
    def sale
      @title    = 'Sale'
      @products = Product.where(meta_keywords: 'sale')

      render :index
    end
  end
end
