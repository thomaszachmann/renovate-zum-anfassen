# Werkzeuge für Doku- und API-Checks (Version hier pflegen, nicht im CI-Job)
# renovate: datasource=npm depName=markdownlint-cli2
MARKDOWNLINT_VERSION ?= 0.10.0
# renovate: datasource=npm depName=@redocly/cli
REDOCLY_VERSION ?= 1.0.0

lint:
	npx --yes markdownlint-cli2@$(MARKDOWNLINT_VERSION) "**/*.md"
	npx --yes @redocly/cli@$(REDOCLY_VERSION) lint openapi.yaml
