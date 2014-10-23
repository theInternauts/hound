# Load and parse config files from GitHub repo
class RepoConfig
  FILE_TYPES = {
    ".yml" => "yaml",
    ".json" => "json",
  }
  HOUND_CONFIG_FILE = ".hound.yml"
  STYLE_GUIDES = %w(ruby coffee_script java_script)

  attr_reader :errors

  def initialize(commit)
    @commit = commit
    @errors = []
  end

  def enabled_for?(style_guide_name)
    style_guide_name == "ruby" && legacy_config? ||
      enabled_in_config?(style_guide_name)
  end

  def for(style_guide_name)
    if style_guide_name == "ruby" && legacy_config?
      hound_config
    else
      config_file_path = config_path_for(style_guide_name)

      if config_file_path
        load_file(config_file_path)
      else
        {}
      end
    end
  end

  def validate
    errors.clear
    validate_style_guide_configs
  end

  private

  attr_reader :commit

  def enabled_in_config?(name)
    config = hound_config[name] || hound_config[name.camelize]
    config && (config["enabled"] == true || config["Enabled"] == true)
  end

  def legacy_config?
    (hound_config.keys & STYLE_GUIDES).empty?
  end

  def hound_config
    @hound_config ||= begin
      content = load_file(HOUND_CONFIG_FILE)
      if content.is_a?(Hash)
        content
      else
        {}
      end
    end
  end

  def config_path_for(style_guide_name)
    hound_config[style_guide_name] &&
      hound_config[style_guide_name]["config_file"]
  end

  def load_file(file_path)
    config_file_content = commit.file_content(file_path)
    extension = File.extname(file_path)

    if config_file_content.present?
      send("parse_#{FILE_TYPES[extension]}", config_file_content)
    else
      {}
    end
  end

  def parse_yaml(content, error_callback = {})
    YAML.load(content)
  rescue Psych::SyntaxError
    error_callback
  end

  def parse_json(content, error_callback = {})
    JSON.parse(content)
  rescue JSON::ParserError
    error_callback
  end

  def validate_style_guide_configs
    STYLE_GUIDES.each do |style_guide|
      file_path = config_path_for(style_guide)
      debugger
      config_file_content = commit.file_content(file_path)
      extension = File.extname(file_path)

      if config_file_content.present?
        send(
          "parse_#{FILE_TYPES[extension]}",
          config_file_content,
          add_config_error(style_guide)
        )
      end
    end
  end

  def add_config_error(style_guide)
    errors < I18n.t("invalid_config", language: style_guide)
  end
end
