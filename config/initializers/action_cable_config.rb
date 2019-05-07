module ActionCableConfig
  def self.[](key)
    unless @config
      template = ERB.new(File.read(Rails.root + 'config/cable.yml'))
      raw_config = template.result(binding)
      @config = YAML.load(raw_config)[Rails.env].symbolize_keys
    end
    @config[key]
  end

  def self.[]=(key, value)
    @config[key.to_sym] = value
  end
end
