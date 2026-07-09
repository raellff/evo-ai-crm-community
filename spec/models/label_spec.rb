# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Label, type: :model do
  describe 'associations' do
    it { should belong_to(:account).optional(true) }
  end
end
