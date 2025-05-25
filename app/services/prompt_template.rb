# frozen_string_literal: true

class PromptTemplate
  def self.build(template_file_name, input)
    new(template_file_name: template_file_name, input: input).render
  end

  attr_reader :template_path, :input

  def initialize(template_file_name:, input:)
    template_dir = Rails.root.join("app", "views", "prompts")
    @template_path = template_dir.join(template_file_name)
    @input = input
  end

  def render
    ERB.new(File.read(template_path), trim_mode: "-").result(binding)
  end
end
