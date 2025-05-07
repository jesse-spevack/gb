required_vars = %w[
  GOOGLE_CLIENT_ID
  GOOGLE_CLIENT_SECRET
  GOOGLE_API_KEY
]

missing_vars = required_vars.select { |var| ENV[var].blank? }

if missing_vars.any?
  Rails.logger.error("Missing Google API environment variables: #{missing_vars.join(", ")}")
end
