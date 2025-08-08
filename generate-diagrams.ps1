# Terraform Infrastructure Diagram Generator
# PowerShell automation for blast-radius diagram generation across multiple AWS environments
# 
# Features:
# - Cross-environment diagram generation with validation
# - Interactive server deployment for real-time exploration
# - Automated prerequisite checking and dependency validation
# - Production-ready error handling and logging
#
# Usage:
#   .\generate-diagrams.ps1 generate                    # Generate all environment diagrams
#   .\generate-diagrams.ps1 serve us-west-1/dev 8080   # Start interactive server
#   .\generate-diagrams.ps1 help                       # Display usage information

param(
    [Parameter(Position=0)]
    [ValidateSet("generate", "serve", "help")]
    [string]$Command = "generate",
    
    [Parameter(Position=1)]
    [string]$Environment,
    
    [Parameter(Position=2)]
    [int]$Port = 5000
)

# Get script directory and project root
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-Status "Checking prerequisites..."
    
    # Check if terraform is installed
    try {
        $null = Get-Command terraform -ErrorAction Stop
    }
    catch {
        Write-Error "Terraform is not installed or not in PATH"
        Write-Status "Download from: https://www.terraform.io/downloads.html"
        exit 1
    }
    
    # Check if blast-radius is installed
    try {
        $null = Get-Command blast-radius -ErrorAction Stop
    }
    catch {
        Write-Error "blast-radius is not installed"
        Write-Status "Install with: pip install blastradius"
        exit 1
    }
    
    # Check if graphviz is installed
    try {
        $null = Get-Command dot -ErrorAction Stop
    }
    catch {
        Write-Error "Graphviz is not installed"
        Write-Status "Install with: choco install graphviz"
        Write-Status "Or download from: https://graphviz.org/download/"
        exit 1
    }
    
    Write-Success "All prerequisites are met"
}

# Function to generate diagram for a specific environment
function New-TerraformDiagram {
    param(
        [string]$EnvPath,
        [string]$EnvName
    )
    
    Write-Status "Generating diagram for $EnvName..."
    
    $FullEnvPath = Join-Path $ProjectRoot $EnvPath
    
    # Check if environment directory exists
    if (-not (Test-Path $FullEnvPath)) {
        Write-Warning "Environment directory not found: $EnvPath"
        return
    }
    
    # Navigate to environment directory
    Push-Location $FullEnvPath
    
    try {
        # Check if terraform files exist
        if (-not (Test-Path "main.tf")) {
            Write-Warning "No main.tf found in $EnvPath, skipping..."
            return
        }
        
        # Initialize terraform if needed
        if (-not (Test-Path ".terraform")) {
            Write-Status "Initializing Terraform for $EnvName..."
            terraform init
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Terraform init failed for $EnvName"
                return
            }
        }
        
        # Generate terraform plan
        Write-Status "Creating Terraform plan for $EnvName..."
        terraform plan -out=tfplan 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Terraform plan failed for $EnvName"
            return
        }
        
        # Generate SVG diagram
        $OutputFile = Join-Path $ProjectRoot "diagrams" "$EnvName.svg"
        Write-Status "Generating SVG diagram: $OutputFile"
        
        blast-radius --svg > $OutputFile 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Generated diagram: diagrams\$EnvName.svg"
        }
        else {
            Write-Error "Failed to generate diagram for $EnvName"
        }
        
        # Clean up plan file
        if (Test-Path "tfplan") {
            Remove-Item "tfplan" -Force
        }
    }
    finally {
        # Return to original directory
        Pop-Location
    }
}

