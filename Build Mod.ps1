# Build script by forbiddenspiral #

# Make sure your global paths are properly configured and 7z/git are accessible in your system/user path.

# Global Paths #

[CmdletBinding()]
param (
  # Set the location where a copy of this repository and its files/folders are (there must be a gamedata folder).
  [string]$RepositoryPath = "$env:USERPROFILE\Documents\STALKER\INGAMESUBS-MODS\CS-MODDING-FOLDER\CS-MAIN-PROJECT",
  # Set the location where the mod is built and stored as a folder together with a compressed 7z file.
  [string]$BuildPath = "$env:USERPROFILE\Documents\STALKER\INGAMESUBS-MODS\CS-MODDING-FOLDER\CS_MAIN_RELEASE"
)

# Script Functions #

function Copy-Items {
  param (
    [Parameter(Mandatory)]
    [array]$Path,
    [Parameter(Mandatory)]
    [string]$Verb,
    [Parameter(Mandatory)]
    [string]$Message
  )

  foreach ($File in $Path) {
    $file_path = $File[0]
    $destination = $File[1]
    if (Test-Path -Path "$file_path" -PathType Any) {
      Copy-Item -Path "$file_path" -Destination "$destination" -Recurse -Force
      Write-Message -Status $? -Verb "$Verb" -Message "$Message '$destination'"
    }
    elseif (-not ($null -eq "$file_path") -or -not ("$file_path" -eq "")) {
      Write-Host "Not copied because it does not exist in '$file_path'"
    }
  }
}

function Remove-Items {
  param (
    [Parameter(Mandatory)]
    [array]$Path,
    [Parameter(Mandatory)]
    [string]$Verb,
    [Parameter(Mandatory)]
    [string]$Message
  )

  foreach ($File in $Path) {
    $file_path = $File[0]
    if (Test-Path -Path "$file_path" -PathType Any) {
      Remove-Item -Path "$file_path" -Recurse -Force
      Write-Message -Status $? -Verb "$Verb" -Message "$Message '$file_path'"
    }
    elseif (-not ($null -eq "$file_path") -or -not ("$file_path" -eq "")) {
      Write-Host "Not deleted because it does not exist in '$file_path'"
    }
  }
}

function Write-Message {
  param (
    [Parameter(Mandatory)]
    [bool]$Status,
    [Parameter(Mandatory)]
    [string]$Verb,
    [Parameter(Mandatory)]
    [string]$Message
  )

  if ($Status -eq $true) {
    Write-Host "$Verb $Message"
  }
  else {
    Write-Host "Not $($Verb.ToLower()) $Message"
  }
}

