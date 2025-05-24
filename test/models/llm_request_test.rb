require "test_helper"

class LLMRequestTest < ActiveSupport::TestCase
  test "it should be valid with valid attributes" do
    llm_request = LLMRequest.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm: :gemini_2_5_pro,
      request_type: :generate_rubric,
      token_count: 100,
      micro_usd: 100,
      prompt: "Generate a rubric for the assignment"
    )
    assert llm_request.valid?
  end

  test "it should be valid with zero token count and cost" do
    llm_request = LLMRequest.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm: :gemini_2_5_pro,
      request_type: :generate_rubric,
      token_count: 0,
      micro_usd: 0,
      prompt: "Generate a rubric for the assignment"
    )
    assert llm_request.valid?
  end

  test "it should not be valid without a trackable" do
    llm_request = LLMRequest.new(
      trackable: nil,
      user: users(:teacher),
      llm: :gemini_2_5_pro,
      request_type: :generate_rubric,
      token_count: 100,
      micro_usd: 100,
      prompt: "Generate a rubric for the assignment"
    )
    assert_not llm_request.valid?
  end

  test "it should not be valid without a user" do
    llm_request = LLMRequest.new(
      trackable: assignments(:english_essay),
      user: nil,
      llm: :gemini_2_5_pro,
      request_type: :generate_rubric,
      token_count: 100,
      micro_usd: 100,
      prompt: "Generate a rubric for the assignment"
    )
    assert_not llm_request.valid?
  end

  test "it should not be valid without an llm" do
    llm_request = LLMRequest.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm: nil,
      request_type: :generate_rubric,
      token_count: 100,
      micro_usd: 100,
      prompt: "Generate a rubric for the assignment"
    )
    assert_not llm_request.valid?
  end

  test "it should not be valid without a request type" do
    llm_request = LLMRequest.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm: :gemini_2_5_pro,
      request_type: nil,
      token_count: 100,
      micro_usd: 100,
      prompt: "Generate a rubric for the assignment"
    )
    assert_not llm_request.valid?
  end

  test "it should not be valid without a token count" do
    llm_request = LLMRequest.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm: :gemini_2_5_pro,
      request_type: :generate_rubric,
      token_count: nil,
      micro_usd: 100,
      prompt: "Generate a rubric for the assignment"
    )
    assert_not llm_request.valid?, llm_request.errors.full_messages
  end

  test "it should not be valid without a micro usd" do
    llm_request = LLMRequest.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm: :gemini_2_5_pro,
      request_type: :generate_rubric,
      token_count: 100,
      micro_usd: nil,
      prompt: "Generate a rubric for the assignment"
    )
    assert_not llm_request.valid?
  end

  test "it should not be valid without a prompt" do
    llm_request = LLMRequest.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm: :gemini_2_5_pro,
      request_type: :generate_rubric,
      token_count: 100,
      micro_usd: 100,
      prompt: nil
    )
    assert_not llm_request.valid?
  end

  test "it should not be valid with negative token count" do
    llm_request = LLMRequest.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm: :gemini_2_5_pro,
      request_type: :generate_rubric,
      token_count: -1,
      micro_usd: 100,
      prompt: "Generate a rubric for the assignment"
    )
    assert_not llm_request.valid?
  end

  test "it should not be valid with negative micro usd" do
    llm_request = LLMRequest.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm: :gemini_2_5_pro,
      request_type: :generate_rubric,
      token_count: 100,
      micro_usd: -1,
      prompt: "Generate a rubric for the assignment"
    )
    assert_not llm_request.valid?
  end

  test "dollars should return the price in dollars" do
    llm_request = LLMRequest.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm: :gemini_2_5_pro,
      request_type: :generate_rubric,
      token_count: 100,
      micro_usd: 100,
      prompt: "Generate a rubric for the assignment"
    )
    assert_equal 0.0001, llm_request.dollars
  end

  test "dollars should return zero for zero micro_usd" do
    llm_request = LLMRequest.new(
      trackable: assignments(:english_essay),
      user: users(:teacher),
      llm: :gemini_2_5_pro,
      request_type: :generate_rubric,
      token_count: 0,
      micro_usd: 0,
      prompt: "Generate a rubric for the assignment"
    )
    assert_equal 0.0, llm_request.dollars
  end
end
