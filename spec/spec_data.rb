shipping_category = Spree::ShippingCategory.create! name:'Wolly mamoth on skates'

first_product = Spree::Product.create! name:'Car', price:'99', shipping_category_id: shipping_category.id