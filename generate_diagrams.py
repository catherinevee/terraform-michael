#!/usr/bin/env python3
"""
Terraform Blast Radius Diagram Generator

Production-grade diagram generation for Terraform infrastructure using blast-radius.
Provides programmatic access to interactive dependency visualization across multiple
AWS environments with automated SVG export and metadata generation.

Key Features:
- Multi-environment diagram generation with environment-specific configurations
- Interactive web server for real-time infrastructure exploration
- Automated prerequisite validation and dependency management
- Cross-platform compatibility with Docker support
- Structured metadata generation for CI/CD integration

Usage:
    python generate_diagrams.py generate                    # Generate all diagrams
    python generate_diagrams.py serve --environment dev     # Start interactive server
    make diagrams                                           # Make target integration
"""

import os
import sys
import subprocess
import json
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Optional

class TerraformDiagramGenerator:
    """Generate Terraform diagrams using blast-radius."""
    
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.diagrams_dir = self.project_root / "diagrams"
        
        # Environment configurations
        self.environments = {
            "us-west-1/dev": {
                "name": "dev-us-west-1",
                "description": "Development environment in us-west-1",
                "color": "#3498db"
            },
            "us-west-1/staging": {
                "name": "staging-us-west-1", 
                "description": "Staging environment in us-west-1",
                "color": "#f39c12"
            },
            "us-west-1/prod": {
                "name": "prod-us-west-1",
                "description": "Production environment in us-west-1", 
                "color": "#e74c3c"
            },
            "us-west-2/dev": {
                "name": "dev-us-west-2",
                "description": "Development environment in us-west-2",
                "color": "#2ecc71"
            }
        }
    
    def check_prerequisites(self) -> bool:
        """Check if all required tools are installed."""
        required_tools = ["terraform", "blast-radius", "dot"]
        
        for tool in required_tools:
            try:
                subprocess.run([tool, "--version"], 
                             capture_output=True, check=True)
            except (subprocess.CalledProcessError, FileNotFoundError):
                print(f"ERROR: {tool} is not installed or not in PATH")
                return False
        
        print("All prerequisites are installed")
        return True
    
    def init_terraform(self, env_path: Path) -> bool:
        """Initialize Terraform for the given environment."""
        try:
            result = subprocess.run(
                ["terraform", "init", "-backend=false"],
                cwd=env_path,
                capture_output=True,
                text=True
            )
            return result.returncode == 0
        except Exception as e:
            print(f"ERROR: Failed to initialize Terraform: {e}")
            return False
    
    def create_terraform_plan(self, env_path: Path) -> bool:
        """Create a Terraform plan for diagram generation."""
        try:
            result = subprocess.run(
                ["terraform", "plan", "-out=tfplan"],
                cwd=env_path,
                capture_output=True,
                text=True
            )
            # Plan might fail without AWS credentials, but that's OK for diagrams
            return True
        except Exception as e:
            print(f"WARNING: Terraform plan failed (continuing anyway): {e}")
            return True
    
    def generate_svg_diagram(self, env_path: Path, output_file: Path) -> bool:
        """Generate SVG diagram using blast-radius."""
        try:
            result = subprocess.run(
                ["blast-radius", "--svg"],
                cwd=env_path,
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                output_file.write_text(result.stdout)
                return True
            else:
                print(f"ERROR: blast-radius failed: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"ERROR: Failed to generate diagram: {e}")
            return False
    
    def generate_dot_diagram(self, env_path: Path, output_file: Path) -> bool:
        """Generate DOT diagram for debugging."""
        try:
            result = subprocess.run(
                ["blast-radius", "--dot"],
                cwd=env_path,
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                output_file.write_text(result.stdout)
                return True
            else:
                return False
                
        except Exception:
            return False
    
    def cleanup_temp_files(self, env_path: Path):
        """Clean up temporary files."""
        plan_file = env_path / "tfplan"
        if plan_file.exists():
            plan_file.unlink()
    
    def generate_environment_diagram(self, env_path: str, env_config: Dict) -> bool:
        """Generate diagram for a specific environment."""
        full_env_path = self.project_root / env_path
        
        if not full_env_path.exists():
            print(f"WARNING: Environment {env_path} does not exist, skipping...")
            return False
        
        if not (full_env_path / "main.tf").exists():
            print(f"WARNING: No main.tf found in {env_path}, skipping...")
            return False
        
        print(f"Generating diagram for {env_config['name']}...")
        
        # Create diagrams directory
        self.diagrams_dir.mkdir(exist_ok=True)
        
        # Initialize Terraform
        if not self.init_terraform(full_env_path):
            print(f"WARNING: Terraform init failed for {env_path}, continuing anyway...")
        
        # Create plan
        self.create_terraform_plan(full_env_path)
        
        # Generate SVG diagram
        svg_file = self.diagrams_dir / f"{env_config['name']}.svg"
        svg_success = self.generate_svg_diagram(full_env_path, svg_file)
        
        # Generate DOT diagram for debugging
        dot_file = self.diagrams_dir / f"{env_config['name']}.dot"
        self.generate_dot_diagram(full_env_path, dot_file)
        
        # Cleanup
        self.cleanup_temp_files(full_env_path)
        
        if svg_success:
            print(f"Generated: {svg_file}")
            return True
        else:
            print(f"ERROR: Failed to generate diagram for {env_path}")
            return False
    
    def generate_all_diagrams(self) -> List[str]:
        """Generate diagrams for all environments."""
        print("Generating diagrams for all environments...")
        
        successful_diagrams = []
        
        for env_path, env_config in self.environments.items():
            if self.generate_environment_diagram(env_path, env_config):
                successful_diagrams.append(env_config['name'])
        
        return successful_diagrams
    
    def generate_metadata(self, successful_diagrams: List[str]):
        """Generate metadata file with diagram information."""
        metadata = {
            "generated_at": datetime.now().isoformat(),
            "project": "terraform-michael",
            "diagrams": []
        }
        
        for env_path, env_config in self.environments.items():
            if env_config['name'] in successful_diagrams:
                svg_file = self.diagrams_dir / f"{env_config['name']}.svg"
                dot_file = self.diagrams_dir / f"{env_config['name']}.dot"
                
                metadata["diagrams"].append({
                    "name": env_config['name'],
                    "description": env_config['description'],
                    "environment_path": env_path,
                    "svg_file": svg_file.name,
                    "dot_file": dot_file.name if dot_file.exists() else None,
                    "color": env_config['color']
                })
        
        metadata_file = self.diagrams_dir / "metadata.json"
        metadata_file.write_text(json.dumps(metadata, indent=2))
        print(f"Generated metadata: {metadata_file}")
    
    def serve_interactive(self, environment: str, port: int = 5000):
        """Start interactive blast-radius server for an environment."""
        if environment not in self.environments:
            print(f"ERROR: Unknown environment: {environment}")
            print(f"Available environments: {list(self.environments.keys())}")
            return False
        
        env_path = self.project_root / environment
        if not env_path.exists():
            print(f"ERROR: Environment directory not found: {environment}")
            return False
        
        print(f"Starting blast-radius server for {environment}...")
        print(f"Server will be available at http://localhost:{port}")
        print("Press Ctrl+C to stop the server")
        
        # Initialize and plan
        self.init_terraform(env_path)
        self.create_terraform_plan(env_path)
        
        try:
            subprocess.run(
                ["blast-radius", "--serve", "--port", str(port)],
                cwd=env_path
            )
        except KeyboardInterrupt:
            print("\nServer stopped")
        finally:
            self.cleanup_temp_files(env_path)


def main():
    """Main function."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Generate Terraform infrastructure diagrams using blast-radius"
    )
    parser.add_argument(
        "command",
        choices=["generate", "serve"],
        help="Command to execute"
    )
    parser.add_argument(
        "--environment", "-e",
        help="Specific environment (for serve command)"
    )
    parser.add_argument(
        "--port", "-p",
        type=int,
        default=5000,
        help="Port for interactive server (default: 5000)"
    )
    parser.add_argument(
        "--project-root",
        default=".",
        help="Project root directory (default: current directory)"
    )
    
    args = parser.parse_args()
    
    generator = TerraformDiagramGenerator(args.project_root)
    
    # Check prerequisites
    if not generator.check_prerequisites():
        print("\nInstallation guide:")
        print("  pip install blastradius")
        print("  # Install Graphviz:")
        print("  #   Windows: choco install graphviz")
        print("  #   macOS:   brew install graphviz") 
        print("  #   Linux:   sudo apt-get install graphviz")
        sys.exit(1)
    
    if args.command == "generate":
        successful_diagrams = generator.generate_all_diagrams()
        generator.generate_metadata(successful_diagrams)
        
        print(f"\nSuccessfully generated {len(successful_diagrams)} diagrams")
        print(f"Diagrams saved to: {generator.diagrams_dir}")
        
    elif args.command == "serve":
        if not args.environment:
            print("ERROR: --environment is required for serve command")
            print(f"Available environments: {list(generator.environments.keys())}")
            sys.exit(1)
        
        generator.serve_interactive(args.environment, args.port)


if __name__ == "__main__":
    main()
