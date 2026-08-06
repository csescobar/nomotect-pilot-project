namespace :demo do
  desc "Seed the Service Desk demo data (development only)"
  task seed: :environment do
    report = DemoSeed.call
    puts JSON.pretty_generate(report)
  end
end

namespace :service_desk do
  desc "Run the Service Desk performance benchmark and write tmp/validation/service-desk-performance.json"
  task benchmark: :environment do
    report = ServiceDeskBenchmark.call
    puts "wrote tmp/validation/service-desk-performance.json"
    puts JSON.pretty_generate(report["measurements"])
  end
end
