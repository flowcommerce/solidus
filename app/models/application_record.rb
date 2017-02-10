# base class for all custom rails models

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # add time stamps if possible to all records
  before_save do
    self[:created_at] ||= Time.now if respond_to?(:created_at)
    self[:updated_at]   = Time.now if respond_to?(:updated_at)
  end
end
