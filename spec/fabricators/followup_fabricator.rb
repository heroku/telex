Fabricator(:followup) do
  message_id { SecureRandom.uuid }
  body       { Faker::Company.bs }
end
