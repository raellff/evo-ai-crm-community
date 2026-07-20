# frozen_string_literal: true

# == Schema Information
#
# Table name: accounts
#
#  id                :uuid             not null, primary key
#  name              :string           not null
#  subdomain         :string           not null
#  support_email     :string
#  locale            :string           default("pt-BR")
#  status            :string           default("active")
#  settings          :jsonb
#  custom_attributes :jsonb
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class Account < ApplicationRecord
  # Evolution Reference Model - managed by evo-auth-service
  # This model serves only as a reference to sync data from evo-auth-service
  include Featurable

  has_many :conversations, dependent: :nullify
  has_many :contacts, dependent: :nullify
  has_many :inboxes, dependent: :nullify
  has_many :messages, dependent: :nullify
  has_many :labels, dependent: :nullify
  has_many :teams, dependent: :nullify
  has_many :agent_bots, dependent: :nullify
  has_many :pipelines, dependent: :nullify
end