function Build-Mod {
  param (
  )

  # Check one by one the folders required by the build process.
  $paths = @($RepositoryPath, $BuildPath)
  foreach ($path in $paths) {
    if (-not (Test-Path -Path "$path" -PathType Container)) {
      Write-Host "'$path' does not exist." -ForegroundColor Red
      $missing_folder = $true
    }
  }

  # Check if there is not an important folder missing.
  if (-not ($missing_folder)) {
    Write-Host "Started the process to build the mod."

    # Ask the user to enter the version number for the build.
    Write-Host ""
    $build_version = $(Read-Host "Enter the version number for the new build (default is `"v0.0`")").ToLower()
    if ($build_version -eq "") { $build_version = "v0.0" }

    # Specify the name for the folder where all the mod files will be stored and also the name of the compressed 7z file.
    $build_folder = "InGameSubs_Mod_$build_version-for_SRP_v1.1.4"
    $build_path = "$BuildPath"
    $repository_path = "$RepositoryPath"
    $build_folder_path = "$build_path\$build_folder"
    $compressed_file_path = "$build_path\$build_folder"

    # Create a folder for the build if it does not exist already.
    if (Test-Path -Path "$build_folder_path" -PathType Container) {
      Write-Host "'$build_folder' already exist in '$build_path'"
    }
    else {
      Write-Host "Created new folder for the build in " -NoNewline
      Write-Host "'$(New-Item "$build_folder_path" -ItemType Directory |
        Get-ItemPropertyValue -Name FullName)'"
    }

    # Unset read-only files (prevents accidental modification of original mod files or extracted files from game databases).
    Get-ChildItem -Path "$build_folder_path" -Recurse -File | ForEach-Object { $_.IsReadOnly = $false }
    Write-Message -Status $? -Verb "Unset" -Message "read-only files in '$build_folder_path'"

    # Clone the repository to a temporary directory.
    if ($null -eq (Get-Command "git" -ErrorAction SilentlyContinue)) {
      # git clone [repository] [directory]
      $status = $false
      $missing_git = $true
      $error_message = "'git' is not in your system/user path."
    }
    else {
      git clone "$repository_path" "$build_folder_path-temporary"
      $status = $?
      $missing_git = $false
      $error_message = "Not cloned the mod repository to a temporary folder."
    }

    # Check if the repository was cloned correctly by git.
    if (($status -eq $true) -and -not ($missing_git)) {
      Write-Host "Cloned the mod repository to a temporary folder." -ForegroundColor Green

      # Delete git-related files in the temporary folder.
      $path_list = @(
        @("$build_folder_path-temporary\.git"),
        @("$build_folder_path-temporary\.gitignore"),
        @("$build_folder_path-temporary\.gitattributes"),
        @("$build_folder_path-temporary\CHANGELOG.md"),
        @("$build_folder_path-temporary\README.md"),
        @("$build_folder_path-temporary\Build Mod.ps1")
      )
      Remove-Items -Path $path_list -Verb "Deleted" -Message "git-related file from the cloned repository in"

      # Copy and overwrite files from the temporary folder to the build folder.
      Copy-Item -Path "$build_folder_path-temporary\*" -Destination "$build_folder_path" -Recurse -Force
      Write-Message -Status $? -Verb "Copied and overwrite" -Message "files from the cloned repository to '$build_folder_path'"

      # Delete the temporary folder used to clone the repository.
      Remove-Item -Path "$build_folder_path-temporary" -Recurse -Force
      Write-Message -Status $? -Verb "Deleted" -Message "the temporary folder in '$build_folder_path-temporary'"

      # Delete folders, configuration or debugging files manually.
      # $path_list = @()
      # Remove-Items -Path $path_list -Verb "Deleted" -Message "configuration or debugging file/folder manually in"

      # Create the files or folders that optional features require.

      # Copy the Instructions and Notes file if it exists in $build_path.
      if (Test-Path -Path "$build_path\Instructions and Notes.txt" -PathType Leaf) {
        Copy-Item -Path "$build_path\Instructions and Notes.txt" -Destination "$build_folder_path\Instructions and Notes.txt" -Force
        Write-Message -Status $? -Verb "Copied" -Message "the 'Instructions and Notes.txt' file to '$build_folder_path'"
      }
      else {
        Write-Host "Not copied 'Instructions and Notes.txt' because it does not exist in '$build_path'"
      }

      # Copy the Readme and Changelog file if it exists in $build_path.
      if (Test-Path -Path "$build_path\Readme and Changelog.txt" -PathType Leaf) {
        Copy-Item -Path "$build_path\Readme and Changelog.txt" -Destination "$build_folder_path\Readme and Changelog.txt" -Force
        Write-Message -Status $? -Verb "Copied" -Message "the 'Readme and Changelog.txt' file to '$build_folder_path'"
      }
      else {
        Write-Host "Not copied 'Readme and Changelog.txt' because it does not exist in '$build_path'"
      }

      Write-Host ""
      # Ask the user to compress the build folder with 7z.
      $answer = $(Read-Host -Prompt "Compress the new build to a 7z file? (Yes/No) (default is `"No`")").ToLower()

      if ($answer -eq "yes" -or $answer -eq "y") {
        if (-not ($null -eq (Get-Command "7z" -ErrorAction SilentlyContinue))) {
          $compressed_file_path = "$compressed_file_path.7z"
          7z a -mx=9 "$compressed_file_path" "$build_folder_path" | Out-String
          Write-Message -Status $? -Verb "Created" -Message "a compressed build in '$compressed_file_path'"
        }
        else {
          $compressed_file_path = "$compressed_file_path.zip"
          Compress-Archive -Path "$build_folder_path" -DestinationPath "$compressed_file_path" -CompressionLevel Optimal
          Write-Message -Status $? -Verb "Created" -Message "a compressed build in '$compressed_file_path'"
        }
      }
      else {
        Write-Host "Not compressed the new build to a 7z file."
      }

      # Print a last message if the build process was completed successfully.
      Write-Host ""
      Write-Host "Completed the process to build the mod."
    }
    else {
      # Cancel the build process if git couldn't properly clone the repository.
      Write-Host ""
      Write-Host "$error_message" -ForegroundColor Red
      Write-Host "Canceled the process to build the mod."
    }
  }
  else {
    # Cancel the build process if there is an important folder missing.
    Write-Host ""
    Write-Host "Canceled the process to build the mod."
  }
}

# Script Main Menu #

while ($true) {
  Write-Host "InGameSubs mod." -ForegroundColor Blue
  Write-Host "b - Build the mod."
  Write-Host "e - Clear the terminal."
  Write-Host "q - Quit the script."
  $option = $(Read-Host "Choose an option").ToLower()

  if ($option -eq "q") {
    exit 0
  }
  elseif (($option -eq "e") -or
  ($option -eq "")) {
    Clear-Host
  }
  elseif ($option -eq "b") {
    Write-Host ""
    Build-Mod
    Write-Host ""
  }
  else {
    Write-Host ""
    Write-Host "Not entered a valid option."
    Write-Host ""
  }
}
