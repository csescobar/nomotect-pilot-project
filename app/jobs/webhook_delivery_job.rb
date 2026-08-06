require "net/http"
require "openssl"
require "resolv"
require "ipaddr"

class WebhookDeliveryJob < ApplicationJob
  queue_as :default

  retry_on Net::OpenTimeout, Net::ReadTimeout, wait: :polynomially_longer, attempts: 5

  def perform(endpoint_id, event_type, payload)
    endpoint = WebhookEndpoint.find(endpoint_id)
    return unless endpoint.subscribes_to?(event_type)

    uri = URI.parse(endpoint.url)
    ensure_public_destination!(uri)
    body = JSON.generate(event: event_type, payload: payload)
    signature = OpenSSL::HMAC.hexdigest("SHA256", endpoint.secret, body)

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["User-Agent"] = "NomoTect-Webhooks"
    request["X-Platform-Event"] = event_type
    request["X-Platform-Signature"] = "sha256=#{signature}"
    request.body = body

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
      http.request(request)
    end
    raise "Webhook delivery failed with HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)
  end

  private

  def ensure_public_destination!(uri)
    raise ArgumentError, "HTTPS webhook URL required" unless uri.is_a?(URI::HTTPS) && uri.host.present?

    Resolv.getaddresses(uri.host).each do |address|
      ip = IPAddr.new(address)
      raise ArgumentError, "Private webhook destinations are not allowed" if ip.private? || ip.loopback? || ip.link_local?
    end
  end
end
