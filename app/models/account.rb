# frozen_string_literal: true

# == Schema Information
#
# Table name: accounts
#
#  id                :uuid             not null, primary key
#  custom_attributes :jsonb
#  locale            :string           default("pt-BR")
#  name              :string           not null
#  settings          :jsonb
#  status            :string           default("active")
#  subdomain         :string           not null
#  support_email     :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_accounts_on_status     (status)
#  index_accounts_on_subdomain  (subdomain) UNIQUE
#
class Account < ApplicationRecord
  # Evolution Reference Model - managed by evo-auth-service
  # This model serves only as a reference to sync data from evo-auth-service
  
  has_many :conversations, dependent: :nullify
  has_many :contacts, dependent: :nullify
  has_many :inboxes, dependent: :nullify
  has_many :messages, dependent: :nullify
  has_many :labels, dependent: :nullify
  has_many :teams, dependent: :nullify
  has_many :agent_bots, dependent: :nullify
end
