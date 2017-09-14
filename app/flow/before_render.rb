class ActionController::Base
  @@before_render ||= {}

  def self.before_render &block
    klass = self.to_s
    @@before_render[klass] ||= []
    @@before_render[klass].push block
  end

  # before render trigger
  # rails does not have before_render filter so we create it like this
  # to make things simple
  def render *args
    self.class.ancestors.each do |klass|
      filters = @@before_render[klass.to_s] || next
      filters.each do |filter|
        # do not run id render or redirect is called
        instance_exec &filter unless performed?
      end
    end

    # call native render unless redirect or render or redirect happend
    super unless performed?
  end
end