require 'rails_helper'

RSpec.describe Near::Chain do
  let!(:chains) { create_list(:near_chain, 3, primary: true) }
  include_examples "is primary scoped"
end
