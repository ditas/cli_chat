.PHONY: help release run test fmt lint docs docs-open clean

CURR_DIR = ${PWD}

.DEFAULT_GOAL := help
help:
	@echo "--------------------------------------------------------------------"
	@echo "Use 'make <target>' where <target> is one of:"
	@echo "--------------------------------------------------------------------"
	@echo "  release        : make prod release"
	@echo "  run            : run dev server"
	@echo "  fmt            : run auto-formatters"
	@echo "  lint           : run linters"
	@echo "  docs           : generate docs"
	@echo "  docs-open      : generate docs and open result in the browser"
	@echo "  clean          : remove artifacts"

release:
	MIX_ENV=prod mix escript.build

run:
	@mix escript.build
	@./cli_chat

fmt:
	@mix format

lint:
	@EXIT_CODE=0;\
	mix format || EXIT_CODE=$$?;\
	mix dialyzer --quiet || EXIT_CODE=$$?;\
	exit $$EXIT_CODE

docs:
	@mix docs --formatter "html" --proglang "elixir"

docs-open:
	@mix docs --formatter "html" --proglang "elixir" --open

clean:
	rm -rf _build
	rm -rf .log
	rm -rf .elixir_ls
	rm -rf doc
	rm -rf log
