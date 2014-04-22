
require 'spec_helper'
require 'dynosaur/ring_buffer'

describe RingBuffer do
  it "should only reach max size" do
    rb = RingBuffer.new(5)

    rb.length.should eql 0

    rb << 3
    rb << 4
    rb << 5
    rb << 5
    rb.length.should eql 4
    rb << 4
    rb.length.should eql 5
    rb.should include 3
    rb << 4
    rb.length.should eql 5

    rb.should_not include 3
  end

  it "should calculate the max ok" do
    # It inherits from array so this should be find
    rb = RingBuffer.new(5)

    rb << 3
    rb.max.should eql 3
    rb << 4
    rb.max.should eql 4
    rb << 5
    rb.max.should eql 5
    rb << 3
    rb.max.should eql 5

  end

end
