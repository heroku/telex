Fabricator(:available_team_notification) do
  team_manager_email { Faker::Internet.email }
  team_notification_email { Faker::Internet.email }
end
