class InternalController < ApplicationController
  def healthcheck
    render plain: "healthy"
  end
end
