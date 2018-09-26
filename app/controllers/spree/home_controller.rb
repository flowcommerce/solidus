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

    def not_found
      @title    = 'Page not found'
      response.status = 404

      render :not_found, formats: 'html'
    end

    def returns_and_refunds
      render :returns_and_refunds
    end
  end
end
