Fabricator(:user) do
  heroku_id { SecureRandom.uuid }
  email { Faker::Internet.email }
end
