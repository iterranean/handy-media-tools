# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

See [README.md](README.md) for what this repo is and how to install/run the scripts.

## Pre-commit

- Run `pre-commit run --all-files` before treating any change as complete; fix findings rather than skipping hooks.
- Always run `bats --tap test` to test any scripts changes; fix findings.

## Architecture

- `bin/` contains Linux style small scripts.
- `test/` contains bats tests.

## Version Control.

- Never commit unless specifically asked.
- Never work on main branch, use feature branches.
- Create pull requests when asked.
- When requested to commit must use semantic release decorators.
