# frozen_string_literal: true

require_relative "lib/websocket_client_lite/version"

Gem::Specification.new do |spec|
  spec.name = "websocket_client_lite"
  spec.version = WebsocketClientLite::VERSION
  spec.authors = ["Ueda Satoshi"]
  spec.email = ["gunyoki@gmail.com"]

  spec.summary = "Easy to use WebSocket client"
  spec.description = "It works as a WebSocket client by simply implementing a block that handles messages."
  spec.homepage = "https://github.com/gunyoki/websocket_client_lite"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/gunyoki/websocket_client_lite"
  spec.metadata["changelog_uri"] = "https://github.com/gunyoki/websocket_client_lite/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "websocket"
end
