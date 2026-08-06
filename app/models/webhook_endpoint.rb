class WebhookEndpoint < ApplicationRecord
  belongs_to :organization

  validates :url, :secret, presence: true
  validate :https_url

  def secret=(value)
    self[:secret] = value.present? ? encryptor.encrypt_and_sign(value) : nil
  end

  def secret
    encrypted = self[:secret]
    encrypted.present? ? encryptor.decrypt_and_verify(encrypted) : nil
  end

  def subscribes_to?(event_type)
    enabled? && events.include?(event_type)
  end

  private

  def encryptor
    key = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base).generate_key("webhook-endpoint-secret", 32)
    ActiveSupport::MessageEncryptor.new(key)
  end

  def https_url
    uri = URI.parse(url)
    errors.add(:url, :invalid) unless uri.is_a?(URI::HTTPS) && uri.host.present?
  rescue URI::InvalidURIError
    errors.add(:url, :invalid)
  end
end
