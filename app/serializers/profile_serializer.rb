class ProfileSerializer
  def self.call(profile)
    {
      id: profile.id,
      user_id: profile.user_id,
      display_name: profile.display_name,
      location: profile.location,
      bio: profile.bio,
      created_at: profile.created_at,
      updated_at: profile.updated_at
    }
  end
end
