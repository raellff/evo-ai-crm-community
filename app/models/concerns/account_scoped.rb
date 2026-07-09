# frozen_string_literal: true

# Scopes a model to the current request's Account (see Current.account,
# set in EvoAuthConcern) and auto-stamps new records with it.
#
# Deliberately fails OPEN when Current.account is unset (background jobs,
# rake tasks, console) to avoid silently breaking every non-web code path
# that doesn't establish a tenant context today — see
# specs/multi-account-tenancy/04-architecture.md, Decision 9.
module AccountScoped
  extend ActiveSupport::Concern

  included do
    default_scope { Current.account ? where(account_id: Current.account.id) : all }

    before_validation :set_account_id_from_current, on: :create
  end

  private

  def set_account_id_from_current
    self.account_id ||= Current.account&.id
  end
end
