
CONTROLLER_IP=10.101.0.75
REMOTE_DIR='/tmp/metalware'

.PHONY: unit-test
unit-test:
	bundle exec rspec --exclude-pattern 'spec/integration/**/*'

.PHONY: test
test:
	bundle exec rspec

.PHONY: view-test-coverage
view-test-coverage:
	xdg-open coverage/index.html

.PHONY: rsync
rsync:
	rsync -r --copy-links --perms . dev@${CONTROLLER_IP}:${REMOTE_DIR}

.PHONY: watch-rsync
watch-rsync:
	rerun \
		--name 'Metalware' \
		--pattern '**/*' \
		--exit \
		make rsync

# Note: need to become root for Metalware; -t option allows coloured output.
.PHONY: remote-run
remote-run: rsync
	ssh -t dev@${CONTROLLER_IP} "sudo su - -c \"cd ${REMOTE_DIR} && ${COMMAND}\""
