###################
# forgottenspiral #
###################

# Ensure that you have set up the folder paths correctly and have 7z/git installed in your system/user path.

# Set up workspace folders before proceeding.
$workspace_folder = "$env:USERPROFILE\Documents\STALKER-PROJECTS\CS-PROJECT"
$release_folder = "$workspace_folder\CS_RELEASE"
$project_folder = "$workspace_folder\CS-MAIN-PROJECT"

# Navigate to the release folder.
Set-Location $release_folder

# Define the version for this release.
$patch_version = "v0.2"

# Begin release process.
Write-Host "====================" -ForegroundColor Green
Write-Host "Starting..." -ForegroundColor Green
Write-Host "====================" -ForegroundColor Green

# Define the folder where final files will be stored.
$final_folder = "Mini-addon_InGameSubs_$patch_version-for_SRP_v1.1.4"

# Create the folder for the files if it doesn't already exist.
If (Test-Path -Path "$final_folder") {
	Write-host "$final_folder already exists." -ForegroundColor Green
}
Else {
	New-Item "$final_folder" -ItemType Directory -Force
	Write-host "$final_folder created successfully." -ForegroundColor Green
}
Write-Host "====================" -ForegroundColor Green

# Determine if releasing is enabled or disabled.
$enable_release = "yes"

If ($enable_release -eq "yes") {
	Write-Host "Releasing is enabled." -ForegroundColor Green
	Write-Host "====================" -ForegroundColor Green

	# Clone the project folder to a temporary one.
	git clone $project_folder "$final_folder-temporal"

	# Remove unnecessary files from the temporary folder.
	Remove-Item -Path "$final_folder-temporal\.git" -Recurse -Force
	Remove-Item -Path "$final_folder-temporal\.gitignore" -Recurse -Force
	Remove-Item -Path "$final_folder-temporal\.gitattributes" -Recurse -Force
	Remove-Item -Path "$final_folder-temporal\CHANGELOG.md" -Recurse -Force
	Remove-Item -Path "$final_folder-temporal\README.md" -Recurse -Force
	Remove-Item -Path "$final_folder-temporal\Release.ps1" -Recurse -Force

	# Copy the files from the temporary folder to the final one.
	Copy-Item -Path "$final_folder-temporal\*" -Destination $final_folder -Recurse -Force

	# Remove the temporary folder.
	Remove-Item -Path "$final_folder-temporal" -Recurse -Force

	# Delete unnecessary or debug files manually.

	# Copy the Instructions and Additional Notes file.
	Copy-Item "$release_folder\Instructions_and_Additional_Notes.txt" -Destination "$final_folder\Instructions_and_Additional_Notes_$patch_version.txt" -Force
	Write-Host "====================" -ForegroundColor Green

	# Copy the Readme and Changelog file.
	Copy-Item "$release_folder\Readme_and_Changelog.txt" -Destination "$final_folder\Readme_and_Changelog_$patch_version.txt" -Force
	Write-Host "====================" -ForegroundColor Green
}
Else {
	Write-Host "Releasing is disabled." -ForegroundColor Yellow
	Write-Host "====================" -ForegroundColor Yellow
}

# Compress the final folder with 7z if it doesn't already exist.
If (!(Test-Path -Path "$final_folder.7z")) {
	7z.exe a "$final_folder.7z" "$final_folder\"
	Write-Host "Compressed the final folder successfully." -ForegroundColor Green
	Write-Host "====================" -ForegroundColor Green
}
Else {
	Write-Host "Compressed file is uncreated." -ForegroundColor Yellow
	Write-Host "====================" -ForegroundColor Yellow
}

Write-Host "Complete." -ForegroundColor Green
Write-Host "====================" -ForegroundColor Green

Pause
Exit
