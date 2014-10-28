#
# Wraps addon plan data into a comparable class that can be returned by
# input plugins
#
class AddonPlan
  include Comparable

  attr_reader :data, :value_field

  def initialize(data, value_field = nil)
    @data = data
    @value_field = value_field
  end

  def <=>(anOther)
    return data[value_field] <=> anOther[value_field]
  end

  def [](key)
    return @data[key]
  end
end
