class Campaign < ApplicationRecord
  # `campaigns.type` is a plain string column (not STI). Disable AR's
  # automatic single-table inheritance lookup so `find_by(id:)` works
  # regardless of the row's `type` value. If a future story introduces
  # real STI (OngoingCampaign / OneOffCampaign), revert this line and
  # update the EvoFlow enrich path that depends on Campaign.find_by.
  self.inheritance_column = nil

  default_scope { where(deleted_at: nil) }
end
