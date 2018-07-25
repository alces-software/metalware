
REMOTE_DIR='/tmp/metalware'

.PHONY: unit-test
unit-test:
	bundle exec rspec \
		--force-colour \
		--exclude-pattern 'spec/slow/**/*, spec/integration/**/*'

.PHONY: test
test:
	bundle exec rspec --force-colour

.PHONY: view-test-coverage
view-test-coverage:
	xdg-open coverage/index.html

.PHONY: rsync
rsync:
	rsync \
		-r \
		--copy-links \
		--delete \
		--exclude tmp/ \
		--exclude .git/ \
		--exclude coverage/ \
		--exclude vendor/ \
		--exclude .bundle/ \
		--perms \
		. root@${IP}:${REMOTE_DIR}

.PHONY: watch-rsync
watch-rsync:
	rerun \
		--name 'Metalware' \
		--pattern '**/*' \
		--exit \
		--no-notify \
		make rsync

# Note: need to become root for Metalware; -t option allows coloured output.
.PHONY: remote-run
remote-run: rsync
	ssh -t dev@${IP} "sudo su - -c \"cd ${REMOTE_DIR} && ${COMMAND}\""

.PHONY: rubocop
rubocop:
	bundle exec rubocop --parallel --display-cop-names --display-style-guide --color

# Fix Rubocop issues, where possible.
.PHONY: rubocop-fix
rubocop-fix:
	bundle exec rubocop --display-cop-names --display-style-guide --color --auto-correct

# Start Pry console, loading main CLI entry point (so all CLI files should be
# loaded) and all files in `spec` dir.
.PHONY: console
console:
	bundle exec pry --exec 'require_relative "src/cli"; require "rspec"; $$LOAD_PATH.unshift "spec"; Dir["#{File.dirname(__FILE__)}/spec/**/*.rb"].map { |f| require(f) }; nil'
