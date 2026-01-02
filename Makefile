.PHONY: help all build-zig run-zig test-zig clean-zig setup-python install-python run-python serve clean

# Default target
help:
	@echo "BioSense Prism - Makefile Commands"
	@echo ""
	@echo "Zig ECG Module:"
	@echo "  make build-zig       Build the Zig ECG executable"
	@echo "  make run-zig         Run the Zig ECG application"
	@echo "  make test-zig        Run Zig tests"
	@echo "  make clean-zig       Clean Zig build artifacts"
	@echo ""
	@echo "Python:"
	@echo "  make setup-python    Create Python virtual environment"
	@echo "  make install-python  Install Python dependencies"
	@echo "  make run-python      Run ECG analysis script"
	@echo ""
	@echo "UI:"
	@echo "  make serve           Start local HTTP server for UI (port 8080)"
	@echo "  make serve-alt       Start HTTP server using npx serve"
	@echo "  make open-ui         Open UI directly in browser"
	@echo ""
	@echo "General:"
	@echo "  make all             Build everything (Zig + Python setup)"
	@echo "  make clean           Clean all build artifacts"

# Build all components
all: build-zig setup-python install-python

# Zig ECG Module targets
build-zig:
	@echo "Building Zig ECG module..."
	cd zig-ecg && zig build

run-zig:
	@echo "Running Zig ECG application..."
	cd zig-ecg && zig build run

test-zig:
	@echo "Running Zig tests..."
	cd zig-ecg && zig build test

clean-zig:
	@echo "Cleaning Zig build artifacts..."
	rm -rf zig-ecg/zig-out zig-ecg/.zig-cache

# Python targets
setup-python:
	@echo "Creating Python virtual environment..."
	python3 -m venv venv
	@echo "Virtual environment created. Activate with: source venv/bin/activate"

install-python:
	@echo "Installing Python dependencies..."
	@if [ -d "venv" ]; then \
		./venv/bin/pip install -r requirements.txt; \
	else \
		echo "Virtual environment not found. Run 'make setup-python' first."; \
		exit 1; \
	fi

run-python:
	@echo "Running ECG analysis script..."
	@if [ -d "venv" ]; then \
		./venv/bin/python ecg-analysis.py; \
	else \
		echo "Virtual environment not found. Run 'make setup-python' and 'make install-python' first."; \
		exit 1; \
	fi

# UI targets
serve:
	@echo "Starting HTTP server on port 8080..."
	@echo "Open http://localhost:8080/biosense-prism.html in your browser"
	python3 -m http.server 8080

serve-alt:
	@echo "Starting HTTP server with npx serve..."
	npx serve .

open-ui:
	@echo "Opening UI in browser..."
	open biosense-prism.html

# Clean all build artifacts
clean: clean-zig
	@echo "Cleaning Python cache..."
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "Removing virtual environment..."
	rm -rf venv
	@echo "Clean complete!"
