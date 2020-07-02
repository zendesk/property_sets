# No delegated property_set
class Thing < ActiveRecord::Base
  property_set :settings do
    property :foo
  end
end
