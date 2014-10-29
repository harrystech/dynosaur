#
# Wraps addon plan data into a comparable class that can be returned by
# input plugins
#
class AddonPlan
  include Comparable

  attr_reader :data, :compar_field

  def initialize(data, compar_field = 'tier')
    @data = data
    @compar_field = compar_field
  end

  def <=>(anOther)
    return data[compar_field] <=> anOther[compar_field]
  end

  def [](key)
    return @data[key]
  end

  def to_s
    return data['name']
  end
end