# Function to generate diagrams for all environments
function New-AllTerraformDiagrams {
    Write-Status "Generating diagrams for all environments..."
    
    # Define environments
    $Environments = @{
        "us-west-1\dev" = "dev-us-west-1"
        "us-west-1\staging" = "staging-us-west-1"
        "us-west-1\prod" = "prod-us-west-1"
        "us-west-2\dev" = "dev-us-west-2"
    }
    
    # Generate diagrams for each environment
    foreach ($EnvPath in $Environments.Keys) {
        $FullPath = Join-Path $ProjectRoot $EnvPath
        if (Test-Path $FullPath) {
            New-TerraformDiagram -EnvPath $EnvPath -EnvName $Environments[$EnvPath]
        }
        else {
            Write-Warning "Environment directory not found: $EnvPath"
        }
    }
}

# Function to start interactive server for specific environment
function Start-BlastRadiusServer {
    param(
        [string]$EnvPath,
        [int]$Port = 5000
    )
    
    Write-Status "Starting blast-radius server for $EnvPath..."
    
    $FullEnvPath = Join-Path $ProjectRoot $EnvPath
    
    # Check if environment directory exists
    if (-not (Test-Path $FullEnvPath)) {
        Write-Error "Environment directory not found: $EnvPath"
        exit 1
    }
    
    # Navigate to environment directory
    Push-Location $FullEnvPath
    
    try {
        # Check if terraform files exist
        if (-not (Test-Path "main.tf")) {
            Write-Error "No main.tf found in $EnvPath"
            exit 1
        }
        
        # Initialize terraform if needed
        if (-not (Test-Path ".terraform")) {
            Write-Status "Initializing Terraform..."
            terraform init
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Terraform init failed"
                exit 1
            }
        }
        
        # Generate terraform plan
        Write-Status "Creating Terraform plan..."
        terraform plan -out=tfplan
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Terraform plan failed"
            exit 1
        }
        
        Write-Success "Starting server on http://localhost:$Port"
        Write-Status "Press Ctrl+C to stop the server"
        
        # Start blast-radius server
        blast-radius --serve --port $Port
    }
    finally {
        # Return to original directory
        Pop-Location
    }
}

# Function to show help
function Show-Help {
    $HelpText = @"
Terraform Diagram Generation Script (PowerShell)

USAGE:
    .\generate-diagrams.ps1 [COMMAND] [OPTIONS]

COMMANDS:
    generate [ENV]     Generate SVG diagrams
    serve [ENV] [PORT] Start interactive server for environment
    help              Show this help message

EXAMPLES:
    .\generate-diagrams.ps1 generate                      # Generate diagrams for all environments
    .\generate-diagrams.ps1 generate us-west-1\dev       # Generate diagram for specific environment
    .\generate-diagrams.ps1 serve us-west-1\dev          # Start server for dev environment
    .\generate-diagrams.ps1 serve us-west-1\prod 5001    # Start server on custom port

ENVIRONMENTS:
    us-west-1\dev      Development environment (us-west-1)
    us-west-1\staging  Staging environment (us-west-1)
    us-west-1\prod     Production environment (us-west-1)
    us-west-2\dev      Development environment (us-west-2)

PREREQUISITES:
    - Terraform (https://www.terraform.io/downloads.html)
    - Python with pip
    - blast-radius (pip install blastradius)
    - Graphviz (choco install graphviz)

"@
    Write-Host $HelpText
}

# Main execution
switch ($Command) {
    "generate" {
        Test-Prerequisites
        if ($Environment) {
            # Generate specific environment
            $EnvName = Split-Path $Environment -Leaf
            $Region = Split-Path $Environment -Parent
            $Region = $Region -replace "us-", ""
            New-TerraformDiagram -EnvPath $Environment -EnvName "$EnvName-$Region"
        }
        else {
            # Generate all environments
            New-AllTerraformDiagrams
        }
    }
    "serve" {
        Test-Prerequisites
        if ($Environment) {
            Start-BlastRadiusServer -EnvPath $Environment -Port $Port
        }
        else {
            Write-Error "Environment path required for serve command"
            Write-Status "Example: .\generate-diagrams.ps1 serve us-west-1\dev"
            exit 1
        }
    }
    "help" {
        Show-Help
    }
    default {
        Write-Error "Unknown command: $Command"
        Show-Help
        exit 1
    }
}
