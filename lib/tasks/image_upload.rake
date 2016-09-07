require "faraday"
require "json"

namespace :example do
  desc "Upload product image"
  task upload_image: :environment do
    solidus_host = "http://flow-solidus.herokuapp.com"
    spree_api_token = "e0ec2c45ac07b731ad3196584378ca0fc7b012d6ab915730"
    # rest_path = "/api/products/1/images"  # For an image on a product's master variant
    rest_path = "/api/variants/10/images" # For an image on a particular variant

    image = File.dirname(__FILE__) + "/audrey.jpg"
    attachment = Faraday::UploadIO.new(image, "image/jpeg")

    connection = Faraday.new(
      url: solidus_host,
      params: { token: spree_api_token }
    ) do |f|
      f.request :multipart
      f.request :url_encoded
      f.adapter :httpclient
    end

    create_params = {
      image: {
        alt:        "Audrey",
        position:   0,
        attachment: attachment
      }
    }
    response = connection.post(rest_path, create_params)

    if response.status == 201
      puts "[SUCCESS] Created an image for a product."
      image = JSON.parse(response.body)
      # Undo! Undo! Undo!
      delete_response = connection.delete(rest_path + "/" + image["id"].to_s)
      if delete_response.status == 204
        puts "[SUCCESS] Deleted the image we just created."
      else
        puts "[FAILURE] Could not delete the image we just created (#{delete_response.status})"
      end
    else
      puts "[FAILURE] Could not create an image for a product (#{response.status})"
    end
  end
end
