# frozen_string_literal: true

require 'rails_helper'

# Inbox visibility is permission-driven: "see everything" comes only from the
# admin role or the conversations.read_all grant (resolved per request into
# Current). The historical zero-membership fallback (no inbox_member => all
# inboxes) is gone — it made revoking conversations.read_all unenforceable for
# users with no memberships, which is the common state on real installs.
RSpec.describe User, '#assigned_inboxes' do
  let(:user) { User.create!(name: 'Scoped', email: "scoped-#{SecureRandom.hex(4)}@example.com") }
  let!(:inbox_a) { Inbox.create!(name: "A #{SecureRandom.hex(3)}", channel: Channel::Api.create!) }
  let!(:inbox_b) { Inbox.create!(name: "B #{SecureRandom.hex(3)}", channel: Channel::Api.create!) }

  after { Current.reset }

  it 'returns NO inboxes for a user with no memberships and no read_all grant' do
    Current.evo_can_read_all_inboxes = false

    expect(user.assigned_inboxes).to be_empty
  end

  it 'returns no inboxes outside a request context (flag nil) without memberships' do
    Current.evo_can_read_all_inboxes = nil

    expect(user.assigned_inboxes).to be_empty
  end

  it 'returns only the assigned inboxes for a member' do
    InboxMember.create!(user: user, inbox: inbox_a)
    Current.evo_can_read_all_inboxes = false

    expect(user.assigned_inboxes).to contain_exactly(inbox_a)
  end

  it 'returns all inboxes for a holder of conversations.read_all' do
    Current.evo_can_read_all_inboxes = true

    expect(user.assigned_inboxes).to include(inbox_a, inbox_b)
  end

  it 'returns all inboxes for an administrator role' do
    Current.evo_role_key = 'administrator'
    Current.evo_can_read_all_inboxes = false

    expect(user.assigned_inboxes).to include(inbox_a, inbox_b)
  end
end
