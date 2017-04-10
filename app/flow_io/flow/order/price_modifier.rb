# Flow.io (2017)

# Order price modifier is a rule that can be applied on final total price
#
# example
# can = Flow::Order::PriceModifier.new(name: 'Canadians 10% off')
# can.set_check do |flow_order|
#   if flow_order.experience.key == 'canada'
#     total_diff = - (flow_order.total * 0.1)
#   end
# end
# Flow::Order::PriceModifier.add(can)

class Flow::Order::PriceModifier
  attr_accessor :total_diff

  @@modifiers = []

  class << self
    def add object
      @@modifiers.push object
    end
  end

  ###

  def initialize name:
    @name = name
    @total_diff = 0
  end

  def set_check &block
    @check = block
  end

end