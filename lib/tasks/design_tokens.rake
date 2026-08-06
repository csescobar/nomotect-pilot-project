namespace :design_tokens do
  desc "Generate JSON, CSS and Ruby artifacts from the canonical YAML tokens"
  task generate: :environment do
    DesignTokens::Compiler.new.write!
  end

  desc "Fail when generated design token artifacts diverge from YAML"
  task check: :environment do
    next if DesignTokens::Compiler.new.current?

    abort "Generated design token artifacts are stale. Run design_tokens:generate."
  end
end
