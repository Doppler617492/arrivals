SHELL := /bin/sh

# Configuration (override on command line or env)
BASE ?= http://localhost:8081
EMAIL ?= it@cungu.com
PASSWORD ?= Dekodera19892603@@@
COOKIES ?= /tmp/arrivals_cookies.txt
ARRIVAL_ID ?=
FILE ?= README.md

.PHONY: help login-cookie me-cookie refresh-cookie logout-cookie create-arrival upload-file download-file full-cookie-flow clean-cookies

help:
	@echo "Targets:"
	@echo "  login-cookie        - Login and store cookies ($(COOKIES))"
	@echo "  me-cookie           - Call /auth/me with stored cookies"
	@echo "  refresh-cookie      - Refresh access cookie (needs csrf_refresh_token)"
	@echo "  logout-cookie       - Clear cookies on server"
	@echo "  create-arrival      - Create a test arrival (prints JSON)"
	@echo "  upload-file         - Upload FILE to ARRIVAL_ID"
	@echo "  download-file       - Hit download endpoint for last uploaded file"
	@echo "  full-cookie-flow    - Run login -> me -> refresh"
	@echo "Vars: BASE, EMAIL, PASSWORD, COOKIES, ARRIVAL_ID, FILE"

login-cookie:
	@echo "==> Login (cookies -> $(COOKIES))"; \
	curl -sS -c $(COOKIES) -X POST $(BASE)/auth/login-cookie \
	  -H 'Content-Type: application/json' \
	  -d '{"email":"$(EMAIL)","password":"$(PASSWORD)"}' | jq -r '.' || true
	@echo "-- Set-Cookie:"; \
	grep -E 'access_token|refresh_token|csrf_' $(COOKIES) || true

me-cookie:
	@echo "==> /auth/me"; \
	curl -sS -b $(COOKIES) $(BASE)/auth/me | jq -r '.' || true

refresh-cookie:
	@echo "==> Refresh access cookie"; \
	CSRF=$$(grep csrf_refresh_token $(COOKIES) | awk '{print $$7}' | tail -n1); \
	[ -n "$$CSRF" ] || (echo "No csrf_refresh_token in $(COOKIES)" && exit 1); \
	curl -sS -b $(COOKIES) -c $(COOKIES) -X POST $(BASE)/auth/refresh-cookie \
	  -H "X-CSRF-TOKEN: $$CSRF" | jq -r '.' || true

logout-cookie:
	@echo "==> Logout (clear cookies)"; \
	curl -sS -b $(COOKIES) -X POST $(BASE)/auth/logout-cookie | jq -r '.' || true

create-arrival:
	@echo "==> Create arrival"; \
	CSRF=$$(grep csrf_access_token $(COOKIES) | awk '{print $$7}' | tail -n1); \
	[ -n "$$CSRF" ] || (echo "No csrf_access_token in $(COOKIES)" && exit 1); \
	curl -sS -b $(COOKIES) -X POST $(BASE)/api/arrivals \
	  -H 'Content-Type: application/json' -H "X-CSRF-TOKEN: $$CSRF" \
	  -d '{"supplier":"Test","status":"not_shipped"}' | tee /tmp/arrival_create.json | jq -r '.' || true
	@echo "-- id: $$(jq -r '.id // .[0].id' /tmp/arrival_create.json 2>/dev/null || true)"

upload-file:
	@echo "==> Upload file to arrival $(ARRIVAL_ID)"; \
	[ -n "$(ARRIVAL_ID)" ] || (echo "ARRIVAL_ID required" && exit 1); \
	CSRF=$$(grep csrf_access_token $(COOKIES) | awk '{print $$7}' | tail -n1); \
	[ -n "$$CSRF" ] || (echo "No csrf_access_token in $(COOKIES)" && exit 1); \
	curl -sS -b $(COOKIES) -X POST $(BASE)/api/arrivals/$(ARRIVAL_ID)/files \
	  -H "X-CSRF-TOKEN: $$CSRF" \
	  -F "file=@$(FILE)" | tee /tmp/upload_resp.json | jq -r '.' || true
	@echo "-- file id: $$(jq -r '.[-1].id' /tmp/upload_resp.json 2>/dev/null || true)"

download-file:
	@echo "==> Download last uploaded"; \
	FID=$$(jq -r '.[-1].id' /tmp/upload_resp.json 2>/dev/null); \
	[ -n "$$FID" ] || (echo "No upload_resp.json or id" && exit 1); \
	curl -i -sS $(BASE)/api/arrivals/$(ARRIVAL_ID)/files/$$FID/download | sed -n '1,12p'

full-cookie-flow: login-cookie me-cookie refresh-cookie

clean-cookies:
	@rm -f $(COOKIES) /tmp/arrival_create.json /tmp/upload_resp.json
