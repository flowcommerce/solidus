Spree::Product.class_eval do
  # Returns the option values for a given option type that are actually used
  # by this product's variants
  def active_option_values_for(option_type = nil)
    return [] unless option_type
    return [] unless has_variants?
    variants.includes(:option_values).
      order(:position).
      map { |variant| variant.option_values.where(option_type: option_type) }.
      flatten.
      compact.
      uniq
  end
end
