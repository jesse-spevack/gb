require "json"

# Load secrets directly from Kamal
begin
  secrets_output = `kamal secrets print`

  secrets_json_str = secrets_output.lines.find { |line| line.start_with?("SECRETS=") }&.split("=", 2)&.last

  if secrets_json_str
    # Remove escaping to parse JSON properly
    secrets_json_clean = secrets_json_str.gsub("\\", "")

    secrets = JSON.parse(secrets_json_clean)

    # Map with full paths as seen in the secrets output
    ENV["GOOGLE_CLIENT_ID"] = secrets["keys/gb/add more/GOOGLE_CLIENT_ID"] if secrets["keys/gb/add more/GOOGLE_CLIENT_ID"]
    ENV["GOOGLE_CLIENT_SECRET"] = secrets["keys/gb/add more/GOOGLE_CLIENT_SECRET"] if secrets["keys/gb/add more/GOOGLE_CLIENT_SECRET"]
    ENV["GOOGLE_AI_KEY"] = secrets["keys/gb/add more/GOOGLE_AI_KEY"] if secrets["keys/gb/add more/GOOGLE_AI_KEY"]
    ENV["GOOGLE_API_KEY"] = secrets["keys/gb/add more/GOOGLE_API_KEY"] if secrets["keys/gb/add more/GOOGLE_API_KEY"]

    ENV["ANTHROPIC_API_KEY"] = secrets["keys/gb/add more/ANTHROPIC_API_KEY"] if secrets["keys/gb/add more/ANTHROPIC_API_KEY"]

    all_google_vars_loaded = ENV["GOOGLE_CLIENT_ID"] && ENV["GOOGLE_CLIENT_SECRET"] && ENV["GOOGLE_API_KEY"]
    raise "Missing Google API credentials" unless all_google_vars_loaded
  end
end
