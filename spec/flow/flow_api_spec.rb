require 'spec_init'

RSpec.describe Flow do

  it 'checks that we can get session from flow' do
    sid = FlowExperience.get_flow_session_id
  end

end
