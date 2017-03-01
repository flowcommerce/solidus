# flow specific controller

class FlowController < ApplicationController

  # when products are updated in Flow catalog, event is trigered
  # this hook can capture all events and update products in catalog
  def handle_flow_web_hook_event

  end

end