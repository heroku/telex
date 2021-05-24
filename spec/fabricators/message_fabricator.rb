Fabricator(:message) do
  producer
  target_type { "user" }
  target_id { SecureRandom.uuid }
  title { Faker::Company.bs }
  body { Faker::Company.bs }
end
