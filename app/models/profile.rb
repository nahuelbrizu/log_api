class Profile < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :display_name, length: { maximum: 100 }
  validates :location, length: { maximum: 100 }
  validates :bio, length: { maximum: 2000 }
end
