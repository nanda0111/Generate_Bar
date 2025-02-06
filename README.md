# Generate_Bar

## Project Overview

`Generate_Bar` is a script-driven process that automates the generation of an IBM ACE BAR (Broker Archive) file and the updating of configuration property files for an IBM ACE (Application Connect Enterprise) project. This project allows you to:
- Generate BAR files from existing ACE applications.
- Override property values in an existing `override.properties` file.
- Push updated property files to a GitHub repository.
- Store the generated BAR files and updated property files in both **local system** and **GitHub**.

## Project Structure

### GitHub Repository

The project structure within the GitHub repository is as follows:

GitHub Repository (Generate_Bar/)

📦 Generate_Bar/      	# GitHubRepository (Stores Source Code & Property File)
│
├── 📂 .github/          # GitHub Actions workflows
│   ├── 📂 workflows/
│   │   ├── override.properties.yml  # GitHub Actions workflow
│	├──  bar_generated.properties    #  if any property file exist previously , then bar_generated.properties will be genratewd after 						running the
├── 📂 workspace/        # IBM ACE workspace (source code stored here)
│   ├── 📂 applications/  # IBM ACE applications
│   │   ├── feb3/
│   │   │   ├── application.descriptor
│   │   │   ├── HTTP_MF_Compute.esql
│   │   │   ├── HTTP_MF.msgflow 
│   │   │   ├──  META-INF
│   │   │   └── .project
│
├── 📂 config/           # Property files for overriding configurations
│   ├── override.property  # Property file to e updated & pushed back to GitHub
│
├── .gitignore           # Ignore unnecessary files (logs, temp files, etc.)
├── README.md            # Documentation for the project



### Local System

The local system project structure looks like this:

Local System (/Generate_Bar/)

📦 /Generate_Bar/         Local System (Stores Final BAR File)
│
├── 📂 file-bar/         # Final BAR file stored here
│   ├── http_demo.bar
│   ├── override.property             # Local script to generate BAR file & update properties
├── buildHTTP.sh            # Local script to generate BAR file & update properties



## Purpose

This project is designed to automate the following tasks:

1. **Generate a BAR file** from an ACE application in the GitHub repository.
2. **Override property values** in the existing `override.properties` file.
3. **Commit the updated property file** back to the GitHub repository.
4. **Store the generated BAR file** and the updated property file in both the **local system** and **GitHub**.

## How to Use

### Prerequisites

Before running the script, ensure that the following are set up:

- IBM App Connect Enterprise (ACE) environment with `mqsicreatebar`, `mqsireadbar`, and `mqsiapplybaroverride` commands available.
- GitHub repository with the following directory structure:
  - `.github/workflows/` for GitHub Actions workflows
  - `workspace/applications/` where ACE application sources are stored
  - `config/override.properties` for property file management

### Step-by-Step Guide

   1. Clone the Repository**:
   	Clone the repository to your local system to access the source code and scripts.
   	``Bash
   		git clone https://github.com/nanda0111/Generate_Bar.git
   		cd Generate_Bar

   2. Prepare the Environment: Ensure the following directories exist in the project structure:

   	workspace/applications/{application_name}
        config/override.properties
    	.github/workflows/ (if using GitHub Actions)

   3.  Run the Script: Execute the buildHTTP.sh script to generate the BAR file and update the property file. The script will:

        Generate the BAR file from the specified ACE application.
    	Extract properties from the generated BAR file.
    	Update the override.properties file with the new property values.
   	Commit the updated property file to GitHub.
    	Trigger the GitHub Actions workflow for property updates.

	Run the following command:
		./buildHTTP.sh

   4.  Check Output:
        The final BAR file (http_demo.bar) will be saved to the file-bar directory on your local system.
        The updated property file (override.properties) will be updated both in the file-bar directory and in the GitHub repository.

   5.	GitHub Workflow: The script will trigger a GitHub Actions workflow (update-properties.yml) to handle any additional property 		updates or actions defined in the workflow.

	Example

	If you are working with an application named feb3, the script will:

   	Generate the http_demo.bar file from the ACE application stored in workspace/applications/feb3.
   	Extract the necessary properties and update the override.properties file in the config/ directory.
    	Commit and push the updated override.properties file back to the GitHub repository.
    	Place both the generated BAR file and the updated properties file in the file-bar directory locally.

   Troubleshooting

	If you encounter issues, check the following:

   	Ensure all directories and files exist as described in the project structure.
    	Ensure GitHub authentication is set up (either with SSH or Personal Access Tokens).
    	Check the log file (buildHTTP.log) for detailed information on any errors or warnings during the process.

   License

	This project is licensed under the MIT License - see the LICENSE file for details.	

	### Key Points:
	- **Structure**: It explains both the **GitHub repository structure** and **local system structure** for the project.
	- **Usage Instructions**: Detailed instructions on how to use the `buildHTTP.sh` script to generate BAR files and update properties.
	- **Project Goals**: Describes what the project does—automating the BAR file generation and updating properties.

	Feel free to customize the README further as needed!
	   
