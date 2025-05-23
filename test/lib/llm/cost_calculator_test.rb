require "test_helper"

class LLM::CostCalculatorTest < ActiveSupport::TestCase
  test "calculates cost for Claude Opus 4" do
    response = LLMResponse.new(
      text: "Test response",
      input_tokens: 1000,
      output_tokens: 500,
      model: "claude-opus-4-20250514"
    )

    # Expected: (1000 * 15.00 + 500 * 75.00) / 1,000,000 * 1,000,000 = 52500 micro_usd
    expected_cost = 52500
    actual_cost = LLM::CostCalculator.get_cost(response)

    assert_equal expected_cost, actual_cost
  end

  test "calculates cost for Claude Sonnet 4" do
    response = LLMResponse.new(
      text: "Test response",
      input_tokens: 1000,
      output_tokens: 500,
      model: "claude-sonnet-4-20250514"
    )

    # Expected: (1000 * 3.00 + 500 * 15.00) / 1,000,000 * 1,000,000 = 10500 micro_usd
    expected_cost = 10500
    actual_cost = LLM::CostCalculator.get_cost(response)

    assert_equal expected_cost, actual_cost
  end

  test "calculates cost for Claude 3.5 Haiku" do
    response = LLMResponse.new(
      text: "Test response",
      input_tokens: 1000,
      output_tokens: 500,
      model: "claude-3-5-haiku-20241022"
    )

    # Expected: (1000 * 0.80 + 500 * 4.00) / 1,000,000 * 1,000,000 = 2800 micro_usd
    expected_cost = 2800
    actual_cost = LLM::CostCalculator.get_cost(response)

    assert_equal expected_cost, actual_cost
  end

  test "calculates cost for Claude Sonnet 3.7" do
    response = LLMResponse.new(
      text: "Test response",
      input_tokens: 1000,
      output_tokens: 500,
      model: "claude-3-7-sonnet-20250219"
    )

    # Expected: (1000 * 3.00 + 500 * 15.00) / 1,000,000 * 1,000,000 = 10500 micro_usd
    expected_cost = 10500
    actual_cost = LLM::CostCalculator.get_cost(response)

    assert_equal expected_cost, actual_cost
  end

  test "calculates cost for Claude 3.5 Sonnet" do
    response = LLMResponse.new(
      text: "Test response",
      input_tokens: 1000,
      output_tokens: 500,
      model: "claude-3-5-sonnet-20241022"
    )

    # Expected: (1000 * 3.00 + 500 * 15.00) / 1,000,000 * 1,000,000 = 10500 micro_usd
    expected_cost = 10500
    actual_cost = LLM::CostCalculator.get_cost(response)

    assert_equal expected_cost, actual_cost
  end

  test "calculates cost for Gemini 2.5 Flash Preview" do
    response = LLMResponse.new(
      text: "Test response",
      input_tokens: 1000,
      output_tokens: 500,
      model: "gemini-2.5-flash-preview"
    )

    # Expected: (1000 * 0.15 + 500 * 0.60) / 1,000,000 * 1,000,000 = 450 micro_usd
    expected_cost = 450
    actual_cost = LLM::CostCalculator.get_cost(response)

    assert_equal expected_cost, actual_cost
  end

  test "calculates cost for Gemini 2.5 Pro Preview" do
    response = LLMResponse.new(
      text: "Test response",
      input_tokens: 1000,
      output_tokens: 500,
      model: "gemini-2.5-pro-preview"
    )

    # Expected: (1000 * 1.25 + 500 * 10.00) / 1,000,000 * 1,000,000 = 6250 micro_usd
    expected_cost = 6250
    actual_cost = LLM::CostCalculator.get_cost(response)

    assert_equal expected_cost, actual_cost
  end

  test "calculates cost for Gemini 2.0 Flash" do
    response = LLMResponse.new(
      text: "Test response",
      input_tokens: 1000,
      output_tokens: 500,
      model: "gemini-2.0-flash"
    )

    # Expected: (1000 * 0.10 + 500 * 0.40) / 1,000,000 * 1,000,000 = 300 micro_usd
    expected_cost = 300
    actual_cost = LLM::CostCalculator.get_cost(response)

    assert_equal expected_cost, actual_cost
  end

  test "calculates cost for Gemini 2.0 Flash-Lite" do
    response = LLMResponse.new(
      text: "Test response",
      input_tokens: 1000,
      output_tokens: 500,
      model: "gemini-2.0-flash-lite"
    )

    # Expected: (1000 * 0.075 + 500 * 0.30) / 1,000,000 * 1,000,000 = 225 micro_usd
    expected_cost = 225
    actual_cost = LLM::CostCalculator.get_cost(response)

    assert_equal expected_cost, actual_cost
  end

  test "calculates cost for Gemini 2.5 Flash (Preview)" do
    response = LLMResponse.new(
      text: "Test response",
      input_tokens: 1000,
      output_tokens: 500,
      model: "gemini-2.5-flash-preview-04-17"
    )

    # Expected: (1000 * 0.15 + 500 * 0.60) / 1,000,000 * 1,000,000 = 450 micro_usd
    expected_cost = 450
    actual_cost = LLM::CostCalculator.get_cost(response)

    assert_equal expected_cost, actual_cost
  end

  test "handles zero tokens" do
    response = LLMResponse.new(
      text: "Test response",
      input_tokens: 0,
      output_tokens: 0,
      model: "claude-3-5-haiku-20241022"
    )

    actual_cost = LLM::CostCalculator.get_cost(response)

    assert_equal 0, actual_cost
  end

  test "handles nil tokens" do
    response = LLMResponse.new(
      text: "Test response",
      input_tokens: nil,
      output_tokens: nil,
      model: "claude-3-5-haiku-20241022"
    )

    actual_cost = LLM::CostCalculator.get_cost(response)

    assert_equal 0, actual_cost
  end

  test "handles large token counts" do
    response = LLMResponse.new(
      text: "Test response",
      input_tokens: 1_000_000,
      output_tokens: 500_000,
      model: "claude-3-5-haiku-20241022"
    )

    # Expected: (1,000,000 * 0.80 + 500,000 * 4.00) = 2,800,000 micro_usd
    expected_cost = 2_800_000
    actual_cost = LLM::CostCalculator.get_cost(response)

    assert_equal expected_cost, actual_cost
  end

  test "raises error for unknown model" do
    response = LLMResponse.new(
      text: "Test response",
      input_tokens: 1000,
      output_tokens: 500,
      model: "unknown-model"
    )

    error = assert_raises(LLM::CostCalculator::UnknownModelError) do
      LLM::CostCalculator.get_cost(response)
    end

    assert_includes error.message, "unknown-model"
  end

  test "raises error for nil model" do
    response = LLMResponse.new(
      text: "Test response",
      input_tokens: 1000,
      output_tokens: 500,
      model: nil
    )

    error = assert_raises(LLM::CostCalculator::UnknownModelError) do
      LLM::CostCalculator.get_cost(response)
    end

    assert_includes error.message, "Model cannot be nil"
  end
end
