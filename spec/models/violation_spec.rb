require 'spec_helper'

describe Violation do
  it { should belong_to(:build) }
end
