#
# Wraps addon plan data into a comparable class that can be returned by
# input plugins
#
class AddonPlan
  include Comparable

  attr_reader :data, :compare_field

  def initialize(data, compare_field = 'tier')
    @data = data
    @compare_field = compare_field
  end

  def <=>(anOther)
    return data[compare_field] <=> anOther[compare_field]
  end

  def [](key)
    return @data[key]
  end

  def to_s
    return data['name']
  end
end
