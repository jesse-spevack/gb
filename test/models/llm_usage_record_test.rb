require "test_helper"

class LLMUsageRecordTest < ActiveSupport::TestCase
  test "it should be valid with valid attributes" do
    llm_usage_record = LLMUsageRecord.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm_provider: :google,
      llm_model: "gemini-2.0-flash-lite",
      request_type: :generate_rubric,
      token_count: 100,
      micro_usd: 100
    )
    assert llm_usage_record.valid?
  end

  test "it should be valid with zero token count and cost" do
    llm_usage_record = LLMUsageRecord.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm_provider: :google,
      llm_model: "gemini-2.0-flash-lite",
      request_type: :generate_rubric,
      token_count: 0,
      micro_usd: 0
    )
    assert llm_usage_record.valid?
  end

  test "it should not be valid without a trackable" do
    llm_usage_record = LLMUsageRecord.new(
      trackable: nil,
      user: users(:teacher),
      llm_provider: :google,
      llm_model: "gemini-2.0-flash-lite",
      request_type: :generate_rubric,
      token_count: 100,
      micro_usd: 100
    )
    assert_not llm_usage_record.valid?
  end

  test "it should not be valid without a user" do
    llm_usage_record = LLMUsageRecord.new(
      trackable: assignments(:english_essay),
      user: nil,
      llm_provider: :google,
      llm_model: "gemini-2.0-flash-lite",
      request_type: :generate_rubric,
      token_count: 100,
      micro_usd: 100
    )
    assert_not llm_usage_record.valid?
  end

  test "it should not be valid without an llm_provider" do
    llm_usage_record = LLMUsageRecord.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm_provider: nil,
      llm_model: "gemini-2.0-flash-lite",
      request_type: :generate_rubric,
      token_count: 100,
      micro_usd: 100
    )
    assert_not llm_usage_record.valid?
  end

  test "it should not be valid without an llm_model" do
    llm_usage_record = LLMUsageRecord.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm_provider: :google,
      llm_model: nil,
      request_type: :generate_rubric,
      token_count: 100,
      micro_usd: 100
    )
    assert_not llm_usage_record.valid?
  end

  test "it should not be valid without a request type" do
    llm_usage_record = LLMUsageRecord.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm_provider: :google,
      llm_model: "gemini-2.0-flash-lite",
      request_type: nil,
      token_count: 100,
      micro_usd: 100
    )
    assert_not llm_usage_record.valid?
  end

  test "it should not be valid without a token count" do
    llm_usage_record = LLMUsageRecord.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm_provider: :google,
      llm_model: "gemini-2.0-flash-lite",
      request_type: :generate_rubric,
      token_count: nil,
      micro_usd: 100
    )
    assert_not llm_usage_record.valid?, llm_usage_record.errors.full_messages
  end

  test "it should not be valid without a micro usd" do
    llm_usage_record = LLMUsageRecord.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm_provider: :google,
      llm_model: "gemini-2.0-flash-lite",
      request_type: :generate_rubric,
      token_count: 100,
      micro_usd: nil
    )
    assert_not llm_usage_record.valid?
  end

  test "it should not be valid with negative token count" do
    llm_usage_record = LLMUsageRecord.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm_provider: :google,
      llm_model: "gemini-2.0-flash-lite",
      request_type: :generate_rubric,
      token_count: -1,
      micro_usd: 100
    )
    assert_not llm_usage_record.valid?
  end

  test "it should not be valid with negative micro usd" do
    llm_usage_record = LLMUsageRecord.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm_provider: :google,
      llm_model: "gemini-2.0-flash-lite",
      request_type: :generate_rubric,
      token_count: 100,
      micro_usd: -1
    )
    assert_not llm_usage_record.valid?
  end

  test "dollars should return the price in dollars" do
    llm_usage_record = LLMUsageRecord.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm_provider: :google,
      llm_model: "gemini-2.0-flash-lite",
      request_type: :generate_rubric,
      token_count: 100,
      micro_usd: 100
    )
    assert_equal 0.0001, llm_usage_record.dollars
  end

  test "dollars should return zero for zero micro_usd" do
    llm_usage_record = LLMUsageRecord.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm_provider: :google,
      llm_model: "gemini-2.0-flash-lite",
      request_type: :generate_rubric,
      token_count: 0,
      micro_usd: 0
    )
    assert_equal 0.0, llm_usage_record.dollars
  end

  test "supports anthropic provider" do
    llm_usage_record = LLMUsageRecord.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm_provider: :anthropic,
      llm_model: "claude-3-5-haiku-20241022",
      request_type: :generate_rubric,
      token_count: 100,
      micro_usd: 100
    )
    assert llm_usage_record.valid?
    assert_equal "anthropic", llm_usage_record.llm_provider
  end

  test "supports google provider" do
    llm_usage_record = LLMUsageRecord.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm_provider: :google,
      llm_model: "gemini-2.0-flash-lite",
      request_type: :generate_rubric,
      token_count: 100,
      micro_usd: 100
    )
    assert llm_usage_record.valid?
    assert_equal "google", llm_usage_record.llm_provider
  end
end
