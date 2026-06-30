Gem::Specification.new do |spec|
  spec.name          = "cerebras"
  spec.version       = "0.1.0"
  spec.authors       = ["Airton Ponce @ton-anywhere"]
  spec.email         = ["ponceairton@gmail.com"]
  spec.summary       = "Ruby SDK for Cerebras AI"
  spec.description   = "Early / alpha release of a Ruby client for the Cerebras AI inference API. Built for a hackathon project. Not intended for production use."
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", ">= 2.0"
  spec.add_dependency "faraday-retry", ">= 2.0"
end
