class Rack::Attack
  throttle("requests/ip", limit: 300, period: 5.minutes) do |request|
    request.ip unless request.path == "/health" || request.path == "/up"
  end

  throttle("logins/ip", limit: 10, period: 5.minutes) do |request|
    request.ip if request.post? && request.path == "/session"
  end

  self.throttled_responder = lambda do |request|
    retry_after = request.env.fetch("rack.attack.match_data").fetch(:period)

    [
      429,
      { "content-type" => "application/json", "retry-after" => retry_after.to_s },
      [ { error: "rate_limited", request_id: request.request_id }.to_json ]
    ]
  end
end
