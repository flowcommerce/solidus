class FlowOtherController < ApplicationController

  def delete_address
    address = Spree::Address.find(params[:address_id])

    if address.lastname.include?('*')
      address.update_columns lastname: address.lastname.sub(' *', '')

      render plain: 'Address allready marked, restored'
    else
      # we have to mark record, because record is read only
      # and could break spree if deleted
      address.update_columns lastname: '%s *' % address.lastname

      render plain: 'Address marked as hidden'
    end
  end

end
