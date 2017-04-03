class Permission < ApplicationRecord
  belongs_to :device
  belongs_to :permissible, polymorphic: true

  before_create { |p| p.privilege = :last_only }

  enum privilege: %i(disallowed last_only complete)

  def self.not_coposition_developers
    keys = [Rails.application.secrets["coposition_api_key"], Rails.application.secrets["mobile_app_api_key"]]
    copo_dev_ids = Developer.where(api_key: keys).select(:id)
    Permission.where.not(["permissible_type = ? AND permissible_id IN (?)", "Developer", copo_dev_ids])
  end
end
